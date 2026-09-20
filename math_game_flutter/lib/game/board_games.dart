import 'dart:math' as math;
import 'dart:typed_data';

/// ─────────────────────────────────────────────────────────────────────────
/// 월드 8~12 — "공식을 알아도 끝나지 않는" 보드 게임 5종.
///   141-160 춉(Chomp)          161-180 점과 상자(Dots & Boxes)
///   181-200 심(Sim)             201-220 스프라우트(Sprouts, 직선 변형)
///   221-240 헥스(Hex)
///
/// 기존 NimEngine 은 `List<int> rows` 한 모양에 묶여 있어, 격자/선/그래프 상태를
/// 가진 이 게임들은 별도 엔진으로 둔다. 화면(board_game_screen.dart)도 형제 화면.
///
/// 편의상 side 0 = 플레이어, side 1 = 예린(AI). 엔진은 side 번호만 안다.
/// ─────────────────────────────────────────────────────────────────────────

enum BoardKind { chomp, dotsBoxes, sim, sprouts, hex }

/// 스테이지 번호 → 게임 종류 (141 이상만 유효)
BoardKind boardKindForStage(int stage) {
  final int t = (stage - 141) ~/ 20;
  const kinds = BoardKind.values;
  return kinds[t.clamp(0, kinds.length - 1)];
}

/// 첫 보드 게임 스테이지 번호 / 마지막 스테이지 번호
const int kBoardFirstStage = 141;
const int kBoardLastStage = 240;
const int kTotalStages = 240;

bool isBoardStage(int stage) => stage >= kBoardFirstStage;

/// 월드 안에서의 진행도 0~19
int _tOf(int stage) => ((stage - kBoardFirstStage) % 20).clamp(0, 19);

/// 예린의 실수 확률 (보드 게임 층 전용).
/// (2026-09-12 대표님) 난이도 단계는 하나. 판 크기가 스테이지마다 커지는 걸로 어려워진다.
/// 대신 **초중반에만** 이 확률로 실수하고, 종반(각 게임의 inEndgame)에 들어가면 완벽하게 둔다.
/// → 초중반 빌드업을 잘한 사람이 이긴다. 종반만 잘 둬서 이기는 건 막는다.
const double kBoardBlunder = 0.2;

double blunderRateForStage(int stage) => kBoardBlunder;

/// 수 하나. 종류별 의미:
///   chomp: (a=행, b=열)   dots: a=변 번호   sim: a=선 번호
///   sprouts: (a=점 i, b=점 j)   hex: a=칸 번호
class BoardMove {
  final int a;
  final int b;
  const BoardMove(this.a, [this.b = 0]);

  @override
  bool operator ==(Object other) =>
      other is BoardMove && other.a == a && other.b == b;
  @override
  int get hashCode => a * 1000003 + b;
  @override
  String toString() => 'M($a,$b)';
}

class _DotsSpec {
  final int r, c;
  final List<int> pre; // 예린이 미리 그어 둔 변 번호
  const _DotsSpec(this.r, this.c, this.pre);
}

/// 점과 상자 20판 — tool/dots_gen.dart 출력 (둘 차례 = 플레이어 필승이 증명된 시작 판)
const List<_DotsSpec> _dotsStages = [
  _DotsSpec(1, 1, [1]), // 161: 자유 변 3, 선공 +1
  _DotsSpec(1, 3, [2]), // 162: 자유 변 9, 선공 +1
  _DotsSpec(1, 3, [2, 4, 8]), // 163: 자유 변 7, 선공 +1
  _DotsSpec(1, 5, [1]), // 164: 자유 변 15, 선공 +1
  _DotsSpec(1, 5, [1, 12, 14]), // 165: 자유 변 13, 선공 +1
  _DotsSpec(1, 7, [13]), // 166: 자유 변 21, 선공 +1
  _DotsSpec(1, 7, [0, 6, 7]), // 167: 자유 변 19, 선공 +1
  _DotsSpec(3, 3, [8]), // 168: 자유 변 23, 선공 +3
  _DotsSpec(3, 3, [5]), // 169: 자유 변 23, 선공 +3
  _DotsSpec(3, 3, [5, 7, 16]), // 170: 자유 변 21, 선공 +3
  _DotsSpec(3, 3, [2, 3, 22]), // 171: 자유 변 21, 선공 +3
  _DotsSpec(3, 3, [1, 7, 17, 20, 23]), // 172: 자유 변 19, 선공 +3
  _DotsSpec(3, 3, [2, 6, 12, 16, 20]), // 173: 자유 변 19, 선공 +3
  _DotsSpec(3, 3, [0, 1, 5, 9, 12, 18, 22]), // 174: 자유 변 17, 선공 +3
  _DotsSpec(3, 3, [2, 3, 4, 5, 7, 13, 22]), // 175: 자유 변 17, 선공 +3
  // 3x5 는 자유 변 18개(기기에서 첫 수부터 완전 풀이) — 뒤로 갈수록 여유(마진)가 줄어든다
  _DotsSpec(3, 5, [0, 1, 2, 3, 5, 10, 11, 14, 16, 17, 18, 19, 22, 24, 25, 28, 29, 31, 32, 35]), // 176: 선공 +7
  _DotsSpec(3, 5, [0, 1, 2, 3, 4, 11, 13, 15, 18, 19, 21, 23, 25, 26, 27, 30, 31, 32, 34, 37]), // 177: 선공 +7
  _DotsSpec(3, 5, [1, 3, 4, 10, 11, 12, 13, 15, 16, 17, 18, 19, 20, 21, 23, 25, 26, 29, 31, 37]), // 178: 선공 +3
  _DotsSpec(3, 5, [0, 1, 2, 4, 6, 15, 16, 17, 20, 23, 25, 26, 27, 29, 30, 31, 33, 35, 36, 37]), // 179: 선공 +3
  _DotsSpec(3, 5, [0, 1, 2, 3, 4, 8, 11, 15, 17, 18, 20, 22, 25, 28, 30, 31, 32, 34, 36, 37]), // 180: 선공 +1
];

abstract class BoardGame {
  BoardKind get kind;

  /// 지금 둘 차례 (0 = 플레이어, 1 = 예린)
  int toMove = 0;

  bool get isOver;

  /// 끝났을 때 이긴 쪽. 안 끝났으면 null.
  int? get winner;

  List<BoardMove> legalMoves();

  /// 수를 둔다. 점과 상자처럼 "한 번 더" 가 있으면 toMove 를 유지한다.
  void apply(BoardMove m);

  BoardGame clone();

  /// 턴 배너 오른쪽에 들어갈 한 줄 요약
  String summary();

  /// 최선의 수 (힌트 / 완벽 AI)
  BoardMove bestMove();

  /// 지금 둘 차례가 "이미 진 포지션" 인가? 확실히 알 수 없으면 false.
  /// (힌트 전구 반짝임과 예린 표정에 쓰인다 — 틀려도 게임 진행엔 영향 없음)
  bool toMoveIsLosing();

  /// 종반인가? 여기부터 예린은 실수하지 않는다. 게임마다 "끝나기 n수 전"의 기준이 다르다.
  bool inEndgame();

  /// 실수로 둘 만한 수 — 최선은 아니지만 바보 같지도 않은 수. 기본은 아무 수.
  List<BoardMove> plausibleMistakes() => legalMoves();

  final math.Random _rng = math.Random();

  /// 실수 확률을 섞은 AI 수. 종반이면 무조건 최선.
  BoardMove aiMove(double blunder) {
    final moves = legalMoves();
    if (moves.isEmpty) return const BoardMove(-1);
    if (blunder > 0 && !inEndgame() && _rng.nextDouble() < blunder) {
      final pool = plausibleMistakes();
      if (pool.isNotEmpty) return pool[_rng.nextInt(pool.length)];
    }
    return bestMove();
  }

  /// 스테이지에 맞는 초기 판을 만든다.
  static BoardGame forStage(int stage) {
    final int t = _tOf(stage);
    switch (boardKindForStage(stage)) {
      case BoardKind.chomp:
        // 독+1칸(1x2)부터 7x8까지. 20단계 전부 다른 크기.
        const sizes = [
          [1, 2], [1, 3], [2, 2], [2, 3], [2, 4], [3, 3], [3, 4], [3, 5], [4, 4], [4, 5],
          [4, 6], [5, 5], [5, 6], [5, 7], [5, 8], [6, 6], [6, 7], [6, 8], [7, 7], [7, 8],
        ];
        return ChompGame(sizes[t][0], sizes[t][1]);
      case BoardKind.dotsBoxes:
        // (2026-09-20 출시 전 전수 점검) 빈 판은 1x1·1x3·1x5·1x7·3x3 전부 **선공 패**(완전 풀이).
        // 그래서 심처럼 예린이 선을 몇 개 미리 그어 둔 판에서 시작한다. 표의 20판은
        // tool/dots_gen.dart 가 "둘 차례(플레이어) 최선 결과 +1 이상"을 DP 로 증명한 시작 판이다.
        // 상자 수는 전부 홀수 → 무승부 없음.
        final spec = _dotsStages[t];
        return DotsBoxesGame(spec.r, spec.c)..preDraw(spec.pre);
      case BoardKind.sim:
        // 심은 점 6개가 규칙 자체라 판 크기가 없다. 20단계 동일.
        // (2026-09-15) K6 심은 후공 필승이 증명된 게임 → 예린이 먼저 한 줄을 그어 둔
        // 판에서 플레이어가 시작한다. 그러면 플레이어가 "후공" 이 되어 필승 쪽이다.
        // K6 는 대칭이라 어느 선이든 같다 — 스테이지마다 다른 선을 골라 그림만 바꾼다.
        return SimGame()
          ..toMove = 1
          ..apply(BoardMove(t % 15));
      case BoardKind.sprouts:
        // (2026-09-20) 완전 탐색 결과: 점 2개 = 선공 승, 점 3·4·5개 = **선공 패**.
        // 그래서 3개부터는 예린이 한 줄을 먼저 잇고 시작한다(지는 자리에서 어떤 수를 둬도
        // 다음 차례가 이기므로, 플레이어 필승). 점 6개는 증명할 수 없어 뺐다.
        const ns = [2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5];
        final g = SproutsGame.circle(ns[t]);
        if (ns[t] >= 3) {
          g.toMove = 1;
          final first = g.legalMoves();
          // 점 5개: (1,4)·(2,4) 로 시작하면 이론상 이기지만 엔진 힌트가 못 따라간다
          // (tool/sprouts_pre.dart 측정) → 힌트가 끝까지 맞는 첫 선만 쓴다.
          const good5 = [0, 1, 2, 3, 4, 5, 7, 9];
          final int i = ns[t] == 5 ? good5[t % good5.length] : t % first.length;
          g.apply(first[i]);
        }
        return g;
      case BoardKind.hex:
        // 3x3(가운데 잡으면 끝)부터 8x8까지
        const ns = [3, 3, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6, 6, 7, 7, 7, 7, 8, 8, 8];
        return HexGame(ns[t]);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 1. 춉 — 독이 든 초콜릿
//    rows[i] = i번째 행에 남은 칸 수 (위에서부터). 항상 비증가(영 다이어그램).
//    (r,c) 를 먹으면 r 이후 모든 행이 c 칸으로 잘린다. (0,0) 이 독.
// ═══════════════════════════════════════════════════════════════════════════
class ChompGame extends BoardGame {
  final int rowsN;
  final int colsN;
  List<int> rows;

  ChompGame(this.rowsN, this.colsN)
      : rows = List<int>.filled(rowsN, colsN, growable: true);
  ChompGame._(this.rowsN, this.colsN, this.rows);

  @override
  BoardKind get kind => BoardKind.chomp;

  /// 독만 남았으면 둘 차례가 진다 (독을 먹을 수밖에 없으니).
  @override
  bool get isOver => rows.length == 1 && rows[0] == 1;

  @override
  int? get winner => isOver ? 1 - toMove : null;

  bool cellAlive(int r, int c) => r < rows.length && c < rows[r];

  @override
  List<BoardMove> legalMoves() {
    final out = <BoardMove>[];
    for (int r = 0; r < rows.length; r++) {
      for (int c = 0; c < rows[r]; c++) {
        if (r == 0 && c == 0) continue; // 독은 "수" 가 아니라 패배
        out.add(BoardMove(r, c));
      }
    }
    return out;
  }

  @override
  void apply(BoardMove m) {
    for (int i = m.a; i < rows.length; i++) {
      if (rows[i] > m.b) rows[i] = m.b;
    }
    while (rows.isNotEmpty && rows.last == 0) {
      rows.removeLast();
    }
    toMove = 1 - toMove;
  }

  @override
  BoardGame clone() =>
      ChompGame._(rowsN, colsN, List<int>.from(rows))..toMove = toMove;

  @override
  String summary() => rows.fold<int>(0, (s, r) => s + r).toString();

  // 승패 완전 탐색 (영 다이어그램 개수가 작아 메모로 충분)
  static final Map<String, bool> _winCache = {};

  static bool _win(List<int> rows) {
    if (rows.length == 1 && rows[0] == 1) return false; // 독만 남음 = 둘 차례 패배
    final key = rows.join(',');
    final cached = _winCache[key];
    if (cached != null) return cached;
    bool result = false;
    outer:
    for (int r = 0; r < rows.length; r++) {
      for (int c = 0; c < rows[r]; c++) {
        if (r == 0 && c == 0) continue;
        final next = List<int>.from(rows);
        for (int i = r; i < next.length; i++) {
          if (next[i] > c) next[i] = c;
        }
        while (next.isNotEmpty && next.last == 0) {
          next.removeLast();
        }
        if (!_win(next)) {
          result = true;
          break outer;
        }
      }
    }
    _winCache[key] = result;
    return result;
  }

  @override
  bool toMoveIsLosing() => !_win(rows);

  /// 종반: 독 포함 6칸 이하
  @override
  bool inEndgame() => rows.fold<int>(0, (s, r) => s + r) <= 6;

  @override
  BoardMove bestMove() {
    final moves = legalMoves();
    final wins = <BoardMove>[];
    for (final m in moves) {
      final g = clone() as ChompGame;
      g.apply(m);
      if (!_win(g.rows)) wins.add(m);
    }
    if (wins.isNotEmpty) return wins[_rng.nextInt(wins.length)];
    // 지는 포지션: 가장 조금 먹는 수로 버틴다 (판을 오래 끌어 상대 실수 유도)
    moves.sort((x, y) {
      final gx = clone() as ChompGame..apply(x);
      final gy = clone() as ChompGame..apply(y);
      return gy.rows.fold<int>(0, (s, r) => s + r) -
          gx.rows.fold<int>(0, (s, r) => s + r);
    });
    return moves.first;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 2. 점과 상자
//    상자 R x C. 가로변 h[r][c] (r 0..R, c 0..C-1), 세로변 v[r][c] (r 0..R-1, c 0..C)
//    변 번호: 가로 = r*C + c,  세로 = H + r*(C+1) + c
// ═══════════════════════════════════════════════════════════════════════════
class DotsBoxesGame extends BoardGame {
  final int R;
  final int C;
  late final int hCount; // (R+1)*C
  late final int edgeCount;
  List<bool> drawn;
  List<int> owner; // 상자 R*C, -1 = 없음
  List<int> score = [0, 0];

  DotsBoxesGame(this.R, this.C)
      : drawn = [],
        owner = [] {
    hCount = (R + 1) * C;
    edgeCount = hCount + R * (C + 1);
    drawn = List.filled(edgeCount, false);
    owner = List.filled(R * C, -1);
  }

  DotsBoxesGame._(this.R, this.C, this.drawn, this.owner, this.score) {
    hCount = (R + 1) * C;
    edgeCount = hCount + R * (C + 1);
  }

  @override
  BoardKind get kind => BoardKind.dotsBoxes;

  /// 예린이 미리 그어 둔 선 (상자를 완성하지 않는 선들). 점수·차례에 영향 없음.
  final Set<int> preDrawn = <int>{};
  void preDraw(List<int> edges) {
    for (final e in edges) {
      drawn[e] = true;
      preDrawn.add(e);
    }
  }

  // ── 완전 풀이 (남은 변 ≤ _exactMax) — 표는 clone 끼리 공유 ──
  static const int _exactMax = 18;
  List<int>? _xFree; // 풀이 시점의 자유 변
  Int8List? _xVal; // 부분집합(그 뒤에 그어진 변) → 둘 차례의 앞으로 마진

  void _ensureExact() {
    if (_xVal != null) return;
    final free = [for (int e = 0; e < edgeCount; e++) if (!drawn[e]) e];
    if (free.length > _exactMax) return;
    final f = free.length;
    final idx = {for (int i = 0; i < f; i++) free[i]: i};
    final boxFree = List<int>.filled(R * C, 0);
    for (int r = 0; r < R; r++) {
      for (int c = 0; c < C; c++) {
        for (final e in boxEdges(r, c)) {
          final i = idx[e];
          if (i != null) boxFree[r * C + c] |= 1 << i;
        }
      }
    }
    final boxesOfFree = [
      for (final e in free) [for (final b in boxesOfEdge(e)) b[0] * C + b[1]]
    ];
    final n = 1 << f;
    final val = Int8List(n);
    for (int mask = n - 2; mask >= 0; mask--) {
      int best = -100;
      for (int i = 0; i < f; i++) {
        final bit = 1 << i;
        if (mask & bit != 0) continue;
        final nm = mask | bit;
        int gain = 0;
        for (final b in boxesOfFree[i]) {
          if (nm & boxFree[b] == boxFree[b]) gain++;
        }
        final v = gain > 0 ? gain + val[nm] : -val[nm];
        if (v > best) best = v;
      }
      val[mask] = best;
    }
    _xFree = free;
    _xVal = val;
  }

  int _xMask() {
    int m = 0;
    final free = _xFree!;
    for (int i = 0; i < free.length; i++) {
      if (drawn[free[i]]) m |= 1 << i;
    }
    return m;
  }

  /// 완전 풀이가 가능하면 최선 수들, 아니면 null
  List<BoardMove>? _exactBest() {
    _ensureExact();
    final val = _xVal;
    if (val == null) return null;
    final free = _xFree!;
    final mask = _xMask();
    int best = -100;
    final out = <BoardMove>[];
    for (int i = 0; i < free.length; i++) {
      final bit = 1 << i;
      if (mask & bit != 0) continue;
      final gain = boxesOfEdge(free[i]).where((b) => boxSides(b[0], b[1]) == 3).length;
      final v = gain > 0 ? gain + val[mask | bit] : -val[mask | bit];
      if (v > best) {
        best = v;
        out.clear();
      }
      if (v == best) out.add(BoardMove(free[i]));
    }
    return out;
  }

  int hIdx(int r, int c) => r * C + c;
  int vIdx(int r, int c) => hCount + r * (C + 1) + c;
  bool isH(int e) => e < hCount;

  /// 상자 (r,c) 의 네 변
  List<int> boxEdges(int r, int c) =>
      [hIdx(r, c), hIdx(r + 1, c), vIdx(r, c), vIdx(r, c + 1)];

  int boxSides(int r, int c) {
    int n = 0;
    for (final e in boxEdges(r, c)) {
      if (drawn[e]) n++;
    }
    return n;
  }

  /// 변 e 에 붙은 상자들
  List<List<int>> boxesOfEdge(int e) {
    final out = <List<int>>[];
    if (isH(e)) {
      final r = e ~/ C, c = e % C;
      if (r > 0) out.add([r - 1, c]);
      if (r < R) out.add([r, c]);
    } else {
      final k = e - hCount;
      final r = k ~/ (C + 1), c = k % (C + 1);
      if (c > 0) out.add([r, c - 1]);
      if (c < C) out.add([r, c]);
    }
    return out;
  }

  @override
  bool get isOver => !drawn.contains(false);

  @override
  int? get winner {
    if (!isOver) return null;
    if (score[0] == score[1]) return 1; // 짝수 판은 안 쓰지만 안전장치
    return score[0] > score[1] ? 0 : 1;
  }

  @override
  List<BoardMove> legalMoves() => [
        for (int e = 0; e < edgeCount; e++)
          if (!drawn[e]) BoardMove(e),
      ];

  @override
  void apply(BoardMove m) {
    drawn[m.a] = true;
    bool got = false;
    for (final b in boxesOfEdge(m.a)) {
      if (boxSides(b[0], b[1]) == 4 && owner[b[0] * C + b[1]] < 0) {
        owner[b[0] * C + b[1]] = toMove;
        score[toMove]++;
        got = true;
      }
    }
    if (!got) toMove = 1 - toMove; // 상자를 먹으면 한 번 더
  }

  @override
  BoardGame clone() {
    final g = DotsBoxesGame._(R, C, List<bool>.from(drawn), List<int>.from(owner),
        List<int>.from(score))
      ..toMove = toMove;
    g.preDrawn.addAll(preDrawn);
    g._xFree = _xFree;
    g._xVal = _xVal;
    return g;
  }

  @override
  String summary() => '${score[0]} : ${score[1]}';

  /// 이 변을 그으면 상자가 완성되는가
  bool completes(int e) =>
      boxesOfEdge(e).any((b) => boxSides(b[0], b[1]) == 3);

  /// 이 변을 그으면 상대에게 3면짜리 상자를 넘겨주는가
  bool givesAway(int e) =>
      boxesOfEdge(e).any((b) => boxSides(b[0], b[1]) == 2);

  /// 종반: 남은 변 12개 이하 — 사슬을 거둬들이는 구간. 여기선 완전 탐색으로 완벽하게.
  @override
  bool inEndgame() => legalMoves().length <= 12;

  /// 실수: 먹을 상자를 놓치거나, 상대에게 3면짜리를 넘겨주는 변.
  /// (사람이 초중반에 실제로 하는 실수 — 파리티 계산 안 하고 아무 데나 긋기)
  @override
  List<BoardMove> plausibleMistakes() {
    final moves = legalMoves();
    final give = moves.where((m) => givesAway(m.a) && !completes(m.a)).toList();
    if (give.isNotEmpty) return give;
    return moves.where((m) => !completes(m.a)).toList();
  }

  /// 정책: ① 먹을 수 있으면 먹는다 ② 안전한 변 ③ 가장 적게 내주는 변.
  /// 남은 변이 적으면 완전 탐색.
  @override
  BoardMove bestMove() {
    final moves = legalMoves();
    final exact = _exactBest();
    if (exact != null && exact.isNotEmpty) return exact[_rng.nextInt(exact.length)];
    final take = moves.where((m) => completes(m.a)).toList();
    if (take.isNotEmpty) return take[_rng.nextInt(take.length)];
    final safe = moves.where((m) => !givesAway(m.a)).toList();
    if (safe.isNotEmpty) return safe[_rng.nextInt(safe.length)];
    // 어쩔 수 없이 내줘야 할 때: 상대가 그리디로 먹었을 때 가장 적게 잃는 변
    BoardMove best = moves.first;
    int bestLoss = 1 << 20;
    for (final m in moves) {
      final g = clone() as DotsBoxesGame;
      g.apply(m);
      final loss = g._greedyGain(1 - toMove);
      if (loss < bestLoss) {
        bestLoss = loss;
        best = m;
      }
    }
    return best;
  }

  /// side 가 지금부터 먹을 수 있는 만큼 전부 먹으면 몇 개인가 (내준 사슬 길이)
  int _greedyGain(int side) {
    final g = clone() as DotsBoxesGame;
    g.toMove = side;
    int gained = 0;
    while (true) {
      final t = g.legalMoves().where((m) => g.completes(m.a)).toList();
      if (t.isEmpty || g.toMove != side) break;
      g.apply(t.first);
      gained++;
    }
    return gained;
  }

  @override
  bool toMoveIsLosing() {
    // 남은 변 ${_exactMax}개 이하에서만 판정 (그 전은 판단 보류 = false).
    _ensureExact();
    final val = _xVal;
    if (val == null) return false;
    final int total = score[toMove] - score[1 - toMove] + val[_xMask()];
    return toMove == 0 ? total <= 0 : total < 0;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 3. 심 — 점 6개, 선 15개. 내 색 삼각형을 만들면 패배.
// ═══════════════════════════════════════════════════════════════════════════
class SimGame extends BoardGame {
  /// 선 번호 → (i,j)
  static final List<List<int>> edges = [
    for (int i = 0; i < 6; i++)
      for (int j = i + 1; j < 6; j++) [i, j],
  ];
  static int edgeIndex(int i, int j) {
    if (i > j) {
      final t = i;
      i = j;
      j = t;
    }
    for (int e = 0; e < edges.length; e++) {
      if (edges[e][0] == i && edges[e][1] == j) return e;
    }
    return -1;
  }

  List<int> color; // -1 없음, 0/1
  int? _winner;

  SimGame() : color = List.filled(15, -1);
  SimGame._(this.color, this._winner);

  @override
  BoardKind get kind => BoardKind.sim;

  @override
  bool get isOver => _winner != null || !color.contains(-1);

  @override
  int? get winner => _winner ?? (isOver ? 1 - toMove : null);

  @override
  List<BoardMove> legalMoves() => [
        for (int e = 0; e < 15; e++)
          if (color[e] < 0) BoardMove(e),
      ];

  /// e 를 side 색으로 칠하면 삼각형이 생기는가
  bool makesTriangle(int e, int side) {
    final a = edges[e][0], b = edges[e][1];
    for (int k = 0; k < 6; k++) {
      if (k == a || k == b) continue;
      if (color[edgeIndex(a, k)] == side && color[edgeIndex(b, k)] == side) {
        return true;
      }
    }
    return false;
  }

  @override
  void apply(BoardMove m) {
    final side = toMove;
    color[m.a] = side;
    if (makesTriangle(m.a, side)) _winner = 1 - side;
    toMove = 1 - toMove;
  }

  @override
  BoardGame clone() => SimGame._(List<int>.from(color), _winner)..toMove = toMove;

  @override
  String summary() => '${15 - color.where((c) => c < 0).length} / 15';

  // ── 완전 탐색 (2026-09-20): 정수 키 메모 + 제자리 탐색이라 빈 판에서도 수십 ms 에 끝난다.
  //    그래서 힌트·되감기·예린의 최선 수가 **첫 수부터** 정확하다.
  static final Map<int, bool> _memo = {};
  static final List<int> _pow3 = [for (int i = 0, p = 1; i < 15; i++, p *= 3) p];

  static bool _winAt(List<int> col, int idx, int side) {
    final c = _memo[idx * 2 + side];
    if (c != null) return c;
    bool res = false;
    for (int e = 0; e < 15; e++) {
      if (col[e] >= 0) continue;
      // 자멸(내 삼각형) 수는 후보에서 제외
      final a = edges[e][0], b = edges[e][1];
      bool tri = false;
      for (int k = 0; k < 6 && !tri; k++) {
        if (k == a || k == b) continue;
        if (col[edgeIndex(a, k)] == side && col[edgeIndex(b, k)] == side) tri = true;
      }
      if (tri) continue;
      col[e] = side;
      final w = _winAt(col, idx + (side + 1) * _pow3[e], 1 - side);
      col[e] = -1;
      if (!w) {
        res = true;
        break;
      }
    }
    _memo[idx * 2 + side] = res;
    return res;
  }

  /// 둘 차례가 이기는가
  static bool _win(SimGame g) {
    if (g.isOver) return g.winner == g.toMove;
    int idx = 0;
    for (int e = 0; e < 15; e++) {
      idx += (g.color[e] + 1) * _pow3[e];
    }
    return _winAt(List<int>.from(g.color), idx, g.toMove);
  }

  int _remaining() => color.where((c) => c < 0).length;

  /// 종반: 남은 선 9개 이하
  @override
  bool inEndgame() => _remaining() <= 9;

  /// 실수: 최선은 아니어도 당장 내 삼각형을 만드는 자멸 수는 아님
  @override
  List<BoardMove> plausibleMistakes() =>
      legalMoves().where((m) => !makesTriangle(m.a, toMove)).toList();

  @override
  bool toMoveIsLosing() => !_win(this);

  @override
  BoardMove bestMove() {
    final moves = legalMoves();
    final safe = moves.where((m) => !makesTriangle(m.a, toMove)).toList();
    if (safe.isEmpty) return moves[_rng.nextInt(moves.length)]; // 어차피 패배
    {
      final wins = <BoardMove>[];
      for (final m in safe) {
        final n = clone() as SimGame;
        n.apply(m);
        if (!_win(n)) wins.add(m);
      }
      if (wins.isNotEmpty) return wins[_rng.nextInt(wins.length)];
    }
    // 휴리스틱: 내 색 선이 적게 모이는 점끼리 잇는다 (삼각형 위험 최소화),
    //           동시에 상대에게 위험한 자리는 남겨둔다.
    BoardMove best = safe.first;
    double bestScore = -1e9;
    for (final m in safe) {
      final a = SimGame.edges[m.a][0], b = SimGame.edges[m.a][1];
      int myDeg = 0, oppDeg = 0;
      for (int k = 0; k < 6; k++) {
        if (k == a || k == b) continue;
        final ea = color[edgeIndex(a, k)], eb = color[edgeIndex(b, k)];
        if (ea == toMove) myDeg++;
        if (eb == toMove) myDeg++;
        if (ea == 1 - toMove) oppDeg++;
        if (eb == 1 - toMove) oppDeg++;
      }
      final double sc = -myDeg * 2.0 + oppDeg * 0.5 + _rng.nextDouble() * 0.3;
      if (sc > bestScore) {
        bestScore = sc;
        best = m;
      }
    }
    return best;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 4. 스프라우트 (직선 변형)
//    점을 직선으로 잇고 그 한가운데에 새 점을 찍는다. 선끼리 교차 금지,
//    한 점에 선 3개까지. 둘 수 없으면 패배.  (자유 곡선 대신 직선 — 모바일 조작용)
// ═══════════════════════════════════════════════════════════════════════════
class SproutsGame extends BoardGame {
  final List<double> px; // 0..1 정규화 좌표
  final List<double> py;
  final List<int> deg;
  final List<List<int>> segs; // [i,j]

  SproutsGame._(this.px, this.py, this.deg, this.segs);

  factory SproutsGame.circle(int n) {
    final px = <double>[], py = <double>[];
    for (int i = 0; i < n; i++) {
      final a = -math.pi / 2 + 2 * math.pi * i / n;
      px.add(0.5 + 0.36 * math.cos(a));
      py.add(0.5 + 0.36 * math.sin(a));
    }
    return SproutsGame._(px, py, List<int>.filled(n, 0, growable: true), <List<int>>[]);
  }

  @override
  BoardKind get kind => BoardKind.sprouts;

  int get pointCount => px.length;

  static double _cross(double ax, double ay, double bx, double by) =>
      ax * by - ay * bx;

  static int _orient(double ax, double ay, double bx, double by, double cx,
      double cy) {
    final v = _cross(bx - ax, by - ay, cx - ax, cy - ay);
    if (v.abs() < 1e-9) return 0;
    return v > 0 ? 1 : -1;
  }

  static bool _onSeg(double ax, double ay, double bx, double by, double px,
      double py) {
    return px <= math.max(ax, bx) + 1e-9 &&
        px >= math.min(ax, bx) - 1e-9 &&
        py <= math.max(ay, by) + 1e-9 &&
        py >= math.min(ay, by) - 1e-9;
  }

  /// 선분 (i,j) 와 (k,l) 이 끝점 공유 이외로 만나는가
  bool _segsClash(int i, int j, int k, int l) {
    final shared = <int>{i, j}.intersection({k, l});
    if (shared.length == 2) return true; // 같은 선분
    final ax = px[i], ay = py[i], bx = px[j], by = py[j];
    final cx = px[k], cy = py[k], dx = px[l], dy = py[l];
    final o1 = _orient(ax, ay, bx, by, cx, cy);
    final o2 = _orient(ax, ay, bx, by, dx, dy);
    final o3 = _orient(cx, cy, dx, dy, ax, ay);
    final o4 = _orient(cx, cy, dx, dy, bx, by);
    if (shared.length == 1) {
      // 끝점 하나를 공유: 일직선으로 겹칠 때만 충돌
      if (o1 == 0 && o2 == 0 && o3 == 0 && o4 == 0) {
        final s = shared.first;
        final o1x = i == s ? j : i, o2x = k == s ? l : k;
        // 공유점에서 두 선분이 같은 방향으로 뻗으면 겹친다
        final v1x = px[o1x] - px[s], v1y = py[o1x] - py[s];
        final v2x = px[o2x] - px[s], v2y = py[o2x] - py[s];
        return v1x * v2x + v1y * v2y > 0;
      }
      return false;
    }
    if (o1 != o2 && o3 != o4) return true;
    if (o1 == 0 && _onSeg(ax, ay, bx, by, cx, cy)) return true;
    if (o2 == 0 && _onSeg(ax, ay, bx, by, dx, dy)) return true;
    if (o3 == 0 && _onSeg(cx, cy, dx, dy, ax, ay)) return true;
    if (o4 == 0 && _onSeg(cx, cy, dx, dy, bx, by)) return true;
    return false;
  }

  /// 선분 (i,j) 가 다른 점을 지나가는가
  bool _passesPoint(int i, int j) {
    for (int p = 0; p < pointCount; p++) {
      if (p == i || p == j) continue;
      if (_orient(px[i], py[i], px[j], py[j], px[p], py[p]) == 0 &&
          _onSeg(px[i], py[i], px[j], py[j], px[p], py[p])) {
        return true;
      }
    }
    return false;
  }

  bool isLegal(int i, int j) {
    if (i == j) return false;
    if (deg[i] >= 3 || deg[j] >= 3) return false;
    if (_passesPoint(i, j)) return false;
    for (final s in segs) {
      if (_segsClash(i, j, s[0], s[1])) return false;
    }
    return true;
  }

  @override
  List<BoardMove> legalMoves() {
    final out = <BoardMove>[];
    for (int i = 0; i < pointCount; i++) {
      if (deg[i] >= 3) continue;
      for (int j = i + 1; j < pointCount; j++) {
        if (isLegal(i, j)) out.add(BoardMove(i, j));
      }
    }
    return out;
  }

  @override
  bool get isOver => legalMoves().isEmpty;

  @override
  int? get winner => isOver ? 1 - toMove : null;

  @override
  void apply(BoardMove m) {
    final i = m.a, j = m.b;
    // 새 점은 선 한가운데. 원래 선 i–j 는 i–새점, 새점–j 두 토막으로 쪼개서 보관해야
    // 나중에 새 점에서 뻗는 선이 "기존 선 위를 지난다"고 잘못 판정되지 않는다.
    final int k = px.length;
    px.add((px[i] + px[j]) / 2);
    py.add((py[i] + py[j]) / 2);
    deg.add(2);
    deg[i]++;
    deg[j]++;
    segs.add([i, k]);
    segs.add([k, j]);
    toMove = 1 - toMove;
  }

  @override
  BoardGame clone() => SproutsGame._(
      List<double>.from(px),
      List<double>.from(py),
      List<int>.from(deg),
      [for (final s in segs) List<int>.from(s)])
    ..toMove = toMove;

  @override
  String summary() => '${segs.length ~/ 2}'; // 한 수 = 토막 2개

  static int _nodes = 0;

  /// 둘 차례가 이기는가. 예산 초과 시 null (모름).
  static bool? _win(SproutsGame g, int budget) {
    _nodes++;
    if (_nodes > budget) return null;
    final moves = g.legalMoves();
    if (moves.isEmpty) return false;
    for (final m in moves) {
      final n = g.clone() as SproutsGame;
      n.apply(m);
      final r = _win(n, budget);
      if (r == null) return null;
      if (!r) return true;
    }
    return false;
  }

  @override
  bool toMoveIsLosing() {
    _nodes = 0;
    return _win(this, 2500) == false;
  }

  /// 종반: 남은 수 6개 이하
  @override
  bool inEndgame() => legalMoves().length <= 6;

  @override
  BoardMove bestMove() {
    final moves = legalMoves();
    // 완전 탐색이 되면 필승 수, 아니면 "상대의 선택지를 줄이는" 휴리스틱
    for (final m in moves) {
      final n = clone() as SproutsGame;
      n.apply(m);
      _nodes = 0;
      final r = _win(n, 1500);
      if (r == false) return m;
      if (r == null) break; // 너무 깊다 → 휴리스틱으로 (예산은 폰 기준 ~50ms)
    }
    BoardMove best = moves.first;
    int bestOpp = 1 << 20;
    for (final m in moves) {
      final n = clone() as SproutsGame;
      n.apply(m);
      final opp = n.legalMoves().length;
      // 상대가 둘 수 있는 수가 짝수면 나에게 유리한 경향
      final sc = opp * 2 + (opp.isEven ? 0 : 1);
      if (sc < bestOpp) {
        bestOpp = sc;
        best = m;
      }
    }
    return best;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 5. 헥스 — N x N. side 0(플레이어) 는 좌↔우, side 1(예린) 은 위↔아래.
// ═══════════════════════════════════════════════════════════════════════════
class HexGame extends BoardGame {
  final int n;
  List<int> cells; // -1 빈칸, 0/1
  int? _winner;

  HexGame(this.n) : cells = List.filled(n * n, -1);
  HexGame._(this.n, this.cells, this._winner);

  @override
  BoardKind get kind => BoardKind.hex;

  @override
  bool get isOver => _winner != null || !cells.contains(-1);

  @override
  int? get winner => _winner;

  @override
  List<BoardMove> legalMoves() => [
        for (int i = 0; i < cells.length; i++)
          if (cells[i] < 0) BoardMove(i),
      ];

  static const List<List<int>> _nb = [
    [-1, 0],
    [-1, 1],
    [0, -1],
    [0, 1],
    [1, -1],
    [1, 0],
  ];

  /// side 가 자기 변을 이었는가
  static bool _connected(List<int> cells, int n, int side) {
    final seen = List<bool>.filled(n * n, false);
    final stack = <int>[];
    for (int k = 0; k < n; k++) {
      final idx = side == 0 ? k * n : k; // 0: 왼쪽 열, 1: 윗 행
      if (cells[idx] == side) {
        seen[idx] = true;
        stack.add(idx);
      }
    }
    while (stack.isNotEmpty) {
      final cur = stack.removeLast();
      final r = cur ~/ n, c = cur % n;
      if (side == 0 ? c == n - 1 : r == n - 1) return true;
      for (final d in _nb) {
        final nr = r + d[0], nc = c + d[1];
        if (nr < 0 || nc < 0 || nr >= n || nc >= n) continue;
        final ni = nr * n + nc;
        if (!seen[ni] && cells[ni] == side) {
          seen[ni] = true;
          stack.add(ni);
        }
      }
    }
    return false;
  }

  @override
  void apply(BoardMove m) {
    cells[m.a] = toMove;
    if (_connected(cells, n, toMove)) _winner = toMove;
    toMove = 1 - toMove;
  }

  @override
  BoardGame clone() => HexGame._(n, List<int>.from(cells), _winner)..toMove = toMove;

  @override
  String summary() => '${cells.where((c) => c < 0).length}';

  /// 무작위로 끝까지 채웠을 때 side 가 이기는가 (헥스는 무승부가 없다)
  bool _playout(List<int> base, int side, int startSide) {
    final b = List<int>.from(base);
    final empties = <int>[
      for (int i = 0; i < b.length; i++)
        if (b[i] < 0) i
    ];
    empties.shuffle(_rng);
    int s = startSide;
    for (final e in empties) {
      b[e] = s;
      s = 1 - s;
    }
    return _connected(b, n, side);
  }

  double _winRate(List<int> base, int side, int startSide, int k) {
    int w = 0;
    for (int i = 0; i < k; i++) {
      if (_playout(base, side, startSide)) w++;
    }
    return w / k;
  }

  @override
  bool toMoveIsLosing() {
    if (isOver) return winner != toMove;
    return _winRate(cells, toMove, toMove, 120) < 0.22;
  }

  bool _hasImmediate(int side) {
    for (final m in legalMoves()) {
      final t = List<int>.from(cells)..[m.a] = side;
      if (_connected(t, n, side)) return true;
    }
    return false;
  }

  /// 종반: 빈칸이 절반 이하이거나, 당장 이기거나 막아야 하는 수가 있을 때
  @override
  bool inEndgame() {
    final empties = cells.where((c) => c < 0).length;
    if (empties * 2 <= n * n) return true;
    return _hasImmediate(toMove) || _hasImmediate(1 - toMove);
  }

  @override
  BoardMove bestMove() {
    final moves = legalMoves();
    final me = toMove, opp = 1 - toMove;
    // 즉시 승리 / 즉시 방어
    for (final m in moves) {
      final t = List<int>.from(cells)..[m.a] = me;
      if (_connected(t, n, me)) return m;
    }
    for (final m in moves) {
      final t = List<int>.from(cells)..[m.a] = opp;
      if (_connected(t, n, opp)) return m;
    }
    // 몬테카를로: 후보마다 무작위 플레이아웃 승률
    final int k = n <= 5 ? 70 : 40;
    BoardMove best = moves.first;
    double bestRate = -1;
    for (final m in moves) {
      final t = List<int>.from(cells)..[m.a] = me;
      final r = _winRate(t, me, opp, k) + _rng.nextDouble() * 0.01;
      if (r > bestRate) {
        bestRate = r;
        best = m;
      }
    }
    return best;
  }
}
