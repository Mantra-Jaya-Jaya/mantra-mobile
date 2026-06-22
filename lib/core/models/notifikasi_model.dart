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
    String extractStatus(dynamic data) {
      if (data is String) return data;
      if (data is Map<String, dynamic>) {
        return data['nama_status'] as String? ?? 'unread';
      }
      return 'unread';
    }

    return NotifikasiModel(
      idNotifikasi: json['id_notifikasi'] ?? 0,
      judul: json['judul'] ?? 'Tanpa Judul',
      pesan: json['pesan'] ?? '',
      status: extractStatus(json['status'] ?? json['status_notifikasi']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }
}