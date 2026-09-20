// 완전 탐색 검증 (예산 제한 없음): 스프라우트 n=2..5, 심(예린 사전 1선 뒤 플레이어 차례)
//   dart run tool/exact_check.dart
import 'dart:typed_data';
import 'package:math_game/game/board_games.dart';

final Map<String, bool> _memo = {};
int _nodes = 0;

String _key(SproutsGame g) {
  // 선분 집합 + 점 차수로 상태 식별 (좌표는 선분 이력으로 결정되므로 선분 목록이면 충분)
  final segs = g.segs.map((s) => '${s[0]}-${s[1]}').toList()..sort();
  return segs.join('|');
}

bool sproutsWin(SproutsGame g) {
  final k = _key(g);
  final c = _memo[k];
  if (c != null) return c;
  _nodes++;
  bool res = false;
  for (final m in g.legalMoves()) {
    final n = g.clone() as SproutsGame;
    n.apply(m);
    if (!sproutsWin(n)) {
      res = true;
      break;
    }
  }
  _memo[k] = res;
  return res;
}

// ── 심: 3^15 상태 DP ──
late Int8List _sim; // 0 = 모름, 1 = 둘 차례 승, 2 = 둘 차례 패
final List<List<int>> _edges = [
  for (int i = 0; i < 6; i++)
    for (int j = i + 1; j < 6; j++) [i, j],
];
int _ei(int a, int b) {
  if (a > b) {
    final t = a;
    a = b;
    b = t;
  }
  for (int e = 0; e < 15; e++) {
    if (_edges[e][0] == a && _edges[e][1] == b) return e;
  }
  return -1;
}

final List<int> _pow3 = [for (int i = 0, p = 1; i < 16; i++, p *= 3) p];

bool _tri(List<int> col, int e, int side) {
  final a = _edges[e][0], b = _edges[e][1];
  for (int k = 0; k < 6; k++) {
    if (k == a || k == b) continue;
    if (col[_ei(a, k)] == side && col[_ei(b, k)] == side) return true;
  }
  return false;
}

/// col: 0 빈, 1 = side0(플레이어), 2 = side1(예린). side = 둘 차례(1|2)
bool simWin(List<int> col, int idx, int side) {
  final c = _sim[idx];
  if (c != 0) return c == 1;
  bool res = false;
  bool any = false;
  for (int e = 0; e < 15; e++) {
    if (col[e] != 0) continue;
    any = true;
    if (_tri(col, e, side)) continue; // 자멸 수
    col[e] = side;
    final w = simWin(col, idx + side * _pow3[e], 3 - side);
    col[e] = 0;
    if (!w) {
      res = true;
      break;
    }
  }
  if (!any) res = false;
  _sim[idx] = res ? 1 : 2;
  return res;
}

void main() {
  for (int n = 2; n <= 5; n++) {
    _memo.clear();
    _nodes = 0;
    final sw = Stopwatch()..start();
    final g = SproutsGame.circle(n);
    final w = sproutsWin(g);
    print('sprouts n=$n  선공 ${w ? "승" : "패"}  (states=$_nodes, ${sw.elapsedMilliseconds}ms)');
  }
  _sim = Int8List(_pow3[15]);
  final col = List<int>.filled(15, 0);
  final sw = Stopwatch()..start();
  final emptyFirstWins = simWin(col, 0, 2); // 빈 판에서 예린(2)이 먼저
  print('sim 빈 판: 먼저 두는 쪽 ${emptyFirstWins ? "승" : "패"}  (${sw.elapsedMilliseconds}ms)');
  for (int e = 0; e < 15; e += 7) {
    col[e] = 2;
    final w = simWin(col, 2 * _pow3[e], 1);
    col[e] = 0;
    print('sim 예린이 선 $e 를 먼저 그은 뒤 플레이어 차례: 플레이어 ${w ? "승" : "패"}');
  }
}
