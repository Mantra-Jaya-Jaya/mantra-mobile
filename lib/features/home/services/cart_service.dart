// features/home/services/cart_service.dart

import 'package:frontend/core/network/api_client.dart';

class CartService {
  final ApiClient _client;

  // Menggunakan konstruktor standar agar sinkron dengan service lainnya
  CartService({ApiClient? client}) : _client = client ?? ApiClient();

  /// 1. AMBIL DATA KERANJANG (GET)
  /// Endpoint: GET /customer/keranjang
  Future<List<Map<String, dynamic>>> getCartItems() async {
    final response = await _client.dio.get('/customer/keranjang');
    // Sesuaikan dengan struktur response JSON dari Golang kamu (misal response.data['data'])
    final List data = response.data['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  /// 2. TAMBAH KE KERANJANG (POST)
  /// Endpoint: POST /customer/keranjang
  Future<void> addToCart({
    required String idBarang, // Bisa berisi id_barang atau public_id
    required int quantity,
    int? idVarian, // Ini yang seharusnya dikirim sebagai id_spesifikasi_barang
  }) async {
    final Map<String, dynamic> requestBody = {
      'id_spesifikasi_barang':
          idVarian, // Backend menunggu id_spesifikasi_barang
      'quantity': quantity,
    };

    // Jika idVarian null (misal dari detail_barang), kita harus berhati-hati
    // karena backend mewajibkan id_spesifikasi_barang (binding:"required").
    // Untuk saat ini, kita kirim apa adanya sesuai parameter.

    await _client.dio.post('/customer/keranjang', data: requestBody);
  }

  /// 3. UPDATE KUANTITAS (PATCH)
  /// Endpoint: PATCH /customer/keranjang/:id_keranjang
  Future<void> updateCartQuantity({
    required String idKeranjang,
    required int newQuantity,
  }) async {
    await _client.dio.patch(
      '/customer/keranjang/$idKeranjang',
      data: {'quantity': newQuantity},
    );
  }

  /// 4. HAPUS BARANG DARI KERANJANG (DELETE)
  /// Endpoint: DELETE /customer/keranjang/:id_keranjang
  Future<void> deleteCartItem(String idKeranjang) async {
    await _client.dio.delete('/customer/keranjang/$idKeranjang');
  }
}
