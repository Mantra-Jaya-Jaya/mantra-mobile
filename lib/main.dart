import 'package:flutter/material.dart';
import 'features/landing_page/landing_page.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/network/api_client.dart';
import 'core/services/push_notification_service.dart';

final RouteObserver<Route> routeObserver = RouteObserver<Route>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  await PushNotificationService.initialize();
  PushNotificationService.startPolling();

  ApiClient.setOnUnauthorized(() {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LandingPage()),
      (route) => false,
    );
  });

  runApp(const MantraApp());
}

class MantraApp extends StatelessWidget {
  const MantraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFAD510D)),
      ),
      navigatorObservers: [routeObserver],
      home: const LandingPage(),
    );
  }
}
