import 'package:flutter/material.dart';
import '../game/stage_manager.dart';
import '../providers/locale_provider.dart';
import '../utils/nim_theme.dart';
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
      backgroundColor: NimTheme.deskBottom,
      appBar: AppBar(
        backgroundColor: NimTheme.frame,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: NimTheme.cream, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(world.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              world.name(s),
              style: const TextStyle(
                fontFamily: NimTheme.font,
                color: NimTheme.cream,
                fontSize: 19,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded,
                color: NimTheme.gold, size: 24),
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
        decoration: const BoxDecoration(gradient: NimTheme.bg),
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
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
    final bool isCurrent = isPlayable && !isCleared;
    return Material(
      color: NimTheme.deskBoard,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCurrent
                  ? NimTheme.gold
                  : (isCleared
                      ? NimTheme.win.withOpacity(0.7)
                      : NimTheme.frame),
              width: isCurrent ? 2.5 : 1.5,
            ),
            // 현재 스테이지 = 골드 글로우
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: NimTheme.gold.withOpacity(0.45),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isCleared)
                const Icon(Icons.check_rounded,
                    size: 18, color: NimTheme.win)
              else if (!isPlayable)
                const Icon(Icons.lock_rounded,
                    size: 15, color: NimTheme.inkSoft)
              else
                const Icon(Icons.play_arrow_rounded,
                    size: 18, color: NimTheme.gold),
              const SizedBox(height: 2),
              Text(
                '$displayNumber',
                style: TextStyle(
                  fontFamily: NimTheme.font,
                  fontSize: 16,
                  color: isCurrent
                      ? NimTheme.gold
                      : (isCleared
                          ? NimTheme.cream
                          : NimTheme.inkSoft),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
