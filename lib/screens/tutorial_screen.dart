import 'package:flutter/material.dart';
import '../utils/design_system.dart';
import '../services/game_save_service.dart';
import 'world_select_screen.dart';

/// 튜토리얼 화면 - 깜냥이가 도박판 규칙을 설명
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  int _step = 0;

  final List<_TutorialStep> _steps = [
    _TutorialStep(
      emoji: '🎩',
      title: '...앉아.',
      description: '이 골목에서 판을 벌이려면\n규칙 정도는 알아야지.\n잘 들어.',
    ),
    _TutorialStep(
      emoji: '🪙',
      title: 'NIM 게임이란',
      description: '칩이 놓여있어.\n번갈아가면서 칩을 가져가는 거야.\n마지막 칩을 가져가면... 지는 거지.',
    ),
    _TutorialStep(
      emoji: '🃏',
      title: '기본 룰',
      description: '칩이 한 줄로 놓여있어.\n한 번에 1~k개까지 가져갈 수 있어.\n마지막 칩을 집는 놈이 지는 거야.',
    ),
    _TutorialStep(
      emoji: '🧠',
      title: '머리를 써.',
      description: '대충 가져가면 당하지.\n상대가 마지막 칩을 가져가도록\n몰아넣는 게 핵심이야.',
    ),
    _TutorialStep(
      emoji: '🌙',
      title: '5개의 테이블',
      description: 'Alley Corner → Neon Tavern → Smoke Den\n→ Shadow Market → The Last Bet\n\n테이블마다 다른 규칙이 있어.',
    ),
    _TutorialStep(
      emoji: '💡',
      title: '힌트가 필요하면',
      description: '어려우면 귓속말을 해줄 수도 있어.\n최적의 수를 알려주지.\n라운드당 3번까지.',
    ),
    _TutorialStep(
      emoji: '🃏',
      title: '자, 시작하지.',
      description: '3판을 클리어하면\n다음 테이블이 열려.\n\n...재밌게 해보자.',
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
            colors: [Color(0xFF0D0D0D), Color(0xFF1A1209), Color(0xFF0D0D0D)],
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
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i <= _step
                            ? DS.primary
                            : DS.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
                const Spacer(),
                // 이모지
                Text(step.emoji, style: const TextStyle(fontSize: 72)),
                const SizedBox(height: DS.spaceLG),
                // 제목
                Text(step.title,
                    style: DS.heading2.copyWith(fontStyle: FontStyle.italic)),
                const SizedBox(height: DS.spaceMD),
                // 설명
                Container(
                  padding: const EdgeInsets.all(DS.spaceLG),
                  decoration: BoxDecoration(
                    color: DS.panelBg,
                    borderRadius: BorderRadius.circular(DS.radiusMD),
                    border: Border.all(color: DS.primaryDark.withOpacity(0.3)),
                  ),
                  child: Text(
                    step.description,
                    style: TextStyle(
                      fontSize: DS.fontLG,
                      height: 1.6,
                      color: DS.textSecondary,
                      fontStyle: FontStyle.italic,
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
                      isLast ? '판에 참여하기' : '다음',
                      style: const TextStyle(fontSize: DS.fontLG),
                    ),
                  ),
                ),
                if (!isLast)
                  TextButton(
                    onPressed: _skip,
                    child: const Text(
                      '건너뛰기',
                      style: TextStyle(color: DS.inactive),
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
