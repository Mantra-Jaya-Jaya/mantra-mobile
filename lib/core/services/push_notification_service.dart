// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:frontend/main.dart';
import 'package:frontend/core/services/notifikasi_service.dart';
import 'package:frontend/core/models/notifikasi_model.dart';
import 'package:frontend/features/notifications/notification_kasir.dart';
import 'package:frontend/features/notifications/notification_customer.dart';
import 'package:frontend/features/notifications/notification_kurir.dart';

class PushNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final NotifikasiService _notifikasiService = NotifikasiService();
  static Timer? _pollingTimer;
  static String _role = '';

  static String get role => _role;

  static void setRole(String role) {
    _role = role;
    debugPrint("--- PushNotificationService: Role di-set ke '$role' ---");
  }

  static Future<void> initialize() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    // FIX 1: initialize() pakai positional argument, bukan named 'settings'
    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (navigatorKey.currentState != null) {
          Widget targetPage;
          if (_role == 'customer') {
            targetPage = const NotificationCustomerPage();
          } else if (_role == 'kurir') {
            targetPage = const NotificationKurirPage();
          } else {
            targetPage = const NotificationScreen();
          }
          navigatorKey.currentState!.push(
            MaterialPageRoute(builder: (context) => targetPage),
          );
        }
      },
    );

    const AndroidNotificationChannel kasirChannel = AndroidNotificationChannel(
      'kasir_notif_channel',
      'Notifikasi Kasir',
      description: 'Channel untuk notifikasi pesanan dan stok kasir',
      importance: Importance.max,
    );

    const AndroidNotificationChannel customerChannel =
        AndroidNotificationChannel(
      'customer_notif_channel',
      'Notifikasi Customer',
      description: 'Channel untuk notifikasi pesanan customer',
      importance: Importance.max,
    );

    const AndroidNotificationChannel kurirChannel = AndroidNotificationChannel(
      'kurir_notif_channel',
      'Notifikasi Kurir',
      description: 'Channel untuk notifikasi pengantaran kurir',
      importance: Importance.max,
    );

    final plugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await plugin?.createNotificationChannel(kasirChannel);
    await plugin?.createNotificationChannel(customerChannel);
    await plugin?.createNotificationChannel(kurirChannel);
  }

  static void startPolling() {
    debugPrint("--- Polling Notifikasi Dimulai (role: $_role) ---");
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await checkNewNotifications();
    });
  }

  static void stopPolling() {
    debugPrint("--- Polling Notifikasi Berhenti ---");
    _pollingTimer?.cancel();
  }

  static Future<void> checkNewNotifications() async {
    if (_role.isEmpty) return;

    try {
      // FIX 2: deklarasi List<NotifikasiModel> langsung
      List<NotifikasiModel> notifList = [];

      if (_role == 'customer') {
        notifList = await _notifikasiService.getNotifikasiCustomer();
      } else if (_role == 'kurir') {
        notifList = await _notifikasiService.getNotifikasiKurir();
      } else {
        notifList = await _notifikasiService.getNotifikasiKasir();
      }

      if (notifList.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final lastId = prefs.getInt('last_notification_id_$_role') ?? 0;

      // FIX 3: idNotifikasi diakses langsung tanpa null check
      final newNotifs =
          notifList.where((n) => n.idNotifikasi > lastId).toList();

      debugPrint(
          "Polling ($_role): Ditemukan ${notifList.length} total, ${newNotifs.length} baru (Last ID: $lastId)");

      if (newNotifs.isNotEmpty) {
        newNotifs.sort((a, b) => a.idNotifikasi.compareTo(b.idNotifikasi));

        for (var notif in newNotifs) {
          await showLocalNotification(
            id: notif.idNotifikasi,
            title: notif.judul,
            body: notif.pesan,
          );
        }

        await prefs.setInt(
            'last_notification_id_$_role', newNotifs.last.idNotifikasi);
      }
    } catch (e) {
      debugPrint("Polling error ($_role): $e");
    }
  }

  static Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    final String channelId;
    final String channelName;

    if (_role == 'customer') {
      channelId = 'customer_notif_channel';
      channelName = 'Notifikasi Customer';
    } else if (_role == 'kurir') {
      channelId = 'kurir_notif_channel';
      channelName = 'Notifikasi Kurir';
    } else {
      channelId = 'kasir_notif_channel';
      channelName = 'Notifikasi Kasir';
    }

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelName,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    final NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    // FIX 4: show() pakai positional arguments, bukan named parameter
    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );
  }
}