import '../l10n/app_strings.dart';
import 'nim_engine.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// (2026-09-15 대표님) 튜토리얼은 "읽기" 에서 "**하기**" 로.
///
/// 월드 첫 판(1, 21, 41, …, 221)은 **가이드 판**이다:
///  - `read` 스텝: 예린이 말풍선으로 한 문장. 아무 데나 누르면 다음.
///  - `act` 스텝: 둬야 할 수가 하늘색으로 빛난다. 그 수만 둘 수 있다.
///    예린의 답수는 정해져 있거나(스크립트) AI 가 둔다.
///  - `follow` 스텝: 판이 끝날 때까지 "하늘색을 따라 두기". 규칙이 복잡한 변형·보드 게임용.
///
/// 글 4문장을 읽히고 손을 놓던 예전 방식(entrySteps)은 폐기했다.
/// ─────────────────────────────────────────────────────────────────────────

enum GuideKind { read, act, follow }

class GuideStep {
  final GuideKind kind;

  /// 말풍선 문장 (act/follow 는 플레이어 차례에만 표시)
  final String text;

  /// act: 플레이어가 둬야 하는 수
  final NimMove? require;

  /// act: 예린의 정해진 답수 (null 이면 AI)
  final NimMove? reply;

  const GuideStep.read(this.text)
      : kind = GuideKind.read,
        require = null,
        reply = null;
  const GuideStep.act(this.text, this.require, {this.reply})
      : kind = GuideKind.act;
  const GuideStep.follow(this.text)
      : kind = GuideKind.follow,
        require = null,
        reply = null;
}

class TutorialManager {
  /// 월드 첫 판인가? (님게임 7월드 + 보드 5월드)
  static bool isTutorialStage(int stageNumber) =>
      stageNumber >= 1 && (stageNumber - 1) % 20 == 0;

  /// stageNumber → 월드 번호 (1~12)
  static int worldOf(int stageNumber) => ((stageNumber - 1) ~/ 20) + 1;

  /// 월드(1-based) → 간식 키. game_screen 의 snackForStage 와 같은 순서.
  static String snackKeyForWorld(int world) {
    const keys = [
      'candy', // 1 등교길
      'chocolate', // 2 점심시간 옥상
      'cookie', // 3 방과후 교실
      'stick', // 4 밤의 도서관 (막대과자)
      'macaron', // 5 체육관
      'donut', // 6 과학실
      'jelly', // 7 뒤뜰 토끼장
    ];
    final i = (world - 1).clamp(0, keys.length - 1);
    return keys[i];
  }

  /// 월드 안에서 몇 번째 판인가 (0 = 가이드 판)
  static int offsetInWorld(int stageNumber) => (stageNumber - 1) % 20;

  /// 예린의 "봐주기" 확률 — 님게임 층 전용. (보드 층은 board_games.kBoardBlunder)
  /// 가이드 판 다음 두 판은 예린이 일부러 흔들린다: 2판째 50%, 3판째 25%. 그 뒤론 완벽.
  /// (D6 조언: 첫 세션 3분 안에 승리 2번이 나와야 한다)
  static double nimBlunderRate(int stageNumber) {
    switch (offsetInWorld(stageNumber)) {
      case 1:
        return 0.5;
      case 2:
        return 0.25;
    }
    return 0.0;
  }

  /// 님게임 층 가이드 스크립트. 스테이지 설정(초기 판)은 NimEngine.generateStage 가 정한다:
  ///   1: [4] 1~2개     21: [3,5]     41: [2,3,5]     61: 막대 6개
  ///   81 카일즈 / 101 위토프 / 121 피보나치: 규칙만 읽고 "하늘색 따라 두기"
  static List<GuideStep> nimGuide(int stageNumber, AppStrings s) {
    if (!isTutorialStage(stageNumber)) return const [];
    final int w = worldOf(stageNumber);
    final String snk = s.snackObj(snackKeyForWorld(w));
    final String snkSubj = s.snackSubj(snackKeyForWorld(w));
    switch (w) {
      case 1: // [4], 1~2개. 1개 → 예린 1개 → 2개 다 가져가면 승리.
        return [
          GuideStep.read(s.get('g1_1', [snk])),
          GuideStep.act(s.get('g1_2'), NimMove(rowIndex: 0, count: 1),
              reply: NimMove(rowIndex: 0, count: 1)),
          GuideStep.act(s.get('g1_3'), NimMove(rowIndex: 0, count: 2)),
        ];
      case 2: // [3,5] → 거울 전략. 아래 2 → [3,3]; 예린 위 2 → [1,3]; 아래 2 → [1,1]; 예린 1 → [0,1]; 마지막.
        return [
          GuideStep.read(s.get('g2_1', [snkSubj])),
          GuideStep.act(s.get('g2_2'), NimMove(rowIndex: 1, count: 2),
              reply: NimMove(rowIndex: 0, count: 2)),
          GuideStep.act(s.get('g2_3'), NimMove(rowIndex: 1, count: 2),
              reply: NimMove(rowIndex: 0, count: 1)),
          GuideStep.act(s.get('g2_4'), NimMove(rowIndex: 1, count: 1)),
        ];
      case 3: // [2,3,5] → 아래 4 → [2,3,1]; 예린 가운데 3 → [2,0,1]; 위 1 → [1,0,1]; 예린 위 1 → [0,0,1]; 마지막.
        return [
          GuideStep.read(s.get('g3_1')),
          GuideStep.act(s.get('g3_2'), NimMove(rowIndex: 2, count: 4),
              reply: NimMove(rowIndex: 1, count: 3)),
          GuideStep.act(s.get('g3_3'), NimMove(rowIndex: 0, count: 1),
              reply: NimMove(rowIndex: 0, count: 1)),
          GuideStep.act(s.get('g3_4'), NimMove(rowIndex: 2, count: 1)),
        ];
      case 4: // 막대 6 → 2+4 → [4,2]; 예린 4 → 1+3 → [3,2,1]; 3 → 1+2 → 예린 못 쪼갬.
        return [
          GuideStep.read(s.get('g4_1')),
          GuideStep.act(
              s.get('g4_2'), NimMove(rowIndex: 0, splitA: 2, splitB: 4, isPepero: true),
              reply: NimMove(rowIndex: 0, splitA: 1, splitB: 3, isPepero: true)),
          GuideStep.act(
              s.get('g4_3'), NimMove(rowIndex: 0, splitA: 1, splitB: 2, isPepero: true)),
        ];
      case 5: // 카일즈
        return [
          GuideStep.read(s.get('tutW6_1', [snk])),
          GuideStep.read(s.get('tutW6_2', [snk])),
          GuideStep.follow(s.get('gFollow', [snk])),
        ];
      case 6: // 위토프
        return [
          GuideStep.read(s.get('tutW7_1')),
          GuideStep.read(s.get('tutW7_2')),
          GuideStep.follow(s.get('gFollow', [snk])),
        ];
      case 7: // 피보나치
        return [
          GuideStep.read(s.get('tutW8_1')),
          GuideStep.read(s.get('tutW8_2')),
          GuideStep.follow(s.get('gFollow', [snk])),
        ];
    }
    return const [];
  }

  /// 보드 게임 층(월드 8~12) 가이드: 규칙 3문장 읽기 → 하늘색 따라 두기.
  static List<GuideStep> boardGuide(int stageNumber, AppStrings s) {
    if (!isTutorialStage(stageNumber)) return const [];
    const prefixes = {8: 'tutChomp', 9: 'tutDots', 10: 'tutSim', 11: 'tutSprouts', 12: 'tutHex'};
    final p = prefixes[worldOf(stageNumber)];
    if (p == null) return const [];
    return [
      for (int i = 1; i <= 3; i++) GuideStep.read(s.get('$p$i')),
      GuideStep.follow(s.get('gFollowBoard')),
    ];
  }

}
