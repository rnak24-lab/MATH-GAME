import 'package:flutter/material.dart';

import '../game/stage_manager.dart';
import '../game/tutorial_manager.dart';
import '../providers/locale_provider.dart';
import '../utils/nim_theme.dart';
import 'rule_intro_screen.dart';
import 'world_select_screen.dart' show worlds;

/// 규칙 노트 — (2026-09-16 대표님) 공략(비법)은 전부 삭제. 게임 규칙만 자세히.
/// 수업마다: 규칙 본문(게임 화면 ? 와 같은 문장) + 보충 설명 2줄(rx_w{n}_1·2).
class NoteScreen extends StatelessWidget {
  final StageManager stageManager;
  final LocaleProvider localeProvider;
  const NoteScreen({super.key, required this.stageManager, required this.localeProvider});

  static const List<String> _ruleKeys = [
    'ruleSingleRow', 'ruleDoubleRow', 'ruleTripleRow', 'rulePepero', 'ruleKayles', 'ruleWythoff',
    'ruleFibonacci', 'ruleChomp', 'ruleDots', 'ruleSim', 'ruleSprouts', 'ruleHex',
  ];
  static const List<String> _modeKeys = [
    'modeSingleRow', 'modeDoubleRow', 'modeTripleRow', 'modePepero', 'modeKayles', 'modeWythoff',
    'modeFibonacci', 'modeChomp', 'modeDots', 'modeSim', 'modeSprouts', 'modeHex',
  ];

  String _ruleText(int n, dynamic s) {
    final String snack = s.snackObj(TutorialManager.snackKeyForWorld(n));
    if (n == 1) return s.get('ruleSingleRow', [snack, '2~5']);
    if (n <= 7) return s.get(_ruleKeys[n - 1], [snack]);
    return s.get(_ruleKeys[n - 1]);
  }

  @override
  Widget build(BuildContext context) {
    final s = localeProvider.strings;
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
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: worlds.length,
          itemBuilder: (_, i) {
            final w = worlds[i];
            final int n = i + 1;
            final bool unlocked = stageManager.isWorldUnlocked(w.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RuleIntroScreen(world: n, localeProvider: localeProvider),
                  ),
                ),
                child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                decoration: BoxDecoration(
                  color: unlocked ? NimTheme.paperLight : NimTheme.deskBoard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: unlocked ? NimTheme.gold : NimTheme.frameHi, width: 2),
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
                            '${w.name(s)} · ${s.get(_modeKeys[n - 1])}',
                            style: TextStyle(
                              fontFamily: NimTheme.font,
                              fontSize: 16,
                              color: unlocked ? NimTheme.ink : NimTheme.cream,
                            ),
                          ),
                        ),
                        if (!unlocked)
                          Icon(Icons.lock_outline_rounded, size: 18, color: NimTheme.cream.withOpacity(0.5)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _ruleText(n, s),
                      style: TextStyle(
                        fontFamily: NimTheme.font,
                        fontSize: 14,
                        height: 1.5,
                        color: unlocked ? NimTheme.ink : NimTheme.cream.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (int k = 1; k <= 2; k++)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('· ', style: TextStyle(fontFamily: NimTheme.font, color: unlocked ? NimTheme.inkSoft : NimTheme.cream.withOpacity(0.6))),
                            Expanded(
                              child: Text(
                                s.get('rx_w${n}_$k'),
                                style: TextStyle(
                                  fontFamily: NimTheme.font,
                                  fontSize: 13,
                                  height: 1.45,
                                  color: unlocked ? NimTheme.inkSoft : NimTheme.cream.withOpacity(0.6),
                                ),
                              ),
                            ),
                          ],
                        ),
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
