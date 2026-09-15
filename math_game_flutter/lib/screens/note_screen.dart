import 'package:flutter/material.dart';

import '../game/stage_manager.dart';
import '../l10n/dialogue.dart';
import '../providers/locale_provider.dart';
import '../utils/nim_theme.dart';
import '../widgets/dialogue_box.dart';
import '../widgets/midnight_character.dart';
import 'world_select_screen.dart' show worlds;

/// 예린의 노트 — (2026-09-15 대표님) 퍼즐을 풀면 남는 것 두 가지.
///  1) 비법 노트: 월드 3판을 깨면 그 월드의 필승 공식 카드가 열린다 (힌트형, 예린 손글씨 톤).
///  2) 이야기: 호감도 단계마다 본 장면을 다시 볼 수 있다.
class NoteScreen extends StatefulWidget {
  final StageManager stageManager;
  final LocaleProvider localeProvider;
  const NoteScreen({super.key, required this.stageManager, required this.localeProvider});

  @override
  State<NoteScreen> createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  int _tab = 0; // 0 비법 노트, 1 이야기

  @override
  Widget build(BuildContext context) {
    final s = widget.localeProvider.strings;
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
          s.get('noteTitle'),
          style: const TextStyle(fontFamily: NimTheme.font, color: NimTheme.cream, fontSize: 19),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: NimTheme.bg),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Expanded(child: _tabButton(0, s.get('noteTabNotes'))),
                  const SizedBox(width: 8),
                  Expanded(child: _tabButton(1, s.get('noteTabStories'))),
                ],
              ),
            ),
            Expanded(child: _tab == 0 ? _notes(s) : _stories(s)),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(int i, String label) {
    final bool on = _tab == i;
    return Material(
      color: on ? NimTheme.gold : NimTheme.frame,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: () => setState(() => _tab = i),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: NimTheme.font,
              fontSize: 15,
              color: on ? NimTheme.deskBottom : NimTheme.cream,
            ),
          ),
        ),
      ),
    );
  }

  // ── 비법 노트 12장 ──
  Widget _notes(dynamic s) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: worlds.length,
      itemBuilder: (_, i) {
        final w = worlds[i];
        final int n = i + 1;
        final bool open = widget.stageManager.getWorldProgress(w.id) >= 3;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            decoration: BoxDecoration(
              color: open ? NimTheme.paperLight : NimTheme.deskBoard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: open ? NimTheme.gold : NimTheme.frameHi, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(w.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        open ? s.get('nb_w${n}_title') : w.name(s),
                        style: TextStyle(
                          fontFamily: NimTheme.font,
                          fontSize: 17,
                          color: open ? NimTheme.ink : NimTheme.cream,
                        ),
                      ),
                    ),
                    Icon(
                      open ? Icons.edit_note_rounded : Icons.lock_outline_rounded,
                      size: 20,
                      color: open ? NimTheme.inkSoft : NimTheme.cream.withOpacity(0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (open)
                  for (int k = 1; k <= 3; k++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('✎ ', style: TextStyle(fontFamily: NimTheme.font, color: NimTheme.inkSoft)),
                          Expanded(
                            child: Text(
                              s.get('nb_w${n}_$k'),
                              style: const TextStyle(
                                fontFamily: NimTheme.font,
                                fontSize: 14,
                                height: 1.45,
                                color: NimTheme.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                else
                  Text(
                    s.get('noteLocked', ['${3 - widget.stageManager.getWorldProgress(w.id)}']),
                    style: TextStyle(
                      fontFamily: NimTheme.font,
                      fontSize: 13,
                      color: NimTheme.cream.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── 이야기 — 수업마다 5/10/15/20판 ──
  Widget _stories(dynamic s) {
    final sm = widget.stageManager;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: worlds.length,
      itemBuilder: (_, i) {
        final w = worlds[i];
        final int n = i + 1;
        final int progress = sm.getWorldProgress(w.id);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            decoration: BoxDecoration(
              color: progress >= 5 ? NimTheme.paperLight : NimTheme.deskBoard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: progress >= 5 ? NimTheme.gold : NimTheme.frameHi, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(w.emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        w.name(s),
                        style: TextStyle(
                          fontFamily: NimTheme.font,
                          fontSize: 16,
                          color: progress >= 5 ? NimTheme.ink : NimTheme.cream,
                        ),
                      ),
                    ),
                    Text(
                      '$progress/20',
                      style: TextStyle(
                        fontFamily: NimTheme.font,
                        fontSize: 12,
                        color: progress >= 5 ? NimTheme.inkSoft : NimTheme.cream.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final t in Dialogue.thresholds) _storyChip(n, t, progress >= t, s),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _storyChip(int world, int threshold, bool open, dynamic s) {
    final String label = open
        ? '${Dialogue.kindLabel(threshold, s)} · ${Dialogue.sceneTitle(world, threshold, s)}'
        : '${Dialogue.kindLabel(threshold, s)} · ${s.get('storyLockedAt', ['$threshold'])}';
    return Material(
      color: open ? NimTheme.gold : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: open ? () => _replayScene(world, threshold, s) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: open ? NimTheme.gold : NimTheme.frameHi, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(open ? Icons.menu_book_rounded : Icons.lock_outline_rounded,
                  size: 14, color: open ? NimTheme.deskBottom : NimTheme.cream.withOpacity(0.5)),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontFamily: NimTheme.font,
                  fontSize: 12,
                  color: open ? NimTheme.deskBottom : NimTheme.cream.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 본 이야기 다시 보기 — 예린 + 대화 상자만 있는 전체 화면
  void _replayScene(int world, int threshold, dynamic s) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _SceneReplay(
          lines: Dialogue.worldScene(world, threshold, s),
          title: Dialogue.sceneTitle(world, threshold, s),
          speaker: s.get('nameMidnight'),
        ),
      ),
    );
  }
}

class _SceneReplay extends StatefulWidget {
  final List<DialogueLine> lines;
  final String title;
  final String speaker;
  const _SceneReplay({required this.lines, required this.title, required this.speaker});

  @override
  State<_SceneReplay> createState() => _SceneReplayState();
}

class _SceneReplayState extends State<_SceneReplay> {
  MidnightFace _face = MidnightFace.neutral;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NimTheme.deskBottom,
      body: Container(
        decoration: const BoxDecoration(gradient: NimTheme.bg),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: MidnightCharacter(face: _face, size: 530, animate: false),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded, color: NimTheme.cream, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: DialogueBox(
                  lines: widget.lines,
                  speaker: widget.speaker,
                  title: widget.title,
                  onFace: (f) => setState(() => _face = f),
                  onDone: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
