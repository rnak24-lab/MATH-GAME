/// (2026-09-15 대표님) 승리 조건은 전 모드 **노멀 플레이**로 통일:
/// 마지막 간식을 가져가는 사람이 이긴다 / 더 둘 수 없는 사람이 진다.
/// (예전 님게임 3모드의 미제르 "마지막 = 패배" 는 폐지 — 규칙이 층마다 뒤집혀 혼란)
enum GameMode {
  singleRow, // 한 줄 님게임 (1-20) — 마지막 = 승리
  doubleRow, // 두 줄 님게임 (21-40) — 마지막 = 승리
  pepero, // 막대과자 게임 (61-80) — 못 쪼개면 패배
  tripleRow, // 세 줄 님게임 (41-60) — 마지막 = 승리
  quadRow, // (2026-07-07 삭제 — enum 유지용)
  // ── 변형 3종 (2026-07-07) — "마지막 돌 = 승리" ──
  kayles, // 카일즈 (81-100): 아무 위치 인접 1~2개 제거, 줄이 쪼개짐
  wythoff, // 위토프 (101-120): 한쪽 마음껏 or 양쪽 같은 개수
  fibonacci, // 피보나치 님 (121-140): 직전 상대 수의 2배까지, 첫 수 전부 금지
}

enum TurnOwner { player, midnight }

/// (2026-09-15) 선공 선택 단계 삭제 — 항상 플레이어가 먼저 둔다.
enum GamePhase { playing, gameOver }

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
