class AppConfig {
  AppConfig._();

  /// Production Render URL
  static const String baseApiUrl = 'https://betebrhana-app.onrender.com/api';

  // Documents and covers are now stored on GitHub, so these are no longer needed
  // for new uploads. Kept for backwards compatibility with any legacy code.
  static const String documentsBaseUrl = 'https://betebrhana-app.onrender.com/documents';
  static const String coversBaseUrl = 'https://betebrhana-app.onrender.com';
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

// class AppConfig {
//   AppConfig._();
//   static const String baseApiUrl = 'http://192.168.8.120:3000/api'; 
//   static const String documentsBaseUrl = 'http://192.168.8.120:3000/documents';
//   static const String coversBaseUrl = 'http://192.168.8.120:3000';
// }

// class AppConfig {
//   AppConfig._();
//   /// For Android Emulator: Use 10.0.2.2
//   static const String baseApiUrl = 'http://10.0.2.2:3000/api'; 
//   static const String documentsBaseUrl = 'http://10.0.2.2:3000/documents';
//   static const String coversBaseUrl = 'http://10.0.2.2:3000';
// }