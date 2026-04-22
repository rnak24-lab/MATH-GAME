import 'package:flutter/material.dart';
import '../game/stage_manager.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_strings.dart';
import 'stage_select_screen.dart';
import 'settings_screen.dart';

class WorldInfo {
  final int id;
  final String nameKey;
  final String emoji;
  final Color color;
  final String subtitleKey;
  // (id=1141) 월드별 고유 배경 그라데이션 (5색, 일관 규칙: 상단 어두움 → 하단 월드 색감).
  final List<Color> bgGradient;

  const WorldInfo({
    required this.id,
    required this.nameKey,
    required this.emoji,
    required this.color,
    required this.subtitleKey,
    required this.bgGradient,
  });

  String name(AppStrings s) => s.get(nameKey);
  String subtitle(AppStrings s) => s.get(subtitleKey);
}

// (id=1141) 배경 디자인 규칙:
// - 3색 선형 그라데이션 (topLeft → bottomRight)
// - 상단: 분위기 어두운 톤 (월드의 테마색 어두운 버전)
// - 중단: 월드 색 원본
// - 하단: 연한 크림톤 (보드가 얹힐 때 가독성)
// - 공통 톤 패턴으로 5개 월드 일관성 유지
const List<WorldInfo> worlds = [
  WorldInfo(
    id: 0,
    nameKey: 'worldAlleyCorner',
    emoji: '🚪',
    color: Color(0xFF66BB6A),
    subtitleKey: 'worldSubtitleSingleRow',
    bgGradient: [Color(0xFF2E4F30), Color(0xFF66BB6A), Color(0xFFE8F5E9)],
  ),
  WorldInfo(
    id: 1,
    nameKey: 'worldNeonTavern',
    emoji: '🍺',
    color: Color(0xFF42A5F5),
    subtitleKey: 'worldSubtitleDoubleRow',
    bgGradient: [Color(0xFF1A3A5C), Color(0xFF42A5F5), Color(0xFFE3F2FD)],
  ),
  WorldInfo(
    id: 2,
    nameKey: 'worldSmokeDen',
    emoji: '💨',
    color: Color(0xFF8D6E63),
    subtitleKey: 'worldSubtitlePepero',
    bgGradient: [Color(0xFF3E2723), Color(0xFF8D6E63), Color(0xFFEFEBE9)],
  ),
  WorldInfo(
    id: 3,
    nameKey: 'worldShadowMarket',
    emoji: '🕶️',
    color: Color(0xFFAB47BC),
    subtitleKey: 'worldSubtitleTripleRow',
    bgGradient: [Color(0xFF4A148C), Color(0xFFAB47BC), Color(0xFFF3E5F5)],
  ),
  WorldInfo(
    id: 4,
    nameKey: 'worldTheLastBet',
    emoji: '🎲',
    color: Color(0xFFEF5350),
    // (id=1201) 월드5 quadRow 전용. 기존 "섞어서" 컨셉 폐기.
    subtitleKey: 'worldSubtitleQuadRow',
    bgGradient: [Color(0xFF5D1A1A), Color(0xFFEF5350), Color(0xFFFFEBEE)],
  ),
];

/// (id=1141) 글로벌 스테이지 번호로 월드 배경 가져오기 (GameScreen에서 사용).
WorldInfo worldForStage(int stageNumber) {
  int idx = ((stageNumber - 1) ~/ 20).clamp(0, worlds.length - 1);
  return worlds[idx];
}

class WorldSelectScreen extends StatefulWidget {
  final StageManager stageManager;
  final LocaleProvider localeProvider;

  const WorldSelectScreen({
    super.key,
    required this.stageManager,
    required this.localeProvider,
  });

  @override
  State<WorldSelectScreen> createState() => _WorldSelectScreenState();
}

class _WorldSelectScreenState extends State<WorldSelectScreen> {
  StageManager get stageManager => widget.stageManager;
  LocaleProvider get localeProvider => widget.localeProvider;

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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded,
                color: Color(0xFF7C4DFF), size: 26),
            tooltip: s.get('settings'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    localeProvider: localeProvider,
                    onChanged: () => setState(() {}),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
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
                  ? () async {
                      // (id=1144) 스테이지 선택 화면에서 돌아올 때 진행도/해금 상태 재갱신
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StageSelectScreen(
                            stageManager: stageManager,
                            world: world,
                            localeProvider: localeProvider,
                          ),
                        ),
                      );
                      if (mounted) setState(() {});
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
                    // (id=1140) 잠긴 월드도 제목은 항상 표시
                    Text(
                      world.name(strings),
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
                          : strings.get('unlockHint3Stages'),
                      style: TextStyle(
                        fontSize: 13,
                        color: isUnlocked ? Colors.grey[500] : Colors.orange[700],
                        fontWeight: isUnlocked ? FontWeight.normal : FontWeight.w600,
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
