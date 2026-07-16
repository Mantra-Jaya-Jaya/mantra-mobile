// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:frontend/core/models/notifikasi_model.dart';
import 'package:frontend/core/services/notifikasi_service.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotifikasiService _service = NotifikasiService();
  late Future<List<NotifikasiModel>> _notifFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _notifFuture = _service.getNotifikasiKasir();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFAF510C),
        title: const Text("Notifikasi", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshData();
          await _notifFuture;
        },
        child: FutureBuilder<List<NotifikasiModel>>(
          future: _notifFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 250),
                  Center(child: Text("Tidak ada notifikasi baru"))
                ],
              );
            }
            final notifications = snapshot.data!;
            // Urutkan berdasarkan yang terbaru (ID descending)
            notifications.sort((a, b) => b.idNotifikasi.compareTo(a.idNotifikasi));

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final item = notifications[index];
                return _buildCard(item);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildCard(NotifikasiModel item) {
    String formattedTime = "";
    if (item.createdAt != null) {
      formattedTime = DateFormat('dd MMM yyyy, HH:mm').format(item.createdAt!);
    }

    return Container(
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.status == 'unread'
                  ? Colors.orange.shade50
                  : Colors.grey.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.status == 'unread'
                  ? Icons.notifications_active
                  : Icons.notifications_none,
              size: 20,
              color: item.status == 'unread'
                  ? const Color(0xFFAF510C)
                  : Colors.grey,
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
                        item.judul,
                        style: TextStyle(
                          fontWeight: item.status == 'unread'
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
    );
  }
}