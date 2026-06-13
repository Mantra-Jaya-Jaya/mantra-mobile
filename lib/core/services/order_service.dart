import 'package:dio/dio.dart';
import '../models/order_model.dart'; // <-- Pastikan mengarah ke model yang baru
import '../network/api_client.dart'; // <-- Sesuaikan dengan lokasi ApiClient kamu

class OrderService {
  final Dio _dio = ApiClient().dio;

  // Pastikan tipe kembaliannya tertulis List<OrderModel> secara tegas
  Future<List<OrderModel>> getDaftarPesanan() async {
    try {
      final response = await _dio.get('/kasir/pesanan');
      
      if (response.data != null && response.data['data'] != null) {
        final List<dynamic> rawData = response.data['data'];
        // Mapping JSON menggunakan model baru
        return rawData.map((json) => OrderModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("❌ Error pada OrderService: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>?> getDetailPesanan(String publicId) async {
    try {
      // 1. Pastikan URL menggunakan prefix yang benar (/kasir/pesanan/...)
      final response = await _dio.get('/kasir/pesanan/$publicId'); 

      if (response.statusCode == 200) {
        // 2. Karena backend Anda mengirimkan response dalam bentuk:
        // {"status": "success", "data": { ...isi detail pesanan... }}
        // Maka kita kembalikan response.data agar UI bisa mengaksesnya
      
        print("Data diterima: ${response.data}"); 
        return response.data; 
      }
      return null;
    } catch (e) {
      print("Error di Service: $e");
      return null;
    }
  }

  // 3. Tambahkan fungsi checkout pesanan
  Future<Map<String, dynamic>> checkoutPesanan({
    required String idAlamat,
    required int idMetodePembayaran,
    int? idEkspedisi,
    int? idLayananEkspedisi,
    int ongkosKirim = 0,
    String catatan = "",
    bool simulasi = false,
  }) async {
    try {
      final response = await _dio.post(
        '/customer/pesanan/checkout',
        data: {
          'id_alamat': idAlamat,
          'id_metode_pembayaran': idMetodePembayaran,
          'id_ekspedisi': idEkspedisi,
          'id_layanan_ekspedisi': idLayananEkspedisi,
          'ongkos_kirim': ongkosKirim,
          'catatan': catatan,
          'simulasi': simulasi,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal membuat pesanan');
    }
  }
}