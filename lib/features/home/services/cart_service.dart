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
    required String idBarang, // Dari DetailBarangPage nilainya bertipe String
    required int quantity,
    int? idVarian,
  }) async {
    // Lakukan parsing dari String ke int agar cocok dengan tipe data di Golang
    final int parsedIdBarang = int.parse(idBarang);

    final Map<String, dynamic> requestBody = {
      'id_barang':
          parsedIdBarang, // Sekarang tipenya sudah int (misal: 12, bukan "12")
      'quantity': quantity,
    };

    // Jangan kirim key id_varian ke Golang jika nilainya null (menghindari error binding map)
    if (idVarian != null) {
      requestBody['id_varian'] = idVarian;
    }

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
