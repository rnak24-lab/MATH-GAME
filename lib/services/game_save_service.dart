import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences로 게임 진행 저장
class GameSaveService {
  static const String _keyMaxStage = 'max_stage_cleared';
  static const String _keyHintKeys = 'hint_keys';
  static const String _keyAdsRemoved = 'ads_removed';
  static const String _keyTutorialDone = 'tutorial_done';
  static const String _keyWorldUnlocked = 'world_unlocked';

  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ─── 스테이지 진행 ───
  static int get maxStageCleared => _prefs.getInt(_keyMaxStage) ?? 0;

  static Future<void> setMaxStageCleared(int stage) async {
    final current = maxStageCleared;
    if (stage > current) {
      await _prefs.setInt(_keyMaxStage, stage);
    }
  }

  // ─── 월드 해금 ───
  static int get worldUnlocked => _prefs.getInt(_keyWorldUnlocked) ?? 0;

  static Future<void> unlockWorld(int world) async {
    if (world > worldUnlocked) {
      await _prefs.setInt(_keyWorldUnlocked, world);
    }
  }

  /// 해당 월드에서 클리어한 스테이지 수 계산
  static int getWorldClearCount(int world) {
    final maxCleared = maxStageCleared;
    final worldStart = world * 20 + 1;
    final worldEnd = (world + 1) * 20;

    if (maxCleared < worldStart) return 0;
    if (maxCleared >= worldEnd) return 20;
    return maxCleared - worldStart + 1;
  }

  /// 다음 월드 해금 조건 확인 (3스테이지 클리어)
  static bool canUnlockNextWorld(int currentWorld) {
    return getWorldClearCount(currentWorld) >= 3;
  }

  // ─── 힌트 열쇠 ───
  static int get hintKeys => _prefs.getInt(_keyHintKeys) ?? 0;

  static Future<void> addHintKeys(int count) async {
    await _prefs.setInt(_keyHintKeys, hintKeys + count);
  }

  static Future<bool> useHintKey() async {
    if (hintKeys <= 0) return false;
    await _prefs.setInt(_keyHintKeys, hintKeys - 1);
    return true;
  }

  // ─── 광고 제거 ───
  static bool get adsRemoved => _prefs.getBool(_keyAdsRemoved) ?? false;

  static Future<void> setAdsRemoved(bool value) async {
    await _prefs.setBool(_keyAdsRemoved, value);
  }

  // ─── 튜토리얼 ───
  static bool get tutorialDone => _prefs.getBool(_keyTutorialDone) ?? false;

  static Future<void> setTutorialDone(bool value) async {
    await _prefs.setBool(_keyTutorialDone, value);
  }
}
