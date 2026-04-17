import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game/stage_manager.dart';
import 'providers/locale_provider.dart';
import 'screens/home_screen.dart';
import 'services/ad_service.dart';

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
      title: 'Math NIM',
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
    ]);

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

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF6B9D),
              Color(0xFF7C4DFF),
              Color(0xFF42A5F5),
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: _scaleAnim.value,
                  child: const Text(
                    '🎲',
                    style: TextStyle(fontSize: 72),
                  ),
                ),
                const SizedBox(height: 24),
                Opacity(
                  opacity: _opacityAnim.value,
                  child: Column(
                    children: [
                      const Text(
                        'Math NIM',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.get('appSubtitle'),
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
                Opacity(
                  opacity: _opacityAnim.value,
                  child: const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
