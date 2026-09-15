import '../widgets/midnight_character.dart' show MidnightFace;
import 'app_strings.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// (2026-09-16 대표님) "클리어할 이유" — 미연시식 이야기. 호감도 게이지는 없다.
///
///  - 매 클리어 뒤: 그 수업(월드)의 짧은 한마디 (3개 로테이션)        → [afterClear]
///  - 수업 안에서 5판·15판 깨면: 짧은 이야기 (2줄)                     → [worldScene]
///  - 10판 깨면: 큰 이야기 (4줄)
///  - 20판 다 깨면: 긴 이야기 (6줄) — 그 수업의 마무리
///
/// 문장은 AppStrings 키(dc_w{w}_{n}, st_w{w}_a/b_{n}, mid_w{w}_{n}, end_w{w}_{n})로 두고
/// 여기선 순서와 표정만 정한다. 열림 여부는 월드 클리어 수로만 결정되므로 "본 기록"이 필요 없다.
/// ─────────────────────────────────────────────────────────────────────────
class DialogueLine {
  final MidnightFace face;
  final String text;
  const DialogueLine(this.face, this.text);
}

class Dialogue {
  /// 이야기가 열리는 수업 내 클리어 수
  static const List<int> thresholds = [5, 10, 15, 20];

  static int worldOf(int stageNumber) => ((stageNumber - 1) ~/ 20) + 1; // 1~12

  /// 클리어 직후 한마디. [nth] = 이 수업에서 몇 번째 클리어인가 (로테이션용).
  static DialogueLine afterClear(int stageNumber, int nth, AppStrings s) {
    final int w = worldOf(stageNumber);
    final int i = (nth % 3) + 1;
    const faces = [MidnightFace.confident, MidnightFace.happy1, MidnightFace.worried1];
    return DialogueLine(faces[nth % 3], s.get('dc_w${w}_$i'));
  }

  /// [count] 판째 클리어에서 열리는 이야기. 문턱이 아니면 null.
  static int? thresholdFor(int count) => thresholds.contains(count) ? count : null;

  /// 다음 이야기까지 남은 판 수. 다 봤으면 0.
  static int untilNext(int count) {
    for (final t in thresholds) {
      if (count < t) return t - count;
    }
    return 0;
  }

  /// 수업 [w](1~12)의 [threshold](5/10/15/20) 이야기.
  static List<DialogueLine> worldScene(int w, int threshold, AppStrings s) {
    switch (threshold) {
      case 5:
        return [
          DialogueLine(MidnightFace.neutral, s.get('st_w${w}_a_1')),
          DialogueLine(MidnightFace.worried1, s.get('st_w${w}_a_2')),
        ];
      case 15:
        return [
          DialogueLine(MidnightFace.confident, s.get('st_w${w}_b_1')),
          DialogueLine(MidnightFace.happy1, s.get('st_w${w}_b_2')),
        ];
      case 10:
        const f = [MidnightFace.neutral, MidnightFace.confident, MidnightFace.worried1, MidnightFace.happy1];
        return [for (int i = 0; i < 4; i++) DialogueLine(f[i], s.get('mid_w${w}_${i + 1}'))];
      case 20:
        const f = [
          MidnightFace.neutral,
          MidnightFace.thinking,
          MidnightFace.worried1,
          MidnightFace.worried2,
          MidnightFace.happy1,
          MidnightFace.happy2,
        ];
        return [for (int i = 0; i < 6; i++) DialogueLine(f[i], s.get('end_w${w}_${i + 1}'))];
    }
    return const [];
  }

  /// 이야기 제목 — 큰/긴 이야기는 고유 제목, 짧은 이야기는 종류 이름.
  static String sceneTitle(int w, int threshold, AppStrings s) {
    switch (threshold) {
      case 10:
        return s.get('mid_w${w}_title');
      case 20:
        return s.get('end_w${w}_title');
    }
    return s.get('storyShort');
  }

  /// 종류 라벨 (노트 화면 칩용)
  static String kindLabel(int threshold, AppStrings s) {
    switch (threshold) {
      case 10:
        return s.get('storyBig');
      case 20:
        return s.get('storyLong');
    }
    return s.get('storyShort');
  }
}
