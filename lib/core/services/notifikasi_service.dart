import 'package:dio/dio.dart';
import '../network/api_client.dart'; // <-- Sesuaikan dengan lokasi ApiClient kamu

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
    return NotifikasiModel(
      idNotifikasi: json['id_notifikasi'] ?? 0,
      judul: json['judul'] ?? 'Tanpa Judul',
      pesan: json['pesan'] ?? '',
      status: json['status'] ?? 'unread',
    );
  }
}

class NotifikasiService {
  final ApiClient _apiClient = ApiClient();

  Future<List<NotifikasiModel>> getNotifikasiKasir() async {
    try {
      final response = await _apiClient.dio.get('/kasir/notifikasi');
      if (response.statusCode == 200) {
        List<dynamic> data = response.data['data'];
        return data.map((json) => NotifikasiModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Gagal memuat notifikasi: $e');
    }
  }
}