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

class DetailPengantaranService {
  final ApiClient _apiClient;

  DetailPengantaranService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  // ----------------------------------------------------------
  // Ambil Data Detail Pengantaran (Khusus Peta & Info)
  // ----------------------------------------------------------
  Future<DetailPengantaranModel?> getDetailPengantaran(String publicId) async {
    try {
      // 🚀 UBAH ENDPOINT INI SESUAI SAMA ROUTES GOLANG LU
      final response = await _apiClient.dio.get(
        '/kurir/pengantaran/$publicId/detail',
      );

      if (response.statusCode == 200 && response.data['data'] != null) {
        // Terjemahin hasil JSON ke bentuk Object DetailPengantaranModel
        return DetailPengantaranModel.fromJson(response.data['data']);
      }
      return null;
    } on DioException catch (e) {
      print(
        '❌ DEBUG API PETA: Error nembak detail -> ${e.response?.statusCode} - ${e.message}',
      );
      return null;
    } catch (e) {
      print('❌ DEBUG API PETA: Gagal Parsing Model -> $e');
      return null;
    }
  }
}
