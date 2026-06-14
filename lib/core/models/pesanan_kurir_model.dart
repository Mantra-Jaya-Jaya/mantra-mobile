class ItemBarangModel {
  final String namaBarang;
  final String gambarBarang;
  final String varian;
  final int jumlahBeli;
  final int hargaSatuan;
  final int subtotalItem;

  ItemBarangModel({
    required this.namaBarang,
    required this.gambarBarang,
    required this.varian,
    required this.jumlahBeli,
    required this.hargaSatuan,
    required this.subtotalItem,
  });

  factory ItemBarangModel.fromJson(Map<String, dynamic> json) {
    return ItemBarangModel(
      namaBarang: json['nama_barang'] ?? 'Barang Tidak Diketahui',
      gambarBarang: json['gambar_barang'] ?? '',
      varian: json['varian'] ?? 'Default',
      jumlahBeli: json['jumlah_beli'] ?? 0,
      hargaSatuan: json['harga_satuan'] ?? 0,
      subtotalItem: json['subtotal_item'] ?? 0,
    );
  }
}

import '../constants/status_constants.dart';

class PesananRingkasModel {
  final String publicId;
  final int totalPembayaran;
  final String tanggalPesanan;
  final int idStatusPesanan;
  final String namaCustomer;
  final String noTelp;
  final String alamatLengkap;
  final String catatanLokasi;
  final List<ItemBarangModel> daftarBarang;

  PesananRingkasModel({
    required this.publicId,
    required this.totalPembayaran,
    required this.tanggalPesanan,
    required this.idStatusPesanan,
    required this.namaCustomer,
    required this.noTelp,
    required this.alamatLengkap,
    required this.catatanLokasi,
    required this.daftarBarang,
  });

  // Helper methods menggunakan StatusConstants
  String get statusPesanan => StatusConstants.getName(idStatusPesanan);
  String get statusDisplayName => StatusConstants.getDisplayName(idStatusPesanan);
  String get statusColor => StatusConstants.getColor(idStatusPesanan);
  bool get isOnlineStatus => StatusConstants.isOnlineStatus(idStatusPesanan);
  bool get isCompleted => StatusConstants.isCompleted(idStatusPesanan);
  bool get isCancelled => StatusConstants.isCancelled(idStatusPesanan);

  factory PesananRingkasModel.fromJson(Map<String, dynamic> json) {
    var listBarangJson = json['daftar_barang'] as List? ?? [];
    List<ItemBarangModel> listBarang = listBarangJson
        .map((i) => ItemBarangModel.fromJson(i))
        .toList();

    return PesananRingkasModel(
      publicId: json['public_id'] ?? '',
      totalPembayaran: json['total_pembayaran'] ?? 0,
      tanggalPesanan: json['tanggal_pesanan'] ?? '',
      idStatusPesanan: (json['id_status_pesanan'] ?? json['status_id'] ?? 1).toInt(),
      namaCustomer: json['nama_customer'] ?? 'Customer',
      noTelp: json['no_telp'] ?? '-',
      alamatLengkap: json['alamat_lengkap'] ?? 'Alamat tidak ditemukan',
      catatanLokasi: json['catatan_lokasi'] ?? '-',
      daftarBarang: listBarang,
    );
  }
}

class DetailPesananModel {
  final String publicId;
  final String namaCustomer;
  final String alamatLengkap;
  final int totalPembayaran;
  final DateTime tanggalPesanan;
  final int idStatusPesanan;
  final MetodeBayarModel metodeBayar;
  final List<ItemBarangModel> daftarBarang;

  DetailPesananModel({
    required this.publicId,
    required this.totalPembayaran,
    required this.namaCustomer,
    required this.alamatLengkap,
    required this.tanggalPesanan,
    required this.idStatusPesanan,
    required this.metodeBayar,
    required this.daftarBarang,
  });

  // Helper methods menggunakan StatusConstants
  String get statusPesanan => StatusConstants.getName(idStatusPesanan);
  String get statusDisplayName => StatusConstants.getDisplayName(idStatusPesanan);
  String get statusColor => StatusConstants.getColor(idStatusPesanan);
  bool get isOnlineStatus => StatusConstants.isOnlineStatus(idStatusPesanan);
  bool get isCompleted => StatusConstants.isCompleted(idStatusPesanan);
  bool get isCancelled => StatusConstants.isCancelled(idStatusPesanan);

  factory DetailPesananModel.fromJson(Map<String, dynamic> json) {
    return DetailPesananModel(
      publicId: json['public_id'] ?? '',
      namaCustomer: json['nama_customer'] ?? 'Customer',
      alamatLengkap: json['alamat_lengkap'] ?? 'Alamat Kosong',
      totalPembayaran: json['total_pembayaran'] ?? 0,
      tanggalPesanan: json['tanggal_pesanan'] != null
          ? DateTime.parse(json['tanggal_pesanan'])
          : DateTime.now(),
      idStatusPesanan: (json['id_status_pesanan'] ?? json['status_id'] ?? 1).toInt(),
      metodeBayar: MetodeBayarModel.fromJson(json['metode_bayar'] ?? {}),
      daftarBarang: json['daftar_barang'] != null
          ? (json['daftar_barang'] as List)
                .map((i) => ItemBarangModel.fromJson(i))
                .toList()
          : [],
    );
  }
}

class MetodeBayarModel {
  final String idMetodeBayar;
  final String namaMetode;

  MetodeBayarModel({required this.idMetodeBayar, required this.namaMetode});

  factory MetodeBayarModel.fromJson(Map<String, dynamic> json) {
    return MetodeBayarModel(
      idMetodeBayar: json['id_metode_bayar'] ?? '-',
      namaMetode: json['nama_metode'] ?? 'Belum ada pembayaran',
    );
  }
}
