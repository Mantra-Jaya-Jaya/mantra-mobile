import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'suksesbayar.dart';

class MidtransSnapScreen extends StatefulWidget {
  final String redirectUrl;
  final String publicId;
  final int totalAkhir;

  const MidtransSnapScreen({
    super.key,
    required this.redirectUrl,
    required this.publicId,
    required this.totalAkhir,
  });

  @override
  State<MidtransSnapScreen> createState() => _MidtransSnapScreenState();
}

class _MidtransSnapScreenState extends State<MidtransSnapScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // Deteksi redirect URL sukses/selesai dari Midtrans
            final url = request.url.toLowerCase();
            if (url.contains('success') || 
                url.contains('status-code=200') || 
                url.contains('transaction_status=settlement')) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => SuksesBayarScreen(
                    kembalian: 0,
                    nomorInvoice: widget.publicId,
                    totalAkhir: widget.totalAkhir,
                    metodePembayaran: 'MIDTRANS',
                  ),
                ),
              );
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.redirectUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran Online'),
        backgroundColor: const Color(0xFFAF510C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
