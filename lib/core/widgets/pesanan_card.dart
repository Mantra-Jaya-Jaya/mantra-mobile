import 'package:flutter/material.dart';
import '../../features/orders/detail_pengantaran_kurir.dart';
import '../../features/pengantaran/rute_pengantaran_page.dart';
import '../models/pesanan_kurir_model.dart';
import 'package:geolocator/geolocator.dart';

import '../services/pesanan_kurir_service.dart';

class PesananCard extends StatelessWidget {
  final PesananRingkasModel data;
  final bool isHighlight;
  final String idPengantaran;

  const PesananCard({super.key,required this.idPengantaran, required this.data, this.isHighlight = false});

  @override
  Widget build(BuildContext context) {
    String displayOrderId = data.publicId.length >= 8
        ? data.publicId.substring(0, 8).toUpperCase()
        : 'IU790SE';

    String variantBadge = 'BARANG';
    if (data.daftarBarang.isNotEmpty) {
      variantBadge = data.daftarBarang.first.varian.toUpperCase();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(isHighlight ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isHighlight ? 0.05 : 0.02),
            blurRadius: isHighlight ? 20 : 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isHighlight
              ? const Color(0xFFAD510D).withOpacity(0.3)
              : Colors.grey.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  Text(
                    displayOrderId,
                    style: const TextStyle(
                      fontSize: 14,
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
                  color: const Color(0xFFFF914D),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  variantBadge,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Konten Utama
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isHighlight) ...[
                Column(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFFAD510D),
                      size: 20,
                    ),
                    Container(
                      width: 2,
                      height: 30,
                      color: Colors.grey.shade200,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                    const Icon(
                      Icons.navigation_outlined,
                      color: Color(0xFFAD510D),
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.namaCustomer.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFAD510D),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data.alamatLengkap,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 🚀 JIKA HIGHLIGHT: TAMPILKAN TOMBOL LIHAT DETAIL & TERIMA
          if (isHighlight) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailPesananPage(
                            idPengantaran: idPengantaran,
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFFAD510D),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Lihat Detail',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFAD510D),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // 🚀 PANGGIL FUNGSI DIALOG SAKTI DI SINI
                      _showLocationPermissionDialog(context, idPengantaran);
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
                      'Terima Pesanan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ]
          // JIKA LIST BIASA
          else ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailPesananPage(
                        idPengantaran: idPengantaran,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Lihat Detail',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFAD510D),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  void _showLocationPermissionDialog(
    BuildContext mainContext,
    String idPengantaran,
  ) {
    showDialog(
      context: mainContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isDialogLoading = false;
        // 🚀 Pakai service yang sama persis kayak di halaman detail
        final service = DetailPesananService();

        return StatefulBuilder(
          builder: (context, setStateDialog) {
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
                    const Text(
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
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isDialogLoading
                                ? null
                                : () => Navigator.pop(dialogContext),
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
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isDialogLoading
                                ? null
                                : () async {
                                    setStateDialog(
                                      () => isDialogLoading = true,
                                    );

                                    // 1. Minta Izin GPS ke Sistem HP
                                    LocationPermission permission =
                                        await Geolocator.checkPermission();
                                    if (permission ==
                                        LocationPermission.denied) {
                                      permission =
                                          await Geolocator.requestPermission();
                                      if (permission ==
                                          LocationPermission.denied) {
                                        setStateDialog(
                                          () => isDialogLoading = false,
                                        );
                                        return; // Berhenti kalau user nolak
                                      }
                                    }

                                    // 2. Tembak API Terima Pesanan ke Backend
                                    final newPengantaranId = await service
                                        .terimaPesanan(idPengantaran);

                                    setStateDialog(
                                      () => isDialogLoading = false,
                                    );

                                    // 3. Cek Hasilnya
                                    if (newPengantaranId != null) {
                                      Navigator.pop(
                                        dialogContext,
                                      ); // Tutup dialog Izin
                                      // 🚀 Buka dialog Sukses (Oper mainContext biar navigasinya aman)
                                      _showSuccessDialog(
                                        mainContext,
                                        newPengantaranId,
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        mainContext,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Gagal! Pesanan mungkin sudah diambil kurir lain.',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFAD510D),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: isDialogLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
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
      },
    );
  }

  void _showSuccessDialog(BuildContext mainContext, String newId) {
    showDialog(
      context: mainContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        // 🚀 Kopi Paste Auto-Redirect Lu! Otomatis pindah setelah 2 detik!
        Future.delayed(const Duration(seconds: 2), () {
          if (mainContext.mounted) {
            Navigator.pop(dialogContext); // Tutup dialog
            Navigator.push(
              mainContext, // Push pakai context utama
              MaterialPageRoute(
                builder: (context) => RutePengantaranPage(idPengantaran: newId),
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
                ),
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
                const Text(
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
