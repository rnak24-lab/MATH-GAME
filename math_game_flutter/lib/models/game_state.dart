enum GameMode {
  singleRow,   // 한 줄 님게임 (1-20)
  doubleRow,   // 두 줄 님게임 (21-40)
  pepero,      // 빼빼로 게임 (41-60)
  tripleRow,   // 세 줄 님게임 (61-80)
  quadRow,     // 네 줄 님게임 (81-100) — 월드5 최종 도전
}

enum TurnOwner { player, midnight }

enum GamePhase { turnChoice, playing, gameOver }

class StageConfig {
  final int stageNumber;
  final GameMode mode;
  final List<int> rows;
  final int maxTake;

  /// AI가 "이기는 포지션"에서도 실수(비최적 수)를 둘 확률 (0.0~1.0).
  /// 난이도 곡선의 핵심: 월드 초반은 높고 월드 내에서 점감,
  /// 매 10번째 스테이지(보스)는 0 = 완벽한 Midnight.
  final double blunderChance;

  const StageConfig({
    required this.stageNumber,
    required this.mode,
    required this.rows,
    required this.maxTake,
    this.blunderChance = 0.0,
  });
}
