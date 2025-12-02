import 'package:flutter/material.dart';

/// Application-wide color schemes matching the web reader themes.
class AppTheme {
  AppTheme._();

  // Enhanced colors with more depth and richness
  static const lightBackground = Color(0xFFF8F9FA); // Softer off-white
  static const lightForeground = Color(0xFF2D3748); // Darker gray for better contrast

  static const darkBackground = Color(0xFF121212); // True dark
  static const darkForeground = Color(0xFFE2E8F0); // Softer light gray

  static const tanBackground = Color(0xFFF4EBD0); // Warmer, richer tan
  static const tanForeground = Color(0xFF4A5568); // Deeper gray-brown

  static const blueBackground = Color(0xFFDBEAFE); // Deeper blue tint
  static const blueForeground = Color(0xFF1E40AF); // Richer blue

  static const greenBackground = Color(0xFFD1FAE5); // Deeper green tint
  static const greenForeground = Color(0xFF065F46); // Richer forest green

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: ColorScheme.light(
        primary: lightForeground,
        onPrimary: lightBackground,
        secondary: lightForeground.withOpacity(0.7),
        onSecondary: lightBackground,
        background: lightBackground,
        onBackground: lightForeground,
        surface: lightBackground,
        onSurface: lightForeground,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme.dark(
        primary: darkForeground,
        onPrimary: darkBackground,
        secondary: darkForeground.withOpacity(0.7),
        onSecondary: darkBackground,
        background: darkBackground,
        onBackground: darkForeground,
        surface: Color(0xFF1E1E1E), // Slightly lighter than background
        onSurface: darkForeground,
      ),
    );
  }

  static ThemeData sepia() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: tanBackground,
      colorScheme: ColorScheme.light(
        primary: tanForeground,
        onPrimary: tanBackground,
        secondary: tanForeground.withOpacity(0.7),
        onSecondary: tanBackground,
        background: tanBackground,
        onBackground: tanForeground,
        surface: tanBackground,
        onSurface: tanForeground,
      ),
    );
  }

  static ThemeData blue() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: blueBackground,
      colorScheme: ColorScheme.light(
        primary: blueForeground,
        onPrimary: blueBackground,
        secondary: blueForeground.withOpacity(0.7),
        onSecondary: blueBackground,
        background: blueBackground,
        onBackground: blueForeground,
        surface: blueBackground,
        onSurface: blueForeground,
      ),
    );
  }

  static ThemeData green() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: greenBackground,
      colorScheme: ColorScheme.light(
        primary: greenForeground,
        onPrimary: greenBackground,
        secondary: greenForeground.withOpacity(0.7),
        onSecondary: greenBackground,
        background: greenBackground,
        onBackground: greenForeground,
        surface: greenBackground,
        onSurface: greenForeground,
      ),
    );
  }
}