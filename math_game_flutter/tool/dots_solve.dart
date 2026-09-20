// 점과 상자 완전 풀이 (변 ≤ 27개). value[mask] = 그 상태에서 둘 차례가 "앞으로" 얻는 상자 수 차이(최선).
//   dart run tool/dots_solve.dart            → 여러 판 크기의 선공 값
//   value > 0 이어야 선공(플레이어) 승리. 0 = 무승부(게임에선 예린 승으로 처리) → 쓰면 안 됨.
import 'dart:typed_data';

class Board {
  final int R, C;
  late final int hCount, E;
  late final List<List<int>> boxesOfEdge; // edge → box indices
  late final List<int> boxMask; // box → 4 edge bits
  Board(this.R, this.C) {
    hCount = (R + 1) * C;
    E = hCount + R * (C + 1);
    boxMask = List.filled(R * C, 0);
    boxesOfEdge = List.generate(E, (_) => <int>[]);
    int h(int r, int c) => r * C + c;
    int v(int r, int c) => hCount + r * (C + 1) + c;
    for (int r = 0; r < R; r++) {
      for (int c = 0; c < C; c++) {
        final b = r * C + c;
        for (final e in [h(r, c), h(r + 1, c), v(r, c), v(r, c + 1)]) {
          boxMask[b] |= 1 << e;
          boxesOfEdge[e].add(b);
        }
      }
    }
  }
}

Int8List solve(Board bd) {
  final int n = 1 << bd.E;
  final val = Int8List(n);
  final int full = n - 1;
  for (int mask = full - 1; mask >= 0; mask--) {
    int best = -100;
    for (int e = 0; e < bd.E; e++) {
      final bit = 1 << e;
      if (mask & bit != 0) continue;
      final nm = mask | bit;
      int gain = 0;
      for (final b in bd.boxesOfEdge[e]) {
        if (nm & bd.boxMask[b] == bd.boxMask[b]) gain++;
      }
      final v = gain > 0 ? gain + val[nm] : -val[nm];
      if (v > best) best = v;
    }
    val[mask] = best;
  }
  return val;
}

void main() {
  for (final sz in [
    [1, 1], [1, 2], [1, 3], [1, 4], [1, 5], [1, 6], [1, 7], [2, 2], [2, 3], [2, 4], [3, 3], [2, 5],
  ]) {
    final bd = Board(sz[0], sz[1]);
    final sw = Stopwatch()..start();
    final val = solve(bd);
    final v = val[0];
    print('${sz[0]}x${sz[1]}  edges=${bd.E}  boxes=${sz[0] * sz[1]}  first-player margin=$v  '
        '${v > 0 ? "선공 승" : (v == 0 ? "무승부" : "선공 패")}  (${sw.elapsedMilliseconds}ms)');
  }
}
