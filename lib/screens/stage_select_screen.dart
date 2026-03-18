import 'package:flutter/material.dart';
import '../utils/design_system.dart';
import '../services/game_save_service.dart';
import '../models/game_state.dart';
import 'game_screen.dart';

/// 스테이지 선택 화면 (월드당 20스테이지)
class StageSelectScreen extends StatelessWidget {
  final int worldIndex;

  const StageSelectScreen({super.key, required this.worldIndex});

  @override
  Widget build(BuildContext context) {
    final worldColor = DS.getWorldColor(worldIndex);
    final startStage = worldIndex * 20 + 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(DS.getWorldName(worldIndex)),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              worldColor.withOpacity(0.1),
              worldColor.withOpacity(0.05),
            ],
          ),
        ),
        child: GridView.builder(
          padding: const EdgeInsets.all(DS.spaceMD),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: DS.spaceSM,
            crossAxisSpacing: DS.spaceSM,
            childAspectRatio: 1,
          ),
          itemCount: 20,
          itemBuilder: (context, index) {
            final stageNum = startStage + index;
            final isCleared = stageNum <= GameSaveService.maxStageCleared;
            final isPlayable = stageNum <= GameSaveService.maxStageCleared + 1;
            final mode = GameState.getModeForStage(stageNum);

            return GestureDetector(
              onTap: isPlayable
                  ? () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => GameScreen(stageNumber: stageNum),
                        ),
                      )
                  : null,
              child: Container(
                decoration: BoxDecoration(
                  color: isCleared
                      ? worldColor.withOpacity(0.2)
                      : isPlayable
                          ? Colors.white
                          : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(DS.radiusMD),
                  border: Border.all(
                    color: isPlayable ? worldColor : Colors.grey.shade400,
                    width: isPlayable ? 2 : 1,
                  ),
                  boxShadow: isPlayable
                      ? [
                          BoxShadow(
                            color: worldColor.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isCleared)
                      const Text('⭐', style: TextStyle(fontSize: 20))
                    else if (!isPlayable)
                      const Text('🔒', style: TextStyle(fontSize: 20))
                    else
                      Text(mode.itemEmoji,
                          style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 4),
                    Text(
                      '$stageNum',
                      style: TextStyle(
                        fontSize: DS.fontMD,
                        fontWeight: FontWeight.bold,
                        color: isPlayable ? DS.textPrimary : DS.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
