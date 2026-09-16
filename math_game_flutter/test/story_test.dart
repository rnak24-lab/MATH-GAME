import 'package:flutter_test/flutter_test.dart';
import 'package:math_game/l10n/dialogue.dart';
import 'package:math_game/l10n/app_strings.dart';

void main() {
  test('story thresholds', () {
    expect(Dialogue.sceneFor(4), isNull);
    expect(Dialogue.sceneFor(5), 1);
    expect(Dialogue.sceneFor(10), 2);
    expect(Dialogue.sceneFor(20), 4);
    expect(Dialogue.untilNext(0), 5);
    expect(Dialogue.untilNext(5), 5);
    expect(Dialogue.untilNext(19), 1);
    expect(Dialogue.untilNext(20), 0);
  });
  test('all story / rule / pool keys exist in every language', () {
    for (final loc in ['en', 'ko', 'ja', 'zh', 'es', 'pt', 'de', 'fr', 'id', 'vi']) {
      final s = AppStrings(loc);
      for (int w = 1; w <= 12; w++) {
        for (int k = 1; k <= 4; k++) {
          final lines = Dialogue.worldScene(w, k, s);
          expect(lines.length, Dialogue.lineCount(k), reason: 'w$w k$k $loc');
          for (final l in lines) {
            expect(l.text, isNot(startsWith('sc_')), reason: 'missing $loc ${l.text}');
          }
          expect(Dialogue.sceneTitle(w, k, s), isNot(endsWith('_title')), reason: 'title w$w k$k $loc');
        }
        expect(s.has('dc_w${w}_1'), isTrue, reason: 'dc w$w');
        for (int i = 1; i <= 2; i++) {
          expect(s.get('rx_w${w}_$i'), isNot(startsWith('rx_')), reason: 'rx w$w $i $loc');
        }
      }
      for (final base in ['greet', 'won', 'lost', 'winEarly', 'winLate']) {
        expect(s.has('${base}_1'), isTrue, reason: 'pool $base');
      }
    }
  });
}
