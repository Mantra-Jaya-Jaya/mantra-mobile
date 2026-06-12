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

// ============================================================
// models/detail_pengantaran_model.dart
// ============================================================

class Penerima {
  final String nama;
  final String noTelp;

  Penerima({required this.nama, required this.noTelp});

  factory Penerima.fromJson(Map<String, dynamic> json) {
    return Penerima(
      nama: json['nama'] ?? 'Customer',
      noTelp: json['no_telp'] ?? '-',
    );
  }
}

class Tujuan {
  final String alamatLengkap;
  final double latitude;
  final double longitude;

  Tujuan({
    required this.alamatLengkap,
    required this.latitude,
    required this.longitude,
  });

  factory Tujuan.fromJson(Map<String, dynamic> json) {
    return Tujuan(
      alamatLengkap: json['alamat_lengkap'] ?? 'Alamat tidak tersedia',
      // 🚀 PENTING: Pakai .toDouble() biar gak crash kalau dari backend kebacanya integer (misal: 110.0 jadi 110)
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
    );
  }
}

class DetailPengantaranModel {
  final String idPengantaran;
  final String statusPengantaran;
  final String? waktuPickup;
  final String? waktuSampai;
  final Penerima penerima;
  final Tujuan tujuan;
  final String? fotoBukti;

  DetailPengantaranModel({
    required this.idPengantaran,
    required this.statusPengantaran,
    this.waktuPickup,
    this.waktuSampai,
    required this.penerima,
    required this.tujuan,
    this.fotoBukti,
  });

  factory DetailPengantaranModel.fromJson(Map<String, dynamic> json) {
    return DetailPengantaranModel(
      idPengantaran: json['id_pengantaran'] ?? '',
      statusPengantaran: json['status_pengantaran'] ?? 'Menunggu',
      waktuPickup: json['waktu_pickup'],
      waktuSampai: json['waktu_sampai'],
      // Manggil class anaknya buat mecah JSON yang di dalem
      penerima: Penerima.fromJson(json['penerima'] ?? {}),
      tujuan: Tujuan.fromJson(json['tujuan'] ?? {}),
      fotoBukti: json['foto_bukti'],
    );
  }
}

class SelesaikanPengantaranModel {
  final String urlBukti;
  final DateTime waktuSampai;

  SelesaikanPengantaranModel({
    required this.urlBukti,
    required this.waktuSampai,
  });

  factory SelesaikanPengantaranModel.fromJson(Map<String, dynamic> json) {
    return SelesaikanPengantaranModel(
      urlBukti: json['url_bukti'] ?? '',
      // Parsing string waktu dari Golang jadi objek DateTime di Dart
      waktuSampai: DateTime.parse(json['waktu_sampai']),
    );
  }
}
