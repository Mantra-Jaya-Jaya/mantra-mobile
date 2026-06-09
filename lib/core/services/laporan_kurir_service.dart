import 'package:dio/dio.dart';
import '../models/laporan_kurir_model.dart'; 
import '../network/api_client.dart'; 

class LaporanService {
  final Dio _dio = ApiClient().dio;

  Future<LaporanKurirModel?> getLaporanHariIni() async {
    try {
      // Tembak rute API Golang lu
      final response = await _dio.get('/kurir/laporan');

      // Cek apakah response sukses dan datanya gak kosong
      if (response.statusCode == 200 && response.data['data'] != null) {
        final Map<String, dynamic> rawData = response.data['data'];

        // Terjemahin JSON ke Object Dart
        return LaporanKurirModel.fromJson(rawData);
      }
      return null;
    } catch (e) {
      print("❌ Error pada LaporanService: $e");
      // Lempar error biar bisa ditangkap sama UI (FutureBuilder)
      rethrow;
    }
  }
}
