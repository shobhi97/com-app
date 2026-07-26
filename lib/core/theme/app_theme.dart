import 'package:flutter/material.dart';

/// TickBell design language: dark-first, finance-app density,
/// deep navy/charcoal surfaces, a single acquisitive accent (amber/gold bell),
/// green/red for gains/losses. Mirrors the visual register of premium
/// trading apps (Zerodha Kite / TradingView dark theme) without copying assets.
class AppColors {
  AppColors._();

  static const Color bgPrimaryDark = Color(0xFF0B0E14);
  static const Color bgSecondaryDark = Color(0xFF12151D);
  static const Color surfaceDark = Color(0xFF1A1E29);
  static const Color surfaceElevatedDark = Color(0xFF232838);

  static const Color bgPrimaryLight = Color(0xFFF7F8FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);

  static const Color accentGold = Color(0xFFE8B84B);
  static const Color accentGoldMuted = Color(0xFF7A6634);

  static const Color bullGreen = Color(0xFF12B76A);
  static const Color bearRed = Color(0xFFF04438);
  static const Color infoBlue = Color(0xFF3E8BFF);

  static const Color textPrimaryDark = Color(0xFFEDEFF3);
  static const Color textSecondaryDark = Color(0xFF9AA1B2);
  static const Color textPrimaryLight = Color(0xFF11131A);
  static const Color textSecondaryLight = Color(0xFF5B6273);

  static const Color divider = Color(0xFF2A2F3E);
}

class AppTheme {
  AppTheme._();

  static const String fontFamily = 'Roboto';

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    final colorScheme = const ColorScheme.dark(
      brightness: Brightness.dark,
      primary: AppColors.accentGold,
      onPrimary: Color(0xFF201A08),
      secondary: AppColors.infoBlue,
      onSecondary: Colors.white,
      error: AppColors.bearRed,
      onError: Colors.white,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.bgPrimaryDark,
      dividerColor: AppColors.divider,
      fontFamily: fontFamily,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgPrimaryDark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimaryDark,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimaryDark),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevatedDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentGold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.bearRed),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
        hintStyle: const TextStyle(color: AppColors.textSecondaryDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentGold,
          foregroundColor: const Color(0xFF201A08),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimaryDark,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.divider),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.accentGold),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgSecondaryDark,
        selectedItemColor: AppColors.accentGold,
        unselectedItemColor: AppColors.textSecondaryDark,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevatedDark,
        contentTextStyle: const TextStyle(color: AppColors.textPrimaryDark),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surfaceElevatedDark,
        labelStyle: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 12),
        side: const BorderSide(color: AppColors.divider),
      ),
    );
  }

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    final colorScheme = const ColorScheme.light(
      primary: Color(0xFFB8860B),
      onPrimary: Colors.white,
      secondary: AppColors.infoBlue,
      error: AppColors.bearRed,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimaryLight,
    );
    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.bgPrimaryLight,
      fontFamily: fontFamily,
    );
  }
}
