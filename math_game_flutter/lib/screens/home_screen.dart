import 'package:flutter/material.dart';
import '../widgets/midnight_character.dart';
import '../widgets/banner_ad_widget.dart';
import '../game/stage_manager.dart';
import '../providers/locale_provider.dart';
import '../utils/nim_theme.dart';
import 'world_select_screen.dart';
import 'settings_screen.dart';

/// 홈 — 세피아 노와르 통일 (2026-07-02 UX 개편 #1·#2).
/// 큰 한밤이 + 스포트라이트, 진행 배지, 이어하기(주)/처음부터(보조).
class HomeScreen extends StatefulWidget {
  final StageManager stageManager;
  final LocaleProvider localeProvider;

  const HomeScreen({
    super.key,
    required this.stageManager,
    required this.localeProvider,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  bool _showButtons = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _fadeController.forward();
      setState(() => _showButtons = true);
    });
    // 언어는 기기 설정 자동 추종 (LocaleProvider.load) — 변경은 설정에서.
    widget.stageManager.addListener(_onProgress); // 진행도 배지 즉시 반영
  }

  void _onProgress() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.stageManager.removeListener(_onProgress);
    _fadeController.dispose();
    super.dispose();
  }

  bool get _hasProgress => widget.stageManager.maxStage > 0;

  @override
  Widget build(BuildContext context) {
    final s = widget.localeProvider.strings;

    return Scaffold(
      backgroundColor: NimTheme.deskBottom,
      // 하단 상시 배너 광고
      bottomNavigationBar: const SafeArea(
        child: SizedBox(height: 50, child: Center(child: BannerAdWidget())),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: NimTheme.bg),
        child: SafeArea(
          child: Column(
            children: [
              // 설정
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8, top: 4),
                  child: IconButton(
                    icon: const Icon(Icons.settings_rounded,
                        color: NimTheme.cream, size: 26),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SettingsScreen(
                            localeProvider: widget.localeProvider,
                            onChanged: () => setState(() {}),
                            stageManager: widget.stageManager,
                          ),
                        ),
                      ).then((_) {
                        if (mounted) setState(() {});
                      });
                    },
                  ),
                ),
              ),
              const Spacer(),
              // 타이틀 (픽셀 폰트, 골드)
              const Text(
                'Math NIM',
                style: TextStyle(
                  fontFamily: NimTheme.font,
                  fontSize: 44,
                  color: NimTheme.gold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                s.get('mathNimSubtitle'),
                style: const TextStyle(
                  fontFamily: NimTheme.font,
                  fontSize: 16,
                  color: NimTheme.inkSoft,
                ),
              ),
              const Spacer(),
              // 큰 한밤이 + 스포트라이트 (주인공답게)
              SizedBox(
                width: 240,
                height: 220,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Center(
                      child: Container(
                        width: 230,
                        height: 230,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              NimTheme.cream.withOpacity(0.22),
                              NimTheme.gold.withOpacity(0.07),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 0.8],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 14,
                      child: Container(
                        width: 100,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: MidnightCharacter(
                        face: MidnightFace.happy1,
                        size: 180,
                        animate: false,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                s.get('midnightGreeting'),
                style: const TextStyle(
                  fontFamily: NimTheme.font,
                  fontSize: 15,
                  color: NimTheme.cream,
                ),
              ),
              const Spacer(),
              // 진행 배지: 다음 목적지 (월드명 · 스테이지 N)
              if (_hasProgress) _progressBadge(s),
              const SizedBox(height: 14),
              // 버튼들
              AnimatedOpacity(
                opacity: _showButtons ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 600),
                child: Column(
                  children: [
                    _stampButton(
                      label: _hasProgress
                          ? s.get('continueGame')
                          : s.get('startGame'),
                      icon: Icons.play_arrow_rounded,
                      color: NimTheme.gold,
                      textColor: NimTheme.deskBottom,
                      onTap: _goToWorldSelect,
                    ),
                    if (_hasProgress) ...[
                      const SizedBox(height: 10),
                      _stampButton(
                        label: s.get('selectStage'),
                        icon: Icons.grid_view_rounded,
                        color: NimTheme.frame,
                        textColor: NimTheme.cream,
                        onTap: _goToWorldSelect,
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _progressBadge(dynamic s) {
    final int next = (widget.stageManager.maxStage + 1).clamp(1, 80);
    final world = worldForStage(next);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: NimTheme.deskBoard,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: NimTheme.frameHi, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, color: world.color),
          const SizedBox(width: 8),
          Text(
            '${world.name(s)} · ${s.get('stageLabel', ['$next'])}',
            style: const TextStyle(
              fontFamily: NimTheme.font,
              fontSize: 13,
              color: NimTheme.cream,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stampButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 44),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: Colors.black.withOpacity(0.35), width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: textColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: NimTheme.font,
                    fontSize: 18,
                    color: textColor,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _goToWorldSelect() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorldSelectScreen(
          stageManager: widget.stageManager,
          localeProvider: widget.localeProvider,
        ),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }
}
