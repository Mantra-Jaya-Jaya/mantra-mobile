// ============================================================
// services/payment_service.dart
// ============================================================
//
// Endpoint yang dipakai:
//   POST /kasir/transaksi/produk          → CariProdukTransaksi (q=nama/barcode)
//   PATCH /kasir/transaksi/item/update    → UpdateQuantityItem
//   GET  /kasir/transaksi/checkout        → GetRingkasanCheckout
//   POST /kasir/transaksi/bayar/tunai     → BayarTunai
//   POST /kasir/transaksi/bayar/non-tunai → BayarNonTunai
// ============================================================

import '../models/payment_model.dart';
// Sesuaikan import ApiClient dengan path di project kamu
import '../network/api_client.dart';

import 'package:dio/dio.dart';

class PaymentService {
  final ApiClient _apiClient;

  PaymentService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<HasilCariProduk?> scanBarcodeProduk(String kodeBarcode) async {
    try {
      final response = await _apiClient.dio.get('/scan/$kodeBarcode');

      if (response.statusCode == 200 && response.data['data'] != null) {
        try {
          return HasilCariProduk.fromJson(response.data['data']);
        } catch (parseError) {
          throw Exception("Gagal membaca struktur JSON: $parseError");
        }
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null; // Memang gak ketemu
      }
      throw Exception("Rute API salah atau Server Mati");
    } catch (e) {
      throw Exception("Error tidak terduga: $e");
    }
  }

  // ----------------------------------------------------------
  // Cari produk berdasarkan nama atau scan barcode
  // Response berbeda: barcode → object tunggal, nama → list
  // ----------------------------------------------------------
  Future<List<HasilCariProduk>> cariProduk(String query) async {
    final response = await _apiClient.dio.post(
      '/kasir/transaksi/produk',
      queryParameters: {'q': query},
    );

    if (response.statusCode != 200) {
      throw Exception('Produk tidak ditemukan');
    }

    final data = response.data['data'];

    // Kalau hasil barcode → object tunggal (ada field id_spesifikasi_barang langsung)
    if (data is Map<String, dynamic> &&
        data.containsKey('id_spesifikasi_barang')) {
      // Ubah ke format list dengan satu varian agar UI konsisten
      return [
        HasilCariProduk(
          idBarang: data['id_barang'] ?? 0,
          namaBarang: data['nama_barang'] ?? '',
          gambarBarang: data['gambar_barang'],
          varian: [
            VarianProduk(
              idSpesifikasiBarang: data['id_spesifikasi_barang'] ?? 0,
              label: data['label'] ?? '',
              hargaBarang: data['harga_barang'] ?? 0,
              hargaDiskon: data['harga_diskon'] ?? 0,
              stok: data['stok'] ?? 0,
            ),
          ],
        ),
      ];
    }

    // Kalau hasil nama → list
    if (data is List) {
      return data.map((item) => HasilCariProduk.fromJson(item)).toList();
    }

    return [];
  }

  // ----------------------------------------------------------
  // Tambah atau update qty item di pesanan yang sedang berjalan
  // jumlah = 0 → hapus item
  // ----------------------------------------------------------
  Future<void> updateQuantityItem({
    required int idPesanan,
    required int idSpesifikasiBarang,
    required int jumlah,
  }) async {
    final response = await _apiClient.dio.patch(
      '/kasir/transaksi/item/update',
      data: {
        'id_pesanan': idPesanan,
        'id_spesifikasi_barang': idSpesifikasiBarang,
        'jumlah': jumlah,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal update quantity item');
    }
  }

  // ----------------------------------------------------------
  // Ambil ringkasan checkout (daftar item + total + pajak)
  // ----------------------------------------------------------
  Future<RingkasanCheckout> getRingkasanCheckout(int idPesanan) async {
    final response = await _apiClient.dio.get(
      '/kasir/transaksi/checkout',
      queryParameters: {'id_pesanan': idPesanan},
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil ringkasan checkout');
    }

    return RingkasanCheckout.fromJson(response.data);
  }

  // ----------------------------------------------------------
  // Bayar tunai → kembalikan kembalian + info invoice
  // ----------------------------------------------------------
  Future<HasilBayarTunai> bayarTunai({
    required int idPesanan,
    required int uangDiterima,
  }) async {
    final response = await _apiClient.dio.post(
      '/kasir/transaksi/bayar/tunai',
      data: {
        'id_pesanan': idPesanan,
        'bayar': uangDiterima,
      },
    );

    if (response.statusCode != 200) {
      final msg = response.data['message'] ?? 'Pembayaran tunai gagal';
      throw Exception(msg);
    }

    return HasilBayarTunai.fromJson(response.data);
  }

  // ----------------------------------------------------------
  // Bayar non-tunai → dapatkan Snap Token Midtrans
  // ----------------------------------------------------------
  Future<HasilBayarNonTunai> bayarNonTunai(int idPesanan) async {
    final response = await _apiClient.dio.post(
      '/kasir/transaksi/bayar/non-tunai',
      data: {'id_pesanan': idPesanan},
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal membuat transaksi Midtrans');
    }

    return HasilBayarNonTunai.fromJson(response.data);
  }
}