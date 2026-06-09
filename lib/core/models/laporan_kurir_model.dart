class LaporanKurirModel {
  final int pesananSelesai;
  final int pesananProses;
  final int pesananTersedia;

  LaporanKurirModel({
    required this.pesananSelesai,
    required this.pesananProses,
    required this.pesananTersedia,
  });

  factory LaporanKurirModel.fromJson(Map<String, dynamic> json) {
    return LaporanKurirModel(
      // Kalau nilainya null dari server, kita kasih default 0 biar aman
      pesananSelesai: json['pesanan_selesai'] ?? 0,
      pesananProses: json['pesanan_proses'] ?? 0,
      pesananTersedia: json['pesanan_tersedia'] ?? 0,
    );
  }
}
