import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/dashboard_kasir_service.dart';

class SemuaAktivitasPage extends StatefulWidget {
  const SemuaAktivitasPage({super.key});

  @override
  State<SemuaAktivitasPage> createState() => _SemuaAktivitasPageState();
}

class _SemuaAktivitasPageState extends State<SemuaAktivitasPage> {
  final DashboardKasirService _service = DashboardKasirService();
  final _currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  List<AktivitasItem> _aktivitas = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAktivitas();
  }

  Future<void> _loadAktivitas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _service.getSemuaAktivitas();
      if (mounted) {
        setState(() {
          _aktivitas = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat aktivitas hari ini';
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
        title: const Text(
          'Semua Aktivitas Hari Ini',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFFAD510D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFFAD510D),
        onRefresh: _loadAktivitas,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFAD510D)))
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadAktivitas,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFAD510D)),
                          child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  )
                : _aktivitas.isEmpty
                    ? const Center(child: Text('Belum ada aktivitas hari ini', style: TextStyle(color: Colors.grey)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: _aktivitas.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _aktivitas[index];
                          return _transactionItem(
                            item.nomorInvoice,
                            '${_capitalize(item.metodePembayaran)} ΓÇó ${item.waktu}',
                            _currencyFormat.format(item.totalBayar),
                          );
                        },
                      ),
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  Widget _transactionItem(String id, String subtitle, String price) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Color(0xFFF0F4F7),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_circle_outline, color: Colors.grey),
      ),
      title: Text(
        id,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Text(
        price,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFAD510D)),
      ),
    );
  }
}
