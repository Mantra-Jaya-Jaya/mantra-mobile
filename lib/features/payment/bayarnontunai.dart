import 'package:flutter/material.dart';
import 'package:frontend/core/services/payment_service.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';
import '../../core/services/order_service.dart';
import 'suksesbayar.dart';

class BayarNonTunaiScreen extends StatefulWidget {
  final String snapToken;
  final int idPesanan;
  final String publicId;
  final int totalAkhir;

  const BayarNonTunaiScreen({
    super.key,
    required this.snapToken,
    required this.idPesanan,
    required this.publicId,
    required this.totalAkhir,
  });

  @override
  State<BayarNonTunaiScreen> createState() => _BayarNonTunaiScreenState();
}

class _BayarNonTunaiScreenState extends State<BayarNonTunaiScreen> {
  late WebViewController _webCtrl;
  bool _loading = true;
  Timer? _timer;
  final OrderService _orderService = OrderService();

  // ── URL Midtrans Snap ─────────────────────────────────────
  // Sandbox: https://app.sandbox.midtrans.com/snap/v2/vtweb/<token>
  // Production: https://app.midtrans.com/snap/v2/vtweb/<token>
  // Ganti ke production URL saat go-live
  String get _snapUrl =>
      'https://app.sandbox.midtrans.com/snap/v2/vtweb/${widget.snapToken}';

  @override
  void initState() {
    super.initState();

    _webCtrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (req) {
            return _handleNavigasi(req.url);
          },
        ),
      )
      ..loadRequest(Uri.parse(_snapUrl));

    _mulaiCekStatus();
  }

  // ── Deteksi hasil pembayaran dari URL ────────────────────
  NavigationDecision _handleNavigasi(String url) {
    // Midtrans redirect ke URL ini setelah pembayaran selesai/gagal/pending
    return NavigationDecision.navigate;
  }

  void _mulaiCekStatus() {
    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) async {
        try {
          // Gunakan publicId (UUID) bukan integer ID
          final response =
              await _orderService.getDetailPesanan(widget.publicId);

          if (!mounted || response == null) return;

          final data = response['data'];

          if (data != null &&
              data['status_pesanan'].toString().toLowerCase() == 'selesai') {
            timer.cancel();
            _keSukses("Non-tunai");
          }
        } catch (e) {
          print("Error cek status pembayaran: $e");
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _keSukses(String metode, {String? invoice}) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => SuksesBayarScreen(
          kembalian: 0,
          nomorInvoice: invoice ?? 'MID-${widget.idPesanan}',
          totalAkhir: widget.totalAkhir,
          metodePembayaran: metode,
        ),
      ),
      (route) => route.isFirst,
    );
  }

  // Fungsi baru untuk simulasi via backend
  Future<void> _simulasiSuksesBackend() async {
    setState(() => _loading = true);
    try {
      final service = PaymentService();
      final hasil = await service.bayarNonTunai(widget.idPesanan, simulasi: true);
      _keSukses('Non-tunai (Simulasi)', invoice: hasil.nomorInvoice);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Simulasi Gagal: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _kePending() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Menunggu Pembayaran'),
        content: const Text(
            'Pembayaran Anda sedang diproses. Silakan selesaikan pembayaran sesuai instruksi.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Kembali ke metode pembayaran
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _keGagal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Pembayaran Gagal'),
        content: const Text('Transaksi dibatalkan atau ditolak. Silakan coba lagi.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Kembali'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        title: const Text('Pembayaran Non-tunai',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _webCtrl.reload();
            },
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Batalkan Pembayaran?'),
                content: const Text(
                    'Apakah Anda yakin ingin membatalkan pembayaran ini?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tidak'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // tutup dialog
                      Navigator.pop(context); // kembali ke metode pembayaran
                    },
                    child: const Text(
                      'Ya, Batalkan',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _webCtrl),
          if (_loading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF8B4513)),
                  SizedBox(height: 16),
                  Text('Memuat halaman pembayaran...'),
                ],
              ),
            ),
          // ── Tombol Simulasi Sukses (Hanya untuk Demo PBL) ──
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Opacity(
              opacity: 0.8,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: _simulasiSuksesBackend,
                child: const Text('SIMULASI SUKSES (Update Status ke Selesai)'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}