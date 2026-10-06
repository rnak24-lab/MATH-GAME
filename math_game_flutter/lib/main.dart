import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game/stage_manager.dart';
import 'providers/locale_provider.dart';
import 'screens/home_screen.dart';
import 'services/ad_service.dart';
import 'services/app_settings.dart';
import 'services/music_service.dart';
import 'services/telemetry.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // AdMob 초기화 (실패해도 앱은 정상 실행)
  AdService.instance.init();
  Telemetry.instance.load(); // 테스트 계측 (세션 수) — 실패해도 무시
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
      // 작업 전환기에 뜨는 이름 — 선택한 언어를 따라간다.
      title: _localeProvider.strings.get('appTitle'),
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
  final Stopwatch _sw = Stopwatch();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
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
    _sw.start();
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

    // 홈 그림을 미리 읽어 두면 홈이 뜰 때 예린이 늦게 나타나지 않는다
    if (mounted) {
      await Future.wait([
        precacheImage(const AssetImage('assets/backgrounds/home.png'), context),
        precacheImage(const AssetImage('assets/yerin/happy.png'), context),
      ]).catchError((_) => <void>[]);
    }
    // 너무 짧으면 깜빡이는 느낌이라 최소 0.9초
    final left = 900 - _sw.elapsedMilliseconds;
    if (left > 0) await Future.delayed(Duration(milliseconds: left));

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

    // (2026-10-06 대표님) 로딩화면 — 게임들처럼 남색 바탕 + 제목 + 진행 막대만.
    // 예린은 홈에서 처음 크게 등장한다 (로딩에서 작게 미리 보여주면 홈이 김빠짐).
    return Scaffold(
      backgroundColor: const Color(0xFF1F1B3A),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Opacity(
              opacity: _opacityAnim.value,
              child: Column(
                children: [
                  const Spacer(flex: 5),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        s.get('appTitle'),
                        maxLines: 1,
                        style: const TextStyle(
                          fontFamily: 'NeoDGM',
                          fontSize: 40,
                          color: Color(0xFFC9A24B),
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    s.get('appSubtitle'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'NeoDGM',
                      fontSize: 15,
                      color: const Color(0xFFEADFC6).withOpacity(0.8),
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(flex: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 72),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: _controller.value,
                        minHeight: 4,
                        backgroundColor: Colors.white.withOpacity(0.12),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC9A24B)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'ENDOLPHIN STUDIO',
                    style: TextStyle(
                      fontFamily: 'NeoDGM',
                      fontSize: 11,
                      letterSpacing: 3,
                      color: const Color(0xFFEADFC6).withOpacity(0.45),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
