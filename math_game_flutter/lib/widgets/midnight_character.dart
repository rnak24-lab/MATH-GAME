import 'package:flutter/material.dart';

/// 예린(YERIN)의 표정 단계.
/// (2026-07-08 리브랜딩 — enum/에셋 경로명은 호환 위해 유지, 아트는 예린 원화로 교체 예정)
enum MidnightFace {
  happy1, // 살짝 미소 (유리할 때 초반) → happy.png
  happy2, // 활짝 웃음 (유리할 때 후반 / 승리) → happy.png + sparkle
  worried1, // 살짝 곤란 → sleepy.png (부드러운 실망)
  worried2, // 매우 곤란 / 패배 → angry.png
  neutral, // 시작/대기 → default.png (대표님 원화 1: 잔잔한 미소)
  confident, // 자신만만 → smug.png
  thinking, // 🤔 고민 — 예린 턴 생각 중 (대표님 원화 2: 턱 괴고 미간)
}

/// 예린 표정 PNG 경로 (assets/yerin/ — 외주/신규 아트 드롭인 폴더).
/// 파일이 없으면 위젯에서 고양이(assets/midnight/)로 폴백된다.
String _yerinAssetPath(MidnightFace face) {
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
      base = 'worried';
      break;
    case MidnightFace.worried2:
      base = 'upset';
      break;
    case MidnightFace.confident:
      base = 'smug';
      break;
    case MidnightFace.thinking:
      base = 'thinking';
      break;
  }
  return 'assets/yerin/$base.png';
}

/// (폴백) 구 고양이 에셋 경로 매핑.
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
    case MidnightFace.thinking:
      // 고양이 에셋엔 고민 표정 없음 → default
      base = 'default';
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
    final yerinPath = _yerinAssetPath(widget.face);
    final catPath = _midnightAssetPath(widget.face, gif: widget.useGif);

    // AnimatedSwitcher로 표정 전환 시 크로스페이드(150ms)
    // 예린 PNG(assets/yerin/) 우선 → 없으면 고양이(임시) → 그것도 없으면 플레이스홀더
    final image = AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: Image.asset(
        yerinPath,
        key: ValueKey('$yerinPath|${widget.face}'),
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (ctx, err, stack) => Image.asset(
          catPath,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (ctx, err, stack) => _FallbackPlaceholder(
            size: widget.size,
            face: widget.face,
          ),
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
      case MidnightFace.thinking:
        return '🤔';
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
