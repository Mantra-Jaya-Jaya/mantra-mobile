import 'package:dio/dio.dart';
import 'dart:io';
import '../models/pengantaran_model.dart'; 
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

  // ----------------------------------------------------------
  // Tembak API Update Lokasi GPS Kurir (Realtime)
  // ----------------------------------------------------------
  Future<bool> updateLokasiKurir(
    String publicId,
    double latitude,
    double longitude,
  ) async {
    try {
      // 🚀 Tembak PUT sesuai router Golang lu
      final response = await _apiClient.dio.put(
        '/kurir/pengantaran/$publicId/lokasi',
        data: {'latitude': latitude, 'longitude': longitude},
      );

      // Kalau sukses (200 OK), kembalikan nilai true
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } on DioException catch (e) {
      print(
        '❌ DEBUG API LOKASI: Error nembak lokasi -> ${e.response?.statusCode} - ${e.message}',
      );
      return false;
    } catch (e) {
      print('❌ DEBUG API LOKASI: Error System -> $e');
      return false;
    }
  }

  Future<SelesaikanPengantaranModel?> uploadBuktiSelesai(
    String publicId,
    File fileGambar,
  ) async {
    try {
      // 🚀 1. Bungkus gambar lu jadi Multipart/Form-Data
      // Ambil nama file asli dari path-nya
      String fileName = fileGambar.path.split('/').last;

      FormData formData = FormData.fromMap({
        // Key "foto_bukti" ini WAJIB sama kayak di Golang lu
        "foto_bukti": await MultipartFile.fromFile(
          fileGambar.path,
          filename: fileName,
        ),
      });

      // 🚀 2. Tembak pakai method PUT (sesuai kesepakatan kita tadi)
      final response = await _apiClient.dio.put(
        '/kurir/pengantaran/$publicId/selesai',
        data: formData,
      );

      // 🚀 3. Tangkap balikannya
      if (response.statusCode == 200 && response.data['data'] != null) {
        print('✅ DEBUG UPLOAD: Sukses upload bukti!');
        return SelesaikanPengantaranModel.fromJson(response.data['data']);
      }
      return null;
    } on DioException catch (e) {
      print(
        '❌ DEBUG API UPLOAD: Error nembak -> ${e.response?.statusCode} - ${e.response?.data}',
      );
      return null;
    } catch (e) {
      print('❌ DEBUG API UPLOAD: Error System -> $e');
      return null;
    }
  }
}


