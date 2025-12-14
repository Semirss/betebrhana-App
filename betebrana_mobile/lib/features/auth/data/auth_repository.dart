import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/js.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../domain/entities/auth_tokens.dart';
import '../domain/entities/auth_user.dart';
import '../../library/data/book_download_service.dart';

class AuthRepository {
  AuthRepository({
    Dio? dio,
    SecureStorageService? secureStorage,
    BookDownloadService? downloadService,
  })  : _dio = dio ?? DioClient.instance.dio,
        _secureStorage = secureStorage ?? SecureStorageService(),
        _downloadService = downloadService ?? BookDownloadService();

  final Dio _dio;
  final SecureStorageService _secureStorage;
  final BookDownloadService _downloadService;

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
        options: Options(
          validateStatus: (status) => true, // Allow all status codes
        ),
      );

      final data = response.data as Map<String, dynamic>;

      // Check for specific error status codes first
      if (response.statusCode == 401 || response.statusCode == 403) {
        final error = data['error'] ?? data['message'] ?? 'Invalid credentials';
        if (error.toString().toLowerCase().contains('invalid') ||
            error.toString().toLowerCase().contains('incorrect') ||
            error.toString().toLowerCase().contains('wrong')) {
          throw Exception('Invalid email or password. Please try again.');
        } else if (error.toString().toLowerCase().contains('locked') ||
            error.toString().toLowerCase().contains('suspended')) {
          throw Exception('Account is temporarily locked. Please try again later.');
        } else if (error.toString().toLowerCase().contains('verify')) {
          throw Exception('Please verify your email before logging in.');
        }
        throw Exception(error.toString());
      }

      if (response.statusCode == 404 || response.statusCode == 400) {
        throw Exception('Account not found. Please check your email.');
      }

      if (response.statusCode == 429) {
        throw Exception('Too many login attempts. Please try again later.');
      }

      if (response.statusCode! >= 500) {
        throw Exception('Server error. Please try again later.');
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        final error = data['error'] ?? data['message'] ?? 'Login failed';
        throw Exception(error.toString());
      }

      // Validate response contains required data
      if (data['success'] == false) {
        final error = data['error'] ?? data['message'] ?? 'Login failed';
        throw Exception(error.toString());
      }

      final token = (data['token'] ?? data['accessToken']) as String?;
      if (token == null || token.isEmpty) {
        throw Exception('Login response did not contain a valid token');
      }

      final refreshToken = data['refreshToken'] as String?;
      final userJson = (data['user'] as Map<String, dynamic>?) ?? {};
      
      // Validate user data
      if (userJson.isEmpty || userJson['id'] == null) {
        throw Exception('Invalid user data received from server');
      }

      final user = AuthUser.fromJson(userJson);
   
      final tokens = AuthTokens.fromRaw(
        accessToken: token,
        refreshToken: refreshToken,
      );

      await _persistSession(tokens: tokens, user: user);
      
      // Set current user ID for downloaded books management
      await _setCurrentUserId(user.id);
      
      // Clear previous user's downloads
      await _downloadService.clearDownloadsForPreviousUser();

      return user;
    } on DioException catch (e) {
      // Handle Dio-specific errors
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('Connection timeout. Please check your internet connection and try again.');
      } else if (e.type == DioExceptionType.connectionError ||
                e.type == DioExceptionType.unknown) {
        throw Exception('No internet connection. Please check your network settings.');
      } else if (e.type == DioExceptionType.badResponse) {
        // This should already be handled above, but as a fallback
        final error = e.response?.data?['error'] ?? 
                     e.response?.data?['message'] ?? 
                     'Login failed. Please try again.';
        throw Exception(error.toString());
      }
      throw Exception('Login failed: ${e.message ?? "Unknown error"}');
    } on FormatException catch (_) {
      throw Exception('Invalid server response. Please try again later.');
    } catch (e) {
      // Catch any other exceptions and provide user-friendly message
      if (e.toString().contains('invalid credentials') ||
          e.toString().contains('Invalid email or password') ||
          e.toString().contains('wrong password') ||
          e.toString().contains('user not found')) {
        throw Exception('Invalid email or password. Please try again.');
      }
      throw Exception('Login failed: ${e.toString().split(':').last.trim()}');
    }
  }
Future<void> register({
  required String name,
  required String email,
  required String password,
}) async {
  try {
    // COMPLETELY clear any existing session
    await _secureStorage.clearAll();
    await _clearCurrentUserId();
    await _downloadService.clearDownloadsForPreviousUser();
    
    final response = await _dio.post(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
      },
      options: Options(
        validateStatus: (status) => true,
      ),
    );

    final data = response.data as Map<String, dynamic>;

    // Check for specific error status codes
    if (response.statusCode == 400 || response.statusCode == 409) {
      final error = data['error'] ?? data['message'] ?? 'Registration failed';
      if (error.toString().toLowerCase().contains('already exists') ||
          error.toString().toLowerCase().contains('duplicate')) {
        throw Exception('Email already registered. Please use a different email or login.');
      } else if (error.toString().toLowerCase().contains('weak') ||
                error.toString().toLowerCase().contains('password')) {
        throw Exception('Password is too weak. Please use a stronger password.');
      } else if (error.toString().toLowerCase().contains('invalid email')) {
        throw Exception('Please enter a valid email address.');
      }
      throw Exception(error.toString());
    }

    if (response.statusCode == 422) {
      throw Exception('Invalid registration data. Please check your information.');
    }

    if (response.statusCode! >= 500) {
      throw Exception('Server error. Please try again later.');
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      final error = data['error'] ?? data['message'] ?? 'Registration failed';
      throw Exception(error.toString());
    }

    if (data['success'] == false) {
      final error = data['error'] ?? data['message'] ?? 'Registration failed';
      throw Exception(error.toString());
    }

    // IMPORTANT: DO NOT set any user ID or session after registration
    // Registration should NOT log the user in
    print('Registration successful for: $email');
  }
     on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.connectionError ||
                e.type == DioExceptionType.unknown) {
        throw Exception('No internet connection. Please check your network settings.');
      }
      throw Exception('Registration failed: ${e.message ?? "Unknown error"}');
    } on FormatException catch (_) {
      throw Exception('Invalid server response. Please try again later.');
    } catch (e) {
      throw Exception('Registration failed: ${e.toString().split(':').last.trim()}');
    }
  }

  Future<void> _persistSession({
    required AuthTokens tokens,
    required AuthUser user,
  }) async {
    try {
      await _secureStorage.saveAccessToken(tokens.accessToken);
      if (tokens.refreshToken != null) {
        await _secureStorage.saveRefreshToken(tokens.refreshToken!);
      }
      await _secureStorage.saveTokenExpiry(tokens.expiry);
      await _secureStorage.saveUser(
        id: user.id,
        email: user.email,
        name: user.name,
      );
    } catch (e) {
      print('Error persisting session: $e');
      throw Exception('Failed to save login session. Please try again.');
    }
  }

  Future<void> logout() async {
    try {
      // Clear secure storage
      await _secureStorage.clearAll();
      
      // Clear current user ID
      await _clearCurrentUserId();
      
      // Clear user-specific downloads
      await _downloadService.clearDownloadsForPreviousUser();
      
    } catch (e) {
      print('Error during logout: $e');
      await _secureStorage.clearAll();
      await _clearCurrentUserId();
    }
  }

  Future<bool> hasValidSession() async {
    try {
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
        await _clearCurrentUserId();
      }
      return isValid;
    } catch (e) {
      print('Error checking session validity: $e');
      return false;
    }
  }

Future<AuthUser?> getCurrentUser() async {
  try {
    final hasSession = await hasValidSession();
    if (!hasSession) return null;
    final userMap = await _secureStorage.getUser();
    final id = userMap['id'];
    final email = userMap['email'];
    final name = userMap['name'];
    if (id == null || email == null || name == null) return null;
    
    // IMPORTANT: Only return user, don't set ID here
    // This prevents automatic login after registration
    return AuthUser(id: id, email: email, name: name);
  } catch (e) {
    print('Error getting current user: $e');
    return null;
  }
}

  // Helper method to set current user ID in SharedPreferences
  Future<void> _setCurrentUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_id', userId);
      print('Set current user ID: $userId');
    } catch (e) {
      print('Error setting current user ID: $e');
    }
  }

  // Helper method to clear current user ID
  Future<void> _clearCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user_id');
      print('Cleared current user ID');
    } catch (e) {
      print('Error clearing current user ID: $e');
    }
  }

  // Helper method to get current user ID
  Future<String?> getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('current_user_id');
    } catch (e) {
      print('Error getting current user ID: $e');
      return null;
    }
  }
}