import 'package:flutter/material.dart';
import 'package:frontend/core/models/notifikasi_model.dart';
import 'package:frontend/core/services/notifikasi_service.dart';
import 'package:frontend/core/widgets/base_header_widget.dart';

class NotificationCustomerPage extends StatefulWidget {
  const NotificationCustomerPage({super.key});

  @override
  State<NotificationCustomerPage> createState() =>
      _NotificationCustomerPageState();
}

class _NotificationCustomerPageState extends State<NotificationCustomerPage> {
  final NotifikasiService _service = NotifikasiService();
  late Future<List<NotifikasiModel>> _notifFuture;
  List<NotifikasiModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _isLoading = true;
      _notifFuture = _service.getNotifikasiCustomer().then((data) {
        if (mounted) {
          setState(() {
            _notifications = data;
            _isLoading = false;
          });
        }
        return data;
      });
    });
  }

  IconData _mapIcon(String? judul, String? pesan) {
    final text = (judul ?? '').toLowerCase() + (pesan ?? '').toLowerCase();
    if (text.contains('diskon') || text.contains('promo')) {
      return Icons.discount_outlined;
    }
    if (text.contains('bayar') || text.contains('pembayaran') || text.contains('payment')) {
      return Icons.payment_outlined;
    }
    if (text.contains('kirim') || text.contains('shipping') || text.contains('kurir')) {
      return Icons.local_shipping_outlined;
    }
    if (text.contains('sampai') || text.contains('diterima') || text.contains('selesai')) {
      return Icons.location_on_outlined;
    }
    return Icons.notifications_active_outlined;
  }

  Future<void> _markAsRead(NotifikasiModel item) async {
    if (item.status == 'read') return;

    await _service.bacaNotifikasiCustomer(item.idNotifikasi);
    final index = _notifications.indexWhere(
      (n) => n.idNotifikasi == item.idNotifikasi,
    );
    if (index != -1 && mounted) {
      setState(() {
        _notifications[index] = NotifikasiModel(
          idNotifikasi: item.idNotifikasi,
          judul: item.judul,
          pesan: item.pesan,
          status: 'read',
        );
      });
    }
  }

  Map<String, List<NotifikasiModel>> _groupByDate(List<NotifikasiModel> items) {
    final grouped = <String, List<NotifikasiModel>>{};

    for (final item in items) {
      String label;
      if (item.status == 'read') {
        label = 'Sebelumnya';
      } else {
        label = 'Baru';
      }

      grouped.putIfAbsent(label, () => []);
      grouped[label]!.add(item);
    }

    final sorted = <String, List<NotifikasiModel>>{};
    if (grouped.containsKey('Baru')) {
      sorted['Baru'] = grouped['Baru']!;
    }
    if (grouped.containsKey('Sebelumnya')) {
      sorted['Sebelumnya'] = grouped['Sebelumnya']!;
    }

    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: BaseHeaderWidget(
        title: 'Notifikasi',
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshData();
          await _notifFuture;
        },
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFAD510D)),
              )
            : _notifications.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 250),
                      Center(
                        child: Text(
                          'Tidak ada notifikasi',
                          style: TextStyle(color: Colors.grey, fontSize: 15),
                        ),
                      ),
                    ],
                  )
                : _buildGroupedList(),
      ),
    );
  }

  Widget _buildGroupedList() {
    final grouped = _groupByDate(_notifications);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      children: [
        if (grouped.containsKey('Baru')) ...[
          const Text(
            'Baru',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          ...grouped['Baru']!.map((item) => _buildNotifCard(item)),
          const SizedBox(height: 20),
        ],
        if (grouped.containsKey('Sebelumnya')) ...[
          const Text(
            'Sebelumnya',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          ...grouped['Sebelumnya']!.map((item) => _buildNotifCard(item)),
        ],
      ],
    );
  }

  Widget _buildNotifCard(NotifikasiModel item) {
    final isUnread = item.status == 'unread';

    return GestureDetector(
      onTap: () => _markAsRead(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUnread ? Colors.white : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isUnread
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
          border: Border.all(
            color: isUnread ? const Color(0xFFAD510D).withOpacity(0.3) : Colors.grey.shade200,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1E8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _mapIcon(item.judul, item.pesan),
                    color: const Color(0xFFAD510D),
                    size: 22,
                  ),
                ),
                if (isUnread)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFFAD510D),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.judul,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.pesan,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
