import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/core/widgets/base_header_widget.dart';
import 'package:frontend/core/widgets/payment_icon_widget.dart';
import '../orders/services/customer_order_service.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:frontend/features/cart/sukses_bayar_customer.dart';

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
  final CustomerOrderService _orderService = CustomerOrderService();
  bool _isChecking = false;

  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  DateTime? _batasWaktu;

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

  String _formatPaymentMethod(Map<String, dynamic> rincian) {
    if (rincian['metode'] == null || rincian['metode'].toString().isEmpty) {
      return 'BELUM TERPILIH';
    }
    
    final String metode = rincian['metode'].toString();
    final String namaBank = (rincian['nama_bank'] ?? '').toString();
    
    if (metode == 'bank_transfer' || metode == 'echannel') {
      if (namaBank.isNotEmpty) {
        return '$namaBank Virtual Account';
      }
      return 'Transfer Bank';
    } else if (metode == 'qris') {
      return 'QRIS';
    } else if (metode == 'gopay') {
      return 'GoPay';
    } else if (metode == 'tunai' || metode == 'cash') {
      return 'Tunai (Cash)';
    }
    
    return metode.toUpperCase();
  }

  void _startTimer() {
    if (widget.data['batas_waktu'] != null) {
      _batasWaktu = DateTime.parse(widget.data['batas_waktu'].toString()).toLocal();
      _updateRemainingTime();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _updateRemainingTime();
          });
        }
      });
    }
  }

  void _updateRemainingTime() {
    if (_batasWaktu != null) {
      final now = DateTime.now();
      if (_batasWaktu!.isAfter(now)) {
        _remainingTime = _batasWaktu!.difference(now);
      } else {
        _remainingTime = Duration.zero;
        _timer?.cancel();
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitHours = twoDigits(duration.inHours);
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitHours:$twoDigitMinutes:$twoDigitSeconds";
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
            Navigator.pop(context);
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
                  if (_batasWaktu != null) ...[
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
                      'Batas akhir: ${DateFormat('dd MMM yyyy, HH:mm').format(_batasWaktu!)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ] else ...[
                    const Text(
                      'Segera Selesaikan Pembayaran',
                      style: TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pesanan Anda akan diproses setelah pembayaran berhasil diverifikasi.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
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
                        onPressed: () async {
                          try {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Mengunduh QR Code...'), backgroundColor: Color(0xFFAD510D)),
                            );
                            
                            var response = await Dio().get(
                              qrUrl,
                              options: Options(responseType: ResponseType.bytes),
                            );
                            
                            final tempDir = await getTemporaryDirectory();
                            final file = File('${tempDir.path}/QR_MANTRA_$orderId.png');
                            await file.writeAsBytes(response.data);
                            
                            // Minta permission jika belum dan simpan ke galeri
                            if (!await Gal.hasAccess(toAlbum: true)) {
                              await Gal.requestAccess(toAlbum: true);
                            }
                            await Gal.putImage(file.path);
                            
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('QR Code berhasil disimpan ke Galeri!'), backgroundColor: Color(0xFFAD510D),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gagal menyimpan QR Code: $e'), backgroundColor: Colors.grey),
                            );
                          }
                        },
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('Unduh QR Code'),
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
                          _formatPaymentMethod(widget.data),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        PaymentIconWidget(
                          iconValue: iconUrl.isNotEmpty ? iconUrl : 'account_balance',
                          paymentName: _formatPaymentMethod(widget.data),
                          size: 32,
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
                onPressed: _isChecking ? null : () async {
                  setState(() => _isChecking = true);
                  try {
                    final publicIdPesanan = (widget.data['public_id_pesanan'] ?? '').toString();
                    final orderDetail = await _orderService.getOrderDetail(publicIdPesanan);
                    final statusP = orderDetail['nama_status_pesanan']?.toString().toLowerCase() ?? '';
                    if (statusP == 'menunggu pembayaran' || statusP == 'belum dibayar') {
                      await Future.delayed(const Duration(milliseconds: 500));
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pembayaran belum diterima. Silakan cek kembali nanti.'),
                          backgroundColor: Colors.grey,
                        ),
                      );
                    } else {
                      if (!mounted) return;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SuksesBayarCustomerScreen(
                            orderId: orderId,
                            totalBayar: widget.totalBayar,
                            metodePembayaran: metode.toUpperCase(),
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    // Abaikan jika error
                  } finally {
                    if (mounted) setState(() => _isChecking = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAD510D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isChecking
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
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
