import '../network/api_client.dart';

class NotifikasiModel {
  final int idNotifikasi;
  final String judul;
  final String pesan;
  final String status;
  final DateTime? createdAt;

  NotifikasiModel({
    required this.idNotifikasi,
    required this.judul,
    required this.pesan,
    required this.status,
    this.createdAt,
  });

  factory NotifikasiModel.fromJson(Map<String, dynamic> json) {
    // Backend mengirim status dalam objek nested: status_notifikasi -> nama_status
    String statusName = 'unread';
    if (json['status_notifikasi'] != null &&
        json['status_notifikasi']['nama_status'] != null) {
      statusName = json['status_notifikasi']['nama_status'];
    }

    return NotifikasiModel(
      idNotifikasi: json['id_notifikasi'] ?? 0,
      judul: json['judul'] ?? 'Tanpa Judul',
      pesan: json['pesan'] ?? '',
      status: statusName,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
    );
  }
}

class NotifikasiService {
  final ApiClient _apiClient = ApiClient();

  Future<void> bacaNotifikasi(int id) async {
    try {
      await _apiClient.dio.patch('/customer/notifikasi/$id/baca');
    } catch (e) {
      print("Error bacaNotifikasi: $e");
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
          return rawData
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