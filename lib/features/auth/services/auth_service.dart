// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/models/user_model.dart';

class AuthService {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthService(this._dio, this._storage);

  // LOGIN
  // Endpoint: POST /api/v1/login
  Future<UserModel> login(String username, String password) async {
    final response = await _dio.post(
      '/login',
      data: {'username': username, 'password': password},
    );

    final rawResponse = response.data;
    final Map<String, dynamic> responseMap = rawResponse is Map<String, dynamic>
        ? rawResponse
        : rawResponse is Map
        ? Map<String, dynamic>.from(rawResponse)
        : throw const FormatException('Format respons login tidak valid');

    final dynamic payloadCandidate = responseMap['data'] ?? responseMap;
    final Map<String, dynamic> data = payloadCandidate is Map<String, dynamic>
        ? payloadCandidate
        : payloadCandidate is Map
        ? Map<String, dynamic>.from(payloadCandidate)
        : throw const FormatException('Data login tidak ditemukan');

    final accessToken = data['access_token']?.toString();
    final refreshToken = data['refresh_token']?.toString();
    final userDataRaw = data['user'];
    final Map<String, dynamic> userData = userDataRaw is Map<String, dynamic>
        ? userDataRaw
        : userDataRaw is Map
        ? Map<String, dynamic>.from(userDataRaw)
        : throw const FormatException('Data user tidak ditemukan');

    if (accessToken == null || accessToken.isEmpty) {
      throw const FormatException('Access token tidak ditemukan');
    }
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const FormatException('Refresh token tidak ditemukan');
    }

    // Simpan token ke secure storage
    // access_token = JWT, refresh_token = random bytes hex
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
    await _storage.write(
      key: 'role',
      value: (userData['role'] ?? '').toString(),
    );

    return UserModel.fromJson(userData);
  }

  // REGISTER
  // Endpoint: POST /api/v1/register
  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String konfirmasiPassword,
    required String namaLengkap,
    required String noTelp,
    required String alamatLengkap,
    required double latitude,
    required double longitude,
    String? catatanLokasi,
  }) async {
    await _dio.post(
      '/register',
      data: {
        'username': username,
        'email': email,
        'password': password,
        'konfirmasi_password': konfirmasiPassword,
        'nama_lengkap': namaLengkap,
        'no_telp': noTelp,
        'alamat_lengkap': alamatLengkap,
        'latitude': latitude,
        'longitude': longitude,
        'catatan_lokasi': catatanLokasi ?? '',
      },
    );
    // Tidak auto-login setelah register — arahkan ke halaman login
  }

  // LOGOUT
  // Endpoint: POST /api/v1/logout
  Future<void> logout() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    try {
      await _dio.post('/logout', data: {'refresh_token': refreshToken});
    } catch (_) {
      // Tetap hapus token lokal meskipun request gagal
    } finally {
      await _storage.deleteAll();
    }
  }

  // CEK SESI — dipakai di splash screen
  Future<bool> isLoggedIn() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    return refreshToken != null && refreshToken.isNotEmpty;
  }

  Future<void> changePassword({
    required String passwordLama,
    required String passwordBaru,
    required String konfirmasiPassword,
  }) async {
    await _dio.put('/change-password', data: {
      'password_lama': passwordLama,
      'password_baru': passwordBaru,
      'konfirmasi_password': konfirmasiPassword,
    });
  }

  // AMBIL ROLE DARI STORAGE — untuk routing setelah login
  Future<String?> getSavedRole() async {
    return await _storage.read(key: 'role');
  }
}
