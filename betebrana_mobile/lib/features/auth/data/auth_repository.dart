import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../domain/entities/auth_tokens.dart';
import '../domain/entities/auth_user.dart';

class AuthRepository {
  AuthRepository({
    Dio? dio,
    SecureStorageService? secureStorage,
  })  : _dio = dio ?? DioClient.instance.dio,
        _secureStorage = secureStorage ?? SecureStorageService();

  final Dio _dio;
  final SecureStorageService _secureStorage;

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    final data = response.data as Map<String, dynamic>;

    final token = (data['token'] ?? data['accessToken']) as String?;
    if (token == null || token.isEmpty) {
      throw Exception('Login response did not contain a token');
    }

    final refreshToken = data['refreshToken'] as String?;
    final userJson = (data['user'] as Map<String, dynamic>?) ?? {};
    final user = AuthUser.fromJson(userJson);

    final tokens = AuthTokens.fromRaw(
      accessToken: token,
      refreshToken: refreshToken,
    );

    await _persistSession(tokens: tokens, user: user);

    return user;
  }

  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
      },
    );

    final data = response.data as Map<String, dynamic>;

    final token = (data['token'] ?? data['accessToken']) as String?;
    if (token == null || token.isEmpty) {
      throw Exception('Register response did not contain a token');
    }

    final refreshToken = data['refreshToken'] as String?;
    final userJson = (data['user'] as Map<String, dynamic>?) ?? {};
    final user = AuthUser.fromJson(userJson);

    final tokens = AuthTokens.fromRaw(
      accessToken: token,
      refreshToken: refreshToken,
    );

    await _persistSession(tokens: tokens, user: user);

    return user;
  }

  Future<void> _persistSession({
    required AuthTokens tokens,
    required AuthUser user,
  }) async {
    await _secureStorage.saveAccessToken(tokens.accessToken);
    await _secureStorage.saveRefreshToken(tokens.refreshToken);
    await _secureStorage.saveTokenExpiry(tokens.expiry);
    await _secureStorage.saveUser(
      id: user.id,
      email: user.email,
      name: user.name,
    );
  }

  Future<void> logout() async {
    await _secureStorage.clearAll();
  }

  Future<bool> hasValidSession() async {
    final token = await _secureStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      return false;
    }
    final expiry = await _secureStorage.getTokenExpiry();
    if (expiry == null) {
      // best-effort fallback when exp is not encoded in JWT
      return true;
    }
    final isValid = DateTime.now().isBefore(expiry);
    if (!isValid) {
      // Clear expired session to match web's forceLogout behavior.
      await _secureStorage.clearAll();
    }
    return isValid;
  }

  Future<AuthUser?> getCurrentUser() async {
    final hasSession = await hasValidSession();
    if (!hasSession) return null;
    final userMap = await _secureStorage.getUser();
    final id = userMap['id'];
    final email = userMap['email'];
    final name = userMap['name'];
    if (id == null || email == null || name == null) return null;
    return AuthUser(id: id, email: email, name: name);
  }
}
