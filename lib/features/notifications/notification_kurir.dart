// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:frontend/core/models/notifikasi_model.dart';
import 'package:frontend/core/services/notifikasi_service.dart';
import 'package:intl/intl.dart';

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
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _notifFuture = _service.getNotifikasiKurir();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFAF510C),
        title: const Text(
          "Notifikasi",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFFAF510C),
        onRefresh: () async {
          _refreshData();
          await _notifFuture;
        },
        child: FutureBuilder<List<NotifikasiModel>>(
          future: _notifFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFAF510C)),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      "Gagal memuat notifikasi",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _refreshData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFAF510C),
                      ),
                      child: const Text(
                        'Coba Lagi',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 250),
                  Center(
                    child: Text(
                      "Tidak ada notifikasi baru",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              );
            }

            final notifications = snapshot.data!;
            notifications.sort(
                (a, b) => b.idNotifikasi.compareTo(a.idNotifikasi));

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return _buildCard(notifications[index]);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildCard(NotifikasiModel item) {
    String formattedTime = '';
    if (item.createdAt != null) {
      formattedTime =
          DateFormat('dd MMM yyyy, HH:mm').format(item.createdAt!);
    }

    final bool isUnread = item.status == 'unread';

    return GestureDetector(
      onTap: () async {
        await _service.bacaNotifikasiKurir(item.idNotifikasi);
        _refreshData();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ikon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isUnread
                    ? Colors.orange.shade50
                    : Colors.grey.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isUnread
                    ? Icons.notifications_active
                    : Icons.notifications_none,
                size: 20,
                color: isUnread ? const Color(0xFFAF510C) : Colors.grey,
              ),
            ),

            const SizedBox(width: 15),

            // Konten
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.judul,
                          style: TextStyle(
                            fontWeight: isUnread
                                ? FontWeight.bold
                                : FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (formattedTime.isNotEmpty)
                        Text(
                          formattedTime,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.pesan,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
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