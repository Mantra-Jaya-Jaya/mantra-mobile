import 'package:flutter/material.dart';
import '../../core/widgets/delivery_card.dart';
import '../../core/widgets/global_appbar_kurir.dart';
import '../../core/services/pengantaran_service.dart';
import '../../core/models/pengantaran_model.dart';

class TugasKurirPage extends StatefulWidget {
  const TugasKurirPage({super.key});

  @override
  State<TugasKurirPage> createState() => _TugasKurirPageState();
}

class _TugasKurirPageState extends State<TugasKurirPage> {
  // State untuk toggle tab (true = Pengantaran, false = Selesai)
  bool _isPengantaran = true;

  // 🚀 Bikin variabel Future buat nampung tarikan data API
  late Future<List<PengantaranModel>> _pengantaranFuture;

  @override
  void initState() {
    super.initState();
    // 🚀 Tarik data dari API saat halaman pertama kali dibuka
    _pengantaranFuture = PengantaranService().getDaftarPengantaran();
  }

  // 🚀 Fungsi buat nge-refresh data kalau ditarik ke bawah (opsional, tapi best practice)
  Future<void> _refreshData() async {
    setState(() {
      _pengantaranFuture = PengantaranService().getDaftarPengantaran();
    });
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
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  // Tombol Pengantaran
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isPengantaran = true),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          color: _isPengantaran
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Pengantaran',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _isPengantaran
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
                      onTap: () => setState(() => _isPengantaran = false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          color: !_isPengantaran
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Selesai',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: !_isPengantaran
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

                        // 🚀 4. DATANYA ADA! Sekarang kita filter sesuai tab yang dipencet
                        final allData = snapshot.data!;
                        final filteredData = allData.where((item) {
                          if (_isPengantaran) {
                            // Tab Pengantaran: Tampilkan yang statusnya BUKAN Selesai
                            return item.status.toLowerCase() != 'selesai';
                          } else {
                            // Tab Selesai: Tampilkan KHUSUS yang statusnya Selesai
                            return item.status.toLowerCase() == 'selesai';
                          }
                        }).toList();

                        // 5. Cek lagi kalau setelah difilter ternyata kosong
                        if (filteredData.isEmpty) {
                          return Center(
                            child: Text(
                              _isPengantaran
                                  ? 'Tidak ada pesanan yang sedang diantar.'
                                  : 'Belum ada pesanan yang diselesaikan.',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          );
                        }

                        // 6. Kalau datanya ada, tampilkan di ListView!
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
                              variant: _isPengantaran
                                  ? CardVariant.history
                                  : CardVariant.done,
                              idPengantaran: dataTugas.publicId,
                              data: dataTugas,
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
