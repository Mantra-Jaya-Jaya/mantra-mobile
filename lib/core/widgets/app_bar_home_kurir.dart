import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
// Import Model dan Service lu
import '../../core/models/profil_kurir_model.dart';
import '../../core/services/kurir_profile_service.dart';

class AppBarHomeKurir extends StatefulWidget {
  const AppBarHomeKurir({super.key});

  @override
  State<AppBarHomeKurir> createState() => _AppBarHomeKurirState();
}

class _AppBarHomeKurirState extends State<AppBarHomeKurir> {
  late Future<ProfilKurirModel> _profilFuture;

  @override
  void initState() {
    super.initState();
    // Tembak API pas widget pertama kali dirender
    _profilFuture = KurirService().getProfilKurir();
  }

  // 🚀 LOGIKA SAPAAN BERDASARKAN JAM HP REAL-TIME
  String _getSapaan() {
    var jam = DateTime.now().hour;

    if (jam >= 4 && jam < 10) {
      return 'Selamat Pagi';
    } else if (jam >= 10 && jam < 15) {
      return 'Selamat Siang';
    } else if (jam >= 15 && jam < 18) {
      return 'Selamat Sore';
    } else {
      return 'Selamat Malam';
    }
  }

  // 🚀 LOGIKA TANGGAL HARI INI BAHASA INDONESIA
  String _getTanggalHariIni() {
    // Format: "Selasa, 14 April 2026"
    return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFAD510D),
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🚀 FUTURE BUILDER SAKTI BUAT NUNGGU NAMA KURIR
          FutureBuilder<ProfilKurirModel>(
            future: _profilFuture,
            builder: (context, snapshot) {
              // Siapin default teks kalau lagi loading / error
              String namaTampil = '...';

              if (snapshot.hasData) {
                // Panggil getter namaPanggilan yang udah kita potong kata pertamanya
                namaTampil = snapshot.data!.namaPanggilan;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TANGGAL REALTIME
                  Text(
                    _getTanggalHariIni(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // SAPAAN REALTIME + NAMA 1 KATA
                  Text(
                    '${_getSapaan()}, $namaTampil 👋',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              );
            },
          ),

          // Icon Lonceng Notifikasi (Tetep sama)
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              Positioned(
                top: 4,
                right: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFC86012),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
