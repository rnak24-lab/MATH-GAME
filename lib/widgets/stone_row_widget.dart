import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../utils/design_system.dart';

/// 칩/코인 줄을 표시하는 위젯 (포커 칩 스타일)
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
        color: DS.panelBg.withOpacity(0.6),
        borderRadius: BorderRadius.circular(DS.radiusMD),
        border: Border.all(
          color: isInteractive
              ? DS.primaryDark.withOpacity(0.5)
              : DS.inactive.withOpacity(0.2),
          width: isInteractive ? 1.5 : 1,
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
                style: TextStyle(
                  color: DS.textSecondary,
                  fontSize: DS.fontSM,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          // 칩 표시
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
                        ? DS.error.withOpacity(0.3)
                        : DS.primaryDark.withOpacity(0.1),
                    border: Border.all(
                      color: isSelected
                          ? DS.error
                          : DS.primaryDark.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
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
          // 선택 슬라이더
          if (isInteractive && count > 0)
            Padding(
              padding: const EdgeInsets.only(top: DS.spaceSM),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('가져갈 수: ',
                      style: TextStyle(color: DS.inactive, fontSize: DS.fontSM)),
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

/// 카드 묶음을 표시하는 위젯 (트럼프 카드 스타일)
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
          color: isSelected
              ? DS.primary.withOpacity(0.1)
              : DS.panelBg,
          borderRadius: BorderRadius.circular(DS.radiusMD),
          border: Border.all(
            color: isSelected
                ? DS.primary
                : DS.inactive.withOpacity(0.3),
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
                (_) => const Text('🃏', style: TextStyle(fontSize: 20)),
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
