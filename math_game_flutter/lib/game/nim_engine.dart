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

  /// 한 줄 님게임 AI
  NimMove singleRowAI(int stones, int maxTake) {
    // EC-01 가드: 게임 종료 상태 (돌이 0 이하)
    if (stones <= 0) return NimMove(count: 0);

    // (n-1) % (maxTake+1) == 0 이면 지는 포지션
    int target = (stones - 1) % (maxTake + 1);
    if (target == 0) {
      // 지는 포지션 -> 랜덤한 개수(1 ~ min(maxTake, stones))로 가져가 변수를 줌
      int maxC = maxTake < stones ? maxTake : stones;
      return NimMove(count: 1 + _rng.nextInt(maxC));
    }
    return NimMove(count: target);
  }

  /// 다중 줄 님게임 AI (XOR 전략)
  NimMove multiRowAI(List<int> rows) {
    // EC-02 가드: 모든 줄이 0이면 게임 종료 상태
    if (rows.isEmpty || rows.every((r) => r == 0)) {
      return NimMove(count: 0);
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

    // 지는 포지션 -> 랜덤한 줄에서 랜덤한 개수로 가져가 변수를 줌
    final nonEmpty = <int>[
      for (int i = 0; i < rows.length; i++)
        if (rows[i] > 0) i
    ];
    if (nonEmpty.isNotEmpty) {
      int ri = nonEmpty[_rng.nextInt(nonEmpty.length)];
      int take = 1 + _rng.nextInt(rows[ri]);
      return NimMove(rowIndex: ri, count: take);
    }

    return NimMove(count: 1);
  }

  /// 빼빼로 게임 AI
  NimMove peperoAI(List<int> piles) {
    // EC-03/04 가드: 빈 배열이거나 모든 파일이 분할 불가(3 미만)
    if (piles.isEmpty || piles.every((p) => p < 3)) {
      return NimMove(isPepero: true, splitA: 0, splitB: 0);
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
    final splittable = <int>[
      for (int i = 0; i < piles.length; i++)
        if (piles[i] >= 3) i
    ];
    if (splittable.isNotEmpty) {
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

    return NimMove(isPepero: true, splitA: 1, splitB: 1);
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

  /// 스테이지 설정 생성.
  ///
  /// 월드 순서 (2026-07-02 대표님 확정 — 개념 난이도 사다리 재배치):
  /// 한줄 → 두줄(거울 전략) → 세줄 → 네줄 → **빼빼로(Grundy, 최종 보스 월드)**.
  /// 빼빼로가 가장 어려운 개념이므로 마지막 월드로 이동.
  StageConfig generateStage(int stageNumber) {
    GameMode mode;
    if (stageNumber <= 20) {
      mode = GameMode.singleRow;
    } else if (stageNumber <= 40) {
      mode = GameMode.doubleRow;
    } else if (stageNumber <= 60) {
      mode = GameMode.tripleRow;
    } else if (stageNumber <= 80) {
      mode = GameMode.quadRow;
    } else {
      // 81-100: 월드5 = 빼빼로(분할, Sprague-Grundy) 최종 도전
      mode = GameMode.pepero;
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
      case GameMode.tripleRow:
        // 41-60 (재배치: 기존 61-80 공식을 새 구간으로 이동)
        int base = 2 + (stageNumber - 41) ~/ 3;
        rows = [base, base + 1, base + 3];
        break;
      case GameMode.quadRow:
        // 61-80 (재배치): stage 61: [3,4,5,6] → stage 80: [12,14,16,18]
        // 각 행별 증가분 (9, 10, 11, 12) / 19스테이지 선형 보간.
        int step = stageNumber - 61; // 0 ~ 19
        int r0 = 3 + (step * 9) ~/ 19;
        int r1 = 4 + (step * 10) ~/ 19;
        int r2 = 5 + (step * 11) ~/ 19;
        int r3 = 6 + (step * 12) ~/ 19;
        rows = [r0, r1, r2, r3];
        break;
      case GameMode.pepero:
        // 81-100 (재배치): 최종 월드. 6개 → 20개(상한)까지 확대.
        int size = 6 + (stageNumber - 81);
        if (size > 20) size = 20;
        rows = [size];
        break;
    }

    return StageConfig(
      stageNumber: stageNumber,
      mode: mode,
      rows: rows,
      maxTake: maxTake,
    );
  }
}
