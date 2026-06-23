import 'package:dio/dio.dart';

class ApiError {
  final String code;
  final String message;

  ApiError({required this.code, required this.message});

  factory ApiError.fromDioException(DioException e) {
    final data = e.response?.data;
    final Map<String, dynamic>? map = data is Map<String, dynamic>
        ? data
        : data is Map
        ? Map<String, dynamic>.from(data)
        : null;

    final error = map?['error'];
    final Map<String, dynamic>? errorMap = error is Map<String, dynamic>
        ? error
        : error is Map
        ? Map<String, dynamic>.from(error)
        : null;

    final statusCode = e.response?.statusCode;
    final code =
        errorMap?['code']?.toString() ??
        map?['code']?.toString() ??
        switch (e.type) {
          DioExceptionType.connectionTimeout => 'NET_001',
          DioExceptionType.sendTimeout => 'NET_001',
          DioExceptionType.receiveTimeout => 'NET_001',
          DioExceptionType.connectionError => 'NET_001',
          DioExceptionType.cancel => 'NET_002',
          DioExceptionType.badResponse => switch (statusCode) {
            400 => 'VAL_001',
            401 => 'AUTH_001',
            403 => 'AUTH_003',
            404 => 'SERVER_404',
            422 => 'VAL_001',
            _ => 'SERVER_001',
          },
          _ => 'SERVER_001',
        };

    final message =
        errorMap?['detail']?.toString() ??
        errorMap?['message']?.toString() ??
        map?['message']?.toString() ??
        switch (e.type) {
          DioExceptionType.connectionTimeout =>
            'Koneksi ke server terlalu lama. Cek BASE_URL atau jaringan internet.',
          DioExceptionType.sendTimeout =>
            'Request ke server terlalu lama. Cek BASE_URL atau jaringan internet.',
          DioExceptionType.receiveTimeout =>
            'Server tidak merespons. Cek BASE_URL atau coba lagi nanti.',
          DioExceptionType.connectionError =>
            'Tidak bisa terhubung ke server. Cek BASE_URL atau jaringan internet.',
          DioExceptionType.cancel => 'Permintaan dibatalkan.',
          _ => e.message ?? 'Terjadi kesalahan, coba lagi',
        };

    return ApiError(code: code, message: message);
  }

  // Pesan khusus per kode error auth
  String get userMessage {
    switch (code) {
      case 'AUTH_001':
        return 'Username atau password salah';
      case 'AUTH_002':
        return 'Anda tidak memiliki akses ke pesanan ini';
      case 'AUTH_003':
        return 'Sesi habis, silakan login kembali';
      case 'CONF_001':
        return 'Username sudah digunakan';
      case 'CONF_002':
        return 'Email sudah terdaftar';
      case 'VAL_002':
        return 'Konfirmasi password tidak cocok';
      case 'VAL_003':
        return 'Format email tidak valid';
      case 'NET_001':
        return 'Tidak bisa terhubung ke server. Cek BASE_URL atau koneksi internet.';
      case 'NET_002':
        return 'Permintaan dibatalkan.';
      default:
        return message;
    }
  }
}
