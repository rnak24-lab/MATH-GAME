import 'package:flutter/material.dart';

import '../game/tutorial_manager.dart';
import '../providers/locale_provider.dart';
import '../utils/nim_theme.dart';
import '../widgets/midnight_character.dart';
import '../game/board_games.dart';
import 'board_game_screen.dart' show BoardView;

/// 규칙 설명 화면 — (2026-09-16 대표님) "아예 시작부터 다른 화면을 만들어서 설명을 보게".
/// 수업의 첫 판에 들어가기 전에 한 번 뜬다(다시 보기: 규칙 노트). 그림 + 한 문장씩, 페이지로.
/// 막대과자(월드 4)는 규칙이 낯설어 전용 그림 3장. 나머지는 규칙 본문 + 보충 2줄.
class RuleIntroScreen extends StatefulWidget {
  final int world; // 1~12
  final LocaleProvider localeProvider;

  /// 게임 화면 안에 인라인으로 띄울 때: 마지막 페이지에서 pop 대신 이 콜백.
  final VoidCallback? onDone;
  const RuleIntroScreen({super.key, required this.world, required this.localeProvider, this.onDone});

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
    // 그림: 님 계열은 간식 줄 그림 3장, 보드 계열은 실제 첫 판 미리보기
    Widget pic(int page) {
      if (n <= 7) return _NimPicture(world: n, page: page, take: s.get('riTake'), last: s.get('riLast'));
      return _BoardPreview(stage: (n - 1) * 20 + 1);
    }
    return [
      _RuleIntroPage(rule, pic(0)),
      _RuleIntroPage(s.get('rx_w${n}_1'), pic(1)),
      _RuleIntroPage(s.get('rx_w${n}_2'), pic(2)),
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
                    const MidnightCharacter(face: MidnightFace.happy1, size: 170, animate: false),
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
                            () => last
                                ? (widget.onDone != null ? widget.onDone!() : Navigator.pop(context))
                                : setState(() => _page++),
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

/// 보드 게임 미리보기 — 실제 첫 판(BoardGame.forStage)을 그대로 그린다 (터치 불가).
class _BoardPreview extends StatelessWidget {
  final int stage;
  const _BoardPreview({required this.stage});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: BoardView(
        game: BoardGame.forStage(stage),
        hint: null,
        selPoint: -1,
        enabled: false,
        onMove: (_) {},
        onSelectPoint: (_) {},
      ),
    );
  }
}

/// 님 계열 규칙 그림 — 간식 줄 + 하늘색(가져갈 것) + 별(마지막 = 승리)
class _NimPicture extends StatelessWidget {
  final int world;
  final int page;
  final String take;
  final String last;
  const _NimPicture({required this.world, required this.page, required this.take, required this.last});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, cons) {
      return CustomPaint(
        size: Size(cons.maxWidth, cons.maxHeight),
        painter: _NimPicturePainter(world, page, take, last),
      );
    });
  }
}

class _NimPicturePainter extends CustomPainter {
  final int world, page;
  final String take, last;
  _NimPicturePainter(this.world, this.page, this.take, this.last);

  static const Color _candy = Color(0xFFE88BB0);
  static const Color _candyDark = Color(0xFFB85C86);
  static const Color _sky = Color(0xFF3D8FB8);
  static const Color _ink = Color(0xFF332817);
  static const Color _gold = Color(0xFFC9A24B);
  static const Color _no = Color(0xFF9B3B2E);

  /// (줄 목록, 강조 집합 {row*100+index}, 라벨, 별 위치 row*100+index or -1, 금지 X 여부)
  List<dynamic> _spec() {
    switch (world) {
      case 1:
        if (page == 0) return [[6], {5}, '1~2 · $take', -1, false];
        if (page == 1) return [[6], {4, 5}, '2 · $take', -1, false];
        return [[1], {0}, last, 0, false];
      case 2:
        if (page == 0) return [[3, 5], {103, 104}, take, -1, false];
        if (page == 1) return [[3, 5], {0, 1, 2}, take, -1, false];
        return [[0, 1], {100}, last, 100, false];
      case 3:
        if (page == 0) return [[2, 3, 5], {202, 203, 204}, take, -1, false];
        if (page == 1) return [[2, 3, 5], {100, 101, 102}, take, -1, false];
        return [[0, 0, 1], {200}, last, 200, false];
      case 5: // 카일즈: 붙어 있는 1~2개, 가운데 빼면 갈라짐
        if (page == 0) return [[7], {3, 4}, '1~2 · $take', -1, false];
        if (page == 1) return [[3, 2], {}, '', -1, false];
        return [[1], {0}, last, 0, false];
      case 6: // 위토프
        if (page == 0) return [[4, 6], {103, 104, 105}, take, -1, false];
        if (page == 1) return [[4, 6], {2, 3, 104, 105}, '= · =', -1, false];
        return [[1, 0], {0}, last, 0, false];
      case 7: // 피보나치
        if (page == 0) return [[8], {0, 1, 2, 3, 4, 5, 6, 7}, '✕', -1, true];
        if (page == 1) return [[8], {6, 7}, '×2', -1, false];
        return [[1], {0}, last, 0, false];
    }
    return [[5], {4}, take, -1, false];
  }

  @override
  void paint(Canvas c, Size size) {
    final spec = _spec();
    final List<int> rows = (spec[0] as List).cast<int>();
    final Set<int> hi = (spec[1] as Set).cast<int>();
    final String label = spec[2] as String;
    final int star = spec[3] as int;
    final bool forbid = spec[4] as bool;
    final int maxLen = rows.fold(1, (m, r) => r > m ? r : m);
    final double cell = ((size.width - 40) / maxLen).clamp(24.0, 56.0);
    final double d = cell * 0.7;
    final double rowH = cell + 10;
    final double top = (size.height - rows.length * rowH) / 2 - 10;
    for (int r = 0; r < rows.length; r++) {
      final n = rows[r];
      final double x0 = (size.width - n * cell) / 2;
      final double cy = top + r * rowH + rowH / 2;
      // 줄 바탕(쟁반)
      if (rows.length > 1) {
        c.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(20, cy - rowH / 2 + 3, size.width - 40, rowH - 6), const Radius.circular(8)),
          Paint()..color = _ink.withOpacity(0.06),
        );
      }
      for (int i = 0; i < n; i++) {
        final cx = x0 + i * cell + cell / 2;
        final bool h = hi.contains(r * 100 + i);
        if (h) {
          c.drawCircle(Offset(cx, cy), d / 2 + 6, Paint()..color = _sky.withOpacity(0.25));
          c.drawCircle(Offset(cx, cy), d / 2 + 6, Paint()
            ..color = _sky
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
        }
        // 사탕: 분홍 원 + 양옆 포장
        c.drawCircle(Offset(cx, cy), d / 2, Paint()..color = _candy);
        c.drawCircle(Offset(cx, cy), d / 2, Paint()
          ..color = _candyDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
        final wrap = Paint()..color = _candyDark;
        c.drawPath(Path()..moveTo(cx - d / 2, cy)..lineTo(cx - d / 2 - 7, cy - 6)..lineTo(cx - d / 2 - 7, cy + 6)..close(), wrap);
        c.drawPath(Path()..moveTo(cx + d / 2, cy)..lineTo(cx + d / 2 + 7, cy - 6)..lineTo(cx + d / 2 + 7, cy + 6)..close(), wrap);
        if (star == r * 100 + i) {
          _text(c, '★', Offset(cx, cy - d / 2 - 16), 22, _gold);
        }
      }
      if (n == 0) {
        _text(c, '—', Offset(size.width / 2, cy), 16, _ink.withOpacity(0.4));
      }
    }
    if (label.isNotEmpty) {
      final double ly = top + rows.length * rowH + 22;
      if (forbid) {
        // 전부 가져가기 금지: 큰 X 를 줄 위에
        _text(c, '✕', Offset(size.width / 2, top + rowH / 2), 40, _no.withOpacity(0.8));
        _text(c, label == '✕' ? '' : label, Offset(size.width / 2, ly), 16, _no);
      } else {
        _text(c, label, Offset(size.width / 2, ly), 16, label == last ? _gold : _sky);
      }
    }
  }

  void _text(Canvas c, String t, Offset center, double size, Color color) {
    if (t.isEmpty) return;
    final tp = TextPainter(
      text: TextSpan(text: t, style: TextStyle(fontFamily: 'NeoDGM', fontSize: size, color: color, fontWeight: FontWeight.w800)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _NimPicturePainter old) => old.world != world || old.page != page;
}
