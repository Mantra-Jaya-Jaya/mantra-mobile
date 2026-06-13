import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/models/pesanan_kurir_model.dart'; // Sesuaikan path model lu yang bener (DetailPesananModel)
import '../../core/services/pengantaran_service.dart';
import '../../core/services/pesanan_kurir_service.dart'; // Sesuaikan path service lu
import '../../core/widgets/card_item_pemesanan_kurir.dart';
import '../../core/widgets/global_appbar_kurir.dart';
import '../pengantaran/ambil_bukti_page.dart';
import '../pengantaran/rute_pengantaran_page.dart';


class DetailPesananPage extends StatefulWidget {
  final String idPengantaran;
  final bool isSedangDiantar;
  final bool isDariPeta;
  final bool isSelesai;

  const DetailPesananPage({
    super.key,
    required this.idPengantaran,
    this.isSedangDiantar = false,
    this.isDariPeta = false,
    this.isSelesai = false,
  });

  @override
  State<DetailPesananPage> createState() => _DetailPesananPageState();
}

class _DetailPesananPageState extends State<DetailPesananPage> {
  final DetailPesananService _service = DetailPesananService();
  late Future<DetailPesananModel?>
  _detailFuture; // Asumsi pakai DetailPesananModel dari jawaban sebelumnya

  @override
  void initState() {
    super.initState();
    _detailFuture = _service.getDetailPesanan(widget.idPengantaran);
  }

  String _formatRupiah(int number) {
    String str = number.toString();
    String result = '';
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      result = str[i] + result;
      count++;
      if (count % 3 == 0 && i != 0) {
        result = '.$result';
      }
    }
    return 'Rp. $result';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFAD510D),
      appBar: GlobalAppBarKurir(
        title: 'Detail Pesanan',
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
      ),
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<DetailPesananModel?>(
          future: _detailFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 50,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Gagal memuat detail pesanan',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _detailFuture = _service.getDetailPesanan(
                            widget.idPengantaran,
                          );
                        });
                      },
                      child: const Text(
                        'Coba Lagi',
                        style: TextStyle(color: Color(0xFFAD510D)),
                      ),
                    ),
                  ],
                ),
              );
            }

            final data = snapshot.data!;

            return Column(
              children: [
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
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
                            // ==========================================
                            // 🚀 HEADER: ORDER ID & STATUS BADGE
                            // ==========================================
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
                                    Text(
                                      data.publicId
                                          .split('-')
                                          .first
                                          .toUpperCase(),
                                      style: const TextStyle(
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
                                    color: widget.isSedangDiantar
                                        ? const Color(0xFFAD510D)
                                        : const Color(0xFF5B6B76),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    widget.isSedangDiantar
                                        ? 'SEDANG DIANTAR'
                                        : 'BELUM DITERIMA',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // ==========================================
                            // 🚀 LIST BARANG
                            // ==========================================
                            ...data.daftarBarang.map((item) {
                              return OrderItemCard(
                                namaBarang: item.namaBarang,
                                varian: item
                                    .varian, // 🚀 Varian dioper secara terpisah
                                qty: item.jumlahBeli,
                                harga: _formatRupiah(item.subtotalItem),
                                imageUrl: item.gambarBarang,
                              );
                            }).toList(),

                            const SizedBox(height: 8),
                            const Text(
                              'Tujuan Pengantaran',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // ==========================================
                            // 🚀 TUJUAN PENGANTARAN (Desain Box Elegan)
                            // ==========================================
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFF9F9F9,
                                ), // Abu-abu super tipis biar clean
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFAD510D,
                                      ).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Color(0xFFAD510D),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data.namaCustomer,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          data.alamatLengkap,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade600,
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Divider(
                                thickness: 2,
                                color: Color(0xFFEEEEEE),
                              ),
                            ),

                            // ==========================================
                            // 🚀 METODE BAYAR (Desain Coklat)
                            // ==========================================
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Rincian Pembayaran',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFAD510D).withOpacity(
                                      0.1,
                                    ), // 🚀 Background Coklat Transparan
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFAD510D,
                                      ).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    data.metodeBayar.namaMetode,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFAD510D),
                                    ), // 🚀 Teks Coklat
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // ==========================================
                            // 🚀 RINCIAN TOTAL BELANJA (Breakdown Matematika)
                            // ==========================================
                            ...data.daftarBarang.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        item.namaBarang,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        '${item.jumlahBeli} x ${_formatRupiah(item.hargaSatuan)}',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        _formatRupiah(item.subtotalItem),
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Divider(
                                thickness: 1,
                                color: Color(0xFFEEEEEE),
                              ),
                            ),

                            // 🚀 TOTAL KESELURUHAN
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Keseluruhan',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  _formatRupiah(data.totalPembayaran),
                                  style: const TextStyle(
                                    fontSize: 18,
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
            );
          },
        ),
      ),

      // 🚀 BOTTOM NAVIGATION BAR SAKTI
      bottomNavigationBar: FutureBuilder<DetailPesananModel?>(
        future: _detailFuture,
        builder: (context, snapshot) {
          // Kalau API Detail Pesanan belum selesai loading, sembunyiin dulu tombolnya
          if (!snapshot.hasData || snapshot.data == null) {
            return const SizedBox.shrink();
          }

          return Container(
            color: Colors.white,
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: widget.isSelesai
                  // 🚀 STAGE 1: DARI TAB SELESAI -> Lihat Bukti
                  ? ElevatedButton(
                      onPressed: () async {
                        // 1. Kasih feedback loading ke kurir
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Mengambil foto bukti...'),
                            duration: Duration(seconds: 1),
                          ),
                        );

                        // 🚀 2. TEMBAKAN SNIPER: Tarik data dari Model Pengantaran!
                        final detailPengantaran =
                            await DetailPengantaranService()
                                .getDetailPengantaran(widget.idPengantaran);

                        // 3. Cek hasil tembakannya, apakah fotoBukti-nya ada isinya?
                        if (detailPengantaran != null &&
                            detailPengantaran.fotoBukti != null &&
                            detailPengantaran.fotoBukti!.isNotEmpty) {
                          // Buka dialog dan lempar URL fotonya
                          _showBuktiDialog(
                            context,
                            detailPengantaran.fotoBukti!,
                          );
                        } else {
                          // Kalau null atau kosong
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Bukti foto belum ada atau gagal dimuat!',
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFAD510D),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Lihat Bukti Pengiriman',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : widget.isDariPeta
                  // 🚀 STAGE 2: DARI PETA -> Upload Bukti
                  ? ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AmbilBuktiPage(publicId: widget.idPengantaran),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFAD510D),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Upload Bukti Pengiriman',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : widget.isSedangDiantar
                  // 🚀 STAGE 3: DARI DAFTAR TUGAS -> Lihat Rute Peta
                  ? ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RutePengantaranPage(
                              idPengantaran: widget.idPengantaran,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFAD510D),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Lihat Rute Pengantaran',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                  // 🚀 STAGE 4: DARI BERANDA -> Terima Pesanan
                  : ElevatedButton(
                      onPressed: () => _showLocationPermissionDialog(context),
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
          );
        },
      ),
    );
  }

  // 🚀 HELPER FUNCTIONS DIALOG (Sama seperti sebelumnya)
  void _showLocationPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isDialogLoading = false; 

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
                                : () => Navigator.pop(context),
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
                            // 🚀 LOGIKA PINTAR DIMULAI DI SINI
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
                                    final newPengantaranId = await _service
                                        .terimaPesanan(widget.idPengantaran);

                                    setStateDialog(
                                      () => isDialogLoading = false,
                                    );

                                    // 3. Cek Hasilnya
                                    if (newPengantaranId != null) {
                                      Navigator.pop(
                                        context,
                                      ); // Tutup dialog Izin
                                      _showSuccessDialog(
                                        context,
                                        newPengantaranId,
                                      ); // Buka dialog Sukses
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
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

  // 🚀 PERBAIKAN 2: Tambahin penampung "String newId" di sini!
  void _showSuccessDialog(BuildContext context, String newId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(seconds: 2), () {
          if (Navigator.of(context).canPop()) {
            Navigator.pop(context);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                // 🚀 PERBAIKAN 3: GANTI widget.idPengantaran JADI newId !!!
                // Ini biang kerok 404-nya! Dia sebelumnya ngebawa ID Pesanan lama!
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

  void _showBuktiDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                // 🚀 Panggil URL MinIO secara ajaib pakai Image.network
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      color: Colors.white,
                      child: const Text(
                        'Gagal memuat gambar',
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
