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
    }
    // 월드 언락 체크는 clearStage 조건과 독립적으로 매번 재계산
    // (id=1140) 규칙: 이전 월드 "마지막 3스테이지(18/19/20번 = 글로벌 stage-2/-1/0)" 모두 클리어 시 다음 월드 해금.
    await _recalculateWorldUnlocked();
  }

  /// (id=1140) 해금 규칙 재계산.
  /// 월드 0(첫 월드)은 항상 해금. 월드 W(1~4)는 이전 월드 W-1의 마지막 3스테이지가 모두 클리어되면 해금.
  /// 이전 월드 W-1의 마지막 3스테이지 = 글로벌 stage (W*20 - 2), (W*20 - 1), (W*20).
  Future<void> _recalculateWorldUnlocked() async {
    int unlocked = 0; // 월드 0은 기본 해금
    for (int w = 1; w <= 4; w++) {
      int lastStageOfPrevWorld = w * 20;
      int first = lastStageOfPrevWorld - 2;
      // 마지막 3스테이지(연속) 모두 클리어 여부 = maxStage >= lastStageOfPrevWorld
      // (stage-by-stage 순차 클리어 전제에서는 동치)
      if (maxStage >= lastStageOfPrevWorld) {
        unlocked = w;
      } else if (maxStage >= first) {
        // 부분 클리어 중: 아직 3개 전부 못깬 상태 → 해금 안 됨
        break;
      } else {
        break;
      }
    }
    if (unlocked != worldUnlocked) {
      worldUnlocked = unlocked;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_worldUnlockedKey, worldUnlocked);
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
