import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 진행도가 바뀌면 notifyListeners()로 알림 —
/// 화면들이 pushReplacement 연쇄 후 뒤로가기해도 즉시 최신 상태를 그린다.
class StageManager extends ChangeNotifier {
  static const String _maxStageKey = 'max_stage';
  static const String _clearedKey = 'cleared_stages';
  static const String _worldUnlockedKey = 'world_unlocked';
  static const String _boardUnlockedKey = 'board_world_unlocked';
  static const String _tutorialDoneKey = 'tutorial_done';
  static const String _dailyWinsKey = 'daily_wins';
  static const String _dailyDoneKey = 'daily_done_date';
  static const String _dailyStreakKey = 'daily_streak';
  static const String _dailyLastKey = 'daily_last_date';
  static const String _ruleIntroKey = 'rule_intro_seen';

  /// 클리어한 최고 스테이지 (홈 화면 "이어하기" 표시용).
  int maxStage = 0;
  int worldUnlocked = 0;

  /// 보드 게임 층(7~11)의 해금 상태 — 님게임 층과 독립적으로 돈다.
  int boardWorldUnlocked = firstBoardWorld;
  bool tutorialDone = false;

  /// 스테이지별 클리어 기록.
  /// 월드 조기 오픈(빠른 패스)으로 순차 진행이 깨질 수 있어 셋으로 관리.
  final Set<int> _cleared = <int>{};

  // ── (2026-09-16 대표님) "클리어할 이유" — 수업(월드)별 이야기 ──
  // 호감도 게이지 없음. 한 수업에서 5·15판 = 짧은 이야기, 10판 = 큰 이야기, 20판 = 긴 이야기.
  // 열림 여부는 월드 클리어 수로만 결정되므로 "본 기록"이 필요 없다 (노트에서 언제든 다시 봄).
  int dailyWins = 0;
  String dailyDoneDate = ''; // yyyyMMdd — 오늘 이미 이겼으면 오늘 날짜
  int dailyStreak = 0;
  String _dailyLastDate = '';

  int get clearCount => _cleared.length;

  /// 규칙 설명 화면을 본 수업(1~12). 수업 첫 판에 들어갈 때 한 번 뜬다.
  final Set<int> _ruleIntroSeen = <int>{};
  bool ruleIntroSeen(int world) => _ruleIntroSeen.contains(world);
  Future<void> markRuleIntroSeen(int world) async {
    if (!_ruleIntroSeen.add(world)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_ruleIntroKey, _ruleIntroSeen.map((e) => '$e').toList());
  }

  /// 이 월드에서 지금까지 클리어한 판 수 (클리어 한마디 로테이션용)
  int worldClears(int stageNumber) => getWorldProgress((stageNumber - 1) ~/ 20);

  // ── 오늘의 한 판 ──
  static String todayKey() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  }

  bool get dailyDoneToday => dailyDoneDate == todayKey();

  /// 오늘의 한 판 승리 기록. 연속 출석은 "어제도 이겼으면 +1, 아니면 1".
  Future<void> recordDailyWin() async {
    if (dailyDoneToday) return;
    final today = todayKey();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yKey = '${yesterday.year}${yesterday.month.toString().padLeft(2, '0')}${yesterday.day.toString().padLeft(2, '0')}';
    dailyStreak = _dailyLastDate == yKey ? dailyStreak + 1 : 1;
    _dailyLastDate = today;
    dailyDoneDate = today;
    dailyWins++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyWinsKey, dailyWins);
    await prefs.setString(_dailyDoneKey, dailyDoneDate);
    await prefs.setInt(_dailyStreakKey, dailyStreak);
    await prefs.setString(_dailyLastKey, _dailyLastDate);
    notifyListeners();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    maxStage = prefs.getInt(_maxStageKey) ?? 0;
    worldUnlocked = prefs.getInt(_worldUnlockedKey) ?? 0;
    boardWorldUnlocked = prefs.getInt(_boardUnlockedKey) ?? firstBoardWorld;
    tutorialDone = prefs.getBool(_tutorialDoneKey) ?? false;
    dailyWins = prefs.getInt(_dailyWinsKey) ?? 0;
    dailyDoneDate = prefs.getString(_dailyDoneKey) ?? '';
    dailyStreak = prefs.getInt(_dailyStreakKey) ?? 0;
    _dailyLastDate = prefs.getString(_dailyLastKey) ?? '';
    _ruleIntroSeen
      ..clear()
      ..addAll((prefs.getStringList(_ruleIntroKey) ?? const []).map(int.parse));

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
  static const int _reviewUnlockFrom = 7;

  /// 보드 게임 층이 시작하는 월드 id (매점=춉). 이 월드는 항상 열려 있다.
  static const int firstBoardWorld = 7;

  /// 마지막 월드 id — 정식 7월드(0~6) + 버전2 보드 게임 5월드(7~11).
  static const int _lastWorldId = 11;

  /// 두 사슬을 따로 계산한다.
  ///  - 님게임 층: 0 → 6 순차 (이전 월드 3판)
  ///  - 보드 층: 7은 항상, 8 → 11 순차 (이전 보드 월드 3판). 님게임 진도와 무관.
  Future<void> _recalculateWorldUnlocked() async {
    int unlocked = 0;
    for (int w = 1; w < firstBoardWorld; w++) {
      if (getWorldProgress(w - 1) >= _unlockClearsNeeded) {
        unlocked = w;
      } else {
        break;
      }
    }
    int board = firstBoardWorld;
    for (int w = firstBoardWorld + 1; w <= _lastWorldId; w++) {
      if (getWorldProgress(w - 1) >= _unlockClearsNeeded) {
        board = w;
      } else {
        break;
      }
    }
    if (unlocked != worldUnlocked || board != boardWorldUnlocked) {
      worldUnlocked = unlocked;
      boardWorldUnlocked = board;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_worldUnlockedKey, worldUnlocked);
      await prefs.setInt(_boardUnlockedKey, boardWorldUnlocked);
    }
  }

  /// 진행도 전체 초기화 (설정 화면 — 확인 다이얼로그 후 호출).
  Future<void> resetProgress() async {
    _cleared.clear();
    maxStage = 0;
    worldUnlocked = 0;
    boardWorldUnlocked = firstBoardWorld;
    dailyWins = 0;
    dailyDoneDate = '';
    dailyStreak = 0;
    _dailyLastDate = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_clearedKey);
    await prefs.remove(_maxStageKey);
    await prefs.remove(_worldUnlockedKey);
    await prefs.remove(_boardUnlockedKey);
    await prefs.remove(_dailyWinsKey);
    await prefs.remove(_dailyDoneKey);
    await prefs.remove(_dailyStreakKey);
    await prefs.remove(_dailyLastKey);
    _ruleIntroSeen.clear();
    await prefs.remove(_ruleIntroKey);
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
    if (worldId >= firstBoardWorld) return worldId <= boardWorldUnlocked;
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
