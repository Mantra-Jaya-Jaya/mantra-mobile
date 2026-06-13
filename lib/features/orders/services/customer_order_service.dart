import 'package:frontend/core/network/api_client.dart';

class CustomerOrderService {
  final ApiClient _client;

  CustomerOrderService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Mengambil daftar pesanan customer berdasarkan status
  Future<List<Map<String, dynamic>>> getOrders({String? status}) async {
    final response = await _client.dio.get(
      '/customer/pesanan',
      queryParameters: status != null && status != 'Semua'
          ? {'status': status}
          : null,
    );
    final List data = response.data['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  /// Membuat pesanan baru (Checkout)
  Future<Map<String, dynamic>> checkout({
    required String idAlamat,
    required String metodePembayaran,
    required int grandTotal,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await _client.dio.post(
      '/customer/pesanan/checkout',
      data: {
        'id_alamat': idAlamat,
        'metode_pembayaran': metodePembayaran,
        'grand_total': grandTotal,
        'items': items,
      },
    );
    return response.data['data'];
  }

  /// Membatalkan pesanan (Hanya jika status Belum Dibayar/Diproses)
  Future<void> cancelOrder(String publicId) async {
    await _client.dio.patch('/customer/pesanan/$publicId/batal');
  }
}
