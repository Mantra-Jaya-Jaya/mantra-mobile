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
}