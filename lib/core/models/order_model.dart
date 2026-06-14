import '../constants/status_constants.dart';

class OrderItemModel {
  final String namaBarang;
  final int qty;
  final int hargaSatuan;

  OrderItemModel({
    required this.namaBarang,
    required this.qty,
    required this.hargaSatuan,
  });

  // Tambahkan factory constructor untuk item agar bisa memetakan data dari backend Go nantinya
  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      namaBarang: json['nama_barang'] ?? json['NamaBarang'] ?? '',
      qty: (json['qty'] ?? json['Qty'] ?? 0).toInt(),
      hargaSatuan: (json['harga_satuan'] ?? json['HargaSatuan'] ?? 0).toInt(),
    );
  }
}

class OrderModel {
  final String orderId;       // Menampilkan ID pesanan ringkas/UUID terpotong
  final int idStatusPesanan;  // Status ID dari backend (integer)
  final String statusText;
  final String itemsDetail;
  final String timeInfo;      // Menampilkan tanggal yang sudah diformat rapi
  final String price;         // Format Rupiah (cth: Rp 125.000)
  final int rawPrice;
  final String imgUrl;
  final bool isOnline;
  final List<OrderItemModel> detailItems;

  OrderModel({
    required this.orderId,
    required this.idStatusPesanan,
    required this.statusText,
    required this.itemsDetail,
    required this.timeInfo,
    required this.price,
    required this.rawPrice,
    required this.imgUrl,
    required this.isOnline,
    required this.detailItems,
  });

  // Helper methods menggunakan StatusConstants
  String get statusDisplayName => StatusConstants.getDisplayName(idStatusPesanan);
  String get statusColor => StatusConstants.getColor(idStatusPesanan);
  bool get isCompleted => StatusConstants.isCompleted(idStatusPesanan);
  bool get isCancelled => StatusConstants.isCancelled(idStatusPesanan);

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // 1. Ambil Status ID dari backend (integer)
    int statusId = (json['id_status_pesanan'] ?? json['status_id'] ?? 1).toInt();

    // 2. KUNCI UTAMA FILTER TAB - Gunakan StatusConstants
    bool checkIsOnline = StatusConstants.isOnlineStatus(statusId);

    // Sesuaikan teks status untuk tampilan UI Kasir
    if (!checkIsOnline) {
      statusStr = "Selesai"; // Sesuai request: Offline udah pasti statusnya selesai semua
    } else {
      statusStr = "Diproses"; // Standarisasi teks tampilan online biar seragam
    }

    // 3. Ambil Harga Nyata (Membaca key 'total_bayar' dari backend temanmu)
    int totalBayar = 0;
    var rawPrice = json['total_bayar'] ?? json['total_pembayaran'] ?? json['totalPembayaran'];
    if (rawPrice != null) {
      if (rawPrice is num) {
        totalBayar = rawPrice.toInt();
      } else {
        totalBayar = int.tryParse(rawPrice.toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      }
    }

    // 4. Ambil ID Pesanan (Membaca key 'id_pesanan' dari backend)
    String idTampil = (json['id_pesanan'] ?? json['public_id'] ?? json['publicId'] ?? '').toString();
    if (idTampil.length > 8) {
      idTampil = idTampil.substring(0, 8).toUpperCase();
    }

    // 5. Format Tanggal Pesanan (Membaca key 'tanggal_pesan' dari backend)
    String formatTanggal = "Baru saja";
    final String rawTanggal = (json['tanggal_pesan'] ?? json['tanggal_pesanan'] ?? '').toString();
    if (rawTanggal.isNotEmpty) {
      try {
        final DateTime parsedDate = DateTime.parse(rawTanggal).toLocal();
        formatTanggal = "${parsedDate.day.toString().padLeft(2, '0')}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.year} ${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}";
      } catch (_) {}
    }

    // 6. Ringkasan Nama Barang Riil (Membaca array 'items' dari backend temanmu)
    String ringkasanItem = checkIsOnline ? "1x Pesanan Online" : "1x Transaksi Kasir";
    if (json['items'] != null && (json['items'] as List).isNotEmpty) {
      var listItems = json['items'] as List;
      var firstItem = listItems[0];
      int qty = firstItem['jumlah'] ?? 1;
      String namaBarang = firstItem['nama_barang'] ?? 'Produk';
      
      if (listItems.length > 1) {
        ringkasanItem = "$qty" "x $namaBarang (+${listItems.length - 1} item lainnya)";
      } else {
        ringkasanItem = "$qty" "x $namaBarang";
      }
    }

    return OrderModel(
      orderId: idTampil.isNotEmpty ? "#ORD-$idTampil" : "#ORD-UNKNOWN",
      idStatusPesanan: statusId,
      statusText: StatusConstants.getName(statusId),
      itemsDetail: ringkasanItem,
      timeInfo: formatTanggal,
      // Memformat nominal integer menjadi Rupiah ber-titik otomatis (cth: Rp 125.000)
      price: totalBayar > 0
          ? "Rp ${totalBayar.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}"
          : "Rp 0",
      rawPrice: totalBayar,
      imgUrl: "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/I5ymBTe5W6/53kzg4cp_expires_30_days.png",
      isOnline: checkIsOnline,
      detailItems: [],
    );
  }
}