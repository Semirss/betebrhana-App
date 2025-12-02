// class AppConfig {
//   AppConfig._();

//   /// Base API URL (can be overridden by flavors / env-specific configs).
//   /// Example dev URL: http://localhost:3000/api
//   static const String baseApiUrl = 'http://localhost:3000/api';

//   /// Documents (books) base URL. The backend serves files from /documents.
//   static const String documentsBaseUrl = 'http://localhost:3000/documents';

//   /// Covers base URL. The backend serves cover images from /covers.
//   static const String coversBaseUrl = 'http://localhost:3000';
// }

class AppConfig {
  AppConfig._();

  /// For Android Emulator: Use 10.0.2.2
  /// For iOS Simulator/Web: Use localhost
  static const String baseApiUrl = 'http://10.0.2.2:3000/api'; 

  static const String documentsBaseUrl = 'http://10.0.2.2:3000/documents';
  static const String coversBaseUrl = 'http://10.0.2.2:3000';
}