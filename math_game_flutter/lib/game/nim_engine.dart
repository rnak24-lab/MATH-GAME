import 'dart:math';
import '../models/game_state.dart';

class NimMove {
  final int rowIndex;
  final int count;
  // pepero용
  final int splitA;
  final int splitB;
  final bool isPepero;

  NimMove({
    this.rowIndex = 0,
    this.count = 1,
    this.splitA = 0,
    this.splitB = 0,
    this.isPepero = false,
  });

  @override
  String toString() {
    if (isPepero) return 'Split into $splitA and $splitB';
    return 'Take $count from row $rowIndex';
  }
}

class NimEngine {
  // Grundy 캐시 (빼빼로용)
  final Map<String, int> _grundyCache = {};
  final Random _rng = Random();

  /// 랜덤 한 줄 수: 가능하면 "마지막 돌 가져가기(즉시 패배)"는 피한다.
  int _randomSingleTake(int stones, int maxTake) {
    int maxC = maxTake < stones ? maxTake : stones;
    // 마지막 돌을 집으면 즉시 패배(미제르) → 다른 선택지가 있으면 회피
    if (maxC >= stones && stones > 1) maxC = stones - 1;
    if (maxC < 1) maxC = 1;
    return 1 + _rng.nextInt(maxC);
  }

  /// 한 줄 님게임 AI.
  /// [blunder]: 이기는 포지션에서도 이 확률로 비최적 수(실수)를 둔다 — 난이도 곡선용.
  NimMove singleRowAI(int stones, int maxTake, {double blunder = 0}) {
    // EC-01 가드: 게임 종료 상태 (돌이 0 이하)
    if (stones <= 0) return NimMove(count: 0);

    // (n-1) % (maxTake+1) == 0 이면 지는 포지션
    int target = (stones - 1) % (maxTake + 1);
    if (target == 0) {
      // 지는 포지션 -> 랜덤한 개수로 가져가 변수를 줌 (자살수는 회피)
      return NimMove(count: _randomSingleTake(stones, maxTake));
    }
    // 이기는 포지션이지만 실수 확률 체크 (역전 기회 창출)
    if (blunder > 0 && _rng.nextDouble() < blunder) {
      int c = _randomSingleTake(stones, maxTake);
      if (c != target) return NimMove(count: c);
      // 우연히 최적수와 같으면 그대로 (자연스러움)
    }
    return NimMove(count: target);
  }

  /// 랜덤 다중 줄 수: 가능하면 "전체 마지막 돌 가져가기(즉시 패배)"는 피한다.
  NimMove _randomMultiMove(List<int> rows) {
    final nonEmpty = <int>[
      for (int i = 0; i < rows.length; i++)
        if (rows[i] > 0) i
    ];
    if (nonEmpty.isEmpty) return NimMove(count: 1);
    int total = rows.fold(0, (a, b) => a + b);
    int ri = nonEmpty[_rng.nextInt(nonEmpty.length)];
    int take = 1 + _rng.nextInt(rows[ri]);
    // 이 수로 전체가 0이 되면(마지막 돌 = 즉시 패배) 한 개 덜 가져가기
    if (take == total && take > 1) take -= 1;
    return NimMove(rowIndex: ri, count: take);
  }

  /// 다중 줄 님게임 AI (XOR 전략).
  /// [blunder]: 이기는 포지션에서도 이 확률로 비최적 수(실수)를 둔다.
  NimMove multiRowAI(List<int> rows, {double blunder = 0}) {
    // EC-02 가드: 모든 줄이 0이면 게임 종료 상태
    if (rows.isEmpty || rows.every((r) => r == 0)) {
      return NimMove(count: 0);
    }

    // 실수 확률 체크 (역전 기회 창출) — 어차피 지는 포지션이면 아래 랜덤 분기와 동일
    if (blunder > 0 && _rng.nextDouble() < blunder) {
      return _randomMultiMove(rows);
    }

    int nimSum = 0;
    for (int r in rows) {
      nimSum ^= r;
    }

    // 엔드게임: 남은 줄이 모두 1 이하
    if (rows.every((r) => r <= 1)) {
      // 홀수개 줄이 남아있으면 1개 가져감
      for (int i = 0; i < rows.length; i++) {
        if (rows[i] == 1) {
          return NimMove(rowIndex: i, count: 1);
        }
      }
    }

    // 1보다 큰 줄이 정확히 1개
    int bigRowCount = rows.where((r) => r > 1).length;
    int oneRowCount = rows.where((r) => r == 1).length;

    if (bigRowCount == 1) {
      int bigIdx = rows.indexWhere((r) => r > 1);
      // 1인 줄의 개수가 짝수면 -> bigRow를 0으로
      // 1인 줄의 개수가 홀수면 -> bigRow를 1로
      int target = (oneRowCount % 2 == 0) ? 0 : 1;
      int take = rows[bigIdx] - target;
      if (take > 0) {
        return NimMove(rowIndex: bigIdx, count: take);
      }
    }

    if (nimSum != 0) {
      // 이기는 수 찾기
      for (int i = 0; i < rows.length; i++) {
        if (rows[i] > 0) {
          int target = rows[i] ^ nimSum;
          if (target < rows[i]) {
            return NimMove(rowIndex: i, count: rows[i] - target);
          }
        }
      }
    }

    // 지는 포지션 -> 랜덤한 줄/개수로 가져가 변수를 줌 (자살수 회피)
    return _randomMultiMove(rows);
  }

  /// 랜덤 분할 수 (빼빼로).
  NimMove _randomSplitMove(List<int> piles) {
    final splittable = <int>[
      for (int i = 0; i < piles.length; i++)
        if (piles[i] >= 3) i
    ];
    if (splittable.isEmpty) {
      return NimMove(isPepero: true, splitA: 1, splitB: 1);
    }
    int pi = splittable[_rng.nextInt(splittable.length)];
    int n = piles[pi];
    int a;
    do {
      a = 1 + _rng.nextInt(n - 1); // 1 ~ n-1
    } while (a == n - a); // 균등 분할 금지
    int b = n - a;
    if (a > b) {
      final t = a;
      a = b;
      b = t;
    }
    return NimMove(rowIndex: pi, splitA: a, splitB: b, isPepero: true);
  }

  /// 빼빼로 게임 AI.
  /// [blunder]: 이기는 포지션에서도 이 확률로 비최적 분할(실수)을 한다.
  NimMove peperoAI(List<int> piles, {double blunder = 0}) {
    // EC-03/04 가드: 빈 배열이거나 모든 파일이 분할 불가(3 미만)
    if (piles.isEmpty || piles.every((p) => p < 3)) {
      return NimMove(isPepero: true, splitA: 0, splitB: 0);
    }

    // 실수 확률 체크 (역전 기회 창출)
    if (blunder > 0 && _rng.nextDouble() < blunder) {
      return _randomSplitMove(piles);
    }

    // Grundy 값 계산
    int totalGrundy = 0;
    for (int p in piles) {
      totalGrundy ^= _grundy(p);
    }

    if (totalGrundy != 0) {
      // 이기는 수 찾기
      for (int i = 0; i < piles.length; i++) {
        if (piles[i] >= 3) {
          // 가능한 분할 시도
          for (int a = 1; a < piles[i]; a++) {
            int b = piles[i] - a;
            if (a != b && a < b) {
              int newGrundy = totalGrundy ^ _grundy(piles[i]) ^ _grundy(a) ^ _grundy(b);
              if (newGrundy == 0) {
                return NimMove(
                  rowIndex: i,
                  splitA: a,
                  splitB: b,
                  isPepero: true,
                );
              }
            }
          }
        }
      }
    }

    // 지는 포지션 -> 랜덤한 더미를 랜덤하게 분할해 변수를 줌
    return _randomSplitMove(piles);
  }

  int _grundy(int n) {
    if (n <= 2) return 0;
    String key = '$n';
    if (_grundyCache.containsKey(key)) return _grundyCache[key]!;

    Set<int> reachable = {};
    for (int a = 1; a < n; a++) {
      int b = n - a;
      if (a != b && a < b) {
        reachable.add(_grundy(a) ^ _grundy(b));
      }
    }

    int mex = 0;
    while (reachable.contains(mex)) mex++;
    _grundyCache[key] = mex;
    return mex;
  }

  /// AI가 유리한 포지션인지 (nimsum == 0 -> 방금 둔 쪽이 유리)
  bool isAIWinning(List<int> rows, GameMode mode) {
    if (mode == GameMode.pepero) {
      int totalGrundy = 0;
      for (int p in rows) {
        totalGrundy ^= _grundy(p);
      }
      // grundy == 0이면 방금 둔 쪽이 유리 (상대가 불리)
      return totalGrundy == 0;
    }

    if (mode == GameMode.singleRow) {
      return true; // singleRow는 별도 maxTake 필요
    }

    // doubleRow / tripleRow / quadRow: 일반 NIM XOR
    int nimSum = 0;
    for (int r in rows) {
      nimSum ^= r;
    }
    return nimSum == 0;
  }

  /// 스테이지별 AI 실수율 — 난이도 곡선의 핵심.
  ///
  /// 설계 원칙 (한붓그리기류 캐주얼 퍼즐 벤치마크):
  /// 1. "모든 스테이지는 이길 수 있어야 한다" — AI가 완벽하면 선공 선택을
  ///    틀린 순간 필패 = 퍼즐이 아니라 시험. 실수율이 역전 창을 만든다.
  /// 2. 월드 내 점감(45%→0%) = 완만한 상승 곡선.
  /// 3. 매 10번째 스테이지(보스)는 실수율 0 = 완벽한 Midnight —
  ///    배운 필승 전략을 "증명"하는 관문. 주기적 스파이크.
  /// 4. 뒷 월드일수록 베이스 실수율이 낮아짐 (전체 게임 곡선).
  double blunderChanceFor(int stageNumber) {
    int world = ((stageNumber - 1) ~/ 20).clamp(0, 4); // 0..4
    int inWorld = (stageNumber - 1) % 20 + 1; // 1..20
    if (inWorld % 10 == 0) return 0.0; // 보스 스테이지(10·20번째): 완벽 AI
    const bases = [0.45, 0.35, 0.30, 0.22, 0.15];
    double t = (inWorld - 1) / 19.0; // 0.0 → 1.0
    return bases[world] * (1.0 - t);
  }

  /// 스테이지 설정 생성
  StageConfig generateStage(int stageNumber) {
    GameMode mode;
    if (stageNumber <= 20) {
      mode = GameMode.singleRow;
    } else if (stageNumber <= 40) {
      mode = GameMode.doubleRow;
    } else if (stageNumber <= 60) {
      mode = GameMode.pepero;
    } else if (stageNumber <= 80) {
      mode = GameMode.tripleRow;
    } else {
      // 81-100: 월드5 = 네 줄 님게임 (quadRow) 최종 도전
      // (id=1201) 대표님 확정: 기존 "섞어서" 구조 폐기, quadRow 전용으로 교체.
      mode = GameMode.quadRow;
    }

    List<int> rows;
    int maxTake = 3;

    switch (mode) {
      case GameMode.singleRow:
        // 기본 최저 난이도 상승: 1~1 제한 폐지, 최소 1~2 선택.
        // NIM 필승 전략(nimber, (n-1) % (maxTake+1)) 보존.
        int n = 7 + (stageNumber - 1) * 2;
        if (n > 30) n = 30;
        // maxTake 최소 2 보장 (플레이어는 항상 1개 또는 2개 선택 가능)
        maxTake = 2 + (stageNumber ~/ 5);
        if (maxTake > 5) maxTake = 5;
        rows = [n];
        break;
      case GameMode.doubleRow:
        int base = 3 + (stageNumber - 21);
        rows = [base, base + 2];
        break;
      case GameMode.pepero:
        int size = 6 + (stageNumber - 41);
        if (size > 20) size = 20;
        rows = [size];
        break;
      case GameMode.tripleRow:
        int base = 2 + (stageNumber - 61) ~/ 3;
        rows = [base, base + 1, base + 3];
        break;
      case GameMode.quadRow:
        // (id=1201) 월드5 quadRow: 점진 증가
        // stage 81: [3, 4, 5, 6] → stage 100: [12, 14, 16, 18]
        // 각 행별 증가분 (9, 10, 11, 12) / 19스테이지 선형 보간.
        int step = stageNumber - 81; // 0 ~ 19
        int r0 = 3 + (step * 9) ~/ 19;
        int r1 = 4 + (step * 10) ~/ 19;
        int r2 = 5 + (step * 11) ~/ 19;
        int r3 = 6 + (step * 12) ~/ 19;
        rows = [r0, r1, r2, r3];
        break;
    }

    return StageConfig(
      stageNumber: stageNumber,
      mode: mode,
      rows: rows,
      maxTake: maxTake,
      blunderChance: blunderChanceFor(stageNumber),
    );
  }
}
