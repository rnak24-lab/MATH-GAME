import 'package:flutter/material.dart';
import '../utils/design_system.dart';
import '../services/game_save_service.dart';
import 'world_select_screen.dart';

/// 튜토리얼 화면 - 팝업으로 하나씩 안내
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  int _step = 0;

  final List<_TutorialStep> _steps = [
    _TutorialStep(
      emoji: '👋',
      title: '안녕! 나는 수아야!',
      description: '나와 함께 수학 님(NIM) 게임을 해보자!\n두뇌싸움 준비됐어?',
    ),
    _TutorialStep(
      emoji: '🪨',
      title: '님 게임이 뭐야?',
      description: '돌이 놓여있어.\n번갈아가면서 돌을 가져가는 거야.\n마지막 돌을 가져가는 사람이 지는 거야!',
    ),
    _TutorialStep(
      emoji: '🎯',
      title: '한 줄 님게임',
      description: '돌이 한 줄로 놓여있어.\n한 번에 1~k개까지 가져갈 수 있어.\n마지막 돌을 가져가면 지는 거야!',
    ),
    _TutorialStep(
      emoji: '💡',
      title: '전략을 세워봐!',
      description: '그냥 가져가면 안 돼!\n상대방이 마지막 돌을 가져가도록\n전략적으로 생각해야 해!',
    ),
    _TutorialStep(
      emoji: '🗺️',
      title: '5개의 월드',
      description: '초원 마을 → 바다 왕국 → 빼빼로 숲\n→ 수정 궁전 → 드래곤 성\n\n월드마다 다른 규칙이 있어!',
    ),
    _TutorialStep(
      emoji: '🔑',
      title: '힌트도 있어!',
      description: '어려우면 힌트 열쇠를 사용해봐!\n최적의 수를 알려줄게.\n라운드당 3번까지 쓸 수 있어!',
    ),
    _TutorialStep(
      emoji: '🎀',
      title: '자, 시작하자!',
      description: '3스테이지를 클리어하면\n다음 월드가 열려!\n\n그럼 가보자~! 화이팅! 💪',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final step = _steps[_step];
    final isLast = _step == _steps.length - 1;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFCE4EC), Color(0xFFFFF3E0)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(DS.spaceLG),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // 진행도
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_steps.length, (i) {
                    return Container(
                      width: i == _step ? 24 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i <= _step
                            ? DS.primary
                            : DS.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const Spacer(),
                // 이모지
                Text(step.emoji, style: const TextStyle(fontSize: 80)),
                const SizedBox(height: DS.spaceLG),
                // 제목
                Text(step.title, style: DS.heading2),
                const SizedBox(height: DS.spaceMD),
                // 설명
                Container(
                  padding: const EdgeInsets.all(DS.spaceLG),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(DS.radiusLG),
                  ),
                  child: Text(
                    step.description,
                    style: DS.body.copyWith(
                      fontSize: DS.fontLG,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Spacer(flex: 2),
                // 버튼
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _next,
                    style: isLast ? DS.primaryButton : DS.secondaryButton,
                    child: Text(
                      isLast ? '게임 시작하기!' : '다음',
                      style: const TextStyle(fontSize: DS.fontLG),
                    ),
                  ),
                ),
                if (!isLast)
                  TextButton(
                    onPressed: _skip,
                    child: const Text(
                      '건너뛰기',
                      style: TextStyle(color: DS.textSecondary),
                    ),
                  ),
                const SizedBox(height: DS.spaceMD),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _next() {
    if (_step < _steps.length - 1) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  void _skip() => _finish();

  void _finish() {
    GameSaveService.setTutorialDone(true);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const WorldSelectScreen()),
    );
  }
}

class _TutorialStep {
  final String emoji;
  final String title;
  final String description;

  const _TutorialStep({
    required this.emoji,
    required this.title,
    required this.description,
  });
}
