import 'package:flutter/material.dart';
import 'features/landing_page/landing_page.dart';
import 'package:intl/date_symbol_data_local.dart';

// 1. TAMBAHKAN INI: Deklarasikan variabel secara global di luar class
final RouteObserver<Route> routeObserver = RouteObserver<Route>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const MantraApp());
}

class MantraApp extends StatelessWidget {
  const MantraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFAD510D)),
      ),
      // 2. TAMBAHKAN INI: Daftarkan observer agar sistem navigasi Flutter mengenalinya
      navigatorObservers: [routeObserver],
      home: const LandingPage(),
    );
  }
}
