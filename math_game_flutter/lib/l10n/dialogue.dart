import 'dart:math';

import '../widgets/midnight_character.dart' show MidnightFace;
import 'app_strings.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// (2026-09-16 대표님) 미연시식 이야기.
///
///  - 매 클리어 뒤: 그 수업(월드)의 짧은 한마디 (3개 로테이션)            → [afterClear]
///  - 수업 안에서 5·10·15판째: 미연시 화면으로 넘어가 예린↔나 대화 6줄     → [worldScene] k=1,2,3
///  - 20판 다 깨면: 긴 대화 12줄 (그 수업의 마무리)                          → [worldScene] k=4
///
/// 문장은 AppStrings 키 sc_w{w}_{k}_{i} / 제목 sc_w{w}_{k}_title. 화자 순서는 여기 고정
/// (짧은 장면 [예,나,예,예,나,예] / 긴 장면 [예,예,나,예,나,예,예,나,예,나,예,예]).
/// 열림 여부는 월드 클리어 수로만 결정되므로 "본 기록"이 필요 없다 (모음집에서 언제든 다시 봄).
/// ─────────────────────────────────────────────────────────────────────────
enum Speaker { yerin, me }

class DialogueLine {
  final MidnightFace face;
  final String text;
  final Speaker speaker;
  const DialogueLine(this.face, this.text, {this.speaker = Speaker.yerin});
}

class Dialogue {
  /// 장면이 열리는 수업 내 클리어 수 (k = 1..4)
  static const List<int> thresholds = [5, 10, 15, 20];

  static int worldOf(int stageNumber) => ((stageNumber - 1) ~/ 20) + 1; // 1~12

  /// 클리어 직후 한마디 — 그 수업의 풀(dc_w{w}_1..N)에서 무작위.
  static DialogueLine afterClear(int stageNumber, AppStrings s, Random rng) {
    final int w = worldOf(stageNumber);
    const faces = [MidnightFace.confident, MidnightFace.happy1, MidnightFace.worried1];
    return DialogueLine(faces[rng.nextInt(faces.length)], s.pick('dc_w$w', rng));
  }

  /// [count] 판째 클리어에서 열리는 장면 번호(1~4). 문턱이 아니면 null.
  static int? sceneFor(int count) {
    final i = thresholds.indexOf(count);
    return i < 0 ? null : i + 1;
  }

  /// 장면 k 가 열리는 클리어 수
  static int thresholdOf(int k) => thresholds[k - 1];

  /// 다음 장면까지 남은 판 수. 다 봤으면 0.
  static int untilNext(int count) {
    for (final t in thresholds) {
      if (count < t) return t - count;
    }
    return 0;
  }

  static const List<Speaker> _shortPattern = [
    Speaker.yerin, Speaker.me, Speaker.yerin, Speaker.yerin, Speaker.me, Speaker.yerin,
  ];
  static const List<MidnightFace> _shortFaces = [
    MidnightFace.neutral, MidnightFace.neutral, MidnightFace.confident,
    MidnightFace.worried1, MidnightFace.worried1, MidnightFace.happy1,
  ];
  static const List<Speaker> _longPattern = [
    Speaker.yerin, Speaker.yerin, Speaker.me, Speaker.yerin, Speaker.me, Speaker.yerin,
    Speaker.yerin, Speaker.me, Speaker.yerin, Speaker.me, Speaker.yerin, Speaker.yerin,
  ];
  static const List<MidnightFace> _longFaces = [
    MidnightFace.neutral, MidnightFace.thinking, MidnightFace.thinking, MidnightFace.confident,
    MidnightFace.confident, MidnightFace.worried1, MidnightFace.worried2, MidnightFace.worried2,
    MidnightFace.happy1, MidnightFace.happy1, MidnightFace.happy1, MidnightFace.happy2,
  ];

  static List<Speaker> speakers(int k) => k == 4 ? _longPattern : _shortPattern;
  static int lineCount(int k) => k == 4 ? 12 : 6;

  /// 수업 [w](1~12)의 장면 [k](1~4).
  static List<DialogueLine> worldScene(int w, int k, AppStrings s) {
    final sp = speakers(k);
    final faces = k == 4 ? _longFaces : _shortFaces;
    return [
      for (int i = 0; i < sp.length; i++)
        DialogueLine(faces[i], s.get('sc_w${w}_${k}_${i + 1}'), speaker: sp[i]),
    ];
  }

  static String sceneTitle(int w, int k, AppStrings s) => s.get('sc_w${w}_${k}_title');

  /// 장면 번호 라벨 "1-2"
  static String sceneNo(int w, int k) => '$w-$k';
}
