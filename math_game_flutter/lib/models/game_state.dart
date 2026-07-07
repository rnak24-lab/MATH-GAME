enum GameMode {
  singleRow, // 한 줄 님게임 (1-20) — 마지막 돌 = 패배
  doubleRow, // 두 줄 님게임 (21-40) — 마지막 돌 = 패배
  pepero, // 빼빼로 게임 (61-80) — 못 쪼개면 패배
  tripleRow, // 세 줄 님게임 (41-60) — 마지막 돌 = 패배
  quadRow, // (2026-07-07 삭제 — enum 유지용)
  // ── 🧪 테스트 모드 3종 (2026-07-07, 대표님 검수용) — 전부 "마지막 돌 = 승리" ──
  kayles, // 카일즈 (81-100): 아무 위치 인접 1~2개 제거, 줄이 쪼개짐
  wythoff, // 위토프 (101-120): 한쪽 마음껏 or 양쪽 같은 개수
  fibonacci, // 피보나치 님 (121-140): 직전 상대 수의 2배까지, 첫 수 전부 금지
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
