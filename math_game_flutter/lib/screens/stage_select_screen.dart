import 'package:flutter/material.dart';
import '../game/stage_manager.dart';
import '../providers/locale_provider.dart';
import 'world_select_screen.dart';
import 'game_screen.dart';
import 'settings_screen.dart';

class StageSelectScreen extends StatefulWidget {
  final StageManager stageManager;
  final WorldInfo world;
  final LocaleProvider localeProvider;

  const StageSelectScreen({
    super.key,
    required this.stageManager,
    required this.world,
    required this.localeProvider,
  });

  @override
  State<StageSelectScreen> createState() => _StageSelectScreenState();
}

class _StageSelectScreenState extends State<StageSelectScreen> {
  StageManager get stageManager => widget.stageManager;
  WorldInfo get world => widget.world;
  LocaleProvider get localeProvider => widget.localeProvider;

  @override
  Widget build(BuildContext context) {
    int worldStart = world.id * 20 + 1;
    final s = localeProvider.strings;

    return Scaffold(
      // (id=1141) 월드별 고유 배경 그라데이션
      extendBodyBehindAppBar: false,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(world.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              world.name(s),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded,
                color: Colors.white, size: 26),
            tooltip: s.get('settings'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    localeProvider: localeProvider,
                    onChanged: () => setState(() {}),
                    stageManager: stageManager,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: world.bgGradient,
            stops: const [0.0, 0.35, 1.0],
          ),
        ),
        child: Padding(
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
                  ? () async {
                      // (id=1144) 게임에서 복귀 시 setState로 진행/해금 갱신
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GameScreen(
                            stageManager: stageManager,
                            stageNumber: stage,
                            localeProvider: localeProvider,
                          ),
                        ),
                      );
                      if (mounted) setState(() {});
                    }
                  : null,
            );
          },
        ),
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
