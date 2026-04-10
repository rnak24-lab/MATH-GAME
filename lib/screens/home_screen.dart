import 'package:flutter/material.dart';
import '../utils/design_system.dart';
import '../services/game_save_service.dart';
import 'world_select_screen.dart';
import 'tutorial_screen.dart';

/// 메인 홈 화면 - 비 내리는 밤 골목 도박판 테마
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _flickerAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _flickerAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D0D0D), Color(0xFF1A1209)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // 가스등 아이콘
              AnimatedBuilder(
                animation: _flickerAnim,
                builder: (context, child) {
                  return Opacity(
                    opacity: _flickerAnim.value,
                    child: child,
                  );
                },
                child: const Text('🏮', style: TextStyle(fontSize: 48)),
              ),
              const SizedBox(height: DS.spaceMD),
              // 타이틀 - 황동 간판 스타일
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFC9A84C), Color(0xFFE8B86D), Color(0xFFC9A84C)],
                ).createShader(bounds),
                child: const Text(
                  'NIM',
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 8,
                  ),
                ),
              ),
              const SizedBox(height: DS.spaceSM),
              const Text(
                'The Gambler\'s Game',
                style: TextStyle(
                  fontSize: DS.fontMD,
                  color: DS.textSecondary,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 3,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: DS.spaceXL),

              // 깜냥이(나이트) 캐릭터
              AnimatedBuilder(
                animation: _flickerAnim,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, -4 * (1 - _flickerAnim.value)),
                    child: child,
                  );
                },
                child: Column(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2A1F14), Color(0xFF3D2B1F)],
                        ),
                        border: Border.all(color: DS.primaryDark, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: DS.primary.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('🎩', style: TextStyle(fontSize: 55)),
                      ),
                    ),
                    const SizedBox(height: DS.spaceSM),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: DS.panelBg,
                        borderRadius: BorderRadius.circular(DS.radiusMD),
                        border: Border.all(color: DS.primaryDark.withOpacity(0.5)),
                      ),
                      child: const Text(
                        '🃏 깜냥이',
                        style: TextStyle(
                          color: DS.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: DS.fontSM,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: DS.spaceMD),
              Text(
                '...자리에 앉겠나?',
                style: DS.body.copyWith(
                  fontSize: DS.fontLG,
                  fontStyle: FontStyle.italic,
                  color: DS.textSecondary,
                ),
              ),

              const Spacer(flex: 2),

              // 게임 시작 버튼 - 나무 문패 스타일
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: DS.spaceXL),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _startGame(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DS.panelBg,
                      foregroundColor: DS.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DS.radiusMD),
                        side: const BorderSide(color: DS.primaryDark, width: 2),
                      ),
                      elevation: 6,
                    ),
                    child: const Text(
                      '판에 참여하기',
                      style: TextStyle(
                        fontSize: DS.fontXL,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: DS.spaceMD),

              // 진행 상황
              Text(
                '클리어: ${GameSaveService.maxStageCleared}/100 스테이지',
                style: const TextStyle(
                  color: DS.inactive,
                  fontSize: DS.fontSM,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  void _startGame(BuildContext context) {
    if (!GameSaveService.tutorialDone) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TutorialScreen()),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const WorldSelectScreen()),
      );
    }
  }
}
