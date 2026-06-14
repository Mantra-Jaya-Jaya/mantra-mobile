import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/base_header_widget.dart';
import '../home/home_kasir.dart';

class SuksesBayarTunaiScreen extends StatelessWidget {
  final int kembalian;
  final String nomorInvoice;
  final int totalAkhir;
  final String metodePembayaran;

  const SuksesBayarTunaiScreen({
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
      backgroundColor: Colors.white,
      appBar: BaseHeaderWidget(
        title: 'Pembayaran Tunai',
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              const Spacer(),

              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: Color(0xFF8B4513),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 52,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'TRANSAKSI SELESAI',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 2),
              Text(
                'Nomor Invoice: ' + nomorInvoice,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),

              const SizedBox(height: 36),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF7F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE7D3B8), width: 1),
                ),
                child: Column(
                  children: [
                    _paymentRow(
                      label: 'Metode',
                      value: metodePembayaran,
                      isBold: true,
                      color: const Color(0xFF8B4513),
                    ),
                    const SizedBox(height: 16),
                    _paymentRow(
                      label: 'Total Dibayar',
                      value: fmt.format(totalAkhir),
                      isBold: true,
                      color: const Color(0xFF8B4513),
                    ),
                    const SizedBox(height: 16),
                    _paymentRow(
                      label: 'Uang Diterima',
                      value: fmt.format(totalAkhir + kembalian),
                      color: Colors.black87,
                    ),
                    const SizedBox(height: 16),
                    _paymentRow(
                      label: 'Kembalian',
                      value: fmt.format(kembalian),
                      color: Colors.green,
                      isBold: true,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DashboardKasirPage(initialIndex: 2),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B4513),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Buat Pesanan Baru',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DashboardKasirPage(initialIndex: 0),
                      ),
                      (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF8B4513),
                    side: const BorderSide(color: Color(0xFF8B4513), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Kembali ke Beranda',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paymentRow({
    required String label,
    required String value,
    required Color color,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
