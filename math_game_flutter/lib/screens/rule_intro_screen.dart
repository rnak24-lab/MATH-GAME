import 'package:flutter/material.dart';

import '../game/tutorial_manager.dart';
import '../providers/locale_provider.dart';
import '../utils/nim_theme.dart';
import '../widgets/midnight_character.dart';
import 'world_select_screen.dart' show worlds;

/// 규칙 설명 화면 — (2026-09-16 대표님) "아예 시작부터 다른 화면을 만들어서 설명을 보게".
/// 수업의 첫 판에 들어가기 전에 한 번 뜬다(다시 보기: 규칙 노트). 그림 + 한 문장씩, 페이지로.
/// 막대과자(월드 4)는 규칙이 낯설어 전용 그림 3장. 나머지는 규칙 본문 + 보충 2줄.
class RuleIntroScreen extends StatefulWidget {
  final int world; // 1~12
  final LocaleProvider localeProvider;
  const RuleIntroScreen({super.key, required this.world, required this.localeProvider});

  @override
  State<RuleIntroScreen> createState() => _RuleIntroScreenState();
}

class _RuleIntroPage {
  final String text;
  final Widget picture;
  const _RuleIntroPage(this.text, this.picture);
}

class _RuleIntroScreenState extends State<RuleIntroScreen> {
  int _page = 0;

  static const List<String> _ruleKeys = [
    'ruleSingleRow', 'ruleDoubleRow', 'ruleTripleRow', 'rulePepero', 'ruleKayles', 'ruleWythoff',
    'ruleFibonacci', 'ruleChomp', 'ruleDots', 'ruleSim', 'ruleSprouts', 'ruleHex',
  ];
  static const List<String> _modeKeys = [
    'modeSingleRow', 'modeDoubleRow', 'modeTripleRow', 'modePepero', 'modeKayles', 'modeWythoff',
    'modeFibonacci', 'modeChomp', 'modeDots', 'modeSim', 'modeSprouts', 'modeHex',
  ];

  List<_RuleIntroPage> _pages(dynamic s) {
    final int n = widget.world;
    if (n == 4) {
      return [
        _RuleIntroPage(s.get('ri_w4_1'), const _PeperoPicture(kind: 0)),
        _RuleIntroPage(s.get('ri_w4_2'), const _PeperoPicture(kind: 1)),
        _RuleIntroPage(s.get('ri_w4_3'), const _PeperoPicture(kind: 2)),
        _RuleIntroPage(s.get('ri_w4_4'), const _PeperoPicture(kind: 3)),
      ];
    }
    final String snack = s.snackObj(TutorialManager.snackKeyForWorld(n));
    final String rule = n == 1
        ? s.get('ruleSingleRow', [snack, '2'])
        : (n <= 7 ? s.get(_ruleKeys[n - 1], [snack]) : s.get(_ruleKeys[n - 1]));
    final w = worlds[(n - 1).clamp(0, worlds.length - 1)];
    Widget emoji(String e) => Center(child: Text(e, style: const TextStyle(fontSize: 64)));
    return [
      _RuleIntroPage(rule, emoji(w.emoji)),
      _RuleIntroPage(s.get('rx_w${n}_1'), emoji('1️⃣')),
      _RuleIntroPage(s.get('rx_w${n}_2'), emoji('2️⃣')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.localeProvider.strings;
    final pages = _pages(s);
    final bool last = _page == pages.length - 1;
    final String mode = s.get(_modeKeys[widget.world - 1]);
    return Scaffold(
      backgroundColor: NimTheme.deskBottom,
      body: Container(
        decoration: const BoxDecoration(gradient: NimTheme.bg),
        child: SafeArea(
          child: Column(
            children: [
              // 상단: 제목
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${s.get('ruleIntroTitle')} · $mode',
                        style: const TextStyle(fontFamily: NimTheme.font, fontSize: 18, color: NimTheme.gold),
                      ),
                    ),
                    Text(
                      '${_page + 1}/${pages.length}',
                      style: TextStyle(fontFamily: NimTheme.font, fontSize: 13, color: NimTheme.cream.withOpacity(0.6)),
                    ),
                  ],
                ),
              ),
              // 예린 (작게) + 그림 카드
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 4),
                    const MidnightCharacter(face: MidnightFace.happy1, size: 210, animate: false),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: NimTheme.paperLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: NimTheme.gold, width: 2),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                child: KeyedSubtree(key: ValueKey(_page), child: pages[_page].picture),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              pages[_page].text,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: NimTheme.font,
                                fontSize: 16,
                                height: 1.55,
                                color: NimTheme.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 하단: 점 + 버튼
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(pages.length, (i) {
                        final on = i == _page;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: on ? 10 : 6,
                          height: on ? 10 : 6,
                          decoration: BoxDecoration(
                            color: on ? NimTheme.gold : NimTheme.cream.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (_page > 0)
                          Expanded(
                            child: _btn(s.get('ruleIntroBack'), NimTheme.frame, NimTheme.cream,
                                () => setState(() => _page--)),
                          ),
                        if (_page > 0) const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: _btn(
                            last ? s.get('ruleIntroStart') : s.get('tutNext'),
                            NimTheme.gold,
                            NimTheme.deskBottom,
                            () => last ? Navigator.pop(context) : setState(() => _page++),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _btn(String label, Color bg, Color fg, VoidCallback onTap) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(fontFamily: NimTheme.font, fontSize: 17, color: fg)),
        ),
      ),
    );
  }
}

/// 막대과자 규칙 그림 — kind 0: 묶음 하나를 둘로 / 1: 같은 개수 X, 다른 개수 O /
/// 2: 1개·2개는 못 쪼갬 / 3: 쪼갤 게 없으면 패배
class _PeperoPicture extends StatelessWidget {
  final int kind;
  const _PeperoPicture({required this.kind});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, cons) {
      return CustomPaint(size: Size(cons.maxWidth, cons.maxHeight), painter: _PeperoPainter(kind));
    });
  }
}

class _PeperoPainter extends CustomPainter {
  final int kind;
  _PeperoPainter(this.kind);

  static const Color _choco = Color(0xFF6B4226);
  static const Color _biscuit = Color(0xFFEAD3A2);
  static const Color _ok = Color(0xFF5E7D52);
  static const Color _no = Color(0xFF9B3B2E);
  static const Color _dim = Color(0xFFB8B0A0);

  void _stick(Canvas c, Offset topLeft, double w, double h, {bool dim = false}) {
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(topLeft.dx, topLeft.dy, w, h), Radius.circular(w / 2));
    c.drawRRect(r, Paint()..color = dim ? _dim : _biscuit);
    final top = RRect.fromRectAndCorners(
      Rect.fromLTWH(topLeft.dx, topLeft.dy, w, h * 0.6),
      topLeft: Radius.circular(w / 2),
      topRight: Radius.circular(w / 2),
    );
    c.drawRRect(top, Paint()..color = dim ? const Color(0xFF8C8478) : _choco);
  }

  /// 묶음: n개 막대, 중심 cx, 위 y. 반환 폭
  double _bundle(Canvas c, double cx, double y, int n, double w, double h, {int cut = -1, bool dim = false, Color? cutColor}) {
    const gap = 6.0;
    final total = n * w + (n - 1) * gap + (cut > 0 ? 14 : 0);
    double x = cx - total / 2;
    for (int i = 0; i < n; i++) {
      if (cut > 0 && i == cut) {
        // 자르는 선
        final lx = x + 4;
        c.drawLine(Offset(lx, y - 8), Offset(lx, y + h + 8), Paint()
          ..color = cutColor ?? _ok
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round);
        x += 14;
      }
      _stick(c, Offset(x, y), w, h, dim: dim);
      x += w + gap;
    }
    return total;
  }

  void _label(Canvas c, String t, Offset center, {Color color = const Color(0xFF332817), double size = 16}) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: TextStyle(fontFamily: 'NeoDGM', fontSize: size, color: color, fontWeight: FontWeight.w800)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _mark(Canvas c, bool ok, Offset center) {
    final p = Paint()
      ..color = ok ? _ok : _no
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    if (ok) {
      c.drawCircle(center, 13, p);
    } else {
      c.drawLine(center + const Offset(-11, -11), center + const Offset(11, 11), p);
      c.drawLine(center + const Offset(-11, 11), center + const Offset(11, -11), p);
    }
  }

  @override
  void paint(Canvas c, Size size) {
    final double cx = size.width / 2;
    const double w = 14, h = 62;
    switch (kind) {
      case 0: // 5 → 2 + 3
        _bundle(c, cx, size.height * 0.12, 5, w, h);
        _label(c, '▼', Offset(cx, size.height * 0.48), size: 18);
        _bundle(c, cx, size.height * 0.62, 5, w, h, cut: 2);
        _label(c, '2 + 3', Offset(cx, size.height * 0.62 + h + 22));
        break;
      case 1: // 6 → 3+3 X, 6 → 2+4 O
        final double y1 = size.height * 0.14, y2 = size.height * 0.58;
        final t1 = _bundle(c, cx - 20, y1, 6, w, h, cut: 3, cutColor: _no);
        _mark(c, false, Offset(cx - 20 + t1 / 2 + 30, y1 + h / 2));
        _label(c, '3 + 3', Offset(cx - 20, y1 + h + 18), color: _no);
        final t2 = _bundle(c, cx - 20, y2, 6, w, h, cut: 2);
        _mark(c, true, Offset(cx - 20 + t2 / 2 + 30, y2 + h / 2));
        _label(c, '2 + 4', Offset(cx - 20, y2 + h + 18), color: _ok);
        break;
      case 2: // 1, 2 는 못 쪼갬 (흐리게), 3 은 됨
        final double y = size.height * 0.3;
        _bundle(c, cx - 110, y, 1, w, h, dim: true);
        _mark(c, false, Offset(cx - 110, y + h + 24));
        _bundle(c, cx - 30, y, 2, w, h, dim: true);
        _mark(c, false, Offset(cx - 30, y + h + 24));
        _bundle(c, cx + 70, y, 3, w, h, cut: 1);
        _mark(c, true, Offset(cx + 70, y + h + 24));
        break;
      case 3: // 남은 게 2,1,2 뿐 → 내 차례면 패배
        final double y = size.height * 0.3;
        _bundle(c, cx - 90, y, 2, w, h, dim: true);
        _bundle(c, cx, y, 1, w, h, dim: true);
        _bundle(c, cx + 80, y, 2, w, h, dim: true);
        _label(c, '✕', Offset(cx, y + h + 30), color: _no, size: 30);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _PeperoPainter old) => old.kind != kind;
}
