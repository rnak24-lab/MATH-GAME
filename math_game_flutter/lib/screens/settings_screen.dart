import 'package:flutter/material.dart';
import '../providers/locale_provider.dart';
import '../services/app_settings.dart';
import '../services/music_service.dart';
import '../game/stage_manager.dart';
import 'privacy_policy_screen.dart';

/// 설정 화면 — 언어 / 게임(진동·규칙·초기화) / 정보(개인정보처리방침·버전).
class SettingsScreen extends StatefulWidget {
  final LocaleProvider localeProvider;
  final VoidCallback onChanged;
  final StageManager? stageManager;

  const SettingsScreen({
    super.key,
    required this.localeProvider,
    required this.onChanged,
    this.stageManager,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _appVersion = '1.0.0';

  @override
  Widget build(BuildContext context) {
    final s = widget.localeProvider.strings;

    return Scaffold(
      backgroundColor: const Color(0xFFEFE6D0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Color(0xFF332817)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          s.get('settings'),
          style: const TextStyle(
            color: Color(0xFF332817),
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── 언어 ──
          _sectionTitle(s.get('languageSettings')),
          const SizedBox(height: 12),
          ...LocaleProvider.supportedLocales.map((loc) {
            final isSelected = widget.localeProvider.locale == loc['code'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _card(
                selected: isSelected,
                onTap: () async {
                  await widget.localeProvider.setLocale(loc['code']!);
                  widget.onChanged();
                  setState(() {});
                },
                child: Row(
                  children: [
                    Text(loc['flag']!, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        loc['name']!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFFC9A24B)
                              : const Color(0xFF332817),
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded,
                          color: Color(0xFFC9A24B), size: 24),
                  ],
                ),
              ),
            );
          }),

          // ── 게임 ──
          const SizedBox(height: 24),
          _sectionTitle(s.get('settingsGameplay')),
          const SizedBox(height: 12),
          // 배경음악 토글
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _card(
              onTap: () async {
                final on = !AppSettings.instance.music;
                await AppSettings.instance.setMusic(on);
                await MusicService.instance.setEnabled(on);
                setState(() {});
              },
              child: Row(
                children: [
                  const Icon(Icons.music_note_rounded,
                      color: Color(0xFFC9A24B)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.get('musicTitle'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF332817),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.get('musicDesc'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: AppSettings.instance.music,
                    activeColor: const Color(0xFFC9A24B),
                    onChanged: (v) async {
                      await AppSettings.instance.setMusic(v);
                      await MusicService.instance.setEnabled(v);
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ),
          // 음량 슬라이더 (음악 ON일 때만) — 드래그 중 실시간 반영, 놓으면 저장
          if (AppSettings.instance.music)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _card(
                child: Row(
                  children: [
                    const Icon(Icons.volume_down_rounded,
                        color: Color(0xFFC9A24B)),
                    Expanded(
                      child: Slider(
                        value: AppSettings.instance.musicVolume,
                        min: 0.0,
                        max: 1.0,
                        activeColor: const Color(0xFFC9A24B),
                        onChanged: (v) {
                          AppSettings.instance.musicVolume = v;
                          MusicService.instance.setVolume(v);
                          setState(() {});
                        },
                        onChangeEnd: (v) =>
                            AppSettings.instance.setMusicVolume(v),
                      ),
                    ),
                    const Icon(Icons.volume_up_rounded,
                        color: Color(0xFFC9A24B)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 42,
                      child: Text(
                        '${(AppSettings.instance.musicVolume * 100).round()}%',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // 효과음 토글
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _card(
              onTap: () async {
                await AppSettings.instance.setSfx(!AppSettings.instance.sfx);
                setState(() {});
              },
              child: Row(
                children: [
                  const Icon(Icons.graphic_eq_rounded,
                      color: Color(0xFFC9A24B)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.get('sfxTitle'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF332817),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.get('sfxDesc'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: AppSettings.instance.sfx,
                    activeColor: const Color(0xFFC9A24B),
                    onChanged: (v) async {
                      await AppSettings.instance.setSfx(v);
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ),
          // 진동 효과 토글
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _card(
              onTap: () async {
                await AppSettings.instance
                    .setHaptics(!AppSettings.instance.haptics);
                setState(() {});
              },
              child: Row(
                children: [
                  const Icon(Icons.vibration_rounded,
                      color: Color(0xFFC9A24B)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.get('hapticsTitle'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF332817),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.get('hapticsDesc'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: AppSettings.instance.haptics,
                    activeColor: const Color(0xFFC9A24B),
                    onChanged: (v) async {
                      await AppSettings.instance.setHaptics(v);
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ),
          // 게임 규칙 보기
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _card(
              onTap: _showRules,
              child: _navRow(
                  Icons.menu_book_rounded, s.get('howToPlay')),
            ),
          ),
          // 진행도 초기화
          if (widget.stageManager != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _card(
                onTap: _confirmReset,
                child: Row(
                  children: [
                    const Icon(Icons.restart_alt_rounded,
                        color: Color(0xFFE57373)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        s.get('resetProgress'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFD32F2F),
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: Color(0xFFE57373)),
                  ],
                ),
              ),
            ),

          // ── 정보 ──
          const SizedBox(height: 24),
          _sectionTitle(s.get('aboutSettings')),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _card(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PrivacyPolicyScreen(
                      localeProvider: widget.localeProvider,
                    ),
                  ),
                );
              },
              child: _navRow(
                  Icons.privacy_tip_outlined, s.get('privacyPolicy')),
            ),
          ),
          // 버전
          _card(
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: Color(0xFFC9A24B)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    s.get('versionLabel'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF332817),
                    ),
                  ),
                ),
                Text(
                  _appVersion,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 게임 규칙 다이얼로그 — 월드 순서(한줄→두줄→세줄→빼빼로)대로 4개 모드 규칙.
  void _showRules() {
    final s = widget.localeProvider.strings;
    final rules = <MapEntry<String, String>>[
      MapEntry(s.get('modeSingleRow'), s.get('ruleSingleRow', ['2~5'])),
      MapEntry(s.get('modeDoubleRow'), s.get('ruleDoubleRow')),
      MapEntry(s.get('modeTripleRow'), s.get('ruleTripleRow')),
      MapEntry(s.get('modePepero'), s.get('rulePepero')),
    ];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          s.get('howToPlay'),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF332817),
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: rules.length,
            separatorBuilder: (_, __) => const Divider(height: 18),
            itemBuilder: (_, i) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${i + 1}. ${rules[i].key}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFC9A24B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rules[i].value,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// 진행도 초기화 — 확인 다이얼로그 후 실행 (되돌릴 수 없음 경고).
  void _confirmReset() {
    final s = widget.localeProvider.strings;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          s.get('resetConfirmTitle'),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF332817),
          ),
        ),
        content: Text(
          s.get('resetConfirmBody'),
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.get('cancel')),
          ),
          TextButton(
            onPressed: () async {
              await widget.stageManager!.resetProgress();
              if (!mounted) return;
              Navigator.pop(ctx);
              widget.onChanged();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(s.get('resetDone')),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(
              s.get('resetDo'),
              style: const TextStyle(
                  color: Color(0xFFD32F2F), fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ── 공용 UI 조각 ──
  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF332817),
      ),
    );
  }

  Widget _card({required Widget child, VoidCallback? onTap, bool selected = false}) {
    return Material(
      color: selected ? const Color(0xFFC9A24B).withOpacity(0.1) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: selected ? 2 : 1,
      shadowColor: const Color(0xFFC9A24B).withOpacity(0.2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: child,
        ),
      ),
    );
  }

  Widget _navRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFC9A24B)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF332817),
            ),
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: Color(0xFFC9A24B)),
      ],
    );
  }
}
