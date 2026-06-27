// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import '../../core/widgets/delivery_card.dart';
import '../../core/widgets/global_appbar_kurir.dart';
import '../../core/services/pengantaran_service.dart';
import '../../core/models/pengantaran_model.dart';

class TugasKurirPage extends StatefulWidget {
  final int initialTabIndex;
  const TugasKurirPage({super.key, this.initialTabIndex = 0});

  @override
  State<TugasKurirPage> createState() => _TugasKurirPageState();
}

class _TugasKurirPageState extends State<TugasKurirPage> {
  int _selectedTabIndex = 0;

  late Future<List<PengantaranModel>> _pengantaranFuture;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
    _fetchData();
  }

  void _fetchData() {
    String filter = "pengantaran";
    if (_selectedTabIndex == 0) {
      filter = "pengantaran";
    } else if (_selectedTabIndex == 1) {
      filter = "tiba_di_tujuan";
    } else if (_selectedTabIndex == 2) {
      filter = "selesai";
    }
    setState(() {
      _pengantaranFuture = PengantaranService().getDaftarPengantaran(
        status: filter,
      );
    });
  }

  Future<void> _refreshData() async {
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFAD510D),

      appBar: GlobalAppBarKurir(
        title: 'Daftar Tugas',
        showBackButton: false,
        onBackPressed: () {},
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(82),
          child: Padding(
            padding: const EdgeInsets.only(
              left: 24,
              right: 24,
              bottom: 20,
              top: 12,
            ),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  // Tombol Pengantaran
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedTabIndex = 0);
                        _fetchData();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 0
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Pengantaran',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _selectedTabIndex == 0
                                ? const Color(0xFFAD510D)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Tombol Tiba Di Tujuan
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedTabIndex = 1);
                        _fetchData();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 1
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Tiba Di Tujuan',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _selectedTabIndex == 1
                                ? const Color(0xFFAD510D)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Tombol Selesai
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedTabIndex = 2);
                        _fetchData();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 2
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Selesai',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _selectedTabIndex == 2
                                ? const Color(0xFFAD510D)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  // 🚀 RefreshIndicator biar kurir bisa pull-to-refresh
                  child: RefreshIndicator(
                    onRefresh: _refreshData,
                    color: const Color(0xFFAD510D),
                    // 🚀 FUTURE BUILDER SAKTI MULAI DI SINI
                    child: FutureBuilder<List<PengantaranModel>>(
                      future: _pengantaranFuture,
                      builder: (context, snapshot) {
                        // 1. Kalau lagi nunggu API (Loading)
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFAD510D),
                            ),
                          );
                        }
                        // 2. Kalau API error / gagal narik data
                        else if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Gagal mengambil data:\n${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        }
                        // 3. Kalau datanya kosong sama sekali dari database
                        else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text(
                              'Belum ada tugas pengantaran.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          );
                        }

                        // 🚀 4. DATANYA ADA! Langsung tampilkan (backend sudah filter sesuai tab)
                        final filteredData = snapshot.data!;

                        if (filteredData.isEmpty) {
                          return Center(
                            child: Text(
                              _selectedTabIndex == 0
                                  ? 'Tidak ada pesanan yang sedang diantar.'
                                  : _selectedTabIndex == 1
                                      ? 'Tidak ada pesanan yang tiba di tujuan.'
                                      : 'Belum ada pesanan yang diselesaikan.',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          );
                        }

                        // 5. Kalau datanya ada, tampilkan di ListView!
                        return ListView.builder(
                          padding: const EdgeInsets.only(
                            top: 24,
                            left: 24,
                            right: 24,
                            bottom: 120,
                          ),
                          itemCount: filteredData.length,
                          physics:
                              const AlwaysScrollableScrollPhysics(), // Biar bisa selalu di-refresh
                          itemBuilder: (context, index) {
                            final dataTugas = filteredData[index];

                            // Panggil DeliveryCard
                            return DeliveryCard(
                              variant: _selectedTabIndex == 2
                                  ? CardVariant.done
                                  : CardVariant.history,
                              idPengantaran: dataTugas.publicId,
                              data: dataTugas,
                              isTibaDiTujuan: _selectedTabIndex == 1,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
