import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/models/summary_model.dart'; // Pastikan import model Anda

class SummaryService {
  final ApiClient _client;

  SummaryService({ApiClient? client}) : _client = client ?? ApiClient();

  // Method 1: Untuk Ringkasan
  Future<SummaryData> getLaporanRingkasan() async {
    try {
      final response = await _client.dio.get('/kasir/laporan');
      return SummaryData.fromJson(response.data['data']);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      throw Exception("Gagal memuat (Error $statusCode): ${e.message}");
    } catch (e) {
      throw Exception("Terjadi kesalahan yang tidak terduga: $e");
    }
  }

  // Method 2: TAMBAHKAN INI untuk Detail Produk
  Future<DetailLaporanModel> getDetailLaporanProduk(String publicId) async {
    try {
      // Pastikan path ini benar-benar sesuai dengan rute di Gin Gonic Anda
      final response = await _client.dio.get('/kasir/laporan/produk/$publicId');
      return DetailLaporanModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      // Jika statusnya 404, pesan ini akan muncul di UI Anda
      throw Exception("Gagal memuat detail (Error $statusCode): ${e.message}");
    } catch (e) {
      throw Exception("Terjadi kesalahan: $e");
    }
  }
}