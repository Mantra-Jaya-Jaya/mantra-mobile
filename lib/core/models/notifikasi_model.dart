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
      idNotifikasi: json['id_notifikasi'],
      judul: json['judul'],
      pesan: json['pesan'],
      status: json['status'],
    );
  }
}