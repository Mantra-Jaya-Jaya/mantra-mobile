import 'package:flutter/material.dart';
import '../../core/widgets/global_appbar_kurir.dart'; // Sesuaikan path komponen lu!
import '../orders/detail_pengantaran_kurir.dart';

class RutePengantaranPage extends StatelessWidget {
  const RutePengantaranPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🚀 1. Background coklat biar nyatu dengan lengkungan
      backgroundColor: const Color(0xFFAD510D),

      appBar: GlobalAppBarKurir(
        title: 'Rute Pengantaran',
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
      ),

      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 🚀 2. SIZEDBOX SAKTI & WADAH MELENGKUNG BIAR GAK KAKU
            const SizedBox(height: 16),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                child: Stack(
                  children: [
                    // ==========================================
                    // 🚀 LAYER 1: PETA PENGANTARAN (Map Area)
                    // ==========================================
                    Positioned.fill(
                      child: Container(
                        color: Colors.blueGrey.shade50,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.map_outlined,
                                size: 80,
                                color: Colors.blueGrey.shade200,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Area Peta (Bisa di-zoom/geser bebas)',
                                style: TextStyle(
                                  color: Colors.blueGrey.shade300,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ==========================================
                    // 🚀 LAYER 2: BOTTOM SHEET BISA DI-SLIDE
                    // ==========================================
                    DraggableScrollableSheet(
                      initialChildSize:
                          0.5, // 🚀 Ukuran saat pertama kali buka (50% layar)
                      minChildSize:
                          0.12, // 🚀 Ukuran saat disembunyikan (12% layar, nyisain garis putih & Order ID)
                      maxChildSize: 0.5, // 🚀 Ukuran maksimal ditarik ke atas
                      builder:
                          (
                            BuildContext context,
                            ScrollController scrollController,
                          ) {
                            return Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFFAD510D),
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(30),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 20,
                                    offset: Offset(0, -5),
                                  ),
                                ],
                              ),
                              // 🚀 SingleChildScrollView wajib pakai Controller dari Draggable biar bisa diseret
                              child: SingleChildScrollView(
                                controller: scrollController,
                                padding: const EdgeInsets.only(
                                  left: 24,
                                  right: 24,
                                  top: 12,
                                  bottom: 40,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 🚀 DRAG HANDLE (Indikator buat diseret)
                                    Center(
                                      child: Container(
                                        width: 50,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // 🚀 ORDER ID
                                    Text(
                                      'ORDER ID',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'IU790SE',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // 🚀 TUJUAN PENGANTARAN
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.location_on_outlined,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Tujuan Pengantaran',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              const Text(
                                                'Ibu Yunani',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Griya Candi Bahagia, Jl. Cempaka Kayu No.39, Semarang, Jawa Tengah',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white
                                                      .withOpacity(0.8),
                                                  height: 1.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // 🚀 TOTAL BELANJA
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.shopping_bag_outlined,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Total Belanja',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              RichText(
                                                text: const TextSpan(
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.white,
                                                  ),
                                                  children: [
                                                    TextSpan(
                                                      text: 'Rp. 172.000, 00 ',
                                                    ),
                                                    TextSpan(
                                                      text: '(lunas)',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 32),

                                    // 🚀 TOMBOL LIHAT SELENGKAPNYA
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const DetailPesananPage(),
                                            ),
                                          );
                                        },
                                        child: const Text(
                                          'Lihat Selengkapnya',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
