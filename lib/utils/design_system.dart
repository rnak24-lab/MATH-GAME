import 'package:flutter/material.dart';

/// 통일된 디자인 시스템 - 어두운 골목 + 도박판 누아르 테마
class DS {
  DS._();

  // ─── 색상 (누아르 도박판 테마) ───
  static const Color primary = Color(0xFFE8B86D);       // 가스등 황금빛 (주 강조색)
  static const Color primaryDark = Color(0xFFC9A84C);   // 앤티크 골드
  static const Color secondary = Color(0xFF4A7C59);     // 녹색 펠트 (카드 테이블)
  static const Color background = Color(0xFF0D0D0D);    // 칠흑 밤 골목
  static const Color surface = Color(0xFF1A1209);       // 낡은 벽돌 벽
  static const Color surfaceLight = Color(0xFF2A1F14);  // 그을린 나무 테이블
  static const Color textPrimary = Color(0xFFE8B86D);   // 가스등 황금빛 텍스트
  static const Color textSecondary = Color(0xFF8B7355); // 담배 연기빛 베이지
  static const Color success = Color(0xFFC9A84C);       // 앤티크 골드 (승리)
  static const Color error = Color(0xFFC0392B);         // 핏빛 레드
  static const Color warning = Color(0xFFD4A853);       // 황동색
  static const Color panelBg = Color(0xFF3D2B1F);       // 마호가니 갈색 (패널)
  static const Color inactive = Color(0xFF6B6B6B);      // 안개 회색

  // 월드별 색상 (도박판 테마)
  static const Color worldAlley = Color(0xFF2D5A3D);    // 뒷골목 공원 (이끼 다크 그린)
  static const Color worldHarbor = Color(0xFF1A4A4A);   // 항구 창고 (바다 테일 그린)
  static const Color worldSaloon = Color(0xFF8B7355);   // 서부 살룬 (모래 베이지)
  static const Color worldForge = Color(0xFF8B2500);    // 지하 용광로 (불꽃 다크 레드)
  static const Color worldSpace = Color(0xFF4A2D6B);    // 우주 암시장 (딥 스페이스 퍼플)

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
      case 0: return '🌙 뒷골목 공원';
      case 1: return '⚓ 항구 창고';
      case 2: return '🤠 서부 살룬';
      case 3: return '🔥 지하 용광로';
      case 4: return '🌌 우주 암시장';
      default: return '???';
    }
  }

  static String getWorldEmoji(int world) {
    const emojis = ['🌙', '⚓', '🤠', '🔥', '🌌'];
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
