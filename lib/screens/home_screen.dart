import 'package:flutter/material.dart';
import '../utils/design_system.dart';
import '../services/game_save_service.dart';
import 'world_select_screen.dart';
import 'tutorial_screen.dart';

/// 메인 홈 화면
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _bounceAnim = Tween<double>(begin: 0, end: 12).animate(
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
            colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // 타이틀
              const Text('🧮', style: TextStyle(fontSize: 64)),
              const SizedBox(height: DS.spaceMD),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [DS.primary, DS.secondary],
                ).createShader(bounds),
                child: const Text(
                  '수학 님 게임',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: DS.spaceSM),
              const Text(
                'Math NIM Game',
                style: TextStyle(
                  fontSize: DS.fontLG,
                  color: DS.textSecondary,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: DS.spaceXL),

              // 수아 캐릭터
              AnimatedBuilder(
                animation: _bounceAnim,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, -_bounceAnim.value),
                    child: child,
                  );
                },
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFCDD2), Color(0xFFF8BBD0)],
                        ),
                        border: Border.all(color: DS.primary, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: DS.primary.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('😊', style: TextStyle(fontSize: 50)),
                      ),
                    ),
                    const SizedBox(height: DS.spaceSM),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: DS.primary,
                        borderRadius: BorderRadius.circular(DS.radiusFull),
                      ),
                      child: const Text(
                        '🎀 수아',
                        style: TextStyle(
                          color: Colors.white,
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
                '수아와 두뇌싸움 할 준비 됐어?',
                style: DS.body.copyWith(fontSize: DS.fontLG),
              ),

              const Spacer(flex: 2),

              // 게임 시작 버튼
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: DS.spaceXL),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _startGame(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DS.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DS.radiusXL),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      '게임 시작!',
                      style: TextStyle(
                        fontSize: DS.fontXL,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: DS.spaceMD),

              // 진행 상황
              Text(
                '클리어: ${GameSaveService.maxStageCleared}/100 스테이지',
                style: DS.caption,
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
