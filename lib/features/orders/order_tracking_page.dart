import 'package:flutter/material.dart';
import 'services/customer_order_service.dart';
import '../../core/widgets/base_header_widget.dart';

class OrderTrackingPage extends StatefulWidget {
  final String noPesanan;

  const OrderTrackingPage({super.key, required this.noPesanan});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  final CustomerOrderService _orderService = CustomerOrderService();
  bool _isLoading = true;
  Map<String, dynamic>? _trackingData;

  @override
  void initState() {
    super.initState();
    _fetchTracking();
  }

  Future<void> _fetchTracking() async {
    try {
      final data = await _orderService.getTrackingInfo(widget.noPesanan);
      if (mounted) {
        setState(() {
          _trackingData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: BaseHeaderWidget(
        title: 'Lacak Pesanan',
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFAD510D)))
          : _trackingData == null
              ? const Center(child: Text("Gagal memuat data pelacakan"))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final data = _trackingData!;
    final tipeEkspedisi = data['tipe_ekspedisi'] ?? 'internal';
    final history = data['history'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data['nomor_resi'] != null) ...[
            _infoCard(
              children: [
                _label("Nomor Resi"),
                Text(
                  data['nomor_resi'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                if (data['ekspedisi'] != null)
                  Text(
                    data['ekspedisi'],
                    style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (tipeEkspedisi == 'internal' && data['kurir'] != null) ...[
            _infoCard(
              children: [
                _label("Kurir"),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: data['kurir']['foto'] != null && data['kurir']['foto'].toString().isNotEmpty
                          ? NetworkImage(data['kurir']['foto'])
                          : null,
                      child: data['kurir']['foto'] == null || data['kurir']['foto'].toString().isEmpty
                          ? const Icon(Icons.person, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['kurir']['nama'] ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        if (data['kurir']['plat_nomor'] != null && data['kurir']['plat_nomor'].toString().isNotEmpty)
                          Text(
                            data['kurir']['plat_nomor'],
                            style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (data['lokasi_kurir'] != null && data['lokasi_kurir']['latitude'] != null) ...[
            _infoCard(
              children: [
                _label("Lokasi Kurir"),
                Text(
                  "${data['lokasi_kurir']['latitude'].toStringAsFixed(6)}, ${data['lokasi_kurir']['longitude'].toStringAsFixed(6)}",
                  style: const TextStyle(fontSize: 13),
                ),
                if (data['jarak_meter'] != null && data['jarak_meter'] > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      "Jarak: ${_formatDistance(data['jarak_meter'])}",
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFFAD510D)),
                    ),
                  ),
                if (data['estimasi_tiba'] != null && data['estimasi_tiba'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      "Estimasi tiba: ${data['estimasi_tiba']}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (history.isNotEmpty) ...[
            const Text(
              "Riwayat Pengiriman",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            ...history.map((h) => _historyItem(h)),
          ] else ...[
            _infoCard(
              children: [
                _label("Status"),
                Text(
                  data['message'] ?? "Pesanan sedang diproses",
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(color: Colors.grey, fontSize: 11),
      ),
    );
  }

  Widget _historyItem(Map<String, dynamic> h) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xFFAD510D),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 2,
                height: 40,
                color: Colors.grey[300],
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  h['status'] ?? '-',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                if (h['deskripsi'] != null)
                  Text(
                    h['deskripsi'],
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                if (h['waktu'] != null)
                  Text(
                    h['waktu'],
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDistance(int meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '$meters m';
  }
}
