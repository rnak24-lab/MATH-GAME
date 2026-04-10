import 'package:flutter/material.dart';
import '../models/sua_character.dart';
import '../utils/design_system.dart';

/// 깜냥이(나이트) 캐릭터 위젯 - 표정 + 말풍선 (누아르 스타일)
class SuaWidget extends StatelessWidget {
  final SuaCharacter sua;
  final String dialogue;
  final double size;

  const SuaWidget({
    super.key,
    required this.sua,
    required this.dialogue,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 말풍선 (누아르 톤)
        Container(
          constraints: const BoxConstraints(maxWidth: 240),
          padding: const EdgeInsets.symmetric(
            horizontal: DS.spaceMD,
            vertical: DS.spaceSM,
          ),
          decoration: BoxDecoration(
            color: DS.panelBg,
            borderRadius: BorderRadius.circular(DS.radiusMD),
            border: Border.all(color: DS.primaryDark.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            dialogue,
            style: TextStyle(
              color: DS.textSecondary,
              fontSize: DS.fontSM,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        // 말풍선 꼬리
        CustomPaint(
          size: const Size(16, 8),
          painter: _BubbleTailPainter(),
        ),
        const SizedBox(height: DS.spaceXS),
        // 깜냥이 얼굴
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2A1F14), Color(0xFF1A1209)],
            ),
            border: Border.all(color: DS.primaryDark, width: 2),
            boxShadow: [
              BoxShadow(
                color: DS.primary.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              sua.emoji,
              style: TextStyle(fontSize: size * 0.5),
            ),
          ),
        ),
        const SizedBox(height: DS.spaceXS),
        // 이름 태그
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: DS.panelBg,
            borderRadius: BorderRadius.circular(DS.radiusMD),
            border: Border.all(color: DS.primaryDark.withOpacity(0.5)),
          ),
          child: Text(
            '🃏 ${sua.name}',
            style: const TextStyle(
              color: DS.primary,
              fontSize: DS.fontSM,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DS.panelBg
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = DS.primaryDark.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
