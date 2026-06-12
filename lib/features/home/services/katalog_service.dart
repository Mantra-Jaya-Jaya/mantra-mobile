import 'package:frontend/core/network/api_client.dart';

// Model Promo/Diskon
class PromoModel {
  final int idDiskon;
  final String namaDiskon;
  final String bannerUrl;
  final String tglSelesai;

  PromoModel({
    required this.idDiskon,
    required this.namaDiskon,
    required this.bannerUrl,
    required this.tglSelesai,
  });

  factory PromoModel.fromJson(Map<String, dynamic> json) {
    return PromoModel(
      idDiskon: json['id_diskon'] ?? 0,
      namaDiskon: json['nama_diskon'] ?? '',
      bannerUrl: json['banner_url'] ?? '',
      tglSelesai: json['tgl_selesai'] ?? '',
    );
  }
}

// Model Kategori
class KategoriModel {
  final int idKategori;
  final String namaKategori;
  final String iconKategori;

  KategoriModel({
    required this.idKategori,
    required this.namaKategori,
    required this.iconKategori,
  });

  factory KategoriModel.fromJson(Map<String, dynamic> json) {
    return KategoriModel(
      idKategori: json['id_kategori'] ?? 0,
      namaKategori: json['nama_kategori'] ?? '',
      iconKategori: json['icon_kategori'] ?? '',
    );
  }
}

// Model Varian/Spesifikasi
class VarianModel {
  final int idVarian;
  final String namaSpesifikasi;
  final String namaDetail;
  final int hargaBarang;
  final int hargaDiskon;
  final int stok;

  VarianModel({
    required this.idVarian,
    required this.namaSpesifikasi,
    required this.namaDetail,
    required this.hargaBarang,
    required this.hargaDiskon,
    required this.stok,
  });

  factory VarianModel.fromJson(Map<String, dynamic> json) {
    return VarianModel(
      idVarian: json['id_spesifikasi_barang'] ?? 0,
      namaSpesifikasi: json['nama_spesifikasi'] ?? '',
      namaDetail: json['nama_detail'] ?? '',
      hargaBarang: json['harga_barang'] ?? 0,
      hargaDiskon: json['harga_diskon'] ?? 0,
      stok: json['stok'] ?? 0,
    );
  }
}

// Model Barang (ringkasan untuk list)
class BarangModel {
  final String idBarang;
  final String namaBarang;
  final int hargaTerendah;
  final int hargaTertinggi;
  final int hargaDiskon;
  final bool punyaDiskon;
  final String gambarBarang;
  final String deskripsi;
  final String stok;
  final List<VarianModel> varian;

  BarangModel({
    required this.idBarang,
    required this.namaBarang,
    required this.hargaTerendah,
    required this.hargaTertinggi,
    required this.hargaDiskon,
    required this.punyaDiskon,
    required this.gambarBarang,
    required this.deskripsi,
    required this.stok,
    this.varian = const [],
  });

  factory BarangModel.fromJson(Map<String, dynamic> json) {
    // 1. Ambil list varian jika ada (biasanya di response detail)
    final List? variansJson = json['varian'] as List?;
    final List<VarianModel> varianList = variansJson != null
        ? variansJson.map((v) => VarianModel.fromJson(v)).toList()
        : [];

    // 2. Hitung harga terendah dari varian jika field harga_terendah tidak ada
    int hTerendah = json['harga_terendah'] ?? 0;
    if (hTerendah == 0 && varianList.isNotEmpty) {
      hTerendah = varianList
          .map((v) => v.hargaBarang)
          .reduce((a, b) => a < b ? a : b);
    }

    // 3. Hitung total stok dari varian jika field stok tidak ada
    String totalStok = (json['stok'] ?? '').toString();
    if ((totalStok == '' || totalStok == '0') && varianList.isNotEmpty) {
      int sumStok = varianList.map((v) => v.stok).reduce((a, b) => a + b);
      totalStok = sumStok.toString();
    }

    return BarangModel(
      // 🔥 Prioritaskan public_id (UUID) agar API detail tidak error syntax
      idBarang: (json['public_id'] ?? json['id_barang'] ?? '').toString(),
      namaBarang: json['nama_barang'] ?? '',
      hargaTerendah: hTerendah,
      hargaTertinggi: json['harga_tertinggi'] ?? 0,
      hargaDiskon: json['harga_diskon'] ?? 0,
      punyaDiskon: json['punya_diskon'] ?? (json['diskon'] != null),
      gambarBarang: json['gambar_barang'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      stok: totalStok,
      varian: varianList,
    );
  }
}

class KatalogService {
  final ApiClient _client;

  KatalogService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Ambil promo yang sedang aktif.
  /// Endpoint: GET /customer/promo
  Future<List<PromoModel>> getPromoAktif() async {
    final response = await _client.dio.get('/customer/promo');
    final List data = response.data['data'] ?? [];
    return data.map((e) => PromoModel.fromJson(e)).toList();
  }

  /// Ambil daftar kategori barang.
  /// Endpoint: GET /customer/kategori
  Future<List<KategoriModel>> getKategori({int? limit}) async {
    final response = await _client.dio.get(
      '/customer/kategori',
      queryParameters: limit != null ? {'limit': limit} : null,
    );
    final List data = response.data['data'] ?? [];
    return data.map((e) => KategoriModel.fromJson(e)).toList();
  }

  /// Ambil daftar barang dengan pagination.
  /// Endpoint: GET /customer/barang?page=&limit=
  Future<List<BarangModel>> getDaftarBarang({
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _client.dio.get(
      '/customer/barang',
      queryParameters: {'page': page, 'limit': limit},
    );
    final List data = response.data['data'] ?? [];
    return data.map((e) => BarangModel.fromJson(e)).toList();
  }

  /// Ambil detail lengkap satu barang berdasarkan ID.
  /// Endpoint: GET /customer/barang/detail/:public_id
  Future<BarangModel> getDetailBarang(String idBarang) async {
    final response = await _client.dio.get('/customer/barang/detail/$idBarang');

    // Karena response detail biasanya mengembalikan satu objek tunggal (bukan List)
    final Map<String, dynamic> data = response.data['data'];

    // Langsung konversi Map JSON menjadi satu objek BarangModel
    return BarangModel.fromJson(data);
  }
}
