import 'dart:io';
import 'package:dio/dio.dart';
import '../models/pengantaran_model.dart';
import '../network/api_client.dart';

class PengantaranService {
  // 🚀 Panggil Dio dari ApiClient temen lu biar tokennya otomatis nempel!
  final Dio _dio = ApiClient().dio;

  // 🚀 Fungsi buat narik data tugas pengantaran
  Future<List<PengantaranModel>> getDaftarPengantaran({String? status}) async {
    try {
      final queryParams = status != null ? {'status': status} : null;
      final response = await _dio.get('/kurir/tugas', queryParameters: queryParams);

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

  Future<void> updateLokasiKurir(String publicId, double latitude, double longitude) async {
    try {
      await _apiClient.dio.put(
        '/kurir/pengantaran/$publicId/lokasi',
        data: {
          'latitude': latitude,
          'longitude': longitude,
        },
      );
    } on DioException catch (e) {
      print('❌ Gagal update lokasi kurir: ${e.response?.statusCode} - ${e.message}');
    }
  }

  Future<Map<String, dynamic>?> uploadBuktiSelesai(String publicId, File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'foto': await MultipartFile.fromFile(imageFile.path, filename: 'bukti_selesai.jpg'),
      });
      final response = await _apiClient.dio.post(
        '/kurir/pengantaran/$publicId/selesai',
        data: formData,
      );
      return response.data;
    } on DioException catch (e) {
      print('❌ Gagal upload bukti selesai: ${e.response?.statusCode} - ${e.message}');
      return null;
    }
  }
}
