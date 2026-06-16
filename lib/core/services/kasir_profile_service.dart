import 'dart:io';
import 'package:dio/dio.dart';
import '../network/api_client.dart';

class KasirProfileService {
  final ApiClient _client;

  KasirProfileService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Mengambil profil kasir
  Future<Map<String, dynamic>> getProfil() async {
    // Sesuaikan dengan endpoint asli backend untuk kasir
    final response = await _client.dio.get('/kasir/profil'); 
    return response.data['data'];
  }

  /// Mengunggah foto profil
  Future<String> uploadFoto(File file) async {
    String fileName = file.path.split('/').last;
    FormData formData = FormData.fromMap({
      "foto": await MultipartFile.fromFile(file.path, filename: fileName),
    });

    final response = await _client.dio.post(
      '/admin/karyawan/upload',
      data: formData,
    );

    return response.data['url'];
  }

  /// Memperbarui profil kasir (foto profil)
  Future<void> updateProfil({required String fotoProfil}) async {
    await _client.dio.put(
      '/admin/profil',
      data: {
        'foto_profil': fotoProfil,
      },
    );
  }

  /// Fungsi logout untuk kasir (jika endpointnya terpisah)
  Future<void> logout() async {
    await _client.dio.post('/auth/logout'); // Sesuaikan endpoint logoutmu
  }
}