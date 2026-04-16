import 'package:flutter/material.dart';
import '../widgets/midnight_character.dart';
import '../widgets/language_select_dialog.dart';
import '../game/stage_manager.dart';
import '../providers/locale_provider.dart';
import 'world_select_screen.dart';
import 'settings_screen.dart';

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

    Future.delayed(const Duration(milliseconds: 500), () {
      _fadeController.forward();
      setState(() => _showButtons = true);
    });

    // 첫 실행 시 언어 선택 모달 노출
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (widget.localeProvider.hasSelectedLanguage) return;
      await LanguageSelectDialog.showIfNeeded(
        context,
        widget.localeProvider,
      );
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.localeProvider.strings;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF3E0),
              Color(0xFFFFE0B2),
              Color(0xFFFFF8E1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Settings button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12, top: 4),
                  child: IconButton(
                    icon: const Icon(Icons.settings_rounded,
                        color: Color(0xFF7C4DFF), size: 28),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SettingsScreen(
                            localeProvider: widget.localeProvider,
                            onChanged: () => setState(() {}),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const Spacer(flex: 1),
              // Title
              _buildTitle(),
              const SizedBox(height: 8),
              Text(
                s.get('mathNimSubtitle'),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(flex: 1),
              // Midnight character
              const MidnightCharacter(
                face: MidnightFace.happy1,
                size: 150,
                animate: true,
              ),
              const SizedBox(height: 12),
              Text(
                s.get('midnightGreeting'),
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                ),
              ),
              const Spacer(flex: 1),
              // Progress
              if (widget.stageManager.maxStage > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      s.get('clearProgress',
                          ['${widget.stageManager.maxStage}']),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7C4DFF),
                      ),
                    ),
                  ),
                ),
              // Buttons
              AnimatedOpacity(
                opacity: _showButtons ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 800),
                child: Column(
                  children: [
                    _buildMainButton(
                      label: widget.stageManager.maxStage > 0
                          ? s.get('continueGame')
                          : s.get('startGame'),
                      icon: widget.stageManager.maxStage > 0
                          ? Icons.play_arrow_rounded
                          : Icons.play_circle_outline_rounded,
                      color: const Color(0xFFFF6B9D),
                      onTap: () => _goToGame(),
                    ),
                    const SizedBox(height: 12),
                    if (widget.stageManager.maxStage > 0)
                      _buildMainButton(
                        label: s.get('selectStage'),
                        icon: Icons.grid_view_rounded,
                        color: const Color(0xFF7C4DFF),
                        onTap: () => _goToWorldSelect(),
                      ),
                    const SizedBox(height: 12),
                    if (widget.stageManager.maxStage > 0)
                      TextButton(
                        onPressed: () => _goToGame(fromStart: true),
                        child: Text(
                          s.get('startFromBeginning'),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFFFF6B9D), Color(0xFF7C4DFF)],
      ).createShader(bounds),
      child: const Text(
        'Math NIM',
        style: TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildMainButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(30),
        elevation: 4,
        shadowColor: color.withOpacity(0.4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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

  void _goToGame({bool fromStart = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorldSelectScreen(
          stageManager: widget.stageManager,
          localeProvider: widget.localeProvider,
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
    );
  }
}
