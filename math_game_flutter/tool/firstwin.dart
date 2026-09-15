import 'package:math_game/game/nim_engine.dart';
import 'package:math_game/game/board_games.dart';
import 'package:math_game/models/game_state.dart';

void main() {
  final e = NimEngine();
  final buf = StringBuffer();
  int firstWins = 0, secondWins = 0;
  for (int st = 1; st <= 140; st++) {
    final c = e.generateStage(st);
    bool fw;
    switch (c.mode) {
      case GameMode.singleRow:
        fw = (c.rows[0] - 1) % (c.maxTake + 1) != 0; break;
      case GameMode.fibonacci:
        fw = !e.fibonacciLosing(c.rows[0], c.rows[0] - 1); break;
      case GameMode.pepero:
        fw = c.rows.any((p) => p >= 3) && !e.isAIWinning(c.rows, c.mode); break;
      default:
        fw = !e.isAIWinning(c.rows, c.mode);
    }
    if (fw) firstWins++; else secondWins++;
    buf.writeln('$st\t${c.mode.name}\t${c.rows}\tmax=${c.maxTake}\t${fw ? "FIRST" : "second"}');
  }
  for (int st = 141; st <= 240; st++) {
    final g = BoardGame.forStage(st);
    final kind = boardKindForStage(st);
    String r;
    try {
      final sw = Stopwatch()..start();
      final losing = g.toMoveIsLosing();
      sw.stop();
      r = (losing ? 'second' : 'FIRST') + ' (${sw.elapsedMilliseconds}ms)';
      if (losing) secondWins++; else firstWins++;
    } catch (ex) { r = 'ERR $ex'; }
    buf.writeln('$st\t${kind.name}\t${g.runtimeType}\t$r');
  }
  buf.writeln('TOTAL first=$firstWins second=$secondWins');
  print(buf);
}
