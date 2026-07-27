import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game/stage_manager.dart';
import 'providers/locale_provider.dart';
import 'screens/home_screen.dart';
import 'services/ad_service.dart';
import 'services/app_settings.dart';
import 'services/music_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // AdMob 초기화 (실패해도 앱은 정상 실행)
  AdService.instance.init();
  runApp(const MathNimApp());
}

class MathNimApp extends StatefulWidget {
  const MathNimApp({super.key});

  @override
  State<MathNimApp> createState() => _MathNimAppState();
}

class _MathNimAppState extends State<MathNimApp> {
  final LocaleProvider _localeProvider = LocaleProvider();

  @override
  void initState() {
    super.initState();
    _localeProvider.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '방과후 님게임',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B9D),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: SplashScreen(localeProvider: _localeProvider),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final LocaleProvider localeProvider;
  const SplashScreen({super.key, required this.localeProvider});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6, curve: Curves.elasticOut),
      ),
    );
    _opacityAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );
    _controller.forward();
    _loadAndNavigate();
  }

  Future<void> _loadAndNavigate() async {
    final stageManager = StageManager();
    await Future.wait([
      stageManager.load(),
      widget.localeProvider.load(),
      AppSettings.instance.load(),
    ]);

    // 배경음악 시작 (설정 ON일 때만, 실패해도 무해)
    if (AppSettings.instance.music) {
      MusicService.instance.start();
    }

    await Future.delayed(const Duration(milliseconds: 2200));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => HomeScreen(
            stageManager: stageManager,
            localeProvider: widget.localeProvider,
          ),
          transitionsBuilder: (_, anim, __, child) {
            return FadeTransition(opacity: anim, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.localeProvider.strings;

    // 로딩화면 — 홈과 같은 컨셉: 크림 수학낙서 배경 + 네이비 타이틀 밴드 + 예린
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E4),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/backgrounds/home.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          SafeArea(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Column(
                  children: [
                    const Spacer(flex: 2),
                    // 타이틀 밴드 (홈과 동일한 네이비+골드)
                    Transform.scale(
                      scale: _scaleAnim.value.clamp(0.0, 1.2),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 36),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xE62F2B57),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFFC9A24B), width: 2.5),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              s.get('appTitle'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'NeoDGM',
                                fontSize: 30,
                                color: Color(0xFFC9A24B),
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              s.get('appSubtitle'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'NeoDGM',
                                fontSize: 14,
                                color: Color(0xFFEADFC6),
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    // 예린 — 아이콘 사각형 대신 캐릭터가 직접 맞이
                    Opacity(
                      opacity: _opacityAnim.value,
                      child: Image.asset(
                        'assets/yerin/happy.png',
                        width: 240,
                        errorBuilder: (_, __, ___) =>
                            const SizedBox(width: 240, height: 200),
                      ),
                    ),
                    const Spacer(),
                    // 골드 스피너
                    Opacity(
                      opacity: _opacityAnim.value,
                      child: const SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          strokeWidth: 3.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFFC9A24B)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 56),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
