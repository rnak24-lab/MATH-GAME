/// 게임 모드 (4가지 님게임)
enum GameMode {
  singleRow,  // 🪨 한 줄 님게임
  doubleRow,  // 🔮 두 줄 님게임
  pepero,     // 🍫 빼빼로 게임
  tripleRow,  // 💎 세 줄 님게임
}

extension GameModeExt on GameMode {
  String get title {
    switch (this) {
      case GameMode.singleRow: return '🪨 한 줄 님게임';
      case GameMode.doubleRow: return '🔮 두 줄 님게임';
      case GameMode.pepero: return '🍫 빼빼로 게임';
      case GameMode.tripleRow: return '💎 세 줄 님게임';
    }
  }

  String get description {
    switch (this) {
      case GameMode.singleRow: return '돌 1줄에서 1~k개 가져가기\n마지막 돌을 가져가면 짐!';
      case GameMode.doubleRow: return '돌 2줄에서 한 줄씩 가져가기\n마지막 돌을 가져가면 짐!';
      case GameMode.pepero: return '묶음을 서로 다른 두 수로 나누기\n못 나누면 짐!';
      case GameMode.tripleRow: return '돌 3줄에서 한 줄씩 가져가기\n마지막 돌을 가져가면 짐!';
    }
  }

  String get itemEmoji {
    switch (this) {
      case GameMode.singleRow: return '🪨';
      case GameMode.doubleRow: return '🔮';
      case GameMode.pepero: return '🍫';
      case GameMode.tripleRow: return '💎';
    }
  }
}

/// 게임 상태
class GameState {
  final GameMode mode;
  final int stageNumber;
  List<int> rows; // 각 줄의 돌 개수 (빼빼로: 묶음 리스트)
  int maxTake; // 한 줄 님게임에서 최대 가져갈 수
  bool isPlayerTurn;
  bool isGameOver;
  bool? playerWon;

  GameState({
    required this.mode,
    required this.stageNumber,
    required this.rows,
    this.maxTake = 3,
    this.isPlayerTurn = true,
    this.isGameOver = false,
    this.playerWon,
  });

  /// 스테이지 번호로 게임 모드 결정
  static GameMode getModeForStage(int stage) {
    if (stage <= 20) return GameMode.singleRow;
    if (stage <= 40) return GameMode.doubleRow;
    if (stage <= 60) return GameMode.pepero;
    if (stage <= 80) return GameMode.tripleRow;
    // 81~100: 혼합
    final mixIndex = (stage - 81) % 4;
    return GameMode.values[mixIndex];
  }

  /// 스테이지 번호로 월드 인덱스 (0~4)
  static int getWorldForStage(int stage) {
    if (stage <= 20) return 0;
    if (stage <= 40) return 1;
    if (stage <= 60) return 2;
    if (stage <= 80) return 3;
    return 4;
  }

  /// 스테이지 설정 생성
  factory GameState.fromStage(int stageNumber) {
    final mode = getModeForStage(stageNumber);
    switch (mode) {
      case GameMode.singleRow:
        final n = 5 + (stageNumber - 1) % 16; // 5~20개 돌
        final k = 2 + (stageNumber - 1) ~/ 5; // 최대 가져갈 수 2~5
        return GameState(
          mode: mode,
          stageNumber: stageNumber,
          rows: [n],
          maxTake: k.clamp(2, 5),
        );

      case GameMode.doubleRow:
        final localStage = stageNumber <= 40 ? stageNumber - 20 : (stageNumber - 80);
        final a = 3 + localStage % 8;
        final b = 2 + (localStage + 3) % 7;
        return GameState(
          mode: mode,
          stageNumber: stageNumber,
          rows: [a, b],
        );

      case GameMode.pepero:
        final localStage = stageNumber <= 60 ? stageNumber - 40 : (stageNumber - 80);
        final size = 4 + localStage % 12;
        return GameState(
          mode: mode,
          stageNumber: stageNumber,
          rows: [size],
        );

      case GameMode.tripleRow:
        final localStage = stageNumber <= 80 ? stageNumber - 60 : (stageNumber - 80);
        final a = 2 + localStage % 6;
        final b = 3 + (localStage + 2) % 5;
        final c = 1 + (localStage + 1) % 7;
        return GameState(
          mode: mode,
          stageNumber: stageNumber,
          rows: [a, b, c],
        );
    }
  }

  /// 총 남은 돌 수
  int get totalRemaining => rows.fold(0, (sum, r) => sum + r);

  /// 게임 종료 체크
  bool checkGameOver() {
    switch (mode) {
      case GameMode.singleRow:
      case GameMode.doubleRow:
      case GameMode.tripleRow:
        return totalRemaining == 0;
      case GameMode.pepero:
        // 모든 묶음이 1이면 더 이상 나눌 수 없음
        return rows.every((r) => r <= 1);
    }
  }

  /// 플레이어 수 실행 (한/두/세 줄: rowIndex에서 count개 가져가기)
  bool makeMove(int rowIndex, int count) {
    if (isGameOver) return false;

    if (mode == GameMode.pepero) {
      return _makePeperoMove(rowIndex, count);
    }

    if (rowIndex < 0 || rowIndex >= rows.length) return false;
    if (count < 1 || count > rows[rowIndex]) return false;
    if (mode == GameMode.singleRow && count > maxTake) return false;

    rows[rowIndex] -= count;

    if (checkGameOver()) {
      isGameOver = true;
      // 마지막 돌을 가져간 사람이 짐
      playerWon = !isPlayerTurn; // 현재 턴인 사람이 가져갔으니 그 사람이 짐
      // 즉, 가져간 사람 = 현재 턴 → 현재 턴이 짐 → 상대방 승리
      playerWon = !isPlayerTurn;
    }

    isPlayerTurn = !isPlayerTurn;
    return true;
  }

  /// 빼빼로 게임: rowIndex 묶음을 count와 (rows[rowIndex]-count)로 나누기
  bool _makePeperoMove(int rowIndex, int count) {
    if (rowIndex < 0 || rowIndex >= rows.length) return false;
    final original = rows[rowIndex];
    final other = original - count;

    // 서로 다른 두 양의 정수로 나눠야 함
    if (count <= 0 || other <= 0 || count == other) return false;

    rows[rowIndex] = count;
    rows.add(other);
    rows.sort();

    if (checkGameOver()) {
      isGameOver = true;
      playerWon = !isPlayerTurn;
    }

    isPlayerTurn = !isPlayerTurn;
    return true;
  }
}
