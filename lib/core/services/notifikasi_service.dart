// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:flutter/foundation.dart';
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
          return (rawData)
              .map((json) => NotifikasiModel.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint("Error pada getNotifikasiCustomer: $e");
      throw Exception('Gagal memuat notifikasi customer: $e');
    }
  }

  Future<void> bacaNotifikasiCustomer(int id) async {
    try {
      await _apiClient.dio.patch('/customer/notifikasi/$id/baca');
    } catch (e) {
      debugPrint("Error bacaNotifikasiCustomer: $e");
    }
  }

  // ─── KASIR ──────────────────────────────────────────────────

  Future<List<NotifikasiModel>> getNotifikasiKasir() async {
    try {
      final response = await _apiClient.dio.get(
        '/kasir/notifikasi',
        options: Options(headers: {'X-Skip-Auth-Redirect': 'true'}),
      );

      debugPrint("--- [NotifikasiService Kasir Debug] ---");
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Full Response Data: ${response.data}");

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
      debugPrint("Error pada getNotifikasiKasir: $e");
      throw Exception('Gagal memuat notifikasi kasir: $e');
    }
  }

  Future<void> bacaNotifikasiKasir(int id) async {
    try {
      await _apiClient.dio.patch('/kasir/notifikasi/$id/baca');
    } catch (e) {
      debugPrint("Error bacaNotifikasiKasir: $e");
    }
  }

  // ─── KURIR ──────────────────────────────────────────────────

  Future<List<NotifikasiModel>> getNotifikasiKurir() async {
    try {
      final response = await _apiClient.dio.get(
        '/kurir/notifikasi',
        options: Options(headers: {'X-Skip-Auth-Redirect': 'true'}),
      );

      debugPrint("--- [NotifikasiService Kurir Debug] ---");
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Full Response Data: ${response.data}");

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
      debugPrint("Error pada getNotifikasiKurir: $e");
      throw Exception('Gagal memuat notifikasi kurir: $e');
    }
  }

  Future<void> bacaNotifikasiKurir(int id) async {
    try {
      await _apiClient.dio.patch('/kurir/notifikasi/$id/baca');
    } catch (e) {
      debugPrint("Error bacaNotifikasiKurir: $e");
    }
  }
}