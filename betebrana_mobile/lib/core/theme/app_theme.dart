import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App-wide color palette matching the web design.
class AppColors {
  AppColors._();

  // Brand
  static const primary = Color(0xFF78A090);
  static const secondary = Color(0xFF385A4B);

  // Light theme
  static const lightBackground = Color(0xFFF3F8F6);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightText = Color(0xFF18181B);
  static const lightSubtext = Color(0xFF5F6F69);
  static const lightDivider = Color(0xFFD7E7E0);

  // Dark theme
  static const darkBackground = Color(0xFF101A16);
  static const darkCard = Color(0xFF17231E);
  static const darkText = Color(0xFFE2E8F0);
  static const darkSubtext = Color(0xFF9CA3AF);
  static const darkDivider = Color(0xFF2F4A40);
}

class AppTheme {
  AppTheme._();

  static ThemeData light({String? fontFamily}) {
    TextTheme customTextTheme = ThemeData.light().textTheme;
    String? nativeFontFamily = fontFamily == 'System' ? null : fontFamily;

    if (fontFamily == 'Abyssinica SIL') {
      customTextTheme = GoogleFonts.abyssinicaSilTextTheme(customTextTheme);
      nativeFontFamily = GoogleFonts.abyssinicaSil().fontFamily;
    } else if (fontFamily == 'Noto Sans Ethiopic') {
      customTextTheme = GoogleFonts.notoSansEthiopicTextTheme(customTextTheme);
      nativeFontFamily = GoogleFonts.notoSansEthiopic().fontFamily;
    }

    return ThemeData(
      fontFamily: nativeFontFamily,
      textTheme: customTextTheme,
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      primaryColor: AppColors.primary,
      cardColor: AppColors.lightCard,
      dividerColor: AppColors.lightDivider,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        surface: AppColors.lightCard,
        onSurface: AppColors.lightText,
        background: AppColors.lightBackground,
        onBackground: AppColors.lightText,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        foregroundColor: AppColors.lightText,
        titleTextStyle: TextStyle(
          color: AppColors.lightText,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightCard,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.lightSubtext,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 10),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith(
          (s) => s.contains(MaterialState.selected) ? AppColors.primary : Colors.grey,
        ),
        trackColor: MaterialStateProperty.resolveWith(
          (s) => s.contains(MaterialState.selected)
              ? AppColors.primary.withOpacity(0.4)
              : Colors.grey.shade300,
        ),
      ),
    );
  }

  static ThemeData dark({String? fontFamily}) {
    TextTheme customTextTheme = ThemeData.dark().textTheme;
    String? nativeFontFamily = fontFamily == 'System' ? null : fontFamily;

    if (fontFamily == 'Abyssinica SIL') {
      customTextTheme = GoogleFonts.abyssinicaSilTextTheme(customTextTheme);
      nativeFontFamily = GoogleFonts.abyssinicaSil().fontFamily;
    } else if (fontFamily == 'Noto Sans Ethiopic') {
      customTextTheme = GoogleFonts.notoSansEthiopicTextTheme(customTextTheme);
      nativeFontFamily = GoogleFonts.notoSansEthiopic().fontFamily;
    }

    return ThemeData(
      fontFamily: nativeFontFamily,
      textTheme: customTextTheme,
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      primaryColor: AppColors.primary,
      cardColor: AppColors.darkCard,
      dividerColor: AppColors.darkDivider,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        surface: AppColors.darkCard,
        onSurface: AppColors.darkText,
        background: AppColors.darkBackground,
        onBackground: AppColors.darkText,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        foregroundColor: AppColors.darkText,
        titleTextStyle: TextStyle(
          color: AppColors.darkText,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkCard,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.darkSubtext,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 10),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith(
          (s) => s.contains(MaterialState.selected) ? AppColors.primary : Colors.grey,
        ),
        trackColor: MaterialStateProperty.resolveWith(
          (s) => s.contains(MaterialState.selected)
              ? AppColors.primary.withOpacity(0.4)
              : Colors.grey.shade800,
        ),
      ),
    );
  }
}