class AppConfig {
  AppConfig._();

  /// Production Render backend URL (API)
  static const String baseApiUrl = 'https://betebrhana-app.onrender.com/api';

  /// Render base URL — only used for LEGACY local /documents or /covers paths
  static const String _renderBaseUrl = 'https://betebrhana-app.onrender.com';

  // These are kept for backwards compatibility only
  static const String documentsBaseUrl = 'https://betebrhana-app.onrender.com/documents';
  static const String coversBaseUrl = 'https://betebrhana-app.onrender.com';

  /// Safely resolves any image or file path to a full URL.
  /// - If path is already a full URL (http/https), returns it as-is.
  /// - If path is a local /covers or /documents path, prepends the Render base URL.
  static String resolveUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path; // Already a full URL (GitHub raw URL etc.)
    }
    // Legacy local path — prepend Render server base
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$_renderBaseUrl$cleanPath';
  }
}

// =====================================================================
// OLD LOCAL CONFIGS — kept for reference only, do not uncomment
// =====================================================================

// class AppConfig {
//   AppConfig._();
//   static const String baseApiUrl = 'http://192.168.8.112:3000/api';
//   static const String documentsBaseUrl = 'http://192.168.8.112:3000/documents';
//   static const String coversBaseUrl = 'http://192.168.8.112:3000';
// }