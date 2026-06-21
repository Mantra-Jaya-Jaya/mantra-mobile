# Changelog — Push Notifikasi Customer & Bug Fix Redirect

## Ringkasan

Perubahan ini menambahkan **push notification untuk role Customer** dan **memperbaiki bug redirect tiap 15 detik** ke halaman onboarding. Total 10 file diubah (5 backend + 5 frontend).

---

## Daftar File yang Diubah

### Frontend (Flutter/Dart) — 5 file

| # | File | Perubahan |
|---|------|-----------|
| 1 | `lib/core/network/api_client.dart` | Skip redirect saat header `X-Skip-Auth-Redirect: true` |
| 2 | `lib/core/services/notifikasi_service.dart` | Tambah header skip-redirect + import Dio |
| 3 | `lib/core/services/push_notification_service.dart` | Role-aware polling, channel customer, navigasi sesuai role |
| 4 | `lib/core/services/customer_checkout_service.dart` | Tambah parameter `items`, catch DioException untuk pesan error |
| 5 | `lib/features/cart/checkout.dart` | Kirim `items` ke backend, pakai `id_metode` (kode), fallback `id` varian |
| 6 | `lib/features/home/home_customer.dart` | Panggil `PushNotificationService.setRole('customer')` |
| 7 | `lib/features/home/home_kasir.dart` | Panggil `PushNotificationService.setRole('kasir')` |

### Backend (Go) — 5 file

| # | File | Perubahan |
|---|------|-----------|
| 1 | `controllers/transaksi/pesanan_controller.go` | Notif checkout, batal, kirim untuk customer |
| 2 | `controllers/transaksi/midtrans_webhook.go` | Notif pembayaran sukses untuk customer |
| 3 | `controllers/pengantaran/pengantaran_controller.go` | Notif pesanan selesai untuk customer |

---

## Detail Perubahan

### 1. Bug Fix — Redirect tiap 15 detik ke Landing Page

**Penyebab:**
- `PushNotificationService.startPolling()` dipanggil di `main.dart` saat app start
- Setiap 15 detik, Dio request `GET /kasir/notifikasi` dikirim
- Sebelum login, tidak ada JWT token → response 401
- Interceptor `_AuthInterceptor.onError` (api_client.dart) menangkap 401 → hapus storage → navigasi ke `LandingPage`
- Ini terjadi terus setiap 15 detik, menarik user keluar dari halaman manapun

**Perbaikan:**
- `api_client.dart:57-60` — cek header `X-Skip-Auth-Redirect`, jika ada lewati redirect
- `notifikasi_service.dart:53,74` — semua request notifikasi (kasir & customer) kasih header `X-Skip-Auth-Redirect: true`

### 2. Backend — 5 titik notifikasi untuk Customer

Semua menggunakan pola goroutine (sama seperti notifikasi kasir di line 689):

#### a) Notifikasi Checkout (`pesanan_controller.go:707-716`)

```go
// Setelah tx.Commit() di CheckoutPesanan
go func() {
    notif := models.Notifikasi{
        UserID:             userID,
        Judul:              "Pesanan Dibuat",
        Pesan:              "Pesanan Anda berhasil dibuat dan sedang diproses.",
        StatusNotifikasiID: utils.GetStatusNotifikasiID("unread"),
    }
    config.DB.Create(&notif)
}()
```

**Trigger:** Customer berhasil checkout (klik Buat Pesanan)

#### b) Notifikasi Pembayaran Berhasil (`midtrans_webhook.go:134-149`)

```go
// Saat transaction_status = settlement/capture
if isLunas {
    go func() {
        var pesanan models.Pesanan
        config.DB.Preload("Customer.User").Where("id_pesanan = ?", pembayaran.PesananID).First(&pesanan)
        if pesanan.Customer.User.IdUser != 0 {
            notif := models.Notifikasi{
                UserID:             pesanan.Customer.User.IdUser,
                Judul:              "Pembayaran Berhasil",
                Pesan:              "Pembayaran Anda telah diterima. Pesanan sedang dikemas.",
                StatusNotifikasiID: utils.GetStatusNotifikasiID("unread"),
            }
            config.DB.Create(&notif)
        }
    }()
}
```

**Trigger:** Midtrans mengirim notifikasi settlement/capture

#### c) Notifikasi Pesanan Dikirim (`pesanan_controller.go:1439-1452`)

```go
// Setelah update status ke "Dikirim" di KirimPesanan
go func() {
    var p models.Pesanan
    config.DB.Preload("Customer.User").Where("id_pesanan = ?", pesanan.IdPesanan).First(&p)
    if p.Customer.User.IdUser != 0 {
        notif := models.Notifikasi{
            UserID:             p.Customer.User.IdUser,
            Judul:              "Pesanan Dikirim",
            Pesan:              "Pesanan Anda telah dikirim dengan nomor resi: " + input.NomorResi,
            StatusNotifikasiID: utils.GetStatusNotifikasiID("unread"),
        }
        config.DB.Create(&notif)
    }
}()
```

**Trigger:** Kasir klik Kirim dan mengisi nomor resi

#### d) Notifikasi Pesanan Selesai (`pengantaran_controller.go:861-876`)

```go
// Setelah status pengantaran = "Selesai"
if statusInput == "Selesai" {
    go func() {
        var p models.Pesanan
        config.DB.Preload("Customer.User").Where("id_pesanan = ?", pengantaran.PesananID).First(&p)
        if p.Customer.User.IdUser != 0 {
            notif := models.Notifikasi{
                UserID:             p.Customer.User.IdUser,
                Judul:              "Pesanan Selesai",
                Pesan:              "Pesanan Anda telah selesai. Terima kasih telah berbelanja!",
                StatusNotifikasiID: utils.GetStatusNotifikasiID("unread"),
            }
            config.DB.Create(&notif)
        }
    }()
}
```

**Trigger:** Kurir menyelesaikan pengantaran

#### e) Notifikasi Pesanan Dibatalkan (`pesanan_controller.go:813-822`)

```go
// Setelah status diubah ke "Dibatalkan"
go func() {
    notif := models.Notifikasi{
        UserID:             userID,
        Judul:              "Pesanan Dibatalkan",
        Pesan:              "Pesanan Anda telah dibatalkan.",
        StatusNotifikasiID: utils.GetStatusNotifikasiID("unread"),
    }
    config.DB.Create(&notif)
}()
```

**Trigger:** Customer klik Batalkan Pesanan (dengan syarat status masih "Menunggu Pembayaran")

### 3. Frontend — Push Notification Role-Aware

**File:** `push_notification_service.dart` — rewrite total

| Komponen | Sebelum | Sesudah |
|----------|---------|---------|
| Role | Selalu kasir | `''` (default) → `'kasir'` / `'customer'` |
| Channel Android | `kasir_notif_channel` saja | `kasir_notif_channel` + `customer_notif_channel` |
| Polling API | Selalu `getNotifikasiKasir()` | Pilih sesuai `_role` |
| SharedPref key | `last_notification_id` | `last_notification_id_kasir` / `last_notification_id_customer` |
| Tap notifikasi | Navigasi ke `NotificationScreen` (kasir) | Navigasi ke screen sesuai `_role` |

**Mekanisme:**
- Role default `''` → `checkNewNotifications()` langsung return (tidak ada polling efektif)
- Setiap home screen panggil `PushNotificationService.setRole('customer'/'kasir')` di `initState`
- Setelah role di-set, polling mulai menggunakan API/channel yang sesuai
- `showLocalNotification` menggunakan channel sesuai role

### 4. Fix Checkout 400 — Field `items` hilang & `metode_pembayaran` salah

**Tiga masalah yang diperbaiki:**

| Masalah | Sebelum | Sesudah |
|---------|---------|---------|
| `items` tidak dikirim | `customer_checkout_service.dart` tidak punya parameter `items` | Tambah parameter `required List<Map<String, dynamic>> items`, kirim di payload |
| `id_spesifikasi_barang` jadi 0 | Mapping langsung `p['id_spesifikasi_barang']` tanpa fallback | Tambah fallback `?? p['id']` (karena "Beli Sekarang" pakai key `id`) |
| `metode_pembayaran` pakai DB ID | `_pembayaranDipilih!['id_metode_pembayaran']` | Ganti ke `_pembayaranDipilih!['id_metode']` (kode: "qris", "tunai", "va_bni", dll) |

### 5. Error Handling Checkout — Tampilkan pesan asli dari backend

**File:** `customer_checkout_service.dart:55-58`

```dart
on DioException catch (e) {
    final msg = e.response?.data['message'] ?? 'Gagal membuat pesanan';
    throw Exception(msg);
}
```

Sebelumnya `DioException` dilempar langsung, snackbar cuma tampil `DioException [bad response]...`. Sekarang snackbar tampil pesan error asli dari backend.

---

## Catatan Penting

- **Compile error nil check:** struct `Customer` dan `User` di Go bukan pointer, jadi tidak bisa dibandingkan dengan `nil`. Fix: ganti `p.Customer != nil && p.Customer.User != nil` → `p.Customer.User.IdUser != 0`
- **Backward compatibility:** Semua perubahan untuk kasir tetap 100% sama
- **Polling:** Tidak menggunakan FCM/OneSignal, tetap pakai polling 15 detik
- **Seeder:** Data notifikasi seeding untuk customer sudah ada di `notifikasi_seeder.go:31-35`

---

## Cara Test

1. Jalankan ulang backend (`make run`) dan frontend (`flutter run`)
2. Login sebagai Customer
3. Lakukan checkout, bayar, tunggu dikirim/diantar
4. Notifikasi akan muncul di tray Android dalam ~15 detik setelah event terjadi
5. Tap notifikasi → langsung ke halaman Notifikasi Customer
