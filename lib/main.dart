import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/game_save_service.dart';
import 'screens/home_screen.dart';
import 'utils/design_system.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 세로 모드 고정
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 저장 서비스 초기화
  await GameSaveService.init();

  runApp(const MathNimApp());
}

class MathNimApp extends StatelessWidget {
  const MathNimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NIM - The Gambler\'s Game',
      debugShowCheckedModeBanner: false,
      theme: DS.theme,
      home: const HomeScreen(),
    );
  }
}
