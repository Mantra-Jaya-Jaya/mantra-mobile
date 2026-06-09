import 'package:dio/dio.dart';
import '../models/profil_kurir_model.dart'; 
import '../network/api_client.dart';

class KurirService {
  // 🚀 Panggil Dio dari ApiClient biar token otomatis nempel!
  final Dio _dio = ApiClient().dio;

  // 🚀 Fungsi buat narik data profil kurir
  Future<ProfilKurirModel> getProfilKurir() async {
    try {
      // Tembak rute API Golang lu (gak perlu nulis baseUrl lagi)
      final response = await _dio.get('/kurir/profile');

      // Cek apakah balasan dari server ada datanya
      if (response.data != null && response.data['data'] != null) {
        final Map<String, dynamic> rawData = response.data['data'];

        // Terjemahin JSON mentah jadi Object Dart
        return ProfilKurirModel.fromJson(rawData);
      } else {
        throw Exception('Data profil kosong dari server');
      }
    } catch (e) {
      // Print error biar gampang debugging di terminal lu
      print("❌ Error pada KurirService (getProfilKurir): $e");

      // Lempar error biar FutureBuilder di UI bisa nangkep dan nampilin pesan
      rethrow;
    }
  }

  Future<void> changePassword({
    required String passwordLama,
    required String passwordBaru,
    required String konfirmasiPassword,
  }) async {
    await _dio.put('/change-password', data: {
      'password_lama': passwordLama,
      'password_baru': passwordBaru,
      'konfirmasi_password': konfirmasiPassword,
    });
  }
}
