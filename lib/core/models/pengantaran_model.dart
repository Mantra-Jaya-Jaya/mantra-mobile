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

class ItemPengantaran {
  final String namaBarang;
  final String variasi;
  final int jumlahBeli;
  final int hargaSatuan;
  final int subtotalItem;

  ItemPengantaran({
    required this.namaBarang,
    required this.variasi,
    required this.jumlahBeli,
    required this.hargaSatuan,
    required this.subtotalItem,
  });

  factory ItemPengantaran.fromJson(Map<String, dynamic> json) {
    return ItemPengantaran(
      namaBarang: json['nama_barang'] ?? '',
      variasi: json['variasi'] ?? 'Default',
      jumlahBeli: json['jumlah_beli'] ?? 0,
      hargaSatuan: json['harga_satuan'] ?? 0,
      subtotalItem: json['subtotal_item'] ?? 0,
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
  final int totalPembayaran;
  final List<ItemPengantaran> daftarBarang;

  DetailPengantaranModel({
    required this.idPengantaran,
    required this.statusPengantaran,
    this.waktuPickup,
    this.waktuSampai,
    required this.penerima,
    required this.tujuan,
    required this.totalPembayaran,
    required this.daftarBarang,
  });

  factory DetailPengantaranModel.fromJson(Map<String, dynamic> json) {
    var list = json['daftar_barang'] as List?;
    List<ItemPengantaran> itemsList = list != null
        ? list.map((i) => ItemPengantaran.fromJson(i)).toList()
        : [];

    return DetailPengantaranModel(
      idPengantaran: json['id_pengantaran'] ?? '',
      statusPengantaran: json['status_pengantaran'] ?? 'Menunggu',
      waktuPickup: json['waktu_pickup'],
      waktuSampai: json['waktu_sampai'],
      penerima: Penerima.fromJson(json['penerima'] ?? {}),
      tujuan: Tujuan.fromJson(json['tujuan'] ?? {}),
      totalPembayaran: json['total_pembayaran'] ?? 0,
      daftarBarang: itemsList,
    );
  }
}
