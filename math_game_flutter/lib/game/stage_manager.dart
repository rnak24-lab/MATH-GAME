import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 진행도가 바뀌면 notifyListeners()로 알림 —
/// 화면들이 pushReplacement 연쇄 후 뒤로가기해도 즉시 최신 상태를 그린다.
class StageManager extends ChangeNotifier {
  static const String _maxStageKey = 'max_stage';
  static const String _clearedKey = 'cleared_stages';
  static const String _worldUnlockedKey = 'world_unlocked';
  static const String _tutorialDoneKey = 'tutorial_done';

  /// 클리어한 최고 스테이지 (홈 화면 "이어하기" 표시용).
  int maxStage = 0;
  int worldUnlocked = 0;
  bool tutorialDone = false;

  /// 스테이지별 클리어 기록.
  /// 월드 조기 오픈(빠른 패스)으로 순차 진행이 깨질 수 있어 셋으로 관리.
  final Set<int> _cleared = <int>{};

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    maxStage = prefs.getInt(_maxStageKey) ?? 0;
    worldUnlocked = prefs.getInt(_worldUnlockedKey) ?? 0;
    tutorialDone = prefs.getBool(_tutorialDoneKey) ?? false;

    _cleared.clear();
    final saved = prefs.getStringList(_clearedKey);
    if (saved != null) {
      _cleared.addAll(saved.map(int.parse));
    } else if (maxStage > 0) {
      // 구버전 세이브 마이그레이션: 순차 진행 전제 → 1..maxStage 전부 클리어 처리
      for (int i = 1; i <= maxStage; i++) {
        _cleared.add(i);
      }
      await prefs.setStringList(
          _clearedKey, _cleared.map((e) => '$e').toList());
    }
    // 언락 규칙이 바뀌었을 수 있으므로 로드 시 1회 재계산
    await _recalculateWorldUnlocked();
  }

  Future<void> clearStage(int stage) async {
    final prefs = await SharedPreferences.getInstance();
    if (_cleared.add(stage)) {
      await prefs.setStringList(
          _clearedKey, _cleared.map((e) => '$e').toList());
    }
    if (stage > maxStage) {
      maxStage = stage;
      await prefs.setInt(_maxStageKey, maxStage);
    }
    await _recalculateWorldUnlocked();
    notifyListeners();
  }

  /// 월드 해금 규칙 (빠른 패스):
  /// 월드 0은 항상 해금. 월드 W(1~4)는 이전 월드 W-1에서 **3판만 클리어하면** 해금.
  /// 공식을 이미 아는 플레이어는 지루한 구간을 빠르게 넘어갈 수 있고,
  /// 20판 전부 깨는 완주는 별개의 목표로 남는다.
  static const int _unlockClearsNeeded = 3;

  /// 🧪 검수용 플래그 — 켜면 전 월드/전 스테이지가 즉시 열린다.
  /// 출시본은 반드시 false. (대표님 검토 빌드를 만들 때만 true)
  static const bool kReviewUnlockTestWorlds = false;

  /// 검수 해금 시작 월드 id.
  static const int _reviewUnlockFrom = 3;

  /// 마지막 월드 id — 정식 4월드(0~3) + 테스트 3월드(4~6).
  static const int _lastWorldId = 6;

  Future<void> _recalculateWorldUnlocked() async {
    int unlocked = 0;
    for (int w = 1; w <= _lastWorldId; w++) {
      if (getWorldProgress(w - 1) >= _unlockClearsNeeded) {
        unlocked = w;
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

  /// 진행도 전체 초기화 (설정 화면 — 확인 다이얼로그 후 호출).
  Future<void> resetProgress() async {
    _cleared.clear();
    maxStage = 0;
    worldUnlocked = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_clearedKey);
    await prefs.remove(_maxStageKey);
    await prefs.remove(_worldUnlockedKey);
    notifyListeners();
  }

  Future<void> setTutorialDone() async {
    tutorialDone = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialDoneKey, true);
  }

  /// 플레이 가능 조건:
  /// - 해당 월드가 해금되어 있고,
  /// - 월드의 첫 스테이지이거나 직전 스테이지를 클리어했을 때 (월드 내 순차 진행).
  bool isStagePlayable(int stage) {
    // 🧪 검수 모드일 때만 아무 스테이지나 진입 (출시본에선 플래그가 false라 무효)
    if (kReviewUnlockTestWorlds) return true;
    int world = (stage - 1) ~/ 20;
    if (!isWorldUnlocked(world)) return false;
    int worldStart = world * 20 + 1;
    return stage == worldStart || _cleared.contains(stage - 1);
  }

  bool isStageCleared(int stage) {
    return _cleared.contains(stage);
  }

  bool isWorldUnlocked(int worldId) {
    if (kReviewUnlockTestWorlds &&
        worldId >= _reviewUnlockFrom &&
        worldId <= _lastWorldId) {
      return true;
    }
    return worldId <= worldUnlocked;
  }

  int getWorldProgress(int worldId) {
    int worldStart = worldId * 20 + 1;
    int cleared = 0;
    for (int i = worldStart; i < worldStart + 20; i++) {
      if (_cleared.contains(i)) cleared++;
    }
    return cleared;
  }
}
