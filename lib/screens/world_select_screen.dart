import 'package:flutter/material.dart';
import '../utils/design_system.dart';
import '../services/game_save_service.dart';
import 'stage_select_screen.dart';

/// 월드 선택 화면 (5개 월드)
class WorldSelectScreen extends StatelessWidget {
  const WorldSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('월드 선택')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(DS.spaceMD),
          itemCount: 5,
          itemBuilder: (context, index) {
            final isUnlocked = index <= GameSaveService.worldUnlocked;
            final clearCount = GameSaveService.getWorldClearCount(index);
            final worldColor = DS.getWorldColor(index);

            return Padding(
              padding: const EdgeInsets.only(bottom: DS.spaceMD),
              child: GestureDetector(
                onTap: isUnlocked
                    ? () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StageSelectScreen(worldIndex: index),
                          ),
                        )
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(DS.spaceLG),
                  decoration: BoxDecoration(
                    color: isUnlocked ? Colors.white : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(DS.radiusLG),
                    border: Border.all(
                      color: isUnlocked ? worldColor : Colors.grey.shade400,
                      width: 2,
                    ),
                    boxShadow: isUnlocked
                        ? [
                            BoxShadow(
                              color: worldColor.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      // 월드 아이콘
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isUnlocked
                              ? worldColor.withOpacity(0.2)
                              : Colors.grey.shade300,
                        ),
                        child: Center(
                          child: Text(
                            isUnlocked ? DS.getWorldEmoji(index) : '🔒',
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                      ),
                      const SizedBox(width: DS.spaceMD),
                      // 월드 정보
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isUnlocked
                                  ? DS.getWorldName(index)
                                  : '??? (잠김)',
                              style: DS.heading3.copyWith(
                                fontSize: DS.fontLG,
                                color: isUnlocked
                                    ? DS.textPrimary
                                    : DS.textSecondary,
                              ),
                            ),
                            const SizedBox(height: DS.spaceXS),
                            Text(
                              '스테이지 ${index * 20 + 1}~${(index + 1) * 20}',
                              style: DS.caption,
                            ),
                            const SizedBox(height: DS.spaceSM),
                            // 진행도 바
                            ClipRRect(
                              borderRadius: BorderRadius.circular(DS.radiusSM),
                              child: LinearProgressIndicator(
                                value: clearCount / 20,
                                minHeight: 8,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation(worldColor),
                              ),
                            ),
                            const SizedBox(height: DS.spaceXS),
                            Text(
                              '$clearCount/20 클리어',
                              style: DS.caption.copyWith(
                                color: worldColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 화살표
                      if (isUnlocked)
                        Icon(
                          Icons.arrow_forward_ios,
                          color: worldColor,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
