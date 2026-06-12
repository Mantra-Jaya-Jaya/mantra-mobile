import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../core/widgets/card_item_pemesanan_kurir.dart';
import '../../core/widgets/global_appbar_kurir.dart';
import '../../core/services/pengantaran_service.dart';
import '../../core/services/pesanan_kurir_service.dart';
import '../../core/models/pengantaran_model.dart';
import '../pengantaran/rute_pengantaran_page.dart';
import 'camera_page.dart';

class DetailPesananPage extends StatefulWidget {
  final String idPengantaran;
  final bool isSedangDiantar;

  const DetailPesananPage({
    super.key,
    required this.idPengantaran,
    this.isSedangDiantar = false,
  });

  @override
  State<DetailPesananPage> createState() => _DetailPesananPageState();
}

class _DetailPesananPageState extends State<DetailPesananPage> {
  final DetailPengantaranService _deliveryService = DetailPengantaranService();
  final PesananService _pesananService = PesananService();
  
  DetailPengantaranModel? _detail;
  bool _isLoading = true;
  String? _errorMessage;

  final rupiahFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp. ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      DetailPengantaranModel? data;
      if (widget.isSedangDiantar) {
        data = await _deliveryService.getDetailPengantaran(widget.idPengantaran);
      } else {
        data = await _pesananService.getDetailPesanan(widget.idPengantaran);
      }

      if (mounted) {
        setState(() {
          _detail = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Gagal memuat detail pesanan: $e";
          _isLoading = false;
        });
      }
    }
  }

  void _acceptOrder() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFAD510D)),
      ),
    );

    try {
      await _pesananService.ambilPesanan(widget.idPengantaran);
      if (mounted) {
        Navigator.pop(context); // Tutup loading dialog
        _showSuccessDialog(context);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Tutup loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil pesanan: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _completeOrder() async {
    final path = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const CameraPage()),
    );

    if (path == null) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFAD510D)),
      ),
    );

    try {
      await _pesananService.updateStatus(widget.idPengantaran, 'Selesai', filePath: path);
      if (mounted) {
        Navigator.pop(context); // Tutup loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesanan berhasil diselesaikan!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Refresh daftar tugas
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Tutup loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyelesaikan pesanan: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
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
        child: Column(
          children: [
            const SizedBox(height: 16),
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
                  child: _buildBodyContent(),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _isLoading || _detail == null
          ? null
          : Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: widget.isSedangDiantar
                    ? ElevatedButton(
                        onPressed: _completeOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFAD510D), 
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Selesaikan Pesanan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      )
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
            ),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFAD510D)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 50, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFAD510D)),
                child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_detail == null) {
      return const Center(child: Text('Data pesanan tidak ditemukan'));
    }

    final detail = _detail!;
    final String displayOrderId = detail.idPengantaran.length >= 8
        ? detail.idPengantaran.substring(0, 8).toUpperCase()
        : detail.idPengantaran.toUpperCase();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    displayOrderId,
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
                  detail.statusPengantaran.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Daftar barang dinamis
          ...detail.daftarBarang.map((item) => OrderItemCard(
                namaBarang: item.namaBarang,
                qty: item.jumlahBeli,
                harga: rupiahFormatter.format(item.hargaSatuan),
              )),
              
          const SizedBox(height: 16),
          const Text(
            'Tujuan Pengantaran',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            detail.penerima.nama,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            detail.tujuan.alamatLengkap,
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
          const Text(
            'Total Belanja',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildReceiptRow(
            'Subtotal',
            '',
            rupiahFormatter.format(detail.totalPembayaran),
            isBold: true,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(
    String title,
    String qty,
    String price, {
    bool isBold = false,
    bool isGreyTitle = false,
  }) {
    return Padding(
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
      barrierDismissible: false,
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
                        onPressed: () => Navigator.pop(context),
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
                        onPressed: () {
                          Navigator.pop(context); // Tutup dialog izin lokasi
                          _acceptOrder();
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

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(seconds: 2), () {
          if (Navigator.of(context).canPop()) {
            Navigator.pop(context); // Tutup success dialog
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => RutePengantaranPage(
                  idPengantaran: widget.idPengantaran,
                ),
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
