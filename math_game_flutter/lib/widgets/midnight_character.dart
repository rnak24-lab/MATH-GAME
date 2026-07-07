import 'package:flutter/material.dart';

/// Midnight의 표정 단계 (기존 6종 유지 — game_screen.dart 호환).
enum MidnightFace {
  happy1, // 살짝 미소 (유리할 때 초반) → happy.png
  happy2, // 활짝 웃음 (유리할 때 후반 / 승리) → happy.png + sparkle
  worried1, // 살짝 곤란 → sleepy.png (부드러운 실망)
  worried2, // 매우 곤란 / 패배 → angry.png (하린 에셋 매핑)
  neutral, // 시작/대기 → default.png
  confident, // 자신만만 → smug.png
}

/// MidnightFace → 실제 에셋 경로 매핑 (PNG 기본).
/// 하린이 배치한 6종 (default/happy/surprised/sleepy/smug/angry)을 사용.
String _midnightAssetPath(MidnightFace face, {bool gif = false}) {
  final String base;
  switch (face) {
    case MidnightFace.neutral:
      base = 'default';
      break;
    case MidnightFace.happy1:
    case MidnightFace.happy2:
      base = 'happy';
      break;
    case MidnightFace.worried1:
      base = 'sleepy';
      break;
    case MidnightFace.worried2:
      base = 'angry';
      break;
    case MidnightFace.confident:
      base = 'smug';
      break;
  }
  if (gif) {
    return 'assets/midnight/gif/cat_$base.gif';
  }
  return 'assets/midnight/$base.png';
}

/// Midnight 캐릭터 위젯 — 하린 PNG 에셋 + 미세 바운스 애니메이션.
class MidnightCharacter extends StatefulWidget {
  final MidnightFace face;
  final double size;
  final bool animate;
  final bool useGif;

  const MidnightCharacter({
    super.key,
    this.face = MidnightFace.neutral,
    this.size = 200,
    this.animate = true,
    this.useGif = false,
  });

  @override
  State<MidnightCharacter> createState() => _MidnightCharacterState();
}

class _MidnightCharacterState extends State<MidnightCharacter>
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
    final path = _midnightAssetPath(widget.face, gif: widget.useGif);

    // AnimatedSwitcher로 표정 전환 시 크로스페이드(150ms)
    final image = AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: Image.asset(
        path,
        key: ValueKey(path),
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (ctx, err, stack) => _FallbackPlaceholder(
          size: widget.size,
          face: widget.face,
        ),
      ),
    );

    return AnimatedBuilder(
      animation: _bounceAnim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_bounceAnim.value),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: child,
          ),
        );
      },
      child: image,
    );
  }
}

/// 에셋 로드 실패 시 아주 단순한 대체 (검은 원 + 이모지).
class _FallbackPlaceholder extends StatelessWidget {
  final double size;
  final MidnightFace face;
  const _FallbackPlaceholder({required this.size, required this.face});

  String _emoji() {
    switch (face) {
      case MidnightFace.happy1:
      case MidnightFace.happy2:
        return '😺';
      case MidnightFace.worried1:
        return '😿';
      case MidnightFace.worried2:
        return '😾';
      case MidnightFace.confident:
        return '😼';
      case MidnightFace.neutral:
        return '🐱';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(_emoji(), style: TextStyle(fontSize: size * 0.5)),
    );
  }
}

/// Midnight + 말풍선 위젯 — 상단 말풍선 + 삼각 꼬리 + 캐릭터.
class MidnightWithBubble extends StatelessWidget {
  final MidnightFace face;
  final String message;
  final double size;
  final bool useGif;

  const MidnightWithBubble({
    super.key,
    required this.face,
    required this.message,
    this.size = 160,
    this.useGif = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 말풍선 (크로스페이드로 텍스트 전환)
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Container(
            key: ValueKey(message),
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
        ),
        // 말풍선 삼각형
        CustomPaint(
          size: const Size(20, 10),
          painter: _BubbleTailPainter(),
        ),
        const SizedBox(height: 4),
        // Midnight (하린 PNG 에셋)
        MidnightCharacter(face: face, size: size, useGif: useGif),
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
