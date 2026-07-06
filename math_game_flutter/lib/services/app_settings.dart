import 'package:shared_preferences/shared_preferences.dart';

/// 앱 전역 설정 (언어 제외 — 언어는 LocaleProvider).
/// SharedPreferences 기반 싱글톤.
class AppSettings {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  static const String _hapticsKey = 'settings_haptics';
  static const String _musicKey = 'settings_music';

  /// 진동(햅틱) 효과 — 돌 집기/확정/승패 순간에 가벼운 진동.
  bool haptics = true;

  /// 배경음악 (칩튠 루프).
  bool music = true;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    haptics = prefs.getBool(_hapticsKey) ?? true;
    music = prefs.getBool(_musicKey) ?? true;
  }

  Future<void> setHaptics(bool v) async {
    haptics = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticsKey, v);
  }

  Future<void> setMusic(bool v) async {
    music = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_musicKey, v);
  }
}
