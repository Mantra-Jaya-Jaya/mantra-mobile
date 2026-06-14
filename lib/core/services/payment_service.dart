import 'package:dio/dio.dart';
import '../models/payment_model.dart';
import '../network/api_client.dart';

class PaymentService {
  final ApiClient _apiClient;

  // Constructor dengan dependency injection opsional
  PaymentService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  // 1. Cari produk berdasarkan nama atau scan barcode
  Future<List<HasilCariProduk>> cariProduk(String query) async {
    try {
      final response = await _apiClient.dio.get(
        '/kasir/transaksi/produk',
        queryParameters: {'q': query},
      );

      if (response.statusCode != 200) return [];

      final data = response.data['data'];

      // Handle hasil barcode (Object tunggal)
      if (data is Map<String, dynamic> && data.containsKey('id_spesifikasi_barang')) {
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

      // Handle hasil pencarian nama (List)
      if (data is List) {
        return data.map((item) => HasilCariProduk.fromJson(item)).toList();
      }
    } catch (e) {
      print("Error cari produk: $e");
    }
    return [];
  }

  // 2. Update quantity item di keranjang
  Future<int> updateQuantityItem({
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

    if (response.statusCode == 200 && response.data['data'] != null) {
      return response.data['data']['id_pesanan'] ?? idPesanan;
    }
    return idPesanan;
  }

  // 3. Ambil ringkasan checkout
  Future<RingkasanCheckout> getRingkasanCheckout(int idPesanan) async {
    final response = await _apiClient.dio.get(
      '/kasir/transaksi/checkout',
      queryParameters: {'id_pesanan': idPesanan},
    );
    return RingkasanCheckout.fromJson(response.data);
  }

  // 4. Bayar tunai (POST) - Sudah diperbaiki agar tipe data jelas
  Future<HasilBayarTunai> bayarTunai({
    required int idPesanan,
    required int uangDiterima,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/kasir/transaksi/bayar/tunai',
        data: {
          'id_pesanan': idPesanan,
          'bayar': uangDiterima,
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        return HasilBayarTunai.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Gagal bayar tunai');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan server');
    }
  }

  // 5. Bayar non-tunai (Midtrans)
  Future<HasilBayarNonTunai> bayarNonTunai({
    required int idPesanan,
    required String metode, // 🚀 BISA DIISI "qris", "bca", "bni", dll
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/kasir/transaksi/bayar/non-tunai',
        data: {
          'id_pesanan': idPesanan,
          'metode': metode, // 🚀 NGIRIM METODE KE GOLANG
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        return HasilBayarNonTunai.fromJson(response.data);
      } else {
        throw Exception(
          response.data['message'] ?? 'Gagal memproses pembayaran',
        );
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ??
            'Terjadi kesalahan saat memproses pembayaran',
      );
    }
  }

  Future<HasilCekStatus> cekStatusPembayaran(String orderId) async {
    try {
      final response = await _apiClient.dio.get(
        '/kasir/transaksi/cek-status/$orderId',
      );

      if (response.statusCode == 200) {
        return HasilCekStatus.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Gagal mengecek status');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Terjadi kesalahan saat mengecek status',
      );
    }
  }

  Future<Object?> getDetailPesanan(int idPesanan) async {}
}