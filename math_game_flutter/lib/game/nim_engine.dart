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

  /// 한 줄 님게임 AI — (2026-09-15) 노멀 플레이: 마지막 간식을 가져가는 사람이 **이긴다**.
  /// 남은 수 n 이 (maxTake+1) 의 배수면 둘 차례가 진다. 아니면 n % (maxTake+1) 개를 가져가
  /// 상대에게 배수를 남긴다.
  NimMove singleRowAI(int stones, int maxTake) {
    // EC-01 가드: 게임 종료 상태 (돌이 0 이하)
    if (stones <= 0) return NimMove(count: 0);

    int target = stones % (maxTake + 1);
    if (target == 0) {
      // 지는 포지션 -> 랜덤한 개수(1 ~ min(maxTake, stones))로 가져가 변수를 줌
      int maxC = maxTake < stones ? maxTake : stones;
      return NimMove(count: 1 + _rng.nextInt(maxC));
    }
    return NimMove(count: target);
  }

  /// 다중 줄 님게임 AI (XOR 전략) — 노멀 플레이라 미제르 종반 예외가 없다.
  NimMove multiRowAI(List<int> rows) {
    // EC-02 가드: 모든 줄이 0이면 게임 종료 상태
    if (rows.isEmpty || rows.every((r) => r == 0)) {
      return NimMove(count: 0);
    }

    int nimSum = 0;
    for (int r in rows) {
      nimSum ^= r;
    }

    if (nimSum != 0) {
      // 이기는 수 찾기: 어떤 줄을 rows[i] ^ nimSum 으로 줄이면 XOR 이 0
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

  /// 지금 둘 차례가 "이미 진 포지션" 인가 (완벽한 상대 기준).
  /// 모든 모드는 노멀 플레이(마지막을 가져가면 승리 / 못 두면 패배).
  ///  - singleRow: n % (maxTake+1) == 0
  ///  - double/triple: XOR == 0
  ///  - pepero: 쪼갤 게 없거나 그런디 XOR == 0
  ///  - kayles / wythoff: 각 그런디·냉 포지션
  ///  - fibonacci: 제켄도르프 최소항 > 이번 턴 한도
  bool toMoveLoses(List<int> rows, GameMode mode,
      {int maxTake = 3, int fibLimit = 0}) {
    switch (mode) {
      case GameMode.singleRow:
        if (rows.isEmpty || rows[0] <= 0) return false;
        return rows[0] % (maxTake + 1) == 0;
      case GameMode.fibonacci:
        return fibonacciLosing(rows[0], fibLimit);
      case GameMode.pepero:
        if (rows.every((p) => p < 3)) return true;
        int g = 0;
        for (int p in rows) {
          g ^= _grundy(p);
        }
        return g == 0;
      case GameMode.kayles:
        int x = 0;
        for (final r in rows) {
          x ^= _kaylesGrundy(r);
        }
        return x == 0;
      case GameMode.wythoff:
        return wythoffCold(rows[0], rows.length > 1 ? rows[1] : 0);
      case GameMode.doubleRow:
      case GameMode.tripleRow:
      case GameMode.quadRow:
        int nimSum = 0;
        for (int r in rows) {
          nimSum ^= r;
        }
        return nimSum == 0;
    }
  }

  /// AI가 유리한 포지션인지 (= 다음에 둘 사람이 지는 포지션인지)
  bool isAIWinning(List<int> rows, GameMode mode,
          {int maxTake = 3, int fibLimit = 0}) =>
      toMoveLoses(rows, mode, maxTake: maxTake, fibLimit: fibLimit);

  /// 모드별 최선 수 — 힌트·가이드("하늘색 따라 두기")·되감기가 같은 함수를 쓴다.
  NimMove bestMove(List<int> rows, GameMode mode,
      {int maxTake = 3, int fibLimit = 0}) {
    switch (mode) {
      case GameMode.singleRow:
        return singleRowAI(rows[0], maxTake);
      case GameMode.pepero:
        return peperoAI(rows);
      case GameMode.kayles:
        return kaylesAI(rows);
      case GameMode.wythoff:
        return wythoffAI(rows);
      case GameMode.fibonacci:
        return fibonacciAI(rows[0], fibLimit);
      case GameMode.doubleRow:
      case GameMode.tripleRow:
      case GameMode.quadRow:
        return multiRowAI(rows);
    }
  }

  /// 아무 합법 수 하나 — 예린의 "봐주기"(초반 두 판) 용. 즉시 이기는 수(전부 가져가기)는 피한다.
  NimMove randomMove(List<int> rows, GameMode mode,
      {int maxTake = 3, int fibLimit = 0}) {
    switch (mode) {
      case GameMode.singleRow:
      case GameMode.fibonacci:
        final int n = rows[0];
        if (n <= 0) return NimMove(count: 0);
        final int lim = mode == GameMode.fibonacci ? fibLimit : maxTake;
        int m = lim < n ? lim : n;
        if (m >= n && n > 1) m = n - 1; // 전부 가져가면 승리 수라 봐주기가 아님
        if (m < 1) m = 1;
        return NimMove(count: 1 + _rng.nextInt(m));
      case GameMode.pepero:
        final splittable = <int>[
          for (int i = 0; i < rows.length; i++)
            if (rows[i] >= 3) i
        ];
        if (splittable.isEmpty) return NimMove(isPepero: true);
        final int pi = splittable[_rng.nextInt(splittable.length)];
        final int n = rows[pi];
        int a;
        do {
          a = 1 + _rng.nextInt(n - 1);
        } while (a == n - a);
        final int b = n - a;
        return NimMove(
            rowIndex: pi, splitA: a < b ? a : b, splitB: a < b ? b : a, isPepero: true);
      case GameMode.kayles:
        final valid = <NimMove>[];
        for (int i = 0; i < rows.length; i++) {
          final n = rows[i];
          for (int t = 1; t <= 2 && t <= n; t++) {
            for (int left = 0; left <= n - t; left++) {
              valid.add(NimMove(
                  rowIndex: i, count: t, isKayles: true, kaylesLeft: left, kaylesRight: n - t - left));
            }
          }
        }
        return valid.isEmpty ? NimMove(count: 0) : valid[_rng.nextInt(valid.length)];
      case GameMode.wythoff:
        final int a = rows[0], b = rows.length > 1 ? rows[1] : 0;
        final valid = <NimMove>[];
        for (int t = 1; t <= a; t++) {
          if (!(a - t == 0 && b == 0)) valid.add(NimMove(isWythoff: true, takeA: t, takeB: 0));
        }
        for (int t = 1; t <= b; t++) {
          if (!(a == 0 && b - t == 0)) valid.add(NimMove(isWythoff: true, takeA: 0, takeB: t));
        }
        final int mn = a < b ? a : b;
        for (int t = 1; t <= mn; t++) {
          if (!(a - t == 0 && b - t == 0)) valid.add(NimMove(isWythoff: true, takeA: t, takeB: t));
        }
        return valid.isEmpty
            ? NimMove(isWythoff: true, takeA: a, takeB: b == a ? b : 0)
            : valid[_rng.nextInt(valid.length)];
      case GameMode.doubleRow:
      case GameMode.tripleRow:
      case GameMode.quadRow:
        final nonEmpty = <int>[
          for (int i = 0; i < rows.length; i++)
            if (rows[i] > 0) i
        ];
        if (nonEmpty.isEmpty) return NimMove(count: 0);
        final int ri = nonEmpty[_rng.nextInt(nonEmpty.length)];
        int m = rows[ri];
        if (nonEmpty.length == 1 && m > 1) m -= 1; // 마지막 줄을 싹 비우면 승리 수
        return NimMove(rowIndex: ri, count: 1 + _rng.nextInt(m));
    }
  }

  /// 초기 판에서 선공(= 항상 플레이어)이 완벽하게 두면 이기는가.
  /// (2026-09-15 대표님) 선공 선택을 없애고 항상 플레이어가 먼저 두므로,
  /// 모든 스테이지는 이 값이 true 여야 한다. [generateStage] 가 보장한다.
  bool firstMoverWins(StageConfig c) {
    final int fibLimit = c.mode == GameMode.fibonacci ? c.rows[0] - 1 : 0;
    return !toMoveLoses(c.rows, c.mode,
        maxTake: c.maxTake, fibLimit: fibLimit);
  }

  /// 오늘의 한 판 — 날짜 시드로 전 세계 같은 판. 플레이어가 아는 모드 안에서 낸다.
  /// [nimWorldUnlocked] 0 = 한 줄만, 1 = 두 줄까지, 2+ = 세 줄까지. 선수 필승 보장.
  StageConfig dailyStage(int seed, int nimWorldUnlocked) {
    final r = Random(seed);
    final int pick = r.nextInt(nimWorldUnlocked.clamp(0, 2) + 1);
    GameMode mode;
    List<int> rows;
    int maxTake = 3;
    if (pick == 0) {
      mode = GameMode.singleRow;
      maxTake = 2 + r.nextInt(3); // 2~4
      rows = [12 + r.nextInt(17)]; // 12~28
    } else if (pick == 1) {
      mode = GameMode.doubleRow;
      rows = [4 + r.nextInt(9), 4 + r.nextInt(9)];
    } else {
      mode = GameMode.tripleRow;
      rows = [2 + r.nextInt(6), 3 + r.nextInt(6), 4 + r.nextInt(6)];
    }
    StageConfig cfg = StageConfig(stageNumber: 0, mode: mode, rows: rows, maxTake: maxTake);
    int guard = 0;
    while (!firstMoverWins(cfg) && guard++ < 8) {
      final b = List<int>.from(cfg.rows);
      b[b.length - 1] += 1;
      cfg = StageConfig(stageNumber: 0, mode: mode, rows: b, maxTake: maxTake);
    }
    return cfg;
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
        // (2026-09-15) 노멀 플레이 튜토리얼: 4개, 1~2개 선택. "1개 가져가 봐" → 예린이
        // 1~2개 → "남은 거 다 가져가!" 로 마지막 간식 = 승리를 손으로 배운다.
        if (stageNumber == 1) {
          maxTake = 2;
          rows = [4];
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
        // 61-80: 그런디 값이 0인 크기(7·10·20·23·26)는 선공이 지므로 표에서 뺐다.
        const sizes = [
          6, 8, 9, 11, 12, 13, 14, 15, 16, 17,
          18, 19, 21, 22, 24, 25, 27, 28, 29, 30,
        ];
        rows = [sizes[(stageNumber - 61).clamp(0, 19)]];
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

    // ── 선수 필승 보장 가드 (2026-09-15) ──
    // 플레이어가 항상 먼저 두므로, 초기 판이 "둘 차례 패배" 면 크기를 1씩 키워
    // 선공 승 판으로 옮긴다. (한 줄 4·6·8, 카일즈 95·96 등이 여기서 교정된다)
    StageConfig cfg = StageConfig(
      stageNumber: stageNumber,
      mode: mode,
      rows: rows,
      maxTake: maxTake,
    );
    int guard = 0;
    while (!firstMoverWins(cfg) && guard++ < 8) {
      final bumped = List<int>.from(cfg.rows);
      bumped[bumped.length - 1] += 1;
      cfg = StageConfig(
        stageNumber: stageNumber,
        mode: mode,
        rows: bumped,
        maxTake: maxTake,
      );
    }
    return cfg;
  }
}
