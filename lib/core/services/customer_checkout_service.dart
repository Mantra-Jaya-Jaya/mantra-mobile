import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../models/metode_pembayaran_model.dart';

class CustomerCheckoutService {
  final Dio _dio = ApiClient().dio;

  Future<List<MetodePembayaran>> getMetodePembayaran() async {
    final response = await _dio.get('/customer/metode-pembayaran');
    final data = response.data['data'] as List;
    return data.map((json) => MetodePembayaran.fromJson(json)).toList();
  }

  Future<Map<String, dynamic>> cekOngkir({
    required String idAlamat,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await _dio.post('/customer/ongkir/cek', data: {
      'id_alamat': idAlamat,
      'items': items,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> checkout({
    required String idAlamat,
    required int idEkspedisi,
    required int idLayananEkspedisi,
    required int ongkosKirim,
    required String catatan,
    required int idMetodePembayaran,
  }) async {
    final response = await _dio.post('/customer/pesanan/checkout', data: {
      'id_alamat': idAlamat,
      'id_ekspedisi': idEkspedisi,
      'id_layanan_ekspedisi': idLayananEkspedisi,
      'ongkos_kirim': ongkosKirim,
      'catatan': catatan,
      'id_metode_pembayaran': idMetodePembayaran,
    });
    return response.data;
  }
}
