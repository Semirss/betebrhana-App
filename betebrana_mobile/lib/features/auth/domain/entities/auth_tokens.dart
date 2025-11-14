import 'dart:convert';

class AuthTokens {
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiry;

  const AuthTokens({
    required this.accessToken,
    this.refreshToken,
    this.expiry,
  });

  /// Create tokens from a raw JWT access token and optional refresh token.
  factory AuthTokens.fromRaw({
    required String accessToken,
    String? refreshToken,
  }) {
    DateTime? expiry;
    try {
      final parts = accessToken.split('.');
      if (parts.length == 3) {
        final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
        final map = json.decode(payload) as Map<String, dynamic>;
        final exp = map['exp'];
        if (exp is int) {
          expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        }
      }
    } catch (_) {
      // Fallback handled below.
    }

    expiry ??= DateTime.now().add(const Duration(hours: 24));

    return AuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiry: expiry,
    );
  }
}

