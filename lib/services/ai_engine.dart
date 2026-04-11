import '../models/game_state.dart';

/// AI 전략 엔진 - 수아의 두뇌
class AIEngine {
  /// AI의 최적 수 계산
  static ({int rowIndex, int count}) getBestMove(GameState state) {
    switch (state.mode) {
      case GameMode.singleRow:
        return _singleRowMove(state);
      case GameMode.doubleRow:
        return _multiRowMove(state);
      case GameMode.tripleRow:
        return _multiRowMove(state);
      case GameMode.pepero:
        return _peperoMove(state);
    }
  }

  /// 한 줄 님게임 AI
  /// 미제르 님: 마지막 가져가면 짐
  /// 필승 전략: (k+1)의 배수 + 1개를 남기면 됨
  static ({int rowIndex, int count}) _singleRowMove(GameState state) {
    final n = state.rows[0];
    final k = state.maxTake;

    // EC-01 가드: 게임 종료 상태 (돌이 0 이하)
    if (n <= 0) return (rowIndex: 0, count: 0);

    // 미제르 님: 상대에게 1을 남기면 이김
    // n을 (k+1)로 나눈 나머지가 1이면 현재 플레이어가 불리
    final remainder = (n - 1) % (k + 1);

    if (remainder == 0) {
      // 불리한 상황 → 아무거나 1개 가져감
      return (rowIndex: 0, count: 1);
    } else {
      // 유리한 상황 → remainder만큼 가져가서 상대에게 불리한 수 남김
      final take = remainder.clamp(1, k);
      return (rowIndex: 0, count: take);
    }
  }

  /// 두/세 줄 님게임 AI (Sprague-Grundy / XOR 전략)
  /// 미제르 님: 모든 줄이 ≤1일 때 짝수 줄이 남으면 이김
  static ({int rowIndex, int count}) _multiRowMove(GameState state) {
    final rows = state.rows;

    // EC-02 가드: 모든 줄이 0이면 게임 종료 상태
    if (rows.isEmpty || rows.every((r) => r == 0)) {
      return (rowIndex: 0, count: 0);
    }

    // XOR (nim-sum) 계산
    int nimSum = 0;
    for (final r in rows) {
      nimSum ^= r;
    }

    // 미제르(misère) 님 조정
    // 모든 pile이 ≤1인지 체크
    final allSmall = rows.every((r) => r <= 1);

    if (allSmall) {
      // 1인 줄의 개수가 홀수이면 → 하나 가져가서 짝수로 만듦
      final onesCount = rows.where((r) => r == 1).length;
      if (onesCount % 2 == 1) {
        // 1인 줄 하나에서 가져감
        final idx = rows.indexWhere((r) => r == 1);
        return (rowIndex: idx, count: 1);
      } else {
        // 이미 짝수 → 불리, 아무거나
        final idx = rows.indexWhere((r) => r == 1);
        if (idx >= 0) return (rowIndex: idx, count: 1);
        return (rowIndex: 0, count: 1);
      }
    }

    if (nimSum == 0) {
      // 불리한 상황 → 가장 큰 줄에서 1개 가져감
      int maxIdx = 0;
      for (int i = 1; i < rows.length; i++) {
        if (rows[i] > rows[maxIdx]) maxIdx = i;
      }
      return (rowIndex: maxIdx, count: 1);
    }

    // 유리한 상황 → nim-sum을 0으로 만드는 수
    for (int i = 0; i < rows.length; i++) {
      final target = rows[i] ^ nimSum;
      if (target < rows[i]) {
        int take = rows[i] - target;

        // 미제르 조정: 이 수를 둔 후 모든 pile ≤1인지 체크
        final remaining = List<int>.from(rows);
        remaining[i] -= take;
        if (remaining.every((r) => r <= 1)) {
          final onesAfter = remaining.where((r) => r == 1).length;
          // 미제르에서는 홀수개의 1을 남겨야 상대가 짐
          if (onesAfter % 2 == 0) {
            // 조정: 1개 더/덜 가져감
            if (take > 1) {
              take -= 1;
            } else if (rows[i] - take - 1 >= 0) {
              take += 1;
            }
          }
        }

        return (rowIndex: i, count: take);
      }
    }

    // fallback
    return (rowIndex: 0, count: 1);
  }

  /// 빼빼로 게임 AI
  /// Grundy 값 기반 전략
  static ({int rowIndex, int count}) _peperoMove(GameState state) {
    final piles = state.rows;

    // EC-03/04 가드: 빈 배열이거나 모든 파일이 분할 불가(3 미만)
    if (piles.isEmpty || piles.every((p) => p < 3)) {
      return (rowIndex: 0, count: 0);
    }

    // 현재 XOR of Grundy values
    int totalGrundy = 0;
    for (final p in piles) {
      totalGrundy ^= _peperoGrundy(p);
    }

    // 나눌 수 있는 묶음 찾아서 시도
    for (int i = 0; i < piles.length; i++) {
      final pile = piles[i];
      if (pile <= 2) continue; // 나눌 수 없음

      // 가능한 분할 시도
      for (int a = 1; a < pile; a++) {
        final b = pile - a;
        if (a >= b || a == b) continue; // 서로 다른 두 수, a < b

        final newGrundy = totalGrundy ^ _peperoGrundy(pile) ^ _peperoGrundy(a) ^ _peperoGrundy(b);
        if (newGrundy == 0) {
          return (rowIndex: i, count: a); // pile을 a와 b로 나눔
        }
      }
    }

    // 불리한 상황 → 나눌 수 있는 첫 묶음에서 아무렇게나 나눔
    for (int i = 0; i < piles.length; i++) {
      if (piles[i] >= 3) {
        return (rowIndex: i, count: 1);
      }
    }

    return (rowIndex: 0, count: 1);
  }

  /// 빼빼로 게임 Grundy 값 (메모이제이션)
  static final Map<int, int> _grundyCache = {};

  static int _peperoGrundy(int n) {
    if (n <= 2) return 0; // 나눌 수 없음
    if (_grundyCache.containsKey(n)) return _grundyCache[n]!;

    final reachable = <int>{};
    for (int a = 1; a < n; a++) {
      final b = n - a;
      if (a < b) {
        reachable.add(_peperoGrundy(a) ^ _peperoGrundy(b));
      }
    }

    // mex (minimum excludant)
    int mex = 0;
    while (reachable.contains(mex)) {
      mex++;
    }

    _grundyCache[n] = mex;
    return mex;
  }

  /// 현재 상태에서 AI가 유리한지 판별
  static bool isAIWinning(GameState state) {
    switch (state.mode) {
      case GameMode.singleRow:
        final n = state.rows[0];
        final k = state.maxTake;
        final remainder = (n - 1) % (k + 1);
        // AI 턴이면 remainder != 0일 때 유리
        return state.isPlayerTurn ? remainder == 0 : remainder != 0;

      case GameMode.doubleRow:
      case GameMode.tripleRow:
        int nimSum = 0;
        for (final r in state.rows) {
          nimSum ^= r;
        }
        return state.isPlayerTurn ? nimSum == 0 : nimSum != 0;

      case GameMode.pepero:
        int totalGrundy = 0;
        for (final p in state.rows) {
          totalGrundy ^= _peperoGrundy(p);
        }
        return state.isPlayerTurn ? totalGrundy == 0 : totalGrundy != 0;
    }
  }

  /// 힌트: 플레이어에게 최적의 수 알려주기
  static String getHint(GameState state) {
    final move = getBestMove(state);

    switch (state.mode) {
      case GameMode.singleRow:
        return '${move.count}개를 가져가세요!';
      case GameMode.doubleRow:
      case GameMode.tripleRow:
        return '${move.rowIndex + 1}번째 줄에서 ${move.count}개를 가져가세요!';
      case GameMode.pepero:
        final pile = state.rows[move.rowIndex];
        final other = pile - move.count;
        return '${pile}을 ${move.count}와 $other로 나누세요!';
    }
  }
}
