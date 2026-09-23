import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 테스트 계측 (2026-09-23) — 스테이지별 시도·승·패·힌트·이탈·시간을 기기에 쌓고
/// 하루 한 번 중계 서버(dev-setup/nim_relay → 텔레그램)로 보낸다.
///
/// - 개인정보 없음: 기기마다 무작위 4자 태그만. 계정·광고ID·기기ID 안 씀.
/// - 봇 토큰은 앱에 없다. 앱은 `kTelemetryUrl` 에 JSON 만 POST 하고 중계가 텔레그램으로 보낸다.
/// - `kTelemetryKey` 는 중계의 스팸 방지용 공유 키(유출돼도 리포트 도배 이상은 못 한다).
/// - 정식 출시 전 `kTelemetryEnabled` 를 끄거나 개인정보처리방침에 "익명 플레이 통계" 문구 추가.
const bool kTelemetryEnabled = true;
const String kTelemetryUrl = 'https://nim-relay.vercel.app/api/report';
const String kTelemetryKey = 'nim-tester-2026';
const Duration _kSendEvery = Duration(hours: 24);

/// 스테이지 하나의 누적 통계. 0 = 오늘 한 판.
class StageStat {
  int tries = 0; // 시작 횟수(다시하기 포함)
  int wins = 0;
  int losses = 0;
  int hints = 0; // 힌트 전구로 답을 본 횟수
  int quits = 0; // 승패 전에 나간 횟수(뒤로가기·앱 종료)
  int secs = 0; // 판 위에 있던 시간(초)

  List<int> toList() => [tries, wins, losses, hints, quits, secs];
  static StageStat fromList(List<dynamic> l) => StageStat()
    ..tries = l[0] as int
    ..wins = l[1] as int
    ..losses = l[2] as int
    ..hints = l[3] as int
    ..quits = l[4] as int
    ..secs = l[5] as int;
}

class Telemetry {
  Telemetry._();
  static final Telemetry instance = Telemetry._();

  static const String _prefsKey = 'telemetry_v1';

  String tag = '';
  String installDate = '';
  int sessions = 0;
  String lastSent = ''; // ISO
  final Map<int, StageStat> stats = {};

  // 진행 중인 판
  int _active = -1;
  DateTime? _startedAt;
  bool _ended = true;
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        tag = m['tag'] as String? ?? '';
        installDate = m['install'] as String? ?? '';
        sessions = m['sessions'] as int? ?? 0;
        lastSent = m['sent'] as String? ?? '';
        final st = m['stats'] as Map<String, dynamic>? ?? {};
        st.forEach((k, v) => stats[int.parse(k)] = StageStat.fromList(v as List));
      }
    } catch (e) {
      debugPrint('[Telemetry] load fail: $e');
    }
    if (tag.isEmpty) {
      const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
      final r = Random.secure();
      tag = List.generate(4, (_) => chars[r.nextInt(chars.length)]).join();
    }
    if (installDate.isEmpty) installDate = _today();
    sessions++;
    await _save();
  }

  static String _today() => DateTime.now().toIso8601String().substring(0, 10);

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(_toJson()));
    } catch (e) {
      debugPrint('[Telemetry] save fail: $e');
    }
  }

  Map<String, dynamic> _toJson() => {
        'tag': tag,
        'install': installDate,
        'sessions': sessions,
        'sent': lastSent,
        'stats': {for (final e in stats.entries) '${e.key}': e.value.toList()},
      };

  StageStat _of(int stage) => stats.putIfAbsent(stage, () => StageStat());

  // ── 게임 화면에서 부르는 훅 ──
  void stageStart(int stage) {
    if (!kTelemetryEnabled) return;
    _of(stage).tries++;
    _active = stage;
    _startedAt = DateTime.now();
    _ended = false;
    _save();
  }

  void stageEnd(int stage, {required bool won}) {
    if (!kTelemetryEnabled || _ended) return;
    final st = _of(stage);
    if (won) {
      st.wins++;
    } else {
      st.losses++;
    }
    st.secs += _elapsed();
    _ended = true;
    _save();
  }

  void hintUsed(int stage) {
    if (!kTelemetryEnabled) return;
    _of(stage).hints++;
    _save();
  }

  /// 화면을 떠날 때 — 승패 전이면 이탈로 센다.
  void stageLeave(int stage) {
    if (!kTelemetryEnabled) return;
    if (_active == stage && !_ended) {
      final st = _of(stage);
      st.quits++;
      st.secs += _elapsed();
      _ended = true;
      _save();
    }
    _active = -1;
  }

  int _elapsed() {
    final s = _startedAt;
    if (s == null) return 0;
    return DateTime.now().difference(s).inSeconds.clamp(0, 3600);
  }

  // ── 요약 ──
  int get totalTries => stats.values.fold(0, (a, b) => a + b.tries);
  int get totalSecs => stats.values.fold(0, (a, b) => a + b.secs);
  int get maxStage => stats.keys.where((k) => k > 0).fold(0, max);

  /// 사람이 읽는 리포트 (전송 실패 시 클립보드용)
  String report() {
    final b = StringBuffer();
    b.writeln('님게임 테스트 리포트 · 기기 $tag · ${_today()}');
    b.writeln('설치 $installDate · 세션 $sessions · 플레이 ${totalSecs ~/ 60}분 · 최고 스테이지 $maxStage');
    b.writeln('스테이지,시도,승,패,힌트,이탈,초');
    final keys = stats.keys.toList()..sort();
    for (final k in keys) {
      final s = stats[k]!;
      b.writeln('${k == 0 ? '오늘한판' : k},${s.tries},${s.wins},${s.losses},${s.hints},${s.quits},${s.secs}');
    }
    return b.toString();
  }

  /// 중계 서버로 전송. 성공하면 true.
  Future<bool> send() async {
    if (!kTelemetryEnabled || totalTries == 0) return false;
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
      final req = await client.postUrl(Uri.parse(kTelemetryUrl));
      req.headers.contentType = ContentType.json;
      req.headers.set('x-nim-key', kTelemetryKey);
      req.write(jsonEncode({..._toJson(), 'ts': DateTime.now().toIso8601String()}));
      final res = await req.close().timeout(const Duration(seconds: 15));
      await res.drain<void>();
      client.close();
      if (res.statusCode == 200) {
        lastSent = DateTime.now().toIso8601String();
        await _save();
        return true;
      }
      debugPrint('[Telemetry] send status ${res.statusCode}');
    } catch (e) {
      debugPrint('[Telemetry] send fail: $e');
    }
    return false;
  }

  /// 홈에 들어올 때 — 하루 한 번 자동 전송 (조용히, 실패해도 무시)
  Future<void> maybeAutoSend() async {
    if (!kTelemetryEnabled || totalTries == 0) return;
    if (lastSent.isNotEmpty) {
      final last = DateTime.tryParse(lastSent);
      if (last != null && DateTime.now().difference(last) < _kSendEvery) return;
    }
    await send();
  }
}
