import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SuksesBayarScreen extends StatelessWidget {
  final int kembalian;
  final String nomorInvoice;
  final int totalAkhir;
  final String metodePembayaran;

  const SuksesBayarScreen({
    super.key,
    required this.kembalian,
    required this.nomorInvoice,
    required this.totalAkhir,
    required this.metodePembayaran,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon sukses
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Color(0xFF8B4513),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 56,
                ),
              ).also((w) => Center(child: w)),

              const SizedBox(height: 24),

              const Center(
                child: Text(
                  'Pembayaran Berhasil!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Transaksi selesai',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),

              const SizedBox(height: 32),

              // Detail pembayaran
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _row('Nomor Invoice', nomorInvoice),
                      const Divider(height: 20),
                      _row('Metode', metodePembayaran),
                      const Divider(height: 20),
                      _row(
                        'Total Dibayar',
                        fmt.format(totalAkhir),
                        bold: true,
                        color: const Color(0xFF8B4513),
                      ),
                      if (kembalian > 0) ...[
                        const Divider(height: 20),
                        _row(
                          'Kembalian',
                          fmt.format(kembalian),
                          bold: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Tombol kembali ke kasir
              ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B4513),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  'Transaksi Baru',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value,
      {bool bold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }
}

// Helper extension agar bisa wrap widget di Center
extension _WidgetAlso on Widget {
  Widget also(Widget Function(Widget) fn) => fn(this);
}