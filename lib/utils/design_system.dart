import 'package:flutter/material.dart';

/// 통일된 디자인 시스템 - 폰트/간격/크기/색상 일괄 관리
class DS {
  DS._();

  // ─── 색상 ───
  static const Color primary = Color(0xFFFF6B9D);
  static const Color primaryDark = Color(0xFFE91E63);
  static const Color secondary = Color(0xFF7C4DFF);
  static const Color background = Color(0xFFFFF8E1);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF2D2D2D);
  static const Color textSecondary = Color(0xFF757575);
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);

  // 월드별 색상
  static const Color worldMeadow = Color(0xFF66BB6A);
  static const Color worldOcean = Color(0xFF42A5F5);
  static const Color worldPepero = Color(0xFF8D6E63);
  static const Color worldCrystal = Color(0xFFAB47BC);
  static const Color worldDragon = Color(0xFFEF5350);

  static Color getWorldColor(int world) {
    switch (world) {
      case 0: return worldMeadow;
      case 1: return worldOcean;
      case 2: return worldPepero;
      case 3: return worldCrystal;
      case 4: return worldDragon;
      default: return primary;
    }
  }

  static String getWorldName(int world) {
    switch (world) {
      case 0: return '🌿 초원 마을';
      case 1: return '🌊 바다 왕국';
      case 2: return '🍫 빼빼로 숲';
      case 3: return '💎 수정 궁전';
      case 4: return '🐉 드래곤 성';
      default: return '???';
    }
  }

  static String getWorldEmoji(int world) {
    const emojis = ['🌿', '🌊', '🍫', '💎', '🐉'];
    return world < emojis.length ? emojis[world] : '❓';
  }

  // ─── 폰트 크기 ───
  static const double fontXS = 10.0;
  static const double fontSM = 12.0;
  static const double fontMD = 14.0;
  static const double fontLG = 18.0;
  static const double fontXL = 24.0;
  static const double fontXXL = 32.0;
  static const double fontTitle = 28.0;

  // ─── 간격 ───
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 24.0;
  static const double spaceXL = 32.0;
  static const double spaceXXL = 48.0;

  // ─── 둥글기 ───
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusFull = 100.0;

  // ─── 텍스트 스타일 ───
  static const TextStyle heading1 = TextStyle(
    fontSize: fontXXL,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: fontTitle,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: fontXL,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: fontMD,
    color: textPrimary,
  );

  static const TextStyle bodyBold = TextStyle(
    fontSize: fontMD,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: fontSM,
    color: textSecondary,
  );

  // ─── 버튼 스타일 ───
  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: primary,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusXL),
    ),
    textStyle: const TextStyle(fontSize: fontLG, fontWeight: FontWeight.bold),
  );

  static ButtonStyle secondaryButton = ElevatedButton.styleFrom(
    backgroundColor: secondary,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusXL),
    ),
    textStyle: const TextStyle(fontSize: fontMD, fontWeight: FontWeight.bold),
  );

  // ─── 카드 데코레이션 ───
  static BoxDecoration cardDecoration = BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(radiusLG),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // ─── 테마 ───
  static ThemeData get theme => ThemeData(
    primaryColor: primary,
    scaffoldBackgroundColor: background,
    fontFamily: 'Pretendard',
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      background: background,
      surface: surface,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButton),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: fontLG,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      iconTheme: IconThemeData(color: textPrimary),
    ),
  );
}
