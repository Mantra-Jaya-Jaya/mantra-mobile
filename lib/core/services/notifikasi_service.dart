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
    return NotifikasiModel(
      // Pastikan key JSON di sini sama persis dengan yang dikirim backend
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
      
      // --- TAMBAHAN LOGGING UNTUK DEBUGGING ---
      print("--- [NotifikasiService Debug] ---");
      print("Status Code: ${response.statusCode}");
      print("Full Response Data: ${response.data}");
      // ----------------------------------------

      if (response.statusCode == 200) {
        // Pengecekan aman: pastikan key 'data' ada dan berbentuk List
        final dynamic rawData = response.data['data'];
        
        if (rawData != null && rawData is List) {
          return (rawData as List)
              .map((json) => NotifikasiModel.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      // Jika terjadi error (misalnya 401 yang tidak ter-handle), 
      // pesan error akan tampil di console
      print("Error pada getNotifikasiKasir: $e");
      throw Exception('Gagal memuat notifikasi: $e');
    }
  }
}