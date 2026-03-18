import 'package:flutter/material.dart';


/// 수아의 표정 단계
enum SuaFace {
  happy1,      // 살짝 미소 (유리할 때 초반)
  happy2,      // 활짝 웃음 (유리할 때 후반)
  worried1,    // 살짝 곤란 (불리할 때 초반)
  worried2,    // 매우 곤란 (불리할 때 후반)
  neutral,     // 시작/대기
  confident,   // 자신만만
}

/// 수아 캐릭터 위젯 - CustomPainter로 애니메이션 캐릭터 그림
class SuaCharacter extends StatefulWidget {
  final SuaFace face;
  final double size;
  final bool animate;

  const SuaCharacter({
    super.key,
    this.face = SuaFace.neutral,
    this.size = 200,
    this.animate = true,
  });

  @override
  State<SuaCharacter> createState() => _SuaCharacterState();
}

class _SuaCharacterState extends State<SuaCharacter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _bounceAnim = Tween<double>(begin: 0, end: 6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounceAnim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_bounceAnim.value),
          child: CustomPaint(
            size: Size(widget.size, widget.size * 1.4),
            painter: _SuaPainter(face: widget.face),
          ),
        );
      },
    );
  }
}

class _SuaPainter extends CustomPainter {
  final SuaFace face;

  _SuaPainter({required this.face});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // === 몸통 (교복) ===
    _drawBody(canvas, cx, h, w);

    // === 머리카락 (뒤쪽, 땋은 머리) ===
    _drawBackHair(canvas, cx, h, w);

    // === 얼굴 ===
    _drawFace(canvas, cx, h, w);

    // === 앞머리 ===
    _drawFrontHair(canvas, cx, h, w);

    // === 표정 ===
    _drawExpression(canvas, cx, h, w);
  }

  void _drawBody(Canvas canvas, double cx, double h, double w) {
    // 교복 블라우스 (흰색)
    final blousePaint = Paint()
      ..color = const Color(0xFFF5F5F5)
      ..style = PaintingStyle.fill;
    final blazerPaint = Paint()
      ..color = const Color(0xFF2C3E50)
      ..style = PaintingStyle.fill;
    final ribbonPaint = Paint()
      ..color = const Color(0xFFE74C3C)
      ..style = PaintingStyle.fill;

    // 몸통 (블레이저)
    final bodyPath = Path();
    double bodyTop = h * 0.52;
    double bodyBottom = h;
    bodyPath.moveTo(cx - w * 0.28, bodyTop);
    bodyPath.quadraticBezierTo(cx - w * 0.32, bodyBottom, cx - w * 0.2, bodyBottom);
    bodyPath.lineTo(cx + w * 0.2, bodyBottom);
    bodyPath.quadraticBezierTo(cx + w * 0.32, bodyBottom, cx + w * 0.28, bodyTop);
    bodyPath.close();
    canvas.drawPath(bodyPath, blazerPaint);

    // 블라우스 V넥
    final neckPath = Path();
    neckPath.moveTo(cx - w * 0.12, bodyTop);
    neckPath.lineTo(cx, bodyTop + h * 0.18);
    neckPath.lineTo(cx + w * 0.12, bodyTop);
    neckPath.close();
    canvas.drawPath(neckPath, blousePaint);

    // 리본
    final ribbonPath = Path();
    ribbonPath.moveTo(cx - w * 0.06, bodyTop + h * 0.02);
    ribbonPath.lineTo(cx, bodyTop + h * 0.08);
    ribbonPath.lineTo(cx + w * 0.06, bodyTop + h * 0.02);
    ribbonPath.lineTo(cx, bodyTop + h * 0.05);
    ribbonPath.close();
    canvas.drawPath(ribbonPath, ribbonPaint);

    // 리본 아래
    final ribbonDown = Path();
    ribbonDown.moveTo(cx - w * 0.02, bodyTop + h * 0.06);
    ribbonDown.lineTo(cx, bodyTop + h * 0.15);
    ribbonDown.lineTo(cx + w * 0.02, bodyTop + h * 0.06);
    canvas.drawPath(ribbonDown, ribbonPaint);
  }

  void _drawBackHair(Canvas canvas, double cx, double h, double w) {
    final hairPaint = Paint()
      ..color = const Color(0xFF1A1A2E)
      ..style = PaintingStyle.fill;

    // 뒤쪽 머리카락 (큰 덩어리)
    final backHair = Path();
    backHair.moveTo(cx - w * 0.3, h * 0.15);
    backHair.quadraticBezierTo(cx - w * 0.38, h * 0.4, cx - w * 0.15, h * 0.55);
    backHair.lineTo(cx + w * 0.15, h * 0.55);
    backHair.quadraticBezierTo(cx + w * 0.38, h * 0.4, cx + w * 0.3, h * 0.15);
    backHair.close();
    canvas.drawPath(backHair, hairPaint);

    // 땋은 머리 (왼쪽으로 내려옴)
    _drawBraid(canvas, cx + w * 0.2, h * 0.35, w * 0.08, h * 0.35, hairPaint);
  }

  void _drawBraid(Canvas canvas, double x, double y, double bw, double bh, Paint paint) {
    // 땋은 머리를 원 체인으로 표현
    int segments = 6;
    double segH = bh / segments;
    for (int i = 0; i < segments; i++) {
      double cy = y + segH * i + segH / 2;
      double offsetX = (i % 2 == 0) ? -bw * 0.3 : bw * 0.3;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x + offsetX, cy),
          width: bw * 0.8,
          height: segH * 0.9,
        ),
        paint,
      );
    }
    // 머리끈
    final tiePaint = Paint()
      ..color = const Color(0xFFFF6B9D)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(x, y + bh + 3),
      bw * 0.5,
      tiePaint,
    );
  }

  void _drawFace(Canvas canvas, double cx, double h, double w) {
    // 얼굴 (살색, 둥글게)
    final skinPaint = Paint()
      ..color = const Color(0xFFFDE8D0)
      ..style = PaintingStyle.fill;

    final faceCenter = Offset(cx, h * 0.32);
    final faceW = w * 0.32;
    final faceH = h * 0.22;

    canvas.drawOval(
      Rect.fromCenter(center: faceCenter, width: faceW * 2, height: faceH * 2),
      skinPaint,
    );

    // 목
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(cx, h * 0.5),
        width: w * 0.12,
        height: h * 0.06,
      ),
      skinPaint,
    );

    // 귀
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - faceW - 2, h * 0.32),
        width: w * 0.06,
        height: h * 0.05,
      ),
      skinPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + faceW + 2, h * 0.32),
        width: w * 0.06,
        height: h * 0.05,
      ),
      skinPaint,
    );
  }

  void _drawFrontHair(Canvas canvas, double cx, double h, double w) {
    final hairPaint = Paint()
      ..color = const Color(0xFF1A1A2E)
      ..style = PaintingStyle.fill;

    // 앞머리 (가르마 있는 앞머리)
    final bangs = Path();
    bangs.moveTo(cx - w * 0.34, h * 0.18);
    bangs.quadraticBezierTo(cx - w * 0.15, h * 0.05, cx, h * 0.12);
    bangs.quadraticBezierTo(cx + w * 0.15, h * 0.05, cx + w * 0.34, h * 0.18);
    bangs.quadraticBezierTo(cx + w * 0.36, h * 0.08, cx + w * 0.2, h * 0.02);
    bangs.quadraticBezierTo(cx, h * -0.02, cx - w * 0.2, h * 0.02);
    bangs.quadraticBezierTo(cx - w * 0.36, h * 0.08, cx - w * 0.34, h * 0.18);
    bangs.close();
    canvas.drawPath(bangs, hairPaint);

    // 양옆 머리카락
    final sideL = Path();
    sideL.moveTo(cx - w * 0.33, h * 0.15);
    sideL.quadraticBezierTo(cx - w * 0.4, h * 0.35, cx - w * 0.28, h * 0.48);
    sideL.quadraticBezierTo(cx - w * 0.3, h * 0.35, cx - w * 0.28, h * 0.15);
    sideL.close();
    canvas.drawPath(sideL, hairPaint);

    final sideR = Path();
    sideR.moveTo(cx + w * 0.33, h * 0.15);
    sideR.quadraticBezierTo(cx + w * 0.4, h * 0.35, cx + w * 0.28, h * 0.48);
    sideR.quadraticBezierTo(cx + w * 0.3, h * 0.35, cx + w * 0.28, h * 0.15);
    sideR.close();
    canvas.drawPath(sideR, hairPaint);
  }

  void _drawExpression(Canvas canvas, double cx, double h, double w) {
    final eyeY = h * 0.30;
    final eyeSpacing = w * 0.12;
    final mouthY = h * 0.40;

    switch (face) {
      case SuaFace.neutral:
        _drawNeutralEyes(canvas, cx, eyeY, eyeSpacing, w);
        _drawNeutralMouth(canvas, cx, mouthY, w);
        break;
      case SuaFace.happy1:
        _drawHappyEyes(canvas, cx, eyeY, eyeSpacing, w, false);
        _drawSmile(canvas, cx, mouthY, w, false);
        _drawBlush(canvas, cx, eyeY, eyeSpacing, w);
        break;
      case SuaFace.happy2:
        _drawHappyEyes(canvas, cx, eyeY, eyeSpacing, w, true);
        _drawSmile(canvas, cx, mouthY, w, true);
        _drawBlush(canvas, cx, eyeY, eyeSpacing, w);
        _drawSparkles(canvas, cx, eyeY, w);
        break;
      case SuaFace.worried1:
        _drawWorriedEyes(canvas, cx, eyeY, eyeSpacing, w, false);
        _drawWorriedMouth(canvas, cx, mouthY, w, false);
        _drawSweat(canvas, cx, eyeY, w, false);
        break;
      case SuaFace.worried2:
        _drawWorriedEyes(canvas, cx, eyeY, eyeSpacing, w, true);
        _drawWorriedMouth(canvas, cx, mouthY, w, true);
        _drawSweat(canvas, cx, eyeY, w, true);
        _drawTeardrop(canvas, cx, eyeY, eyeSpacing, w);
        break;
      case SuaFace.confident:
        _drawConfidentEyes(canvas, cx, eyeY, eyeSpacing, w);
        _drawSmirk(canvas, cx, mouthY, w);
        break;
    }
  }

  // === 눈 그리기 ===

  void _drawNeutralEyes(Canvas canvas, double cx, double ey, double sp, double w) {
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final pupilPaint = Paint()
      ..color = const Color(0xFF1A1A2E)
      ..style = PaintingStyle.fill;

    for (double sign in [-1, 1]) {
      double ex = cx + sign * sp;
      // 눈 흰자
      canvas.drawOval(
        Rect.fromCenter(center: Offset(ex, ey), width: w * 0.12, height: w * 0.10),
        whitePaint,
      );
      // 눈동자
      canvas.drawCircle(Offset(ex, ey), w * 0.04, pupilPaint);
      // 하이라이트
      canvas.drawCircle(Offset(ex + w * 0.015, ey - w * 0.015), w * 0.012, whitePaint);
    }
  }

  void _drawHappyEyes(Canvas canvas, double cx, double ey, double sp, double w, bool intense) {
    final eyePaint = Paint()
      ..color = const Color(0xFF2C3E50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = intense ? 3.0 : 2.5
      ..strokeCap = StrokeCap.round;

    for (double sign in [-1, 1]) {
      double ex = cx + sign * sp;
      // ^ 형태의 감은 눈
      final path = Path();
      double eyeW = intense ? w * 0.07 : w * 0.06;
      path.moveTo(ex - eyeW, ey + w * 0.01);
      path.quadraticBezierTo(ex, ey - w * 0.04, ex + eyeW, ey + w * 0.01);
      canvas.drawPath(path, eyePaint);
    }
  }

  void _drawWorriedEyes(Canvas canvas, double cx, double ey, double sp, double w, bool intense) {
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final pupilPaint = Paint()
      ..color = const Color(0xFF1A1A2E)
      ..style = PaintingStyle.fill;
    final browPaint = Paint()
      ..color = const Color(0xFF2C3E50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    for (double sign in [-1, 1]) {
      double ex = cx + sign * sp;
      // 눈 (살짝 작게)
      double eyeH = intense ? w * 0.08 : w * 0.09;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(ex, ey), width: w * 0.11, height: eyeH),
        whitePaint,
      );
      // 눈동자 (아래쪽으로)
      double pupilY = intense ? ey + w * 0.01 : ey;
      canvas.drawCircle(Offset(ex, pupilY), w * 0.035, pupilPaint);
      canvas.drawCircle(Offset(ex + w * 0.01, pupilY - w * 0.01), w * 0.01, whitePaint);

      // 걱정 눈썹 (\/형태)
      final browPath = Path();
      browPath.moveTo(ex - sign * w * 0.06, ey - w * 0.07);
      browPath.lineTo(ex + sign * w * 0.04, ey - w * 0.05);
      canvas.drawPath(browPath, browPaint);
    }
  }

  void _drawConfidentEyes(Canvas canvas, double cx, double ey, double sp, double w) {
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final pupilPaint = Paint()
      ..color = const Color(0xFF1A1A2E)
      ..style = PaintingStyle.fill;

    // 왼쪽 눈: 감은 눈 (윙크)
    final winkPaint = Paint()
      ..color = const Color(0xFF2C3E50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    double lex = cx - sp;
    final winkPath = Path();
    winkPath.moveTo(lex - w * 0.06, ey);
    winkPath.quadraticBezierTo(lex, ey - w * 0.03, lex + w * 0.06, ey);
    canvas.drawPath(winkPath, winkPaint);

    // 오른쪽 눈: 크게 뜬 눈
    double rex = cx + sp;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(rex, ey), width: w * 0.13, height: w * 0.11),
      whitePaint,
    );
    canvas.drawCircle(Offset(rex, ey), w * 0.045, pupilPaint);
    canvas.drawCircle(Offset(rex + w * 0.015, ey - w * 0.015), w * 0.013, whitePaint);
  }

  // === 입 그리기 ===

  void _drawNeutralMouth(Canvas canvas, double cx, double my, double w) {
    final mouthPaint = Paint()
      ..color = const Color(0xFF2C3E50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx - w * 0.04, my),
      Offset(cx + w * 0.04, my),
      mouthPaint,
    );
  }

  void _drawSmile(Canvas canvas, double cx, double my, double w, bool intense) {
    final mouthPaint = Paint()
      ..color = intense ? const Color(0xFFE74C3C) : const Color(0xFF2C3E50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = intense ? 2.5 : 2.0
      ..strokeCap = StrokeCap.round;

    double mouthW = intense ? w * 0.08 : w * 0.06;
    double curve = intense ? w * 0.04 : w * 0.025;

    final path = Path();
    path.moveTo(cx - mouthW, my);
    path.quadraticBezierTo(cx, my + curve, cx + mouthW, my);
    canvas.drawPath(path, mouthPaint);

    if (intense) {
      // 열린 입
      final fillPaint = Paint()
        ..color = const Color(0xFFE74C3C).withOpacity(0.3)
        ..style = PaintingStyle.fill;
      final openPath = Path();
      openPath.moveTo(cx - mouthW * 0.7, my);
      openPath.quadraticBezierTo(cx, my + curve * 1.2, cx + mouthW * 0.7, my);
      openPath.close();
      canvas.drawPath(openPath, fillPaint);
    }
  }

  void _drawWorriedMouth(Canvas canvas, double cx, double my, double w, bool intense) {
    final mouthPaint = Paint()
      ..color = const Color(0xFF2C3E50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    double mouthW = w * 0.05;
    double curve = intense ? w * 0.035 : w * 0.02;

    // 아래로 볼록 (ㅠ)
    final path = Path();
    path.moveTo(cx - mouthW, my);
    path.quadraticBezierTo(cx, my - curve, cx + mouthW, my);
    canvas.drawPath(path, mouthPaint);

    if (intense) {
      // 물결 입
      final wavePath = Path();
      wavePath.moveTo(cx - mouthW, my);
      wavePath.quadraticBezierTo(cx - mouthW * 0.5, my + w * 0.015, cx, my);
      wavePath.quadraticBezierTo(cx + mouthW * 0.5, my - w * 0.015, cx + mouthW, my);
      canvas.drawPath(wavePath, mouthPaint);
    }
  }

  void _drawSmirk(Canvas canvas, double cx, double my, double w) {
    final mouthPaint = Paint()
      ..color = const Color(0xFF2C3E50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(cx - w * 0.04, my + w * 0.01);
    path.quadraticBezierTo(cx + w * 0.02, my - w * 0.02, cx + w * 0.06, my - w * 0.01);
    canvas.drawPath(path, mouthPaint);
  }

  // === 이펙트 ===

  void _drawBlush(Canvas canvas, double cx, double ey, double sp, double w) {
    final blushPaint = Paint()
      ..color = const Color(0xFFFF9999).withOpacity(0.4)
      ..style = PaintingStyle.fill;

    for (double sign in [-1, 1]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + sign * (sp + w * 0.04), ey + w * 0.04),
          width: w * 0.08,
          height: w * 0.04,
        ),
        blushPaint,
      );
    }
  }

  void _drawSweat(Canvas canvas, double cx, double ey, double w, bool intense) {
    final sweatPaint = Paint()
      ..color = const Color(0xFF87CEEB).withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // 땀방울
    double sx = cx + w * 0.28;
    double sy = ey - w * 0.03;
    final path = Path();
    path.moveTo(sx, sy - w * 0.02);
    path.quadraticBezierTo(sx + w * 0.015, sy, sx, sy + w * 0.02);
    path.quadraticBezierTo(sx - w * 0.015, sy, sx, sy - w * 0.02);
    canvas.drawPath(path, sweatPaint);

    if (intense) {
      // 두번째 땀방울
      double sx2 = cx + w * 0.22;
      double sy2 = ey + w * 0.02;
      final path2 = Path();
      path2.moveTo(sx2, sy2 - w * 0.015);
      path2.quadraticBezierTo(sx2 + w * 0.01, sy2, sx2, sy2 + w * 0.015);
      path2.quadraticBezierTo(sx2 - w * 0.01, sy2, sx2, sy2 - w * 0.015);
      canvas.drawPath(path2, sweatPaint);
    }
  }

  void _drawTeardrop(Canvas canvas, double cx, double ey, double sp, double w) {
    final tearPaint = Paint()
      ..color = const Color(0xFF87CEEB).withOpacity(0.6)
      ..style = PaintingStyle.fill;

    double tx = cx - sp;
    double ty = ey + w * 0.06;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(tx, ty), width: w * 0.025, height: w * 0.04),
      tearPaint,
    );
  }

  void _drawSparkles(Canvas canvas, double cx, double ey, double w) {
    final sparklePaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.fill;

    // 별 반짝이
    List<Offset> positions = [
      Offset(cx - w * 0.35, ey - w * 0.1),
      Offset(cx + w * 0.35, ey - w * 0.05),
      Offset(cx - w * 0.25, ey + w * 0.1),
    ];

    for (var pos in positions) {
      _drawStar(canvas, pos.dx, pos.dy, w * 0.02, sparklePaint);
    }
  }

  void _drawStar(Canvas canvas, double x, double y, double r, Paint paint) {
    // + 형태 별
    canvas.drawRect(
      Rect.fromCenter(center: Offset(x, y), width: r * 2, height: r * 0.5),
      paint,
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset(x, y), width: r * 0.5, height: r * 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(_SuaPainter oldDelegate) => oldDelegate.face != face;
}

/// 수아 + 말풍선 위젯
class SuaWithBubble extends StatelessWidget {
  final SuaFace face;
  final String message;
  final double size;

  const SuaWithBubble({
    super.key,
    required this.face,
    required this.message,
    this.size = 160,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 말풍선
        Container(
          constraints: BoxConstraints(maxWidth: size * 1.8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C3E50),
            ),
          ),
        ),
        // 말풍선 삼각형
        CustomPaint(
          size: const Size(20, 10),
          painter: _BubbleTailPainter(),
        ),
        const SizedBox(height: 4),
        // 수아
        SuaCharacter(face: face, size: size),
      ],
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
