class PengantaranModel {
  final String publicId;
  final String status;
  final String ekspedisi;
  final String? waktuPickup;
  final String? waktuSampai;
  final String namaCustomer;
  final String noTelp;
  final String alamatLengkap;
  final int totalPendapatan;

  PengantaranModel({
    required this.publicId,
    required this.status,
    required this.ekspedisi,
    this.waktuPickup,
    this.waktuSampai,
    required this.namaCustomer,
    required this.noTelp,
    required this.alamatLengkap,
    required this.totalPendapatan,
  });

  factory PengantaranModel.fromJson(Map<String, dynamic> json) {
    return PengantaranModel(
      // 🚀 SEKARANG DATANYA DIAMBIL LANGSUNG KARENA JSON-NYA UDAH FLAT (DTO)
      publicId: json['public_id'] ?? '',
      status: json['status'] ?? 'MENUNGGU',
      ekspedisi: json['ekspedisi'] ?? 'Internal / Belum Ada',
      waktuPickup: json['waktu_pickup'],
      waktuSampai: json['waktu_sampai'],
      namaCustomer: json['nama_customer'] ?? 'Customer',
      noTelp: json['no_telp'] ?? '-',
      alamatLengkap: json['alamat_lengkap'] ?? 'Alamat tidak ditemukan',
      totalPendapatan: json['total_pendapatan'] ?? 0,
    );
  }
}
