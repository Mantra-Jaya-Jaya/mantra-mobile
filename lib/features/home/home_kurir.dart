import 'package:flutter/material.dart';

class DashboardKurir extends StatelessWidget {
  const DashboardKurir({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text("Ini adalah dashboard kurir"),
        ),
      ),
    );
  }
}