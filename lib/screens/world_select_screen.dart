import 'package:flutter/material.dart';
import '../utils/design_system.dart';
import '../services/game_save_service.dart';
import 'stage_select_screen.dart';

/// 월드 선택 화면 - 도박장 안쪽, 여러 테이블 테마
class WorldSelectScreen extends StatelessWidget {
  const WorldSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('테이블 선택'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: DS.textSecondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D0D0D), Color(0xFF1A1209)],
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
                            builder: (_) =>
                                StageSelectScreen(worldIndex: index),
                          ),
                        )
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(DS.spaceLG),
                  decoration: BoxDecoration(
                    color: isUnlocked ? DS.panelBg : DS.surface,
                    borderRadius: BorderRadius.circular(DS.radiusMD),
                    border: Border.all(
                      color: isUnlocked
                          ? worldColor.withOpacity(0.6)
                          : DS.inactive.withOpacity(0.3),
                      width: isUnlocked ? 2 : 1,
                    ),
                    boxShadow: isUnlocked
                        ? [
                            BoxShadow(
                              color: worldColor.withOpacity(0.15),
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
                              ? worldColor.withOpacity(0.3)
                              : DS.inactive.withOpacity(0.2),
                          border: Border.all(
                            color: isUnlocked
                                ? worldColor
                                : DS.inactive.withOpacity(0.3),
                          ),
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
                              style: TextStyle(
                                fontSize: DS.fontLG,
                                fontWeight: FontWeight.bold,
                                color: isUnlocked
                                    ? DS.textPrimary
                                    : DS.inactive,
                              ),
                            ),
                            const SizedBox(height: DS.spaceXS),
                            Text(
                              '스테이지 ${index * 20 + 1}~${(index + 1) * 20}',
                              style: TextStyle(
                                color: DS.inactive,
                                fontSize: DS.fontSM,
                              ),
                            ),
                            const SizedBox(height: DS.spaceSM),
                            // 진행도 바
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(DS.radiusSM),
                              child: LinearProgressIndicator(
                                value: clearCount / 20,
                                minHeight: 6,
                                backgroundColor: DS.surface,
                                valueColor:
                                    AlwaysStoppedAnimation(worldColor),
                              ),
                            ),
                            const SizedBox(height: DS.spaceXS),
                            Text(
                              '$clearCount/20 클리어',
                              style: TextStyle(
                                color: worldColor,
                                fontWeight: FontWeight.bold,
                                fontSize: DS.fontSM,
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
                          size: 18,
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
