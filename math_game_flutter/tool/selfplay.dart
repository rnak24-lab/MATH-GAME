import 'dart:math';
import 'package:math_game/game/board_games.dart';

void main() {
  final rng = Random(42);
  final stages = <int>[141, 142, 143, 150, 160, 161, 162, 164, 166, 172, 175, 178, 180, 181, 200, 201, 203, 207, 212, 217, 220, 221, 223, 226, 230, 234, 240];
  int fails = 0;
  for (final st in stages) {
    final kind = boardKindForStage(st);
    int wins0 = 0, games = 0, maxMs = 0, totalMoves = 0;
    final sw = Stopwatch();
    for (int gi = 0; gi < 6; gi++) {
      final g = BoardGame.forStage(st);
      g.toMove = gi % 2; // 선후공 번갈아
      int guard = 0;
      try {
        while (!g.isOver && guard++ < 400) {
          if (g.toMove == 0) {
            // 플레이어 흉내: 절반은 랜덤, 절반은 최선
            final ms = g.legalMoves();
            final m = rng.nextBool() ? ms[rng.nextInt(ms.length)] : g.bestMove();
            g.apply(m);
          } else {
            sw.reset(); sw.start();
            final m = g.aiMove(blunderRateForStage(st));
            sw.stop();
            if (sw.elapsedMilliseconds > maxMs) maxMs = sw.elapsedMilliseconds;
            if (m.a < 0) throw StateError('AI returned no move');
            if (!g.legalMoves().contains(m)) throw StateError('AI illegal move $m');
            g.apply(m);
          }
          totalMoves++;
        }
        if (!g.isOver) throw StateError('did not terminate (guard)');
        if (g.winner == null) throw StateError('over but winner null');
        // 지는 판정 호출도 예외 없이 도는지
        BoardGame.forStage(st).toMoveIsLosing();
        games++;
        if (g.winner == 0) wins0++;
      } catch (e, s) {
        fails++;
        print('FAIL stage $st ($kind): $e\n$s');
        break;
      }
    }
    print('stage $st ${kind.name.padRight(9)} games=$games playerWins=$wins0 '
        'avgMoves=${games == 0 ? 0 : totalMoves ~/ games} aiMaxMs=$maxMs');
  }
  // 춉: 2x2 판은 선수필승, 1x1 은 둘 차례 패배
  final c = ChompGame(2, 2);
  print('chomp 2x2 toMoveIsLosing=${c.toMoveIsLosing()} (기대 false)');
  // 심: 삼각형 판정
  final sim = SimGame();
  sim.apply(BoardMove(SimGame.edgeIndex(0, 1))); // p0
  sim.apply(BoardMove(SimGame.edgeIndex(3, 4))); // p1
  sim.apply(BoardMove(SimGame.edgeIndex(1, 2))); // p0
  sim.apply(BoardMove(SimGame.edgeIndex(4, 5))); // p1
  sim.apply(BoardMove(SimGame.edgeIndex(0, 2))); // p0 삼각형 → p1 승
  print('sim triangle → over=${sim.isOver} winner=${sim.winner} (기대 1)');
  // 스프라우트: 겹치는 선 금지
  final sp = SproutsGame.circle(3);
  sp.apply(const BoardMove(0, 1)); // 새 점 3 = 0-1 중점
  print('sprouts 3-1 legal=${sp.isLegal(1, 3)} (기대 false, 겹침) 3-2 legal=${sp.isLegal(2, 3)} (기대 true)');
  print(fails == 0 ? 'ALL OK' : 'FAILS=$fails');
}
