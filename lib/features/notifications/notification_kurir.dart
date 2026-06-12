import 'package:flutter/material.dart';
import 'package:frontend/core/services/notifikasi_service.dart';
import 'package:frontend/core/widgets/base_header_widget.dart';

class NotificationKurirPage extends StatefulWidget {
  const NotificationKurirPage({super.key});

  @override
  State<NotificationKurirPage> createState() => _NotificationKurirPageState();
}

class _NotificationKurirPageState extends State<NotificationKurirPage> {
  final NotifikasiService _service = NotifikasiService();
  late Future<List<NotifikasiModel>> _notifFuture;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    setState(() {
      _notifFuture = _service.getNotifikasiKurir();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: BaseHeaderWidget(
        title: "Notifikasi Kurir",
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFFAD510D),
        onRefresh: () async {
          _loadNotifications();
          await _notifFuture;
        },
        child: FutureBuilder<List<NotifikasiModel>>(
          future: _notifFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFAD510D),
                ),
              );
            } else if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                          const SizedBox(height: 10),
                          Text("Gagal memuat notifikasi: ${snapshot.error}"),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _loadNotifications,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFAD510D),
                            ),
                            child: const Text("Coba Lagi", style: TextStyle(color: Colors.white)),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey),
                          const SizedBox(height: 10),
                          Text("Tidak ada notifikasi baru"),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            final notifications = snapshot.data!;
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final item = notifications[index];
                return _buildNotificationCard(
                  title: item.judul,
                  message: item.pesan,
                  status: item.status,
                  icon: Icons.notifications_active_outlined,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required String title,
    required String message,
    required String status,
    required IconData icon,
  }) {
    final bool isUnread = status.toLowerCase() == 'unread' || status.toLowerCase() == 'aktif';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isUnread ? const Color(0xFFFFF7F2) : Colors.white,
        border: Border.all(
          color: isUnread ? const Color(0xFFFFD8BF) : const Color(0xFFBFC9D1).withOpacity(0.5),
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUnread ? const Color(0xFFFFE5D4) : const Color(0xFFECEFF1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isUnread ? const Color(0xFFAD510D) : Colors.grey,
              size: 22,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isUnread ? const Color(0xFFAD510D) : Colors.black87,
                        ),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFAD510D),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
