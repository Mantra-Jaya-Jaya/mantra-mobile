// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/models/barang_model.dart';

class DiskonService {
  final ApiClient _client;

  DiskonService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Ambil daftar barang berdasarkan ID diskon.
  /// Endpoint: GET /customer/promo/:public_id/barang
  Future<List<BarangModelCore>> getBarangByDiskon(String publicIdDiskon, {int page = 1, int limit = 50}) async {
    final response = await _client.dio.get(
      '/customer/promo/$publicIdDiskon/barang',
      queryParameters: {'page': page, 'limit': limit},
    );
    final List data = response.data['data'] ?? [];
    return data.map((e) => BarangModelCore.fromJson(e)).toList();
  }
}
