import 'package:dio/dio.dart';
import '../network/api_client.dart';

class NotifikasiModel {
  final int idNotifikasi;
  final String judul;
  final String pesan;
  final String status;

  NotifikasiModel({
    required this.idNotifikasi,
    required this.judul,
    required this.pesan,
    required this.status,
  });

  factory NotifikasiModel.fromJson(Map<String, dynamic> json) {
    // Backend sekarang return status_notifikasi relation (object)
    // Fallback ke json['status'] untuk kompatibilitas
    String status = 'unread';
    if (json['status_notifikasi'] != null && json['status_notifikasi'] is Map) {
      status = json['status_notifikasi']['nama_status'] ?? 'unread';
    } else {
      status = json['status'] ?? 'unread';
    }

    return NotifikasiModel(
      idNotifikasi: json['id_notifikasi'] ?? 0,
      judul: json['judul'] ?? 'Tanpa Judul',
      pesan: json['pesan'] ?? '',
      status: status,
    );
  }
}

class NotifikasiService {
  final ApiClient _apiClient = ApiClient();

  Future<List<NotifikasiModel>> getNotifikasiKasir() async {
    try {
      final response = await _apiClient.dio.get('/kasir/notifikasi');

      print("--- [NotifikasiService Debug] ---");
      print("Status Code: ${response.statusCode}");
      print("Full Response Data: ${response.data}");

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
      print("Error pada getNotifikasiKasir: $e");
      throw Exception('Gagal memuat notifikasi: $e');
    }
  }

  Future<List<NotifikasiModel>> getNotifikasiKurir() async {
    try {
      final response = await _apiClient.dio.get('/kurir/notifikasi');
      if (response.statusCode == 200) {
        List<dynamic> data = response.data['data'];
        return data.map((json) => NotifikasiModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Gagal memuat notifikasi: $e');
    }
  }

  Future<List<NotifikasiModel>> getNotifikasiCustomer() async {
    try {
      final response = await _apiClient.dio.get('/customer/notifikasi');
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
      throw Exception('Gagal memuat notifikasi: $e');
    }
  }
}
