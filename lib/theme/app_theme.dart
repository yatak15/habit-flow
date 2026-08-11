import 'package:flutter/material.dart';

/// Habit Flow - ミニマル・禅スタイルのテーマ定義
/// セージグリーン × クリームベージュを基調とした落ち着いた配色
class AppColors {
  static const Color sage = Color(0xFF8BA888);
  static const Color sageDark = Color(0xFF6B8A68);
  static const Color sageLight = Color(0xFFC5D6C3);
  static const Color cream = Color(0xFFFAF7F2);
  static const Color creamDark = Color(0xFFF0EAE0);
  static const Color textPrimary = Color(0xFF3A3A36);
  static const Color textSecondary = Color(0xFF8A8680);
  static const Color accentGold = Color(0xFFD4AF6A); // プライズ用アクセント
  static const Color divider = Color(0xFFE6E1D8);
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.cream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.sage,
        brightness: Brightness.light,
        surface: AppColors.cream,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w300,
          color: AppColors.textPrimary,
          letterSpacing: 0.5,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w300,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.sage,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.sageDark,
        unselectedItemColor: AppColors.textSecondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      dividerColor: AppColors.divider,
    );
  }
}
