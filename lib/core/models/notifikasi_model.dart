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
    // Backend sekarang return status_notifikasi relation
    String status = json['status_notifikasi']?['nama_status'] ??
                   json['status'] ??
                   'unread';

    return NotifikasiModel(
      idNotifikasi: json['id_notifikasi'],
      judul: json['judul'],
      pesan: json['pesan'],
      status: status,
    );
  }
}

// ============================================================================
// StatusNotifikasiModel - Helper class for status relation
// ============================================================================
class StatusNotifikasiModel {
  final int idStatusNotifikasi;
  final String namaStatus;

  StatusNotifikasiModel({
    required this.idStatusNotifikasi,
    required this.namaStatus,
  });

  factory StatusNotifikasiModel.fromJson(Map<String, dynamic> json) {
    return StatusNotifikasiModel(
      idStatusNotifikasi: json['id'] ?? 0,
      namaStatus: json['nama_status'] ?? 'unread',
    );
  }
}