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

  const StageConfig({
    required this.stageNumber,
    required this.mode,
    required this.rows,
    required this.maxTake,
  });
}
