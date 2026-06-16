import 'package:frontend/core/network/api_client.dart';

class CustomerOrderService {
  final ApiClient _client;

  CustomerOrderService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Mengambil daftar pesanan customer berdasarkan status
  Future<List<Map<String, dynamic>>> getOrders({String? status}) async {
    final statusMap = {
      'Belum Dibayar': 'menunggu_pembayaran',
      'Dikemas': 'dikemas',
      'Dikirim': 'dikirim',
      'Selesai': 'selesai',
      'Dibatalkan': 'dibatalkan',
    };
    final backendStatus = statusMap[status];

    final response = await _client.dio.get(
      '/customer/pesanan',
      queryParameters: backendStatus != null
          ? {'status': backendStatus}
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

  /// Mengambil detail satu pesanan
  Future<Map<String, dynamic>> getOrderDetail(String publicId) async {
    final response = await _client.dio.get('/customer/pesanan/$publicId');
    return response.data['data'];
  }

  /// Membatalkan pesanan (Hanya jika status Belum Dibayar)
  Future<void> cancelOrder(String publicId) async {
    await _client.dio.patch('/customer/pesanan/$publicId/batal');
  }

  /// Mengambil daftar metode pembayaran yang aktif
  Future<List<Map<String, dynamic>>> GetMetodePembayaran() async {
    final response = await _client.dio.get('/customer/metode-pembayaran');
    final List data = response.data['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  /// Info lacak pengiriman
  Future<Map<String, dynamic>> getTrackingInfo(String publicId) async {
    final response = await _client.dio.get('/customer/pesanan/$publicId/lacak');
    return response.data['data'];
  }
}
