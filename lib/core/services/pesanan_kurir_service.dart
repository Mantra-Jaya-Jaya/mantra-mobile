import 'package:dio/dio.dart';
import '../models/pesanan_kurir_model.dart';
import '../network/api_client.dart';

class PesananService {
  final Dio _dio = ApiClient().dio;

  // 🚀 1. Narik 1 Pesanan Paling Baru (Buat Highlight)
  Future<PesananRingkasModel?> getPesananTerbaru() async {
    try {
      final response = await _dio.get('/kurir/pesanan/new');
      if (response.statusCode == 200 && response.data['data'] != null) {
        return PesananRingkasModel.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      // Return null kalau 404 (Gak ada pesanan baru)
      return null;
    }
  }

  // 🚀 2. Narik Semua Pesanan Online (Buat List di bawahnya)
  Future<List<PesananRingkasModel>> getAllPesananOnline() async {
    try {
      final response = await _dio.get('/kurir/pesanan');
      if (response.statusCode == 200 && response.data['data'] != null) {
        final List<dynamic> rawData = response.data['data'];
        return rawData
            .map((json) => PesananRingkasModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

class DetailPesananService {
  final Dio _dio = ApiClient().dio;

  // 🚀 Narik Detail Pesanan Berdasarkan Public ID
  Future<DetailPesananModel?> getDetailPesanan(String publicId) async {
    try {
      final response = await _dio.get('/kurir/pesanan/$publicId');

      if (response.statusCode == 200 && response.data['data'] != null) {
        return DetailPesananModel.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      // Return null kalau meledak (misal 404 Not Found atau 500)
      return null;
    }
  }

  Future<String?> terimaPesanan(String publicIdPesanan) async {
    try {
      // Kita tembak API yang lu tes di Bruno tadi
      final response = await _dio.post(
        '/kurir/pesanan/$publicIdPesanan/terima',
      );

      // Kalau dapet 200 OK, kita tangkep ID Pengantaran barunya!
      if (response.statusCode == 200 && response.data['data'] != null) {
        return response.data['data'].toString();
      }
      return null;
    } catch (e) {
      print('Gagal terima pesanan: $e');
      return null;
    }
  }
}

