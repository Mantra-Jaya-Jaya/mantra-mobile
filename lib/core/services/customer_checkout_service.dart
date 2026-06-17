import 'package:dio/dio.dart';
import '../network/api_client.dart';

class CustomerCheckoutService {
  final Dio _dio = ApiClient().dio;

  Future<Map<String, dynamic>> getMetodePembayaran() async {
    final response = await _dio.get('/customer/metode-pembayaran');
    return response.data;
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

  Future<Map<String, dynamic>> cekRadius({
    required String idAlamat,
  }) async {
    final response = await _dio.post('/customer/ongkir/cek-radius', data: {
      'id_alamat': idAlamat,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> checkout({
    required String idAlamat,
    int? idEkspedisi,
    int? idLayananEkspedisi,
    int ongkosKirim = 0,
    String catatan = "",
    required String idMetodePembayaran,
    int? idTipeKurir,
  }) async {
    final response = await _dio.post('/customer/pesanan/checkout', data: {
      'id_alamat': idAlamat,
      'metode_pembayaran': idMetodePembayaran,
      'id_ekspedisi': idEkspedisi,
      'id_layanan_ekspedisi': idLayananEkspedisi,
      'ongkos_kirim': ongkosKirim,
      'catatan': catatan,
      'id_tipe_kurir': idTipeKurir,
    });
    return response.data;
  }
}
