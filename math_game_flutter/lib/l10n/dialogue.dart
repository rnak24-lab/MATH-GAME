import '../widgets/midnight_character.dart' show MidnightFace;
import 'app_strings.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// (2026-09-15 대표님) "클리어할 이유" — 미연시식 대화.
///
///  - 매 클리어 뒤: 그 월드의 짧은 한마디 (3개 로테이션)  → [afterClear]
///  - 호감도 단계가 오를 때: 4줄짜리 장면 (표정이 바뀐다)   → [scene]
///
/// 문장은 AppStrings 키(dc_w{월드}_{n}, sc_{레벨}_{n})로 두고 여기선 순서와 표정만 정한다.
/// ─────────────────────────────────────────────────────────────────────────
class DialogueLine {
  final MidnightFace face;
  final String text;
  const DialogueLine(this.face, this.text);
}

class Dialogue {
  /// 클리어 직후 한마디. [nth] = 이 월드에서 몇 번째 클리어인가 (로테이션용).
  static DialogueLine afterClear(int stageNumber, int nth, AppStrings s) {
    final int w = ((stageNumber - 1) ~/ 20) + 1; // 1~12
    final int i = (nth % 3) + 1;
    const faces = [MidnightFace.confident, MidnightFace.happy1, MidnightFace.worried1];
    return DialogueLine(faces[nth % 3], s.get('dc_w${w}_$i'));
  }

  /// 호감도 [level] 도달 장면 (2~10). 표정 순서는 레벨마다 다르다.
  static List<DialogueLine> scene(int level, AppStrings s) {
    const faces = <int, List<MidnightFace>>{
      2: [MidnightFace.neutral, MidnightFace.confident, MidnightFace.worried1, MidnightFace.happy1],
      3: [MidnightFace.neutral, MidnightFace.confident, MidnightFace.happy1, MidnightFace.happy2],
      4: [MidnightFace.neutral, MidnightFace.worried1, MidnightFace.happy1, MidnightFace.confident],
      5: [MidnightFace.thinking, MidnightFace.worried2, MidnightFace.neutral, MidnightFace.happy1],
      6: [MidnightFace.neutral, MidnightFace.worried1, MidnightFace.happy1, MidnightFace.confident],
      7: [MidnightFace.happy2, MidnightFace.neutral, MidnightFace.worried1, MidnightFace.happy1],
      8: [MidnightFace.thinking, MidnightFace.neutral, MidnightFace.happy1, MidnightFace.worried2],
      9: [MidnightFace.happy1, MidnightFace.happy2, MidnightFace.neutral, MidnightFace.worried1],
      10: [MidnightFace.confident, MidnightFace.neutral, MidnightFace.happy1, MidnightFace.happy2],
    };
    final f = faces[level];
    if (f == null) return const [];
    return [
      for (int i = 0; i < f.length; i++) DialogueLine(f[i], s.get('sc_${level}_${i + 1}')),
    ];
  }

  /// 장면 제목 (노트·홈 표시용)
  static String sceneTitle(int level, AppStrings s) => s.get('sc_${level}_title');
}
