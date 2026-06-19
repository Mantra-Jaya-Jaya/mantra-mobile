import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:frontend/main.dart';
import 'package:frontend/core/services/notifikasi_service.dart';
import 'package:frontend/features/notifications/notification_kasir.dart';

class PushNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  static final NotifikasiService _notifikasiService = NotifikasiService();
  static Timer? _pollingTimer;

  static Future<void> initialize() async {
    // 1. Request Izin Notifikasi (Penting untuk Android 13+)
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Logika saat notifikasi diklik
        if (navigatorKey.currentState != null) {
          navigatorKey.currentState!.push(
            MaterialPageRoute(
              builder: (context) => const NotificationScreen(),
            ),
          );
        }
      },
    );

    // 2. Buat Notification Channel secara eksplisit
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'kasir_notif_channel', // id
      'Notifikasi Kasir', // title
      description: 'Channel untuk notifikasi pesanan dan stok kasir', // description
      importance: Importance.max,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static void startPolling() {
    print("--- Polling Notifikasi Dimulai ---");
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      await checkNewNotifications();
    });
  }

  static void stopPolling() {
    print("--- Polling Notifikasi Berhenti ---");
    _pollingTimer?.cancel();
  }

  static Future<void> checkNewNotifications() async {
    try {
      final notifList = await _notifikasiService.getNotifikasiKasir();
      if (notifList.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final lastId = prefs.getInt('last_notification_id') ?? 0;

      // Filter notifikasi baru (ID > lastId)
      final newNotifs = notifList.where((n) => n.idNotifikasi > lastId).toList();

      print("Polling: Ditemukan ${notifList.length} total, ${newNotifs.length} baru (Last ID: $lastId)");

      if (newNotifs.isNotEmpty) {
        newNotifs.sort((a, b) => a.idNotifikasi.compareTo(b.idNotifikasi));

        for (var notif in newNotifs) {
          await showLocalNotification(
            id: notif.idNotifikasi,
            title: notif.judul,
            body: notif.pesan,
          );
        }

        // Simpan ID terbaru agar tidak muncul lagi
        await prefs.setInt('last_notification_id', newNotifs.last.idNotifikasi);
      }
    } catch (e) {
      print("Polling error: $e");
    }
  }

  static Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'kasir_notif_channel',
      'Notifikasi Kasir',
      channelDescription: 'Channel untuk notifikasi pesanan dan stok kasir',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );
  }
}
