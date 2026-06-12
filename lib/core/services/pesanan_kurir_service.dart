import 'package:dio/dio.dart';
import '../models/pesanan_kurir_model.dart';
import '../models/pengantaran_model.dart';
import '../network/api_client.dart';

class PesananService {
  final Dio _dio = ApiClient().dio;

  // 🚀 1. Narik 1 Pesanan Paling Baru (Buat Highlight)
  Future<PesananRingkasModel?> getPesananTerbaru() async {
    try {
      final response = await _dio.get('/kurir/pesanan/new');
      if (response.statusCode == 200 && response.data['data'] != null) {
        return PesananRingkasModel.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      // Return null kalau 404 (Gak ada pesanan baru)
      return null;
    }
  }

  // 🚀 2. Narik Semua Pesanan Online (Buat List di bawahnya)
  Future<List<PesananRingkasModel>> getAllPesananOnline() async {
    try {
      final response = await _dio.get('/kurir/pesanan');
      if (response.statusCode == 200 && response.data['data'] != null) {
        final List<dynamic> rawData = response.data['data'];
        return rawData
            .map((json) => PesananRingkasModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 🚀 3. Mengambil tugas pesanan (Claim Task)
  Future<void> ambilPesanan(String publicId) async {
    await _dio.post('/kurir/pengantaran/$publicId/ambil');
  }

  // 🚀 4. Memperbarui status tugas pengantaran (dengan upload foto bukti jika Selesai)
  Future<void> updateStatus(String publicId, String status, {String? filePath}) async {
    if (filePath != null) {
      final formData = FormData.fromMap({
        'status': status,
        'foto': await MultipartFile.fromFile(filePath, filename: 'bukti_pengantaran.jpg'),
      });
      await _dio.post('/kurir/pengantaran/$publicId/status', data: formData);
    } else {
      await _dio.post('/kurir/pengantaran/$publicId/status', data: {'status': status});
    }
  }

  // 🚀 5. Ambil Detail Pesanan (sebelum diclaim / status masih Dikemas)
  Future<DetailPengantaranModel?> getDetailPesanan(String publicId) async {
    try {
      final response = await _dio.get('/kurir/pesanan/$publicId');
      if (response.statusCode == 200 && response.data['data'] != null) {
        final data = response.data['data'];
        
        final wrappedData = {
          'id_pengantaran': data['public_id'],
          'status_pengantaran': 'Menunggu Pickup',
          'penerima': {
            'nama': data['nama_customer'],
            'no_telp': data['no_telp'],
          },
          'tujuan': {
            'alamat_lengkap': data['alamat_lengkap'],
            'latitude': 0.0,
            'longitude': 0.0,
          },
          'total_pembayaran': data['total_pembayaran'],
          'daftar_barang': data['daftar_barang'],
        };
        
        return DetailPengantaranModel.fromJson(wrappedData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
