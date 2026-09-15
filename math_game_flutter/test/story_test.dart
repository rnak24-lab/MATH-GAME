import 'package:flutter_test/flutter_test.dart';
import 'package:math_game/l10n/dialogue.dart';
import 'package:math_game/l10n/app_strings.dart';

void main() {
  test('story thresholds', () {
    expect(Dialogue.thresholdFor(4), isNull);
    expect(Dialogue.thresholdFor(5), 5);
    expect(Dialogue.thresholdFor(20), 20);
    expect(Dialogue.untilNext(0), 5);
    expect(Dialogue.untilNext(5), 5);
    expect(Dialogue.untilNext(19), 1);
    expect(Dialogue.untilNext(20), 0);
  });
  test('all story keys exist in every language', () {
    for (final loc in ['en', 'ko', 'ja', 'zh', 'es', 'pt', 'de', 'fr', 'id', 'vi']) {
      final s = AppStrings(loc);
      for (int w = 1; w <= 12; w++) {
        for (final t in Dialogue.thresholds) {
          final lines = Dialogue.worldScene(w, t, s);
          expect(lines.length, t == 10 ? 4 : (t == 20 ? 6 : 2), reason: 'w$w t$t $loc');
          for (final l in lines) {
            expect(l.text, isNot(matches(RegExp(r'^(st_|mid_|end_)'))), reason: 'missing $loc ${l.text}');
          }
          expect(Dialogue.sceneTitle(w, t, s), isNot(endsWith('_title')), reason: 'title w$w t$t $loc');
        }
        for (int i = 1; i <= 3; i++) {
          expect(s.get('dc_w${w}_$i'), isNot(startsWith('dc_')), reason: 'dc w$w $i $loc');
        }
      }
    }
  });
}
