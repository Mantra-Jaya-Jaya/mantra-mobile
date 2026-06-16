import '../network/api_client.dart';

class KasirProfileService {
  final ApiClient _client;

  KasirProfileService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Mengambil profil kasir
  Future<Map<String, dynamic>> getProfil() async {
    final response = await _client.dio.get('/kasir/profil'); 
    return response.data['data'];
  }

  /// Memperbarui profil kasir
  Future<Map<String, dynamic>> updateProfil({
    String? namaLengkap,
    String? noTelp,
    String? email,
    String? alamat,
    String? fotoProfil,
  }) async {
    final body = <String, dynamic>{};
    if (namaLengkap != null) body['nama_lengkap'] = namaLengkap;
    if (noTelp != null) body['no_telp'] = noTelp;
    if (email != null) body['email'] = email;
    if (alamat != null) body['alamat'] = alamat;
    if (fotoProfil != null) body['foto_profil'] = fotoProfil;

    final response = await _client.dio.put('/kasir/profil', data: body);
    return response.data['data'];
  }

  /// Fungsi logout untuk kasir
  Future<void> logout() async {
    await _client.dio.post('/auth/logout');
  }
}
