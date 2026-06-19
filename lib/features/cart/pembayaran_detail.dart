import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/core/widgets/base_header_widget.dart';
import '../home/home_customer.dart';
import 'package:intl/intl.dart';

class PembayaranDetailPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final int totalBayar;

  const PembayaranDetailPage({
    super.key,
    required this.data,
    required this.totalBayar,
  });

  @override
  State<PembayaranDetailPage> createState() => _PembayaranDetailPageState();
}

class _PembayaranDetailPageState extends State<PembayaranDetailPage> {
  Timer? _timer;
  Duration _remainingTime = const Duration(hours: 23, minutes: 59, seconds: 59);

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    // Simulasi hitung mundur dari 24 jam (bisa disesuaikan dengan data backend nanti)
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingTime.inSeconds > 0) {
            _remainingTime -= const Duration(seconds: 1);
          } else {
            _timer?.cancel();
          }
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  String _formatRupiah(int number) {
    final formatter = NumberFormat("#,###", "pt_BR");
    return 'Rp. ${formatter.format(number).replaceAll(',', '.')}';
  }

  void _copyToClipboard(BuildContext context, String text) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Berhasil disalin ke clipboard'),
        backgroundColor: Color(0xFFAD510D),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String metode = (widget.data['metode'] ?? '').toString();
    final String vaNumber = (widget.data['va_number'] ?? '').toString();
    final String qrUrl = (widget.data['qr_url'] ?? '').toString();
    final String billKey = (widget.data['bill_key'] ?? '').toString();
    final String billCode = (widget.data['bill_code'] ?? '').toString();
    final String orderId = (widget.data['order_id'] ?? '-').toString();
    final String iconUrl = (widget.data['icon'] ?? '').toString();

    bool isVA =
        vaNumber.isNotEmpty || (billKey.isNotEmpty && billCode.isNotEmpty);
    bool isQRIS = qrUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: BaseHeaderWidget(
        title: 'Detail Pembayaran',
        leading: IconButton(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const HomeScreen(initialIndex: 2),
              ),
              (route) => false,
            );
          },
          icon: const Icon(Icons.close, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timer & Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFAD510D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFAD510D), width: 0.5),
              ),
              child: Column(
                children: [
                  const Text(
                    'Selesaikan Pembayaran Dalam',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDuration(_remainingTime),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFAD510D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Batas akhir: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now().add(const Duration(days: 1)))}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Card Inti (QR atau VA)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (isQRIS) ...[
                    const Text(
                      'QRIS',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: qrUrl.startsWith('http')
                          ? Image.network(
                              qrUrl,
                              width: 200,
                              height: 200,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.qr_code_2,
                                  size: 200,
                                  color: Colors.grey,
                                );
                              },
                            )
                          : const Icon(
                              Icons.qr_code_2,
                              size: 200,
                              color: Colors.grey,
                            ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Scan kode QR di atas untuk membayar',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Gambar QR Berhasil Disimpan'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('Simpan QR Code'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFAD510D),
                          side: const BorderSide(color: Color(0xFFAD510D)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ] else if (isVA) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          metode.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        iconUrl.isNotEmpty
                            ? Image.network(
                                iconUrl,
                                width: 45, // sesuaikan ukuran lebar
                                height: 30, // sesuaikan ukuran tinggi
                                fit: BoxFit.contain,
                                // Error builder jika gambar gagal di-load dari internet atau URL rusak
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.account_balance_rounded,
                                    color: Color(0xFFAD510D),
                                  );
                                },
                              )
                            : const Icon(
                                Icons.account_balance_rounded,
                                color: Color(0xFFAD510D),
                              ),
                      ],
                    ),
                    const Divider(height: 32),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Nomor Virtual Account',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            vaNumber.isNotEmpty
                                ? vaNumber
                                : '$billCode\n$billKey',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _copyToClipboard(
                            context,
                            vaNumber.isNotEmpty
                                ? vaNumber
                                : '$billCode$billKey',
                          ),
                          child: const Text(
                            'SALIN',
                            style: TextStyle(
                              color: Color(0xFFAD510D),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (billCode.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Biller Code',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          billCode,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Bill Key',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          billKey,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Rincian Pesanan
            const Text(
              'Rincian Pesanan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Order ID', orderId),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Total Pembayaran',
                    _formatRupiah(widget.totalBayar),
                    isBold: true,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Metode Pembayaran', metode.toUpperCase()),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Tombol Selesai
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HomeScreen(initialIndex: 2),
                    ),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAD510D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Cek Status Pesanan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: isBold ? const Color(0xFFAD510D) : Colors.black87,
          ),
        ),
      ],
    );
  }
}
