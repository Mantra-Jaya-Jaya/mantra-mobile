// ignore_for_file: use_build_context_synchronously, deprecated_member_use
class MetodePembayaran {
  final int idMetodePembayaran;
  final String publicId;
  final String namaMetode;
  final String kodeMetode;
  final String penyedia;
  final String icon;
  final int urutan;
  final bool isActive;

  MetodePembayaran({
    required this.idMetodePembayaran,
    required this.publicId,
    required this.namaMetode,
    required this.kodeMetode,
    required this.penyedia,
    required this.icon,
    required this.urutan,
    required this.isActive,
  });

  factory MetodePembayaran.fromJson(Map<String, dynamic> json) {
    return MetodePembayaran(
      idMetodePembayaran: json['id_metode_pembayaran'] ?? 0,
      publicId: json['public_id'] ?? '',
      namaMetode: json['nama_metode'] ?? '',
      kodeMetode: json['kode_metode'] ?? '',
      penyedia: json['penyedia'] ?? '',
      icon: json['icon'] ?? '',
      urutan: json['urutan'] ?? 0,
      isActive: json['is_active'] ?? false,
    );
  }
}
