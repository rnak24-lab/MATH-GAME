import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../utils/design_system.dart';

/// 돌/구슬/보석 줄을 표시하는 위젯
class StoneRowWidget extends StatelessWidget {
  final int rowIndex;
  final int count;
  final GameMode mode;
  final int selectedCount;
  final bool isInteractive;
  final ValueChanged<int>? onCountChanged;

  const StoneRowWidget({
    super.key,
    required this.rowIndex,
    required this.count,
    required this.mode,
    this.selectedCount = 0,
    this.isInteractive = false,
    this.onCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: DS.spaceSM),
      padding: const EdgeInsets.all(DS.spaceMD),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(DS.radiusMD),
        border: Border.all(
          color: isInteractive ? DS.primary : Colors.grey.shade300,
          width: isInteractive ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // 줄 라벨
          if (mode != GameMode.singleRow)
            Padding(
              padding: const EdgeInsets.only(bottom: DS.spaceSM),
              child: Text(
                '${rowIndex + 1}번째 줄',
                style: DS.caption.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          // 돌 표시
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: List.generate(count, (i) {
              final isSelected = isInteractive && i >= (count - selectedCount);
              return GestureDetector(
                onTap: isInteractive
                    ? () => onCountChanged?.call(count - i)
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? DS.error.withOpacity(0.2)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? DS.error : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      mode.itemEmoji,
                      style: TextStyle(
                        fontSize: isSelected ? 28 : 24,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          // 개수 표시
          Padding(
            padding: const EdgeInsets.only(top: DS.spaceSM),
            child: Text(
              '$count개',
              style: DS.bodyBold,
            ),
          ),
          // 선택 슬라이더 (인터랙티브 모드)
          if (isInteractive && count > 0)
            Padding(
              padding: const EdgeInsets.only(top: DS.spaceSM),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('가져갈 수: ', style: DS.caption),
                  Text(
                    '$selectedCount개',
                    style: DS.bodyBold.copyWith(color: DS.primary),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 빼빼로 묶음을 표시하는 위젯
class PeperoWidget extends StatelessWidget {
  final int index;
  final int size;
  final bool isSelected;
  final VoidCallback? onTap;

  const PeperoWidget({
    super.key,
    required this.index,
    required this.size,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(DS.spaceXS),
        padding: const EdgeInsets.all(DS.spaceSM),
        decoration: BoxDecoration(
          color: isSelected ? DS.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(DS.radiusMD),
          border: Border.all(
            color: isSelected ? DS.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 2,
              children: List.generate(
                size,
                (_) => const Text('🍫', style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(height: 4),
            Text('$size개', style: DS.bodyBold),
          ],
        ),
      ),
    );
  }
}
