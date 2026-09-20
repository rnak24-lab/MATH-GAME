// 출시 전 전수 점검: "항상 먼저 두는 플레이어가 최선으로 두면 예린을 이길 수 있는가"
//   dart run tool/winnable.dart            → 240판 요약
//   dart run tool/winnable.dart 161 180    → 구간만
// 플레이어 = 엔진의 bestMove(힌트와 같은 수). 예린 = 실제 게임과 같은 AI.
//   A열: 예린이 실제 설정(봐주기 포함)일 때 승률   B열: 예린이 실수 0(최강)일 때 승률
import 'dart:math';
import 'package:math_game/game/nim_engine.dart';
import 'package:math_game/game/board_games.dart';
import 'package:math_game/game/tutorial_manager.dart';
import 'package:math_game/models/game_state.dart';

final _rng = Random(7);

List<int> _apply(List<int> rows, NimMove m) {
  final r = List<int>.from(rows);
  if (m.isPepero) {
    r.removeAt(m.rowIndex);
    r.add(m.splitA);
    r.add(m.splitB);
    r.sort((x, y) => y.compareTo(x));
  } else if (m.isKayles) {
    r.removeAt(m.rowIndex);
    if (m.kaylesRight > 0) r.insert(m.rowIndex, m.kaylesRight);
    if (m.kaylesLeft > 0) r.insert(m.rowIndex, m.kaylesLeft);
  } else if (m.isWythoff) {
    r[0] -= m.takeA;
    r[1] -= m.takeB;
  } else {
    r[m.rowIndex] -= m.count;
  }
  return r;
}

bool _over(List<int> rows, GameMode mode) =>
    mode == GameMode.pepero ? !rows.any((p) => p >= 3) : rows.fold<int>(0, (a, b) => a + b) == 0;

/// 님 계열 한 판. 반환: 플레이어 승리 여부
bool playNim(NimEngine e, StageConfig c, double blunder) {
  var rows = List<int>.from(c.rows);
  int fib = c.mode == GameMode.fibonacci ? rows[0] - 1 : 0;
  bool playerTurn = true;
  int guard = 0;
  while (guard++ < 500) {
    if (_over(rows, c.mode)) {
      // 방금 둔 쪽이 승리 (노멀 플레이) / 막대과자: 둘 차례가 못 쪼개면 패배
      return !playerTurn;
    }
    NimMove m = e.bestMove(rows, c.mode, maxTake: c.maxTake, fibLimit: fib);
    if (!playerTurn && blunder > 0) {
      final bool endgame = c.mode == GameMode.pepero
          ? rows.where((p) => p >= 3).length <= 2
          : rows.fold<int>(0, (a, b) => a + b) <= 6;
      final bool winning = !e.toMoveLoses(rows, c.mode, maxTake: c.maxTake, fibLimit: fib);
      if (!endgame && winning && _rng.nextDouble() < blunder) {
        m = e.randomMove(rows, c.mode, maxTake: c.maxTake, fibLimit: fib);
      }
    }
    rows = _apply(rows, m);
    if (c.mode == GameMode.fibonacci) fib = m.count * 2;
    playerTurn = !playerTurn;
  }
  return false;
}

bool playBoard(int stage, double blunder) {
  final g = BoardGame.forStage(stage);
  g.toMove = 0;
  int guard = 0;
  while (!g.isOver && guard++ < 600) {
    final m = g.toMove == 0 ? g.bestMove() : g.aiMove(blunder);
    if (m.a < 0) break;
    g.apply(m);
  }
  return g.winner == 0;
}

void main(List<String> args) {
  final int from = args.isNotEmpty ? int.parse(args[0]) : 1;
  final int to = args.length > 1 ? int.parse(args[1]) : 240;
  final e = NimEngine();
  final bad = <String>[];
  for (int st = from; st <= to; st++) {
    int winA = 0, winB = 0;
    final int games = st <= 140 ? 20 : 12;
    String label;
    if (st <= 140) {
      final c = e.generateStage(st);
      label = '${c.mode.name} ${c.rows}';
      final br = TutorialManager.nimBlunderRate(st);
      for (int i = 0; i < games; i++) {
        if (playNim(e, c, br)) winA++;
        if (playNim(e, c, 0)) winB++;
      }
    } else {
      label = boardKindForStage(st).name;
      for (int i = 0; i < games; i++) {
        if (playBoard(st, kBoardBlunder)) winA++;
        if (playBoard(st, 0)) winB++;
      }
    }
    final line = '$st\t$label\tA=$winA/$games\tB=$winB/$games';
    print(line);
    if (winA * 10 < games * 7 || (st <= 140 && winB < games)) bad.add(line);
  }
  print('──── 문제 의심 (A < 70% 또는 님 계열 B < 100%) ────');
  for (final b in bad) {
    print(b);
  }
  print('TOTAL bad=${bad.length}');
}
