import '../l10n/app_strings.dart';

/// 월드별 튜토리얼 스텝 — 예린 시나리오(NIM_월드별_튜토리얼_시나리오.md) 기반.
/// 각 월드의 1라운드(Stage 1, 21, 41, 61, 81)에서만 활성화된다.
class TutorialStep {
  /// 말풍선에 표시할 텍스트
  final String text;

  /// 하이라이트 대상 (선택적, UI 구현에 따라 확장 가능)
  /// 현재는 말풍선 + 다음 버튼만 구현 (최소 MVP).
  final String? highlightTarget;

  const TutorialStep({required this.text, this.highlightTarget});
}

class TutorialManager {
  /// 특정 stageNumber가 월드별 튜토리얼 1라운드인가?
  /// 월드 1=1, 월드 2=21, 월드 3=41, 월드 4=61, 월드 5=81
  static bool isTutorialStage(int stageNumber) {
    return stageNumber == 1 ||
        stageNumber == 21 ||
        stageNumber == 41 ||
        stageNumber == 61 ||
        stageNumber == 81;
  }

  /// stageNumber → 월드 번호 (1~5)
  static int worldOf(int stageNumber) {
    if (stageNumber <= 20) return 1;
    if (stageNumber <= 40) return 2;
    if (stageNumber <= 60) return 3;
    if (stageNumber <= 80) return 4;
    return 5;
  }

  /// 게임 시작 시 표시할 진입 튜토리얼 스텝 리스트.
  /// 비어있으면 튜토리얼 없음 = 일반 게임 플로우.
  static List<TutorialStep> entrySteps(int stageNumber, AppStrings s) {
    if (!isTutorialStage(stageNumber)) return const [];
    switch (worldOf(stageNumber)) {
      case 1:
        // (2026-07-02 대표님) 짧고 액션 지시형 4스텝 — 표정 설명 삭제(플레이하며 발견),
        // 지시대로 따라 하면(2개 집기) 스테이지 1은 무조건 승리.
        return [
          TutorialStep(text: s.get('tutW1_1')),
          TutorialStep(text: s.get('tutW1_2'), highlightTarget: 'stones'),
          TutorialStep(text: s.get('tutW1_3'), highlightTarget: 'last_stone'),
          TutorialStep(text: s.get('tutW1_4'), highlightTarget: 'take_buttons'),
        ];
      case 2:
        return [
          TutorialStep(text: s.get('tutW2_1'), highlightTarget: 'rows'),
          TutorialStep(text: s.get('tutW2_2')),
          TutorialStep(text: s.get('tutW2_3')),
          TutorialStep(text: s.get('tutW2_4'), highlightTarget: 'row_1'),
        ];
      case 3:
        return [
          TutorialStep(text: s.get('tutW3_1'), highlightTarget: 'maxtake_badge'),
          TutorialStep(text: s.get('tutW3_2')),
          TutorialStep(text: s.get('tutW3_3')),
          TutorialStep(text: s.get('tutW3_4')),
        ];
      case 4:
        return [
          TutorialStep(text: s.get('tutW4_1'), highlightTarget: 'rows'),
          TutorialStep(text: s.get('tutW4_2')),
          TutorialStep(text: s.get('tutW4_3')),
          TutorialStep(text: s.get('tutW4_4')),
        ];
      case 5:
        return [
          TutorialStep(text: s.get('tutW5_1')),
          TutorialStep(text: s.get('tutW5_2')),
          TutorialStep(text: s.get('tutW5_3')),
        ];
    }
    return const [];
  }

  /// 2회 연속 패배 시 자동 힌트 텍스트 (예린 정책).
  /// 현재는 월드 1/2만 차별화된 힌트 제공, 나머지는 공통.
  static String autoHintOnConsecutiveLoss(int stageNumber, AppStrings s) {
    switch (worldOf(stageNumber)) {
      case 1:
        return s.get('tutHintW1');
      case 2:
        return s.get('tutHintW2');
      case 3:
        return s.get('tutHintW3');
      case 4:
        return s.get('tutHintW4');
      case 5:
        return s.get('tutHintW5');
    }
    return s.get('tutHintGeneric');
  }
}
