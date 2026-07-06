import 'package:flutter/material.dart';

/// NIM 공용 디자인 토큰 — 전 화면 세피아 노와르 통일 (귀여움 규칙 K1·K2).
/// 게임 화면(game_screen._Pal)과 동일 값. 새 화면은 반드시 이 토큰만 사용.
class NimTheme {
  NimTheme._();

  // 배경/구조
  static const deskTop = Color(0xFF3A332A);
  static const deskBottom = Color(0xFF241F18);
  static const deskBoard = Color(0xFF2B251D);
  static const frame = Color(0xFF4A3D2C);
  static const frameHi = Color(0xFF6E5C42);

  // 종이/텍스트
  static const paper = Color(0xFFC8B790);
  static const paperLight = Color(0xFFEFE6D0); // 밝은 종이(설정 등 라이트 화면)
  static const cream = Color(0xFFEADFC6);
  static const ink = Color(0xFF332817);
  static const inkSoft = Color(0xFF6A5A3F);

  // 의미색 3개 (K2 — 추가 금지)
  static const gold = Color(0xFFC9A24B);
  static const alarm = Color(0xFF9B3B2E);
  static const win = Color(0xFF5E7D52);

  /// 한글+영문 픽셀 폰트 (네오둥근모)
  static const font = 'NeoDGM';

  static const bg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [deskTop, deskBottom],
  );
}
