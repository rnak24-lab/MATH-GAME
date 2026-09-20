// 점과 상자 스테이지 생성기 — "플레이어(선공) 필승"이 **완전 풀이로 증명된** 시작 판만 뽑는다.
//   dart run tool/dots_gen.dart  → lib/game/board_games.dart 에 붙여 넣을 Dart 표 출력
// 아이디어: 빈 판은 1x1·1x3·1x5·1x7·3x3 전부 선공 패(또는 무승부)다. 그래서 예린이 선을 몇 개
// "미리 그어 둔" 판에서 시작한다(심과 같은 연출). 미리 그은 선은 상자를 완성하지 않고(3변 이상 금지),
// 그 상태에서 둘 차례(플레이어)의 최선 결과가 +1 이상임을 DP 로 확인한다.
import 'dart:math';
import 'dart:typed_data';

class Board {
  final int R, C;
  late final int hCount, E;
  late final List<List<int>> boxesOfEdge;
  late final List<List<int>> edgesOfBox;
  Board(this.R, this.C) {
    hCount = (R + 1) * C;
    E = hCount + R * (C + 1);
    boxesOfEdge = List.generate(E, (_) => <int>[]);
    edgesOfBox = List.generate(R * C, (_) => <int>[]);
    int h(int r, int c) => r * C + c;
    int v(int r, int c) => hCount + r * (C + 1) + c;
    for (int r = 0; r < R; r++) {
      for (int c = 0; c < C; c++) {
        final b = r * C + c;
        for (final e in [h(r, c), h(r + 1, c), v(r, c), v(r, c + 1)]) {
          edgesOfBox[b].add(e);
          boxesOfEdge[e].add(b);
        }
      }
    }
  }
}

/// pre 가 그어진 상태에서 둘 차례의 최선 마진. 자유 변 ≤ 25.
int solveFrom(Board bd, Set<int> pre) {
  final free = [for (int e = 0; e < bd.E; e++) if (!pre.contains(e)) e];
  final f = free.length;
  final idx = {for (int i = 0; i < f; i++) free[i]: i};
  // 상자별: 자유 변 비트마스크
  final boxFree = List<int>.filled(bd.R * bd.C, 0);
  for (int b = 0; b < bd.R * bd.C; b++) {
    for (final e in bd.edgesOfBox[b]) {
      if (idx.containsKey(e)) boxFree[b] |= 1 << idx[e]!;
    }
  }
  final boxesOfFree = [for (final e in free) bd.boxesOfEdge[e]];
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
  return val[0];
}

bool okPre(Board bd, Set<int> pre) {
  for (int b = 0; b < bd.R * bd.C; b++) {
    int n = 0;
    for (final e in bd.edgesOfBox[b]) {
      if (pre.contains(e)) n++;
    }
    if (n >= 3) return false;
  }
  return true;
}

void main() {
  // [R, C, 미리 그을 선 수]
  final plan = <List<int>>[
    [1, 1, 1], [1, 3, 1], [1, 3, 3], [1, 5, 1], [1, 5, 3], [1, 7, 1], [1, 7, 3],
    [3, 3, 1], [3, 3, 1], [3, 3, 3], [3, 3, 3], [3, 3, 5], [3, 3, 5], [3, 3, 7], [3, 3, 7],
    [3, 5, 20], [3, 5, 20], [3, 5, 20], [3, 5, 20], [3, 5, 20],
  ];
  final rng = Random(20260920);
  final used = <String>{};
  final out = StringBuffer();
  for (int t = 0; t < plan.length; t++) {
    final bd = Board(plan[t][0], plan[t][1]);
    final k = plan[t][2];
    Set<int>? found;
    int margin = 0;
    for (int tries = 0; tries < 200000 && found == null; tries++) {
      final pre = <int>{};
      while (pre.length < k) {
        pre.add(rng.nextInt(bd.E));
      }
      if (!okPre(bd, pre)) continue;
      final key = '${bd.R}x${bd.C}:${(pre.toList()..sort()).join(",")}';
      if (used.contains(key)) continue;
      if (bd.E - k > 25) continue;
      final v = solveFrom(bd, pre);
      if (v >= 1 && v <= 3) {
        found = pre;
        margin = v;
        used.add(key);
      }
    }
    if (found == null) {
      out.writeln('    // stage ${161 + t}: NOT FOUND for ${plan[t]}');
      continue;
    }
    final list = found.toList()..sort();
    out.writeln('    _DotsSpec(${bd.R}, ${bd.C}, [${list.join(", ")}]), // ${161 + t}: 자유 변 ${bd.E - k}, 선공 +$margin');
    // ignore: avoid_print
    print('stage ${161 + t} ok ${bd.R}x${bd.C} k=$k margin=+$margin');
  }
  // ignore: avoid_print
  print('\n──── paste ────\n$out');
}
