import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

  /// Fungsi logout untuk kasir
  Future<void> logout() async {
    final storage = const FlutterSecureStorage();
    final refreshToken = await storage.read(key: 'refresh_token');
    await _client.dio.post('/logout', data: {'refresh_token': refreshToken});
  }
}