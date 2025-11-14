import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';

/// Interceptor that attaches JWT and handles unauthorized responses.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._secureStorage);

  final SecureStorageService _secureStorage;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) {
      // Clear all persisted auth data to force re-login on next app start.
      await _secureStorage.clearAll();
    }
    handler.next(err);
  }
}

/// Centralized Dio client with JWT header injection and auth handling.
class DioClient {
  DioClient._internal()
      : _secureStorage = SecureStorageService(),
        _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.baseApiUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 30),
          ),
        ) {
    _dio.interceptors.add(AuthInterceptor(_secureStorage));
  }

  static final DioClient _instance = DioClient._internal();
  static DioClient get instance => _instance;

  final Dio _dio;
  final SecureStorageService _secureStorage;

  Dio get dio => _dio;
}

