import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../../core/services/payment_service.dart';
import 'suksesbayar.dart';

// ── Design Tokens ─────────────
class _K {
  static const orange = Color(0xFFAF510C);
  static const orangeLight = Color(0xFFFFE0CC);
  static const orangeDark = Color(0xFF8A3D06);
  static const black = Color(0xFF1A1A1A);
  static const grey600 = Color(0xFF757575);
  static const grey300 = Color(0xFFE0E0E0);
  static const grey100 = Color(0xFFF5F5F5);
  static const white = Color(0xFFFFFFFF);
  static const red = Color(0xFFC62828);
}

class BayarNonTunaiScreen extends StatefulWidget {
  final String orderId;
  final String metode;
  final String? qrUrl;
  final String? vaNumber;
  final String? billKey;  // 🚀 Tambahan Mandiri
  final String? billCode; // 🚀 Tambahan Mandiri
  final int totalAkhir;
  final String publicId;

  const BayarNonTunaiScreen({
    super.key,
    required this.orderId,
    required this.metode,
    this.qrUrl,
    this.vaNumber,
    this.billKey,
    this.billCode,
    required this.totalAkhir,
    required this.publicId,
  });

  @override
  State<BayarNonTunaiScreen> createState() => _BayarNonTunaiScreenState();
}

class _BayarNonTunaiScreenState extends State<BayarNonTunaiScreen> {
  final _fmt = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  Timer? _visualTimer;
  Timer? _statusTimer; // 🚀 Timer buat nge-cek status otomatis
  final PaymentService _paymentService = PaymentService();

  int _countdown = 900; // Standar Midtrans 15 Menit (900 detik)
  bool _isChecking = false; // Buat loading tombol cek status
  bool _isSuccess = false; // Mencegah multiple navigasi

  @override
  void initState() {
    super.initState();

    // 1. Murni buat ngurangin angka jam di layar, GAK NGE-HIT API
    _visualTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });

    // 2. 🚀 POLLING OTOMATIS: Cek status tiap 5 detik biar kasir gak capek klik
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isChecking && !_isSuccess) {
        _cekStatusOtomatis();
      }
    });

    // 🚀 REQUEST KHUSUS ABANGKU: PRINT URL QR KE TERMINAL
    final isQris =
        widget.metode.toLowerCase() == 'qris' ||
        widget.metode.toLowerCase() == 'gopay';
    if (isQris && widget.qrUrl != null) {
      print("=============Kode QR===========");
      print(widget.qrUrl);
      print("===============================");
    }
  }

  @override
  void dispose() {
    _visualTimer?.cancel();
    _statusTimer?.cancel(); // 🚀 Jangan lupa dimatiin timernya
    super.dispose();
  }

  // 🚀 LOGIC BARU: CEK STATUS OTOMATIS (DI-HIT TIMER)
  Future<void> _cekStatusOtomatis() async {
    try {
      final hasil = await _paymentService.cekStatusPembayaran(widget.orderId);
      if (hasil.isLunas && !_isSuccess && mounted) {
        _isSuccess = true;
        _statusTimer?.cancel();
        _keSukses(widget.metode);
      }
    } catch (e) {
      print("Polling status error: $e");
    }
  }

  // 🚀 LOGIC BARU: CEK STATUS MANUAL (Ditekan sama Kasir)
  Future<void> _cekStatusManual() async {
    if (_isSuccess) return;
    setState(() => _isChecking = true);

    try {
      // Tinggal panggil service-nya, gak pusing mikirin URL lagi!
      final hasil = await _paymentService.cekStatusPembayaran(widget.orderId);

      if (!mounted) return;

      if (hasil.isLunas) {
        _isSuccess = true;
        _statusTimer?.cancel();
        _keSukses(widget.metode);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pembayaran belum diterima, silakan cek lagi nanti.'),
            backgroundColor: _K.orangeDark,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: _K.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  void _keSukses(String metode) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => SuksesBayarScreen(
          kembalian: 0,
          nomorInvoice: widget.orderId,
          totalAkhir: widget.totalAkhir,
          metodePembayaran: metode.toUpperCase(),
        ),
      ),
      (route) => route.isFirst,
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nomor VA disalin!'),
        backgroundColor: _K.orange,
        duration: Duration(seconds: 1),
      ),
    );
  }

  String get _formatWaktu {
    final menit = (_countdown / 60).floor();
    final detik = _countdown % 60;
    return '${menit.toString().padLeft(2, '0')}:${detik.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final cleanMetode = widget.metode.toLowerCase();
    final isQris = cleanMetode == 'qris' || cleanMetode == 'gopay';
    final isMandiri = cleanMetode == 'mandiri';
    
    // Cek apakah data instruksi ada (antisipasi string kosong dari backend)
    final bool hasQr = isQris && widget.qrUrl != null && widget.qrUrl!.isNotEmpty;
    final bool hasVa = !isQris && !isMandiri && widget.vaNumber != null && widget.vaNumber!.isNotEmpty;
    final bool hasMandiri = isMandiri && widget.billKey != null && widget.billCode != null;

    return Scaffold(
      backgroundColor: _K.grey100,
      appBar: AppBar(
        backgroundColor: _K.orange,
        foregroundColor: _K.white,
        elevation: 0,
        title: const Text(
          'Pembayaran',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Kartu Tagihan ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: _K.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Total Akhir',
                    style: TextStyle(
                      color: _K.grey600,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _fmt.format(widget.totalAkhir),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 32,
                      color: _K.orangeDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: _K.grey300, thickness: 1),
                  const SizedBox(height: 16),

                  // ── Area QRIS / VA / MANDIRI ──
                  if (hasQr) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _K.grey100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _K.grey300),
                      ),
                      child: Image.network(
                        widget.qrUrl!,
                        width: 220,
                        height: 220,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image,
                          size: 100,
                          color: _K.grey600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Scan QR code menggunakan aplikasi E-Wallet atau M-Banking.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: _K.grey600),
                    ),
                  ] else if (hasVa) ...[
                    // Tampilan Virtual Account
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _K.orangeLight.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _K.orange.withOpacity(0.5)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Virtual Account ${widget.metode.toUpperCase()}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: _K.orangeDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.center,
                                  child: Text(
                                    widget.vaNumber!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 28,
                                      color: _K.black,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _copyToClipboard(widget.vaNumber!),
                                child: const Icon(
                                  Icons.copy_rounded,
                                  color: _K.orange,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else if (hasMandiri) ...[
                    // Tampilan Mandiri Bill
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _K.orangeLight.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _K.orange.withOpacity(0.5)),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Mandiri Bill Payment',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _K.orangeDark),
                          ),
                          const SizedBox(height: 12),
                          _rowMandiri('Bill Key', widget.billKey!),
                          const SizedBox(height: 8),
                          _rowMandiri('Bill Code', widget.billCode!),
                        ],
                      ),
                    ),
                  ] else ...[
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: _K.red,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Gagal memuat instruksi pembayaran. Pastikan Server Key Midtrans valid.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _K.red),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // ── Tombol Cek Status Manual ──
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isChecking ? null : _cekStatusManual,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _K.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isChecking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Cek Status Pembayaran',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Countdown timer (Murni Visual)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: _K.grey600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Batas Waktu: $_formatWaktu',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: _K.grey600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Tombol Batal
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.cancel_outlined, size: 20),
                label: const Text(
                  'Batalkan Transaksi',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _K.red,
                  side: const BorderSide(color: _K.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowMandiri(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: _K.grey600)),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _K.black)),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy_rounded, color: _K.orange, size: 20),
          onPressed: () => _copyToClipboard(value),
        ),
      ],
    );
  }
}
