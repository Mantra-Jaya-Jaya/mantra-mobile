import 'package:flutter/material.dart';
import '../../core/widgets/card_item_pemesanan_kurir.dart';
import '../../core/widgets/global_appbar_kurir.dart';
import '../pengantaran/rute_pengantaran_page.dart'; 

// ==========================================
// 1. WIDGET UTAMA: HALAMAN DETAIL PESANAN
// ==========================================
class DetailPesananPage extends StatelessWidget {
  const DetailPesananPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFAD510D), // Coklat valid Mantra!
      // 🚀 PANGGIL KOMPONEN GLOBAL APP BAR
      appBar: GlobalAppBarKurir(
        title: 'Detail Pesanan',
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
      ),

      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 🚀 1. SIZEDBOX SAKTI BIAR LENGKUNGANNYA GAK KEMEPETAN
            const SizedBox(height: 16),

            // 🚀 WADAH PUTIH MELENGKUNG
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🚀 HEADER: ORDER ID & STATUS BADGE
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ORDER ID',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'IU790SE',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5B6B76),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'BELUM DITERIMA',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Jarak dari header ke list barang sedikit dirapatkan
                        const SizedBox(height: 20),

                        // 🚀 LIST BARANG (Nanti bisa diganti pakai ListView.builder dari API)
                        const OrderItemCard(
                          namaBarang: 'Nama barang 1',
                          qty: 1,
                          harga: 'Rp. 50.000',
                        ),
                        const OrderItemCard(
                          namaBarang: 'Nama barang 2',
                          qty: 1,
                          harga: 'Rp. 50.000',
                        ),
                        const OrderItemCard(
                          namaBarang: 'Nama barang 3',
                          qty: 1,
                          harga: 'Rp. 50.000',
                        ),

                        const SizedBox(height: 16),

                        // 🚀 SEKSI TUJUAN PENGANTARAN
                        const Text(
                          'Tujuan Pengantaran',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Ibu Yunani',
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Griya Candi Bahagia, Jl. Cempaka Kayu No.39,\nSemarang, Jawa Tengah',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Divider(
                            thickness: 2,
                            color: Color(0xFFEEEEEE),
                          ),
                        ),

                        // 🚀 SEKSI TOTAL BELANJA (Struk Rincian dirapatkan)
                        const Text(
                          'Total Belanja',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildReceiptRow('Item 1', 'x1', 'Rp. 50.000, 00'),
                        _buildReceiptRow('Item 2', 'x1', 'Rp. 50.000, 00'),
                        _buildReceiptRow('Item 3', 'x1', 'Rp. 50.000, 00'),
                        _buildReceiptRow(
                          'Delivery fee',
                          '',
                          'Rp. 20.000, 00',
                          isGreyTitle: true,
                        ),
                        _buildReceiptRow(
                          'Protection fee',
                          '',
                          'Rp. 2.000, 00',
                          isGreyTitle: true,
                        ),

                        // Jarak ke Subtotal
                        const SizedBox(height: 4),
                        _buildReceiptRow(
                          'Subtotal',
                          '',
                          'Rp. 172.000, 00',
                          isBold: true,
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Divider(
                            thickness: 2,
                            color: Color(0xFFEEEEEE),
                          ),
                        ),

                        // 🚀 SEKSI METODE PEMBAYARAN
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Metode Pembayaran',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Transfer Bank (lunas)',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Divider(
                            thickness: 2,
                            color: Color(0xFFEEEEEE),
                          ),
                        ),

                        // 🚀 SEKSI PENDAPATAN KURIR
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Pendapatan Kurir',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFAD510D),
                              ),
                            ),
                            const Text(
                              'Rp. 35.000, 00',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFAD510D),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // 🚀 FIXED BOTTOM BUTTON
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            // 🚀 PANGGIL FUNGSI DIALOG PERTAMA DI SINI
            onPressed: () {
              _showLocationPermissionDialog(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFAD510D),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Terima Pesanan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🚀 2. HELPER FUNGSI DIRAPATKAN (padding bottom dikurangi)
  Widget _buildReceiptRow(
    String title,
    String qty,
    String price, {
    bool isBold = false,
    bool isGreyTitle = false,
  }) {
    return Padding(
      // Padding ini disusutkan dari 12 jadi 6 biar rapet kayak struk asli!
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: isGreyTitle
                    ? Colors.grey.shade400
                    : (isBold ? Colors.black : Colors.grey.shade400),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              qty,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              price,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: isBold ? Colors.black : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Biar ga bisa ditutup sembarangan kalau klik luar
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 50,
                  color: Color(0xFFAD510D),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Aplikasi perlu mengetahui\nlokasimu',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF301905),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Izinkan akses lokasi untuk pemantauan\nproses pengantaran',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    // Tombol Tolak
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.pop(context), // Cukup tutup dialog
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFFAD510D),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Tolak',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFAD510D),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Tombol Izinkan
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Nanti kode untuk memanggil permission sistem aslinya ditaruh di sini
                          Navigator.pop(context); // Tutup dialog pertama
                          _showSuccessDialog(context); // Panggil dialog kedua
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFAD510D),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Izinkan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 🚀 FUNGSI 2: MUNCULIN DIALOG SUKSES & OTOMATIS PINDAH HALAMAN
  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // 🚀 Ini sihirnya: Delay 2 detik lalu otomatis pindah halaman
        Future.delayed(const Duration(seconds: 2), () {
          // Cek kalau widget masih ada biar ga error
          if (Navigator.of(context).canPop()) {
            Navigator.pop(context); // Tutup dialog sukses
            // Gunakan pushReplacement biar kalau di-back dari peta, gak balik ke dialog
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const RutePengantaranPage(),
              ),
            );
          }
        });

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.two_wheeler,
                  size: 60,
                  color: Color(0xFFAD510D),
                ), // Ikon Motor Kurir
                const SizedBox(height: 16),
                const Text(
                  'Pesanan diterima!\nPelacakan lokasi aktif',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFAD510D),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Mari mengantar pesanan ini dengan selamat.\nSemangat!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
