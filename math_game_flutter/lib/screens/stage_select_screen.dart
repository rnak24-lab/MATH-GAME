import 'package:flutter/material.dart';
import '../game/stage_manager.dart';
import 'world_select_screen.dart';
import 'game_screen.dart';

class StageSelectScreen extends StatelessWidget {
  final StageManager stageManager;
  final WorldInfo world;

  const StageSelectScreen({
    super.key,
    required this.stageManager,
    required this.world,
  });

  @override
  Widget build(BuildContext context) {
    int worldStart = world.id * 20 + 1;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(world.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              world.name,
              style: const TextStyle(
                color: Color(0xFF2C3E50),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: 20,
          itemBuilder: (context, index) {
            int stage = worldStart + index;
            bool isCleared = stageManager.isStageCleared(stage);
            bool isPlayable = stageManager.isStagePlayable(stage);

            return _StageCell(
              stage: stage,
              displayNumber: index + 1,
              isCleared: isCleared,
              isPlayable: isPlayable,
              worldColor: world.color,
              onTap: isPlayable
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GameScreen(
                            stageManager: stageManager,
                            stageNumber: stage,
                          ),
                        ),
                      );
                    }
                  : null,
            );
          },
        ),
      ),
    );
  }
}

class _StageCell extends StatelessWidget {
  final int stage;
  final int displayNumber;
  final bool isCleared;
  final bool isPlayable;
  final Color worldColor;
  final VoidCallback? onTap;

  const _StageCell({
    required this.stage,
    required this.displayNumber,
    required this.isCleared,
    required this.isPlayable,
    required this.worldColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isCleared
          ? worldColor.withOpacity(0.15)
          : isPlayable
              ? Colors.white
              : Colors.grey[200],
      borderRadius: BorderRadius.circular(16),
      elevation: isPlayable ? 3 : 0,
      shadowColor: worldColor.withOpacity(0.2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: isPlayable && !isCleared
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: worldColor, width: 2),
                )
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isCleared)
                const Text('⭐', style: TextStyle(fontSize: 20))
              else if (!isPlayable)
                Icon(Icons.lock, size: 20, color: Colors.grey[400])
              else
                Icon(Icons.play_arrow_rounded, size: 20, color: worldColor),
              const SizedBox(height: 4),
              Text(
                '$displayNumber',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isPlayable
                      ? const Color(0xFF2C3E50)
                      : Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
