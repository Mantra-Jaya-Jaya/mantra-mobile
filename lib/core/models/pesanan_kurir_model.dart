class ItemBarangModel {
  final String namaBarang;
  final String varian;
  final int jumlah;

  ItemBarangModel({
    required this.namaBarang,
    required this.varian,
    required this.jumlah,
  });

  factory ItemBarangModel.fromJson(Map<String, dynamic> json) {
    return ItemBarangModel(
      namaBarang: json['nama_barang'] ?? '',
      varian: json['varian'] ?? '',
      jumlah: json['jumlah'] ?? 0,
    );
  }
}

class PesananRingkasModel {
  final String publicId;
  final int totalPembayaran;
  final String tanggalPesanan;
  final String statusPesanan;
  final String namaCustomer;
  final String noTelp;
  final String alamatLengkap;
  final String catatanLokasi;
  final List<ItemBarangModel> daftarBarang;

  PesananRingkasModel({
    required this.publicId,
    required this.totalPembayaran,
    required this.tanggalPesanan,
    required this.statusPesanan,
    required this.namaCustomer,
    required this.noTelp,
    required this.alamatLengkap,
    required this.catatanLokasi,
    required this.daftarBarang,
  });

  factory PesananRingkasModel.fromJson(Map<String, dynamic> json) {
    var listBarangJson = json['daftar_barang'] as List? ?? [];
    List<ItemBarangModel> listBarang = listBarangJson
        .map((i) => ItemBarangModel.fromJson(i))
        .toList();

    return PesananRingkasModel(
      publicId: json['public_id'] ?? '',
      totalPembayaran: json['total_pembayaran'] ?? 0,
      tanggalPesanan: json['tanggal_pesanan'] ?? '',
      statusPesanan: json['status_pesanan'] ?? '',
      namaCustomer: json['nama_customer'] ?? 'Customer',
      noTelp: json['no_telp'] ?? '-',
      alamatLengkap: json['alamat_lengkap'] ?? 'Alamat tidak ditemukan',
      catatanLokasi: json['catatan_lokasi'] ?? '-',
      daftarBarang: listBarang,
    );
  }
}
