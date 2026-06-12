import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/summary_model.dart';
import '../../core/services/summary_service.dart';

class RiwayatTransaksi extends StatefulWidget {
  final String publicId; // Pastikan ini String

  const RiwayatTransaksi({super.key, required this.publicId});

  @override
  State<RiwayatTransaksi> createState() => _RiwayatTransaksiState();
}

class _RiwayatTransaksiState extends State<RiwayatTransaksi> {
  final SummaryService _apiService = SummaryService();
  DetailLaporanModel? _detailData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDetailData();
  }

  Future<void> _loadDetailData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Menggunakan Service untuk memanggil backend
      final data = await _apiService.getDetailLaporanProduk(widget.publicId);
      if (mounted) {
        setState(() {
          _detailData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Gagal memuat: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text("Transaksi Produk", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFAF510C),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFAF510C)))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _detailData == null
                  ? const Center(child: Text("Data tidak ditemukan"))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderCard(),
                          const SizedBox(height: 16),
                          _buildStatsCard(),
                          const SizedBox(height: 24),
                          const Text("Riwayat Transaksi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),
                          ..._detailData!.riwayatTransaksi.map((tx) => _buildTransactionItem(tx)),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(_detailData!.produk.imageUrl, width: 56, height: 56, fit: BoxFit.cover)),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_detailData!.produk.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(_detailData!.produk.kategori ?? "-", style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

Widget _buildStatsCard() {
  return Container(
    padding: const EdgeInsets.all(16),
    width: double.infinity,
    decoration: BoxDecoration(color: const Color(0xFFAF510C), borderRadius: BorderRadius.circular(14)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Total Terjual", style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 6),
        Text(
          "${_detailData!.totalTerjual}",
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}

// Helper untuk memformat tanggal
  String _formatDate(dynamic dateInput) {
    if (dateInput == null) return "-";
    String dateStr = dateInput.toString();
    if (dateStr.isEmpty) return "-";
    
    try {
      final DateTime date = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildTransactionItem(TransactionHistoryModel tx) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tx.nomorInvoice, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text("Tanggal: ${_formatDate(tx.tanggalWaktu)}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ]),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(currencyFormat.format(tx.subtotal), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFAF510C), fontSize: 13)),
            Text("Qty: ${tx.quantity}", style: const TextStyle(fontSize: 11)),
          ]),
        ],
      ),
    );
  }
}