import 'dart:math';
import '../models/game_state.dart';

class NimMove {
  final int rowIndex;
  final int count;
  // pepero용
  final int splitA;
  final int splitB;
  final bool isPepero;
  // 카일즈용: 제거 후 남는 좌/우 조각 크기
  final bool isKayles;
  final int kaylesLeft;
  final int kaylesRight;
  // 위토프용: 각 무더기에서 가져갈 개수
  final bool isWythoff;
  final int takeA;
  final int takeB;

  NimMove({
    this.rowIndex = 0,
    this.count = 1,
    this.splitA = 0,
    this.splitB = 0,
    this.isPepero = false,
    this.isKayles = false,
    this.kaylesLeft = 0,
    this.kaylesRight = 0,
    this.isWythoff = false,
    this.takeA = 0,
    this.takeB = 0,
  });

  @override
  String toString() {
    if (isPepero) return 'Split into $splitA and $splitB';
    if (isKayles) return 'Kayles take $count → [$kaylesLeft|$kaylesRight]';
    if (isWythoff) return 'Wythoff take $takeA/$takeB';
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
              int newGrundy =
                  totalGrundy ^ _grundy(piles[i]) ^ _grundy(a) ^ _grundy(b);
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

  // ── 🧪 카일즈 (Kayles) — 아무 위치 인접 1~2개 제거, 마지막 돌 = 승리 ──
  final Map<int, int> _kaylesCache = {};

  int _kaylesGrundy(int n) {
    if (n <= 0) return 0;
    if (_kaylesCache.containsKey(n)) return _kaylesCache[n]!;
    final Set<int> reachable = {};
    for (int t = 1; t <= 2 && t <= n; t++) {
      for (int left = 0; left <= n - t; left++) {
        reachable.add(_kaylesGrundy(left) ^ _kaylesGrundy(n - t - left));
      }
    }
    int mex = 0;
    while (reachable.contains(mex)) mex++;
    _kaylesCache[n] = mex;
    return mex;
  }

  NimMove kaylesAI(List<int> rows) {
    if (rows.isEmpty || rows.every((r) => r <= 0)) return NimMove(count: 0);

    int x = 0;
    for (final r in rows) {
      x ^= _kaylesGrundy(r);
    }

    if (x != 0) {
      // 필승 수 탐색
      for (int i = 0; i < rows.length; i++) {
        final n = rows[i];
        for (int t = 1; t <= 2 && t <= n; t++) {
          for (int left = 0; left <= n - t; left++) {
            final right = n - t - left;
            if (x ^
                    _kaylesGrundy(n) ^
                    _kaylesGrundy(left) ^
                    _kaylesGrundy(right) ==
                0) {
              return NimMove(
                rowIndex: i,
                count: t,
                isKayles: true,
                kaylesLeft: left,
                kaylesRight: right,
              );
            }
          }
        }
      }
    }

    // 지는 포지션 → 랜덤 수 (변수 주기)
    final valid = <NimMove>[];
    for (int i = 0; i < rows.length; i++) {
      final n = rows[i];
      for (int t = 1; t <= 2 && t <= n; t++) {
        for (int left = 0; left <= n - t; left++) {
          valid.add(NimMove(
            rowIndex: i,
            count: t,
            isKayles: true,
            kaylesLeft: left,
            kaylesRight: n - t - left,
          ));
        }
      }
    }
    if (valid.isNotEmpty) return valid[_rng.nextInt(valid.length)];
    return NimMove(count: 0);
  }

  // ── 🧪 위토프 (Wythoff) — 한쪽 마음껏 or 양쪽 같은 개수, 마지막 돌 = 승리 ──
  /// 냉(cold) 포지션: (⌊kφ⌋, ⌊kφ⌋+k) — 이 상태에서 둘 차례인 쪽이 진다.
  bool wythoffCold(int p, int q) {
    final int m = p < q ? p : q;
    final int M = p < q ? q : p;
    final int k = M - m;
    final double phi = (1 + sqrt(5)) / 2;
    return m == (k * phi).floor();
  }

  NimMove wythoffAI(List<int> rows) {
    final int a = rows[0], b = rows[1];
    if (a <= 0 && b <= 0) return NimMove(count: 0);

    if (!wythoffCold(a, b)) {
      // 필승: 냉 포지션으로 보내는 수 탐색
      for (int t = 1; t <= a; t++) {
        if (wythoffCold(a - t, b)) {
          return NimMove(isWythoff: true, takeA: t, takeB: 0);
        }
      }
      for (int t = 1; t <= b; t++) {
        if (wythoffCold(a, b - t)) {
          return NimMove(isWythoff: true, takeA: 0, takeB: t);
        }
      }
      final int mn = a < b ? a : b;
      for (int t = 1; t <= mn; t++) {
        if (wythoffCold(a - t, b - t)) {
          return NimMove(isWythoff: true, takeA: t, takeB: t);
        }
      }
    }

    // 지는 포지션 → 랜덤 (즉시 자멸 수는 피함: 전부 비우기 금지)
    final valid = <NimMove>[];
    for (int t = 1; t <= a; t++) {
      if (!(a - t == 0 && b == 0)) {
        valid.add(NimMove(isWythoff: true, takeA: t, takeB: 0));
      }
    }
    for (int t = 1; t <= b; t++) {
      if (!(a == 0 && b - t == 0)) {
        valid.add(NimMove(isWythoff: true, takeA: 0, takeB: t));
      }
    }
    final int mn = a < b ? a : b;
    for (int t = 1; t <= mn; t++) {
      if (!(a - t == 0 && b - t == 0)) {
        valid.add(NimMove(isWythoff: true, takeA: t, takeB: t));
      }
    }
    if (valid.isNotEmpty) return valid[_rng.nextInt(valid.length)];
    // 어쩔 수 없이 마지막 처리 (사실상 승리 수)
    return NimMove(isWythoff: true, takeA: a, takeB: b == a ? b : 0);
  }

  // ── 🧪 피보나치 님 — 직전 상대 수의 2배까지, 마지막 돌 = 승리 ──
  /// 제켄도르프 분해의 최소항. (n ≥ 1)
  int zeckendorfSmallest(int n) {
    final fibs = <int>[1, 2];
    while (fibs.last < n) {
      fibs.add(fibs[fibs.length - 1] + fibs[fibs.length - 2]);
    }
    int rest = n, smallest = 0;
    for (int i = fibs.length - 1; i >= 0; i--) {
      if (fibs[i] <= rest) {
        smallest = fibs[i];
        rest -= fibs[i];
      }
    }
    return smallest;
  }

  /// 현재 둘 차례가 지는 포지션인가 (남은 n, 이번 턴 최대 maxAllowed).
  bool fibonacciLosing(int n, int maxAllowed) {
    if (n <= 0) return false;
    if (n <= maxAllowed) return false; // 전부 가져가면 즉시 승리
    return zeckendorfSmallest(n) > maxAllowed;
  }

  NimMove fibonacciAI(int n, int maxAllowed) {
    if (n <= 0) return NimMove(count: 0);
    if (n <= maxAllowed) return NimMove(count: n); // 다 가져가면 승리!

    final int s = zeckendorfSmallest(n);
    if (s <= maxAllowed) return NimMove(count: s); // 필승 수

    // 지는 포지션 → 작게 랜덤 (상대의 다음 한도를 최소화 + 자멸 방지)
    int safeMax = (n - 1) ~/ 3; // c ≥ ⌈n/3⌉ 이면 상대가 나머지를 전부 가져감
    if (safeMax < 1) safeMax = 1;
    if (safeMax > maxAllowed) safeMax = maxAllowed;
    return NimMove(count: 1 + _rng.nextInt(safeMax));
  }

  /// AI가 유리한 포지션인지 (= 다음에 둘 사람이 지는 포지션인지)
  bool isAIWinning(List<int> rows, GameMode mode) {
    if (mode == GameMode.pepero) {
      int totalGrundy = 0;
      for (int p in rows) {
        totalGrundy ^= _grundy(p);
      }
      // grundy == 0이면 방금 둔 쪽이 유리 (상대가 불리)
      return totalGrundy == 0;
    }

    if (mode == GameMode.kayles) {
      int x = 0;
      for (final r in rows) {
        x ^= _kaylesGrundy(r);
      }
      return x == 0;
    }

    if (mode == GameMode.wythoff) {
      return wythoffCold(rows[0], rows.length > 1 ? rows[1] : 0);
    }

    if (mode == GameMode.fibonacci) {
      return true; // fibonacci는 maxAllowed 필요 → fibonacciLosing 사용
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
  /// 월드 순서 (2026-07-07): 한줄 → 두줄 → 세줄 → 빼빼로(최종)
  /// + 🧪 테스트 월드 3종: 카일즈(81-100) → 위토프(101-120) → 피보나치(121-140).
  StageConfig generateStage(int stageNumber) {
    GameMode mode;
    if (stageNumber <= 20) {
      mode = GameMode.singleRow;
    } else if (stageNumber <= 40) {
      mode = GameMode.doubleRow;
    } else if (stageNumber <= 60) {
      mode = GameMode.tripleRow;
    } else if (stageNumber <= 80) {
      // 61-80: 월드4 = 빼빼로(분할, Sprague-Grundy) 최종 도전
      mode = GameMode.pepero;
    } else if (stageNumber <= 100) {
      mode = GameMode.kayles;
    } else if (stageNumber <= 120) {
      mode = GameMode.wythoff;
    } else {
      mode = GameMode.fibonacci;
    }

    List<int> rows;
    int maxTake = 3;

    switch (mode) {
      case GameMode.singleRow:
        // (2026-07-02) 스테이지 1 = 튜토리얼 전용: 돌 3개, 1~2개 선택.
        // "2개를 집어봐!" 지시대로 하면 한밤이가 마지막 돌을 강제로 가져가 무조건 승리
        // → 첫 판에서 규칙(마지막 돌=패배)과 승리 감각을 동시에 학습.
        if (stageNumber == 1) {
          maxTake = 2;
          rows = [3];
          break;
        }
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
        // (2026-07-07 삭제된 월드 — 도달 불가, enum 유지용 폴백)
        rows = [3, 4, 5, 6];
        break;
      case GameMode.pepero:
        // 61-80: 최종 월드. 6개 → 20개(상한)까지 확대.
        int size = 6 + (stageNumber - 61);
        if (size > 20) size = 20;
        rows = [size];
        break;
      case GameMode.kayles:
        // 81-100: 한 줄 → 두 줄 → 세 줄로 점점 복잡하게 (인접 1~2개 제거)
        int t = stageNumber - 81; // 0~19
        maxTake = 2;
        if (t < 7) {
          rows = [5 + t]; // 5~11
        } else if (t < 14) {
          int k = t - 7;
          rows = [6 + k, 4 + k]; // ~[12,10]
        } else {
          int k = (t - 14) ~/ 2;
          rows = [7 + k, 6 + k, 4 + k];
        }
        break;
      case GameMode.wythoff:
        // 101-120: 두 무더기. 냉 포지션으로 시작하면 선공 필패라 피한다.
        int t = stageNumber - 101; // 0~19
        int a = 3 + t;
        int b = a + 2 + (t % 3);
        if (wythoffCold(a, b)) b += 1;
        rows = [a, b];
        break;
      case GameMode.fibonacci:
        // 121-140: 한 무더기. 피보나치 수로 시작하면 선공 필패라 피한다.
        int t = stageNumber - 121; // 0~19
        int n = 6 + t; // 6~25
        const fibsSet = {8, 13, 21};
        if (fibsSet.contains(n)) n += 1;
        rows = [n];
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
