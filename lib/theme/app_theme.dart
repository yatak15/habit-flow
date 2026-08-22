import 'package:flutter/material.dart';

/// Habit Flow - "Quiet Momentum"（静かな勢い）デザインシステム
/// ウォームアイボリー × セージグリーン × テラコッタを基調とした
/// 落ち着きと積み重ねの実感を両立する配色・タイポグラフィ体系
class AppColors {
  // Base
  static const Color bg = Color(0xFFF6F3EC); // warm ivory background
  static const Color surface = Color(0xFFFFFFFF); // card surface
  static const Color ink = Color(0xFF1F221E); // primary text
  static const Color inkSub = Color(0xFF6E7268); // secondary text
  static const Color inkMuted = Color(0xFFA6A99F); // tertiary / disabled
  static const Color line = Color(0xFFE8E4D8); // borders, dividers

  // Sage (primary)
  static const Color sage = Color(0xFF7C9A73); // primary (light)
  static const Color sageDeep = Color(0xFF5A7C52); // primary (deep / active)
  static const Color sageSoft = Color(0xFFDCE6D5); // sage subtle
  static const Color sageBg = Color(0xFFEDF1E6); // sage background tint

  // Terracotta (accent / milestones)
  static const Color terracotta = Color(0xFFC67A54);
  static const Color terraSoft = Color(0xFFF3E1D5);

  // 互換エイリアス（既存コードとの橋渡し用）
  static const Color sageDark = sageDeep;
  static const Color sageLight = sageSoft;
  static const Color cream = bg;
  static const Color creamDark = sageBg;
  static const Color textPrimary = ink;
  static const Color textSecondary = inkSub;
  static const Color accentGold = terracotta;
  static const Color divider = line;
}

/// シャドウトークン（tinted shadow / soft depth）
class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0A1F221E), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0F1F221E), blurRadius: 24, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> cardLg = [
    BoxShadow(color: Color(0x0D1F221E), blurRadius: 4, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x141F221E), blurRadius: 40, offset: Offset(0, 20)),
  ];

  static List<BoxShadow> selectedCard = [
    const BoxShadow(
      color: Color(0x475A7C52),
      blurRadius: 20,
      offset: Offset(0, 6),
    ),
  ];

  static List<BoxShadow> cta = [
    const BoxShadow(
      color: Color(0x475A7C52),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
    const BoxShadow(
      color: Color(0x265A7C52),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];
}

/// スペーシングスケール（24 / 32 / 48 を基準とした余白体系）
class AppSpace {
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s14 = 14;
  static const double s16 = 16;
  static const double s18 = 18;
  static const double s20 = 20;
  static const double s22 = 22;
  static const double s24 = 24;
  static const double s28 = 28;
  static const double s32 = 32;
  static const double s36 = 36;
  static const double s48 = 48;
}

/// タイポグラフィ：iOS標準フォント（San Francisco / ヒラギノ角ゴ）を用いつつ、
/// ウェイト・レタースペーシングでNoto Sans JPデザイン仕様の質感を再現する。
/// Hero数字は軽めのウェイト（w500）で大胆に、UIラベルはw600中心のはっきりした階調で構成。
class AppText {
  // Hero titles
  static const TextStyle heroHome = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    height: 1.15,
    letterSpacing: -1,
  );
  static const TextStyle heroSelected = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    height: 1.15,
    letterSpacing: -1,
  );
  static const TextStyle heroHistory = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    height: 1.15,
    letterSpacing: -1,
  );

  // Numerals
  static const TextStyle historyHeroNumber = TextStyle(
    fontSize: 60,
    fontWeight: FontWeight.w500,
    letterSpacing: -2,
    height: 0.9,
  );
  static const TextStyle momentumValue = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.8,
    color: AppColors.ink,
    height: 1.0,
  );
  static const TextStyle timerValue = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
    height: 1.0,
  );
  static const TextStyle historySubMetric = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.5,
    color: AppColors.ink,
    height: 1.0,
  );

  static const TextStyle h2Section = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: AppColors.ink,
  );
  static const TextStyle rowLabel = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
    color: AppColors.ink,
  );
  static const TextStyle ctaLabel = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: Colors.white,
  );
  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.ink,
  );
  static const TextStyle cardLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: AppColors.ink,
  );
  static const TextStyle chipLabel = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );
  static const TextStyle subMeta = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.inkSub,
  );
  static const TextStyle eyebrow = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
    color: AppColors.sageDeep,
  );
  static const TextStyle streakCaption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.inkSub,
  );
  static const TextStyle microLabel = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
    color: AppColors.inkSub,
  );
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      fontFamily: '.SF Pro Text',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.sage,
        brightness: Brightness.light,
        surface: AppColors.bg,
      ),
      textTheme: const TextTheme(
        headlineMedium: AppText.heroHome,
        titleLarge: AppText.h2Section,
        bodyMedium: AppText.body,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.line, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.sageDeep,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: AppText.ctaLabel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.sageDeep,
        unselectedItemColor: AppColors.inkMuted,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      dividerColor: AppColors.line,
    );
  }
}
