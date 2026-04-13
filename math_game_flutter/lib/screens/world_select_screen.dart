import 'package:flutter/material.dart';
import '../game/stage_manager.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_strings.dart';
import 'stage_select_screen.dart';

class WorldInfo {
  final int id;
  final String nameKey;
  final String emoji;
  final Color color;
  final String subtitleKey;

  const WorldInfo({
    required this.id,
    required this.nameKey,
    required this.emoji,
    required this.color,
    required this.subtitleKey,
  });

  String name(AppStrings s) => s.get(nameKey);
  String subtitle(AppStrings s) => s.get(subtitleKey);
}

const List<WorldInfo> worlds = [
  WorldInfo(
    id: 0,
    nameKey: 'worldAlleyCorner',
    emoji: '🚪',
    color: Color(0xFF66BB6A),
    subtitleKey: 'worldSubtitleSingleRow',
  ),
  WorldInfo(
    id: 1,
    nameKey: 'worldNeonTavern',
    emoji: '🍺',
    color: Color(0xFF42A5F5),
    subtitleKey: 'worldSubtitleDoubleRow',
  ),
  WorldInfo(
    id: 2,
    nameKey: 'worldSmokeDen',
    emoji: '💨',
    color: Color(0xFF8D6E63),
    subtitleKey: 'worldSubtitlePepero',
  ),
  WorldInfo(
    id: 3,
    nameKey: 'worldShadowMarket',
    emoji: '🕶️',
    color: Color(0xFFAB47BC),
    subtitleKey: 'worldSubtitleTripleRow',
  ),
  WorldInfo(
    id: 4,
    nameKey: 'worldTheLastBet',
    emoji: '🎲',
    color: Color(0xFFEF5350),
    subtitleKey: 'worldSubtitleChallenge',
  ),
];

class WorldSelectScreen extends StatelessWidget {
  final StageManager stageManager;
  final LocaleProvider localeProvider;

  const WorldSelectScreen({
    super.key,
    required this.stageManager,
    required this.localeProvider,
  });

  @override
  Widget build(BuildContext context) {
    final s = localeProvider.strings;

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
        title: Text(
          s.get('worldSelect'),
          style: const TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: worlds.length,
        itemBuilder: (context, index) {
          final world = worlds[index];
          final isUnlocked = stageManager.isWorldUnlocked(world.id);
          final progress = stageManager.getWorldProgress(world.id);

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _WorldCard(
              world: world,
              strings: s,
              isUnlocked: isUnlocked,
              progress: progress,
              onTap: isUnlocked
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StageSelectScreen(
                            stageManager: stageManager,
                            world: world,
                            localeProvider: localeProvider,
                          ),
                        ),
                      );
                    }
                  : null,
            ),
          );
        },
      ),
    );
  }
}

class _WorldCard extends StatelessWidget {
  final WorldInfo world;
  final AppStrings strings;
  final bool isUnlocked;
  final int progress;
  final VoidCallback? onTap;

  const _WorldCard({
    required this.world,
    required this.strings,
    required this.isUnlocked,
    required this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isUnlocked ? Colors.white : Colors.grey[200],
      borderRadius: BorderRadius.circular(20),
      elevation: isUnlocked ? 4 : 1,
      shadowColor: world.color.withOpacity(0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? world.color.withOpacity(0.15)
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    isUnlocked ? world.emoji : '🔒',
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isUnlocked
                          ? world.name(strings)
                          : strings.get('worldLocked'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isUnlocked
                            ? const Color(0xFF2C3E50)
                            : Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isUnlocked
                          ? world.subtitle(strings)
                          : strings.get('clearPreviousWorld'),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                    if (isUnlocked) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress / 20,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    world.color),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$progress/20',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: world.color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (isUnlocked)
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey[400],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
