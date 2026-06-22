class BarangModelCore {
  final String idBarang;
  final String namaBarang;
  final int hargaTerendah;
  final int hargaTertinggi;
  final int hargaDiskon;
  final bool punyaDiskon;
  final String gambarBarang;
  final String deskripsi;
  final String stok;

  BarangModelCore({
    required this.idBarang,
    required this.namaBarang,
    required this.hargaTerendah,
    required this.hargaTertinggi,
    required this.hargaDiskon,
    required this.punyaDiskon,
    required this.gambarBarang,
    required this.deskripsi,
    required this.stok,
  });

  factory BarangModelCore.fromJson(Map<String, dynamic> json) {
    return BarangModelCore(
      idBarang: (json['public_id'] ?? json['id_barang'] ?? '').toString(),
      namaBarang: json['nama_barang'] ?? '',
      hargaTerendah: json['harga_terendah'] ?? 0,
      hargaTertinggi: json['harga_tertinggi'] ?? 0,
      hargaDiskon: json['harga_diskon'] ?? 0,
      punyaDiskon: json['punya_diskon'] ?? (json['diskon'] != null),
      gambarBarang: json['gambar_barang'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      stok: (json['stok'] ?? '').toString(),
    );
  }
}
