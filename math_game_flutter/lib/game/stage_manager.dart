import 'package:shared_preferences/shared_preferences.dart';

class StageManager {
  static const String _maxStageKey = 'max_stage';
  static const String _worldUnlockedKey = 'world_unlocked';
  static const String _tutorialDoneKey = 'tutorial_done';

  int maxStage = 0;
  int worldUnlocked = 0;
  bool tutorialDone = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    maxStage = prefs.getInt(_maxStageKey) ?? 0;
    worldUnlocked = prefs.getInt(_worldUnlockedKey) ?? 0;
    tutorialDone = prefs.getBool(_tutorialDoneKey) ?? false;
  }

  Future<void> clearStage(int stage) async {
    if (stage > maxStage) {
      maxStage = stage;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_maxStageKey, maxStage);

      // 월드 언락 체크 (이전 월드에서 3스테이지 클리어 시)
      int newWorldUnlock = (maxStage - 1) ~/ 20;
      if (maxStage % 20 >= 3 || maxStage % 20 == 0) {
        newWorldUnlock = ((maxStage - 1) ~/ 20) + 1;
      }
      if (newWorldUnlock > worldUnlocked && newWorldUnlock <= 4) {
        worldUnlocked = newWorldUnlock;
        await prefs.setInt(_worldUnlockedKey, worldUnlocked);
      }
    }
  }

  Future<void> setTutorialDone() async {
    tutorialDone = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialDoneKey, true);
  }

  bool isStagePlayable(int stage) {
    return stage <= maxStage + 1;
  }

  bool isStageCleared(int stage) {
    return stage <= maxStage;
  }

  bool isWorldUnlocked(int worldId) {
    return worldId <= worldUnlocked;
  }

  int getWorldProgress(int worldId) {
    int worldStart = worldId * 20 + 1;
    int worldEnd = worldStart + 19;
    int cleared = 0;
    for (int i = worldStart; i <= worldEnd; i++) {
      if (i <= maxStage) cleared++;
    }
    return cleared;
  }
}
