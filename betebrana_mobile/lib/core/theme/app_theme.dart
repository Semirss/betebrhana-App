import 'package:flutter/material.dart';

/// Application-wide color schemes matching the web reader themes.
class AppTheme {
  AppTheme._();

  // Base colors from requirements
  static const lightBackground = Color(0xFFFFFFFF); // #ffffff
  static const lightForeground = Color(0xFF333333); // #333333

  static const darkBackground = Color(0xFF1A1A1A); // #1a1a1a
  static const darkForeground = Color(0xFFE0E0E0); // #e0e0e0

  static const tanBackground = Color(0xFFFDF6E3); // #fdf6e3
  static const tanForeground = Color(0xFF586E75); // #586e75

  static const blueBackground = Color(0xFFE3F2FD); // #e3f2fd
  static const blueForeground = Color(0xFF1565C0); // #1565c0

  static const greenBackground = Color(0xFFE8F5E8); // #e8f5e8
  static const greenForeground = Color(0xFF2E7D32); // #2e7d32

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: lightForeground,
        brightness: Brightness.light,
        background: lightBackground,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: darkForeground,
        brightness: Brightness.dark,
        background: darkBackground,
      ),
    );
  }
}

