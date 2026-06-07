import 'package:dio/dio.dart';
import '../models/pengantaran_model.dart'; // Pastikan lu udah bikin modelnya
import '../network/api_client.dart';

class PengantaranService {
  // 🚀 Panggil Dio dari ApiClient temen lu biar tokennya otomatis nempel!
  final Dio _dio = ApiClient().dio;

  // 🚀 Fungsi buat narik data tugas pengantaran
  Future<List<PengantaranModel>> getDaftarPengantaran() async {
    try {
      // Tembak rute API Golang lu (sesuaikan dengan rute di Golang)
      final response = await _dio.get('/kurir/tugas');

      if (response.data != null && response.data['data'] != null) {
        final List<dynamic> rawData = response.data['data'];

        // Terjemahin JSON mentah jadi Object Dart pakai model lu
        return rawData.map((json) => PengantaranModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("❌ Error pada PengantaranService: $e");
      return [];
    }
  }
}
