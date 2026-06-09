import 'package:flutter/material.dart';
import '../../core/models/pesanan_kurir_model.dart';
import '../../core/models/laporan_kurir_model.dart';
import '../../core/services/laporan_kurir_service.dart';
import '../../core/services/pesanan_kurir_service.dart';
import '../../core/widgets/app_bar_home_kurir.dart';
import '../../core/widgets/bottom_navbar.dart';
import '../../core/widgets/pesanan_card.dart';
import '../orders/tugas_kurir.dart';
import '../profile/profile_kurir.dart';

// ==========================================
// 1. WIDGET INDUK (Pegang Bottom Nav & Routing)
// ==========================================
class DashboardKurir extends StatefulWidget {
  const DashboardKurir({super.key});

  @override
  State<DashboardKurir> createState() => _DashboardKurirState();
}

class _DashboardKurirState extends State<DashboardKurir> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardContent(),
    const TugasKurirPage(),
    const ProfileKurirPage(),
  ];

  final List<NavMenuModel> _menus = [
    NavMenuModel(label: 'Home', icon: Icons.home_filled, index: 0),
    NavMenuModel(label: 'Tugas', icon: Icons.local_shipping_outlined, index: 1),
    NavMenuModel(label: 'Profile', icon: Icons.person_outline, index: 2),
  ];

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double navPadding = 20.0;
    double rowWidth = screenWidth - (navPadding * 2);
    double sectionWidth = rowWidth / _menus.length;
    double fabXOffset =
        (sectionWidth * _currentIndex) + (sectionWidth / 2) - 28 + navPadding;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: IndexedStack(index: _currentIndex, children: _pages),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFFAD510D),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
          side: const BorderSide(color: Colors.white, width: 4),
        ),
        child: Icon(_menus[_currentIndex].icon, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: DynamicFabLocation(fabXOffset),
      bottomNavigationBar: CustomDynamicNavbar(
        currentIndex: _currentIndex,
        menus: _menus,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}

// ==========================================
// 2. WIDGET KONTEN (Isi Halaman Dashboard)
// ==========================================
class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  late Future<PesananRingkasModel?> _pesananTerbaruFuture;
  late Future<List<PesananRingkasModel>> _semuaPesananFuture;
  late Future<LaporanKurirModel?> _laporanFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() {
      _pesananTerbaruFuture = PesananService().getPesananTerbaru();
      _semuaPesananFuture = PesananService().getAllPesananOnline();
      _laporanFuture = LaporanService().getLaporanHariIni();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: const Color(0xFFAD510D),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            const AppBarHomeKurir(),
            Transform.translate(
              offset: const Offset(0, -24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🚀 1. PESANAN BARU
                    const Text(
                      'Pesanan Baru',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<PesananRingkasModel?>(
                      future: _pesananTerbaruFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFAD510D),
                            ),
                          );
                        } else if (snapshot.hasError ||
                            !snapshot.hasData ||
                            snapshot.data == null) {
                          return _buildEmptyState('Belum ada pesanan masuk.');
                        }
                        return PesananCard(
                          idPengantaran: snapshot.data!.publicId,
                          data: snapshot.data!,
                          isHighlight: true,
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // 🚀 2. LAPORAN DESAIN ELEGAN (SATU KOTAK, ADA DIVIDERNYA)
                    const Text(
                      'Laporan Hari Ini',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<LaporanKurirModel?>(
                      future: _laporanFuture,
                      builder: (context, snapshot) {
                        String selesai = '0';
                        String proses = '0';
                        String tersedia = '0';

                        if (snapshot.hasData && snapshot.data != null) {
                          selesai = '${snapshot.data!.pesananSelesai}';
                          proses = '${snapshot.data!.pesananProses}';
                          tersedia = '${snapshot.data!.pesananTersedia}';
                        }

                        // 🚀 DESAIN BARU: LIST MENURUN SUPER ELEGAN
                        return Column(
                          children: [
                            _buildLaporanTile(
                              Icons.inbox_outlined,
                              'Pesanan Menunggu',
                              'Paket nganggur yang siap diantar',
                              tersedia,
                              true, // Card pertama di-highlight full coklat
                            ),
                            _buildLaporanTile(
                              Icons.local_shipping_outlined,
                              'Sedang Diperjalanan',
                              'Paket yang lagi kamu bawa sekarang',
                              proses,
                              false,
                            ),
                            _buildLaporanTile(
                              Icons.check_circle_outline,
                              'Berhasil Diantar',
                              'Kerja kerasmu yang udah tuntas hari ini',
                              selesai,
                              false,
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // 🚀 3. DAFTAR PESANAN LAINNYA
                    const Text(
                      'Daftar Pesanan Tersedia',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ), // 🚀 Jarak udah dikurangin drastis

                    FutureBuilder<List<PesananRingkasModel>>(
                      future: _semuaPesananFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFAD510D),
                            ),
                          );
                        } else if (snapshot.hasError ||
                            !snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: _buildEmptyState('Tidak ada pesanan lain.'),
                          );
                        }

                        final daftarLainnya = snapshot.data!.skip(1).toList();
                        if (daftarLainnya.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: _buildEmptyState('Tidak ada pesanan lain.'),
                          );
                        }

                        return ListView.builder(
                          padding: EdgeInsets
                              .zero, // 🚀 MENGHAPUS PADDING BAWAAN LISTVIEW BIAR GAK JAUH
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: daftarLainnya.length,
                          itemBuilder: (context, index) {
                            return PesananCard(
                              idPengantaran: daftarLainnya[index].publicId,
                              data: daftarLainnya[index],
                            );
                          },
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

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade300,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

// 🚀 DESAIN KOTAK LAPORAN BARU (MODERN LIST TILE)
  Widget _buildLaporanTile(
    IconData icon,
    String title,
    String subtitle,
    String value,
    bool isPrimary,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFFAD510D) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPrimary ? const Color(0xFFAD510D) : Colors.grey.shade100,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isPrimary
                ? const Color(0xFFAD510D).withOpacity(0.25)
                : Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon Box
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isPrimary
                  ? Colors.white.withOpacity(0.2)
                  : const Color(0xFFAD510D).withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: isPrimary ? Colors.white : const Color(0xFFAD510D),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isPrimary ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isPrimary
                        ? Colors.white.withOpacity(0.8)
                        : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          // Angka Besar
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: isPrimary ? Colors.white : const Color(0xFFAD510D),
            ),
          ),
        ],
      ),
    );
  }
}
