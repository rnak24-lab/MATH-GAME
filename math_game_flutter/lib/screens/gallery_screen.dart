import 'package:flutter/material.dart';

import '../game/stage_manager.dart';
import '../l10n/dialogue.dart';
import '../providers/locale_provider.dart';
import '../utils/nim_theme.dart';
import '../widgets/midnight_character.dart';
import 'scene_screen.dart';
import 'world_select_screen.dart' show worlds;

/// 이야기 모음집 — (2026-09-16 대표님) 메인 메뉴에서 따로. 수업마다 1-1 … 1-4 카드.
/// 연 장면은 배경 + 예린 썸네일, 잠긴 장면은 자물쇠 + "n판 클리어하면 열려".
class GalleryScreen extends StatelessWidget {
  final StageManager stageManager;
  final LocaleProvider localeProvider;
  const GalleryScreen({super.key, required this.stageManager, required this.localeProvider});

  @override
  Widget build(BuildContext context) {
    final s = localeProvider.strings;
    int opened = 0;
    for (final w in worlds) {
      final p = stageManager.getWorldProgress(w.id);
      for (final t in Dialogue.thresholds) {
        if (p >= t) opened++;
      }
    }
    final int total = worlds.length * Dialogue.thresholds.length;

    return Scaffold(
      backgroundColor: NimTheme.deskBottom,
      appBar: AppBar(
        backgroundColor: NimTheme.frame,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: NimTheme.cream, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          s.get('galleryTitle'),
          style: const TextStyle(fontFamily: NimTheme.font, color: NimTheme.cream, fontSize: 19),
        ),
        centerTitle: true,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Text(
                '$opened/$total',
                style: const TextStyle(fontFamily: NimTheme.font, color: NimTheme.gold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: NimTheme.bg),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: worlds.length,
          itemBuilder: (_, i) {
            final w = worlds[i];
            final int n = i + 1;
            final int progress = stageManager.getWorldProgress(w.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(w.emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$n. ${w.name(s)}',
                          style: const TextStyle(
                            fontFamily: NimTheme.font,
                            fontSize: 16,
                            color: NimTheme.cream,
                          ),
                        ),
                      ),
                      Text(
                        '$progress/20',
                        style: TextStyle(
                          fontFamily: NimTheme.font,
                          fontSize: 12,
                          color: NimTheme.cream.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (int k = 1; k <= 4; k++) ...[
                        Expanded(
                          child: _SceneCard(
                            world: n,
                            worldId: w.id,
                            scene: k,
                            open: progress >= Dialogue.thresholdOf(k),
                            title: Dialogue.sceneTitle(n, k, s),
                            lockedText: s.get('storyLockedAt', ['${Dialogue.thresholdOf(k)}']),
                            gradient: w.bgGradient,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SceneScreen(
                                  world: n,
                                  scene: k,
                                  localeProvider: localeProvider,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (k < 4) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SceneCard extends StatelessWidget {
  final int world;
  final int worldId;
  final int scene;
  final bool open;
  final String title;
  final String lockedText;
  final List<Color> gradient;
  final VoidCallback onTap;
  const _SceneCard({
    required this.world,
    required this.worldId,
    required this.scene,
    required this.open,
    required this.title,
    required this.lockedText,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool long = scene == 4;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: open ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 118,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: open ? (long ? NimTheme.alarm : NimTheme.gold) : NimTheme.frameHi,
              width: open ? 2 : 1.5,
            ),
            color: NimTheme.deskBoard,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (open)
                Image.asset(
                  'assets/backgrounds/world$worldId.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradient,
                      ),
                    ),
                  ),
                ),
              if (open)
                const Positioned(
                  left: 0,
                  right: 0,
                  top: 10,
                  child: Center(
                    child: MidnightCharacter(
                      face: MidnightFace.happy1,
                      size: 150,
                      animate: false,
                    ),
                  ),
                ),
              // 아래 라벨
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  color: Colors.black.withOpacity(open ? 0.6 : 0.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$world-$scene',
                        style: TextStyle(
                          fontFamily: NimTheme.font,
                          fontSize: 12,
                          color: open ? NimTheme.gold : NimTheme.cream.withOpacity(0.6),
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        open ? title : lockedText,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: NimTheme.font,
                          fontSize: 10.5,
                          height: 1.2,
                          color: open ? NimTheme.cream : NimTheme.cream.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!open)
                Positioned(
                  top: 10,
                  left: 0,
                  right: 0,
                  child: Icon(Icons.lock_outline_rounded, size: 22, color: NimTheme.cream.withOpacity(0.35)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
