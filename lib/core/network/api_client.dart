// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

typedef OnUnauthorized = void Function();

class ApiClient {
  static const String _fallbackBaseUrl =
      'http://172.16.160.135:8080/api/v1'; // local dev fallback
  static const String _configuredBaseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: '',
  );

  static bool get hasExplicitBaseUrl => _configuredBaseUrl.isNotEmpty;
  static String get baseUrl =>
      hasExplicitBaseUrl ? _configuredBaseUrl : _fallbackBaseUrl;

  static OnUnauthorized? onUnauthorized;

  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient({Dio? dio, FlutterSecureStorage? storage}) {
    return _instance;
  }

  final Dio _dio;
  final FlutterSecureStorage _storage;

  ApiClient._internal()
    : _dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      )),
      _storage = const FlutterSecureStorage() {
    _dio.interceptors.add(_AuthInterceptor(_storage, _dio));
  }

  Dio get dio => _dio;

  static void setOnUnauthorized(OnUnauthorized callback) {
    onUnauthorized = callback;
  }
}

class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  final Dio _dio;

  _AuthInterceptor(this._storage, this._dio);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers['X-Client-Type'] = 'flutter';

    final token = await _storage.read(key: 'access_token');
    if (token != null && token != 'null') {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      if (err.requestOptions.path.contains('/login')) {
        handler.next(err);
        return;
      }
      if (err.requestOptions.headers['X-Skip-Auth-Redirect'] == 'true') {
        handler.next(err);
        return;
      }
      final refreshed = await _tryRefresh();
      if (refreshed) {
        final token = await _storage.read(key: 'access_token');
        err.requestOptions.headers['Authorization'] = 'Bearer $token';
        final response = await _dio.fetch(err.requestOptions);
        handler.resolve(response);
        return;
      }
      await _storage.deleteAll();
      ApiClient.onUnauthorized?.call();
    }
    handler.next(err);
  }

  Future<bool> _tryRefresh() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) return false;

      final response = await Dio().post(
        '${ApiClient.baseUrl}/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final newToken = response.data['data']['access_token'];
      await _storage.write(key: 'access_token', value: newToken);
      return true;
    } catch (_) {
      return false;
    }
  }
}
