// 스프라우트: 예린의 첫 선(사전 1선) 위치별로, 엔진 최선 수로 두는 플레이어가 최강 예린을 이기는지 측정.
import 'package:math_game/game/board_games.dart';

void main() {
  for (final n in [3, 4, 5]) {
    final base = SproutsGame.circle(n);
    base.toMove = 1;
    final firsts = base.legalMoves();
    final good = <int>[];
    for (int i = 0; i < firsts.length; i++) {
      int win = 0;
      const games = 8;
      for (int k = 0; k < games; k++) {
        final g = SproutsGame.circle(n)..toMove = 1;
        g.apply(firsts[i]);
        int guard = 0;
        while (!g.isOver && guard++ < 300) {
          final m = g.toMove == 0 ? g.bestMove() : g.aiMove(0);
          if (m.a < 0) break;
          g.apply(m);
        }
        if (g.winner == 0) win++;
      }
      if (win == games) good.add(i);
      print('n=$n pre#$i ${firsts[i]}  player $win/$games');
    }
    print('n=$n GOOD indices: $good');
  }
}
