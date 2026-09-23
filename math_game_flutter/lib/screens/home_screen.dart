import 'package:flutter/material.dart';
import '../widgets/midnight_character.dart';
import '../game/stage_manager.dart';
import '../providers/locale_provider.dart';
import '../utils/nim_theme.dart';
import 'world_select_screen.dart';
import 'settings_screen.dart';
import 'note_screen.dart';
import 'gallery_screen.dart';
import 'game_screen.dart';
import '../game/nim_engine.dart';

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

  /// 하단 책상 패널 대략 높이(인사말+배지+버튼 3줄) — 예린 크기 계산용
  static const double _kHomePanelH = 250;

  @override
  Widget build(BuildContext context) {
    final s = widget.localeProvider.strings;

    return Scaffold(
      backgroundColor: NimTheme.deskBottom,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: NimTheme.bg),
        // 수학 기호 난사 배경 (assets/backgrounds/home.png 있으면 사용)
        foregroundDecoration: null,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/backgrounds/home.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
            _homeBody(s),
          ],
        ),
      ),
    );
  }

  Widget _homeBody(dynamic s) {
    return SafeArea(
      child: LayoutBuilder(builder: (context, cons) {
        final double h = cons.maxHeight;
        // 타이틀 밴드 아래(+130)부터 하단 패널 위(-_kHomePanelH)까지가 예린 머리~가슴팍.
        // 게임 화면처럼 그림 높이의 약 62% 지점에서 잘리게 크기를 정한다.
        final double yerinTop = h * 0.075 + 130;
        final double yerinH =
            ((h - yerinTop - _kHomePanelH) / 0.62).clamp(560.0, 820.0);
        return Stack(
          children: [
            // 예린 — 게임 화면과 같은 구도: 타이틀 밴드 아래에 얼굴, 가슴팍까지만 보이고
            // 나머지는 하단 책상 패널 뒤로 (2026-09-23 대표님: 크게, 가슴팍까지)
            Positioned(
              top: yerinTop,
              left: 0,
              right: 0,
              child: Center(
                child: MidnightCharacter(
                  face: MidnightFace.happy1,
                  size: yerinH,
                  animate: false,
                ),
              ),
            ),
            // 설정
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8, top: 4),
                child: IconButton(
                  icon: const Icon(Icons.settings_rounded,
                      color: Color(0xFF2F2B57), size: 26),
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
            // 타이틀 밴드 — 진네이비 패널 + 골드, 확실히 보이게
            Positioned(
              top: h * 0.075,
              left: 24,
              right: 24,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xE62F2B57),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: NimTheme.gold, width: 2.5),
                ),
                child: Column(
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        s.get('appTitle'),
                        maxLines: 1,
                        style: const TextStyle(
                          fontFamily: NimTheme.font,
                          fontSize: 42,
                          color: NimTheme.gold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      s.get('mathNimSubtitle'),
                      style: const TextStyle(
                        fontFamily: NimTheme.font,
                        fontSize: 16,
                        color: NimTheme.cream,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 하단 책상 패널 — 인사말·배지·버튼. 예린 하반신을 가린다 (불투명).
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 16),
                decoration: const BoxDecoration(
                  color: Color(0xF2EFE6D0),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                  border: Border(top: BorderSide(color: NimTheme.gold, width: 2.5)),
                  boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 14, offset: Offset(0, -4))],
                ),
                child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 인사말 캡슐
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: const Color(0x332F2B57), width: 1),
                    ),
                    child: Text(
                      s.get(_hasProgress ? 'midnightGreeting' : 'midnightGreetingNew'),
                      style: const TextStyle(
                        fontFamily: NimTheme.font,
                        fontSize: 15,
                        color: Color(0xFF2F2B57),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_hasProgress) _progressBadge(s),
                  const SizedBox(height: 12),
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
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 44),
                          child: Row(
                            children: [
                              Expanded(child: _smallButton(
                                label: widget.stageManager.dailyDoneToday
                                    ? s.get('dailyDone', ['${widget.stageManager.dailyStreak}'])
                                    : s.get('dailyButton'),
                                icon: widget.stageManager.dailyDoneToday
                                    ? Icons.check_circle_rounded
                                    : Icons.today_rounded,
                                onTap: _startDaily,
                              )),
                              const SizedBox(width: 8),
                              Expanded(child: _smallButton(
                                label: s.get('galleryButton'),
                                icon: Icons.auto_stories_rounded,
                                onTap: _openGallery,
                              )),
                              const SizedBox(width: 8),
                              Expanded(child: _smallButton(
                                label: s.get('noteButton'),
                                icon: Icons.menu_book_rounded,
                                onTap: _openNote,
                              )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _progressBadge(dynamic s) {
    // 버전2: 7월드 140 + 보드 게임 5월드 100 = 240 스테이지
    final int next = (widget.stageManager.maxStage + 1).clamp(1, 240);
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

  /// 보조 버튼 — 오늘의 한 판 / 예린의 노트 (반폭)
  Widget _smallButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: NimTheme.frame,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black.withOpacity(0.35), width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: NimTheme.cream, size: 16),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: NimTheme.font,
                    fontSize: 13,
                    color: NimTheme.cream,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 오늘의 한 판 — 날짜 시드, 아는 모드 안에서. 이미 이겼으면 안내만.
  void _startDaily() {
    final sm = widget.stageManager;
    if (sm.dailyDoneToday) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.localeProvider.strings.get('dailyDoneHint'),
            style: const TextStyle(fontFamily: NimTheme.font)),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
      return;
    }
    final cfg = NimEngine().dailyStage(
        int.parse(StageManager.todayKey()), sm.worldUnlocked);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          stageManager: sm,
          stageNumber: 0,
          localeProvider: widget.localeProvider,
          dailyConfig: cfg,
        ),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _openGallery() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GalleryScreen(
          stageManager: widget.stageManager,
          localeProvider: widget.localeProvider,
        ),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _openNote() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteScreen(
          stageManager: widget.stageManager,
          localeProvider: widget.localeProvider,
        ),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
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
