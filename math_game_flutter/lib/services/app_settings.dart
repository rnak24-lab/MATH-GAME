import 'package:shared_preferences/shared_preferences.dart';

/// 앱 전역 설정 (언어 제외 — 언어는 LocaleProvider).
/// SharedPreferences 기반 싱글톤.
class AppSettings {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  static const String _hapticsKey = 'settings_haptics';
  static const String _musicKey = 'settings_music';
  static const String _musicVolumeKey = 'settings_music_volume';

  /// 진동(햅틱) 효과 — 돌 집기/확정/승패 순간에 가벼운 진동.
  bool haptics = true;

  /// 배경음악 (칩튠 루프).
  bool music = true;

  /// 배경음악 음량 (0.0 ~ 1.0).
  double musicVolume = 0.3;

  /// 효과음 (돌 가져가기 슉! 등).
  bool sfx = true;
  static const String _sfxKey = 'settings_sfx';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    haptics = prefs.getBool(_hapticsKey) ?? true;
    music = prefs.getBool(_musicKey) ?? true;
    musicVolume = prefs.getDouble(_musicVolumeKey) ?? 0.3;
    sfx = prefs.getBool(_sfxKey) ?? true;
  }

  Future<void> setSfx(bool v) async {
    sfx = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sfxKey, v);
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

  Future<void> setMusicVolume(double v) async {
    musicVolume = v.clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_musicVolumeKey, musicVolume);
  }
}
