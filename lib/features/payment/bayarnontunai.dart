import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'suksesbayar.dart';

class BayarNonTunaiScreen extends StatefulWidget {
  final String snapToken;
  final int idPesanan;
  final int totalAkhir;

  const BayarNonTunaiScreen({
    super.key,
    required this.snapToken,
    required this.idPesanan,
    required this.totalAkhir,
  });

  @override
  State<BayarNonTunaiScreen> createState() => _BayarNonTunaiScreenState();
}

class _BayarNonTunaiScreenState extends State<BayarNonTunaiScreen> {
  late WebViewController _webCtrl;
  bool _loading = true;

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
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _loading = true),
        onPageFinished: (_) => setState(() => _loading = false),
        onNavigationRequest: (req) {
          return _handleNavigasi(req.url);
        },
      ))
      ..loadRequest(Uri.parse(_snapUrl));
  }

  // ── Deteksi hasil pembayaran dari URL ────────────────────
  NavigationDecision _handleNavigasi(String url) {
    // Midtrans redirect ke URL ini setelah pembayaran selesai/gagal/pending
    if (url.contains('transaction_status=settlement') ||
        url.contains('transaction_status=capture')) {
      _keSukses('Non-tunai');
      return NavigationDecision.prevent;
    }
    if (url.contains('transaction_status=pending')) {
      _kePending();
      return NavigationDecision.prevent;
    }
    if (url.contains('transaction_status=deny') ||
        url.contains('transaction_status=cancel') ||
        url.contains('transaction_status=expire')) {
      _keGagal();
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  void _keSukses(String metode) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => SuksesBayarScreen(
          kembalian: 0,
          nomorInvoice: 'MID-${widget.idPesanan}',
          totalAkhir: widget.totalAkhir,
          metodePembayaran: metode,
        ),
      ),
      (route) => route.isFirst,
    );
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
        ],
      ),
    );
  }
}