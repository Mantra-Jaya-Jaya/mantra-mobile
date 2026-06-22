import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../models/notifikasi_model.dart';

class NotifikasiService {
  final ApiClient _apiClient = ApiClient();

  // ─── CUSTOMER ───────────────────────────────────────────────

  Future<List<NotifikasiModel>> getNotifikasiCustomer() async {
    try {
      final response = await _apiClient.dio.get(
        '/customer/notifikasi',
        options: Options(headers: {'X-Skip-Auth-Redirect': 'true'}),
      );

      if (response.statusCode == 200) {
        final dynamic rawData = response.data['data'];
        if (rawData != null && rawData is List) {
          return (rawData as List)
              .map((json) => NotifikasiModel.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print("Error pada getNotifikasiCustomer: $e");
      throw Exception('Gagal memuat notifikasi customer: $e');
    }
  }

  Future<void> bacaNotifikasiCustomer(int id) async {
    try {
      await _apiClient.dio.patch('/customer/notifikasi/$id/baca');
    } catch (e) {
      print("Error bacaNotifikasiCustomer: $e");
    }
  }

  // ─── KASIR ──────────────────────────────────────────────────

  Future<List<NotifikasiModel>> getNotifikasiKasir() async {
    try {
      final response = await _apiClient.dio.get(
        '/kasir/notifikasi',
        options: Options(headers: {'X-Skip-Auth-Redirect': 'true'}),
      );

      print("--- [NotifikasiService Kasir Debug] ---");
      print("Status Code: ${response.statusCode}");
      print("Full Response Data: ${response.data}");

      if (response.statusCode == 200) {
        final dynamic rawData = response.data['data'];
        if (rawData != null && rawData is List) {
          return rawData
              .map((json) => NotifikasiModel.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print("Error pada getNotifikasiKasir: $e");
      throw Exception('Gagal memuat notifikasi kasir: $e');
    }
  }

  Future<void> bacaNotifikasiKasir(int id) async {
    try {
      await _apiClient.dio.patch('/kasir/notifikasi/$id/baca');
    } catch (e) {
      print("Error bacaNotifikasiKasir: $e");
    }
  }

  // ─── KURIR ──────────────────────────────────────────────────

  Future<List<NotifikasiModel>> getNotifikasiKurir() async {
    try {
      final response = await _apiClient.dio.get(
        '/kurir/notifikasi',
        options: Options(headers: {'X-Skip-Auth-Redirect': 'true'}),
      );

      print("--- [NotifikasiService Kurir Debug] ---");
      print("Status Code: ${response.statusCode}");
      print("Full Response Data: ${response.data}");

      if (response.statusCode == 200) {
        final dynamic rawData = response.data['data'];
        if (rawData != null && rawData is List) {
          return rawData
              .map((json) => NotifikasiModel.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print("Error pada getNotifikasiKurir: $e");
      throw Exception('Gagal memuat notifikasi kurir: $e');
    }
  }

  Future<void> bacaNotifikasiKurir(int id) async {
    try {
      await _apiClient.dio.patch('/kurir/notifikasi/$id/baca');
    } catch (e) {
      print("Error bacaNotifikasiKurir: $e");
    }
  }
}