import 'package:flutter/material.dart';

/// 통일된 디자인 시스템 - 어두운 골목 + 도박판 누아르 테마
class DS {
  DS._();

  // ─── 색상 (누아르 도박판 테마 — 단비 피그마 가이드라인 반영) ───
  static const Color primary = Color(0xFFD4A017);       // 골드 (도박/카드 황금빛, 1차 포인트)
  static const Color primaryDark = Color(0xFFC9A84C);   // 앤티크 골드
  static const Color secondary = Color(0xFF2ECC71);     // 에메랄드 (소액 칩/이득 표시, 3차 포인트)
  static const Color accent = Color(0xFFC0392B);        // 크림슨 레드 (위험/긴장감, 2차 포인트)
  static const Color glow = Color(0xFFF5C518);          // 앰버 옐로우 (가로등 빛 번짐)
  static const Color background = Color(0xFF0D0D0D);    // 딥 블랙 (골목 밤하늘)
  static const Color surface = Color(0xFF1A1208);       // 다크 브라운 (낡은 골목 벽)
  static const Color surfaceLight = Color(0xFF1F1A0F);  // 다크 앰버 (낡은 나무 테이블)
  static const Color overlay = Color(0xB00A0A0A);       // 반투명 블랙 (골목 그림자)
  static const Color textPrimary = Color(0xFFE8DCC8);   // 크림 베이지 (기본 텍스트)
  static const Color textSecondary = Color(0xFF9B8B6E); // 모래 갈색 (보조 텍스트)
  static const Color textAccent = Color(0xFFD4A017);    // 골드 (강조 텍스트)
  static const Color success = Color(0xFF2ECC71);       // 에메랄드 (승리)
  static const Color error = Color(0xFFC0392B);         // 크림슨 레드
  static const Color warning = Color(0xFFD4A853);       // 황동색
  static const Color panelBg = Color(0xFF3D2B1F);       // 마호가니 갈색 (패널)
  static const Color inactive = Color(0xFF4A3F2F);      // 다크 카키 (비활성)

  // 월드별 색상 (도박판 테마)
  static const Color worldAlley = Color(0xFF2D5A3D);    // Alley Corner (이끼 다크 그린)
  static const Color worldHarbor = Color(0xFF1A4A4A);   // Neon Tavern (바다 테일 그린)
  static const Color worldSaloon = Color(0xFF8B7355);   // Smoke Den (모래 베이지)
  static const Color worldForge = Color(0xFF8B2500);    // Shadow Market (불꽃 다크 레드)
  static const Color worldSpace = Color(0xFF4A2D6B);    // The Last Bet (딥 스페이스 퍼플)

  static Color getWorldColor(int world) {
    switch (world) {
      case 0: return worldAlley;
      case 1: return worldHarbor;
      case 2: return worldSaloon;
      case 3: return worldForge;
      case 4: return worldSpace;
      default: return primary;
    }
  }

  static String getWorldName(int world) {
    switch (world) {
      case 0: return '🚪 Alley Corner';
      case 1: return '🍺 Neon Tavern';
      case 2: return '💨 Smoke Den';
      case 3: return '🕶️ Shadow Market';
      case 4: return '🎲 The Last Bet';
      default: return '???';
    }
  }

  static String getWorldEmoji(int world) {
    const emojis = ['🚪', '🍺', '💨', '🕶️', '🎲'];
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

  // ─── 텍스트 스타일 (누아르 톤) ───
  static const TextStyle heading1 = TextStyle(
    fontSize: fontXXL,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: 1.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: fontTitle,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: 1.0,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: fontXL,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: fontMD,
    color: textSecondary,
  );

  static const TextStyle bodyBold = TextStyle(
    fontSize: fontMD,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: fontSM,
    color: inactive,
  );

  // ─── 버튼 스타일 (나무+황동 테두리) ───
  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: panelBg,
    foregroundColor: primary,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMD),
      side: const BorderSide(color: primaryDark, width: 1.5),
    ),
    textStyle: const TextStyle(fontSize: fontLG, fontWeight: FontWeight.bold),
  );

  static ButtonStyle secondaryButton = ElevatedButton.styleFrom(
    backgroundColor: surfaceLight,
    foregroundColor: textSecondary,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMD),
      side: const BorderSide(color: inactive, width: 1),
    ),
    textStyle: const TextStyle(fontSize: fontMD, fontWeight: FontWeight.bold),
  );

  // ─── 카드 데코레이션 (나무 패널 스타일) ───
  static BoxDecoration cardDecoration = BoxDecoration(
    color: panelBg,
    borderRadius: BorderRadius.circular(radiusMD),
    border: Border.all(color: primaryDark.withOpacity(0.4), width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.4),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // ─── 펠트 테이블 데코레이션 (게임 보드용) ───
  static BoxDecoration feltTableDecoration = BoxDecoration(
    color: secondary.withOpacity(0.3),
    borderRadius: BorderRadius.circular(radiusLG),
    border: Border.all(color: primaryDark.withOpacity(0.6), width: 2),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.5),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );

  // ─── 테마 (누아르 다크) ───
  static ThemeData get theme => ThemeData(
    brightness: Brightness.dark,
    primaryColor: primary,
    scaffoldBackgroundColor: background,
    fontFamily: 'Pretendard',
    colorScheme: ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: surface,
      error: error,
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
