import 'package:flutter/material.dart';

import '../l10n/dialogue.dart';
import '../providers/locale_provider.dart';
import '../utils/nim_theme.dart';
import '../widgets/dialogue_box.dart';
import '../widgets/midnight_character.dart';
import 'world_select_screen.dart' show worlds;

/// 미연시 화면 — (2026-09-16 대표님) "진짜 미연시 화면으로 넘어간 것처럼".
/// 그 수업의 배경 + 큰 예린 + 아래 대화 상자([예린]/[나] 이름표). 어디를 눌러도 다음 줄.
/// 내가 말할 땐 예린이 살짝 어두워진다. 게임에서 5·10·15·20판째에 열리고, 모음집에서도 연다.
class SceneScreen extends StatefulWidget {
  final int world; // 1~12
  final int scene; // 1~4
  final LocaleProvider localeProvider;

  const SceneScreen({
    super.key,
    required this.world,
    required this.scene,
    required this.localeProvider,
  });

  @override
  State<SceneScreen> createState() => _SceneScreenState();
}

class _SceneScreenState extends State<SceneScreen> {
  final GlobalKey<DialogueBoxState> _box = GlobalKey<DialogueBoxState>();
  MidnightFace _face = MidnightFace.neutral;
  bool _meSpeaking = false;
  bool _showTitle = true;

  @override
  void initState() {
    super.initState();
    // 제목 카드 1.4초 뒤 사라짐
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _showTitle = false);
    });
  }

  void _onLine(DialogueLine l) {
    setState(() {
      _meSpeaking = l.speaker == Speaker.me;
      if (l.speaker == Speaker.yerin) _face = l.face;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.localeProvider.strings;
    final w = worlds[(widget.world - 1).clamp(0, worlds.length - 1)];
    final lines = Dialogue.worldScene(widget.world, widget.scene, s);
    final title = Dialogue.sceneTitle(widget.world, widget.scene, s);
    final no = Dialogue.sceneNo(widget.world, widget.scene);
    final double h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: NimTheme.deskBottom,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _box.currentState?.tap(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 배경 — 그 수업의 배경 그림
            Image.asset(
              'assets/backgrounds/world${w.id}.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: w.bgGradient,
                  ),
                ),
              ),
            ),
            // 예린 — 크게. 내가 말할 땐 어두워진다. (Positioned 는 Stack 바로 아래여야 한다)
            Positioned(
              top: h * 0.08,
              left: 0,
              right: 0,
              // 투명도 대신 어둡게 (투명하면 배경이 비쳐 보여 어색하다)
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(_meSpeaking ? 0.38 : 0.0),
                  BlendMode.srcATop,
                ),
                child: Center(
                  child: MidnightCharacter(
                    face: _face,
                    size: (h * 0.78).clamp(420.0, 760.0),
                    animate: false,
                  ),
                ),
              ),
            ),
            // 아래 어두운 그라데이션 (대화 상자 가독성)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 320,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
                    ),
                  ),
                ),
              ),
            ),
            // 왼쪽 위: 장면 번호 · 제목  /  오른쪽 위: 건너뛰기
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$no · $title',
                        style: const TextStyle(
                          fontFamily: NimTheme.font,
                          fontSize: 13,
                          color: NimTheme.cream,
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: NimTheme.cream,
                        backgroundColor: Colors.black.withOpacity(0.45),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      child: Text(
                        s.get('sceneSkip'),
                        style: const TextStyle(fontFamily: NimTheme.font, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 제목 카드 — 시작할 때 잠깐
            if (_showTitle)
              IgnorePointer(
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _showTitle ? 1 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: NimTheme.gold, width: 2),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            no,
                            style: const TextStyle(
                              fontFamily: NimTheme.font,
                              fontSize: 14,
                              color: NimTheme.gold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            title,
                            style: const TextStyle(
                              fontFamily: NimTheme.font,
                              fontSize: 22,
                              color: NimTheme.cream,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            // 대화 상자
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: DialogueBox(
                  key: _box,
                  lines: lines,
                  yerinName: s.get('nameMidnight'),
                  meName: s.get('nameYou'),
                  onLine: _onLine,
                  onDone: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
