import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import '../services/app_settings.dart';
import '../services/sfx_service.dart';
import 'settings_screen.dart';
import '../game/stage_manager.dart';
import '../game/nim_engine.dart';
import '../models/game_state.dart';
import '../widgets/midnight_character.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_strings.dart';
import '../services/ad_service.dart';
import '../game/tutorial_manager.dart';
import '../l10n/dialogue.dart';
import '../widgets/dialogue_box.dart';
import 'scene_screen.dart';
import 'rule_intro_screen.dart';
import 'world_select_screen.dart' show worldForStage;
import 'board_game_screen.dart' show stageScreenFor;
import '../game/board_games.dart' show kTotalStages;

/// Papers-Please풍 "심문 책상" 탑뷰 팔레트 (sepia noir).
/// 책상 상단 y — **고정값**. 돌 개수가 바뀌어도 책상은 절대 움직이지 않는다.
/// (개수 변화는 책상 '안'에서 셀 크기가 적응하는 방식으로 흡수)
/// 값이 클수록 책상이 아래로 내려가 캐릭터가 더 많이 보인다.
const double _kDeskTop = 340;

/// 예린 이미지 높이(논리 px). 원화 머리 구간(높이의 6%~36%)이 말풍선 아래~책상 위에
/// 오도록 530 (대표님: 400과 660의 중간). 폭은 자동(530 × 1080/1920 ≈ 298) — 폰 해상도가 달라도 논리 px 기준이라
/// 얼굴 크기가 같다. 아래쪽(허리 이하)은 책상에 가려진다 — 의도.
const double _kYerinH = 530;

/// 예린 이미지 상단 y. 머리 꼭대기(높이의 ~6.5%)가 y≈83 에 오도록 (말풍선 바로 아래).
const double _kYerinTop = 83 - _kYerinH * 0.065; // 대표님: 가슴팍까지 보이게 위로

class _Pal {
  static const deskTop = Color(0xFF3A332A); // 책상 상단(밝은 쪽)
  static const deskBottom = Color(0xFF241F18); // 책상 하단(어두운 쪽)
  static const grid = Color(0x12E8DCC0); // 책상 위 미세 그리드/마크
  static const paper = Color(0xFFC8B790); // 낡은 종이 패널
  static const paperEdge = Color(0xFFA68F66);
  static const frame = Color(0xFF4A3D2C); // 짙은 나무 프레임
  static const frameHi = Color(0xFF6E5C42); // 프레임 하이라이트(베벨)
  static const cream = Color(0xFFEADFC6); // 어두운 배경 위 글자
  static const ink = Color(0xFF332817); // 종이 위 글자
  static const inkSoft = Color(0xFF6A5A3F);
  static const gold = Color(0xFFC9A24B); // 강조(현재 턴/선택)
  static const alarm = Color(0xFF9B3B2E); // 경고/패배/제거
  static const win = Color(0xFF5E7D52); // 승리/성공
  static const sky = Color(0xFF79C6EA); // 막대과자 선택(하늘색)
  static const hint = Color(0xFF3D8FB8); // 힌트 강조(짙은 하늘) — 어두운 배경 위
  static const alarmHi = Color(0xFFE0574A); // 경고 밝은 버전(어두운 배경 위)

  // ── 교실 팔레트 (2026-07-08 대표님 원화 기준 — 손그림 파스텔) ──
  static const roomWall = Color(0xFFF2EDE3); // 크림 벽
  static const roomWallLow = Color(0xFFE7DED0); // 벽 아랫단(살짝 어둡게)
  static const chalkboard = Color(0xFF3F9C6F); // 초록 칠판
  static const chalkboardDark = Color(0xFF2E7D5B); // 칠판 음영
  static const woodFrame = Color(0xFFC98F52); // 나무 프레임/문설주
  static const deskWood = Color(0xFFD9A05B); // 밝은 나무 책상
  static const deskWoodDark = Color(0xFFB98443); // 책상 결/모서리
  static const windowGlass = Color(0xFFBFD8EC); // 창문 하늘
  static const windowFrame = Color(0xFFEFF2F4); // 창틀
  static const cloud = Color(0xFFF6F3E7); // 구름
  static const sketchInk = Color(0xFF3A342E); // 손그림 라인/낙서
}

const String _mono = 'NeoDGM'; // 한글+영문 픽셀 폰트 (10번 제안)

class GameScreen extends StatefulWidget {
  final StageManager stageManager;
  final int stageNumber;
  final LocaleProvider localeProvider;

  /// 오늘의 한 판이면 그 판 설정 (stageNumber 는 0). 클리어는 진행도가 아니라
  /// 호감도(dailyWins)·연속 출석으로 기록된다.
  final StageConfig? dailyConfig;

  const GameScreen({
    super.key,
    required this.stageManager,
    required this.stageNumber,
    required this.localeProvider,
    this.dailyConfig,
  });

  bool get isDaily => dailyConfig != null;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final NimEngine _engine = NimEngine();
  late StageConfig _config;
  AppStrings get s => widget.localeProvider.strings;

  // Game state
  GamePhase _phase = GamePhase.playing;
  TurnOwner _currentTurn = TurnOwner.player;
  List<int> _rows = [];
  bool _playerWon = false;
  int _turnCount = 0;

  // Selection state
  int _selectedRow = 0;
  int _selectedCount = 0; // 0 = 아무 돌도 안 집은 상태 (턴 시작 시 미리선택 없음)
  int _selectedPile = -1; // 빼빼로: 선택 없음 = -1 (미리 선택해주지 않기)

  // ── 🧪 카일즈: 아무 위치 인접 1~2개 선택 ──
  int _kSelRow = -1;
  int _kSelStart = -1;
  int _kSelCount = 0;

  // ── 🧪 위토프: 줄별 suffix 선택 개수 ──
  int _wSelA = 0;
  int _wSelB = 0;

  // ── 🧪 피보나치: 이번 턴 가져갈 수 있는 최대 (직전 상대 수의 2배, 첫 수 = n-1) ──
  int _fibLimit = 0;

  /// 한 번에 가져갈 수 있는 최대 개수 (피보나치는 턴마다 변동).
  int get _effectiveMaxTake =>
      _config.mode == GameMode.fibonacci ? _fibLimit : _config.maxTake;
  int _splitA = 1;

  // Midnight state
  MidnightFace _midnightFace = MidnightFace.neutral;

  // 대사는 "키+인자"로 저장하고 그릴 때 현재 언어로 해석
  // → 게임 중 언어를 바꿔도 말풍선이 즉시 새 언어로 표시된다.
  String? _msgKey;
  List<String> _msgArgs = const [];
  String get _midnightMessage =>
      _msgKey == null ? '' : s.get(_msgKey!, _msgArgs);

  /// 말풍선 대사 설정 (setState 밖에서도 호출 가능 — 호출부가 setState 책임)
  void _say(String key, [List<String> args = const []]) {
    _msgKey = key;
    _msgArgs = args;
  }

  bool _isAiAnimating = false;
  bool _leaving = false; // Take 시 선택된 돌이 슈르륵 빠지는 중

  // 한밤이가 가져간 돌이 "슉!" 날아가는 연출용 (id 리스트)
  final List<int> _flights = [];
  int _flightSeq = 0;

  /// 돌 하나가 고양이 쪽으로 슉 날아가는 연출 + 효과음.
  void _spawnFlight() {
    final id = _flightSeq++;
    setState(() => _flights.add(id));
    SfxService.instance.playTake();
    Future.delayed(const Duration(milliseconds: 420), () {
      if (mounted) setState(() => _flights.remove(id));
    });
  }

  /// (귀여움 규칙) 진동 효과 — 설정에서 끌 수 있음.
  void _haptic([bool strong = false]) {
    if (!AppSettings.instance.haptics) return;
    strong ? HapticFeedback.mediumImpact() : HapticFeedback.selectionClick();
  }

  // 플레이어 턴 시작 시 NIM 패배 상태 연속 카운트 (happy → confident 전환용)
  int _consecutiveLossTurns = 0;

  // ── 손으로 배우는 가이드 (월드 첫 판) — TutorialManager.nimGuide ──
  List<GuideStep> _guide = const [];
  int _guideIndex = 0;
  bool get _guideActive => _guideIndex < _guide.length;
  GuideStep? get _guideStep => _guideActive ? _guide[_guideIndex] : null;

  /// "읽기" 스텝 — 책상 아래를 어둡게 하고 다음 버튼
  bool get _guideReading => _guideStep?.kind == GuideKind.read;

  /// 지금 플레이어가 둬야 하는 수 (act = 스크립트, follow = 엔진 최선). 아니면 null.
  NimMove? get _guideRequired {
    final st = _guideStep;
    if (st == null || _currentTurn != TurnOwner.player) return null;
    if (st.kind == GuideKind.act) return st.require;
    if (st.kind == GuideKind.follow) {
      return _engine.bestMove(_rows, _config.mode,
          maxTake: _config.maxTake, fibLimit: _fibLimit);
    }
    return null;
  }

  /// 가이드 문장은 플레이어 차례(또는 읽기 스텝)에만 말풍선을 차지한다.
  bool get _guideSpeaking =>
      _guideActive &&
      (_guideReading || (_currentTurn == TurnOwner.player && !_isAiAnimating));

  final math.Random _rng = math.Random();

  // ── 패배 되감기: "이기던 판을 지는 판으로 만든 첫 수" 를 기억한다 ──
  List<int>? _mistakeRows;
  NimMove? _mistakeMove;
  NimMove? _mistakeBest;
  int _mistakeFib = 0;
  bool _replaying = false;

  // ── 클리어 뒤 미연시식 대화 (한마디 + 호감도 장면) ──
  List<DialogueLine>? _dialogue;
  String? _dialogueTitle;
  int? _dialogueScene; // 지금 보여주는 이야기 문턱 (5/10/15/20) — 대화 상자 key 용

  // 연속 패배 추적 (2회 연속 패배 시 자동 힌트)
  int _consecutiveDefeats = 0;

  @override
  void initState() {
    super.initState();
    _config = widget.dailyConfig ?? _engine.generateStage(widget.stageNumber);
    _rows = List.from(_config.rows);
    _sayGreeting();
    // 피보나치: 첫 수는 "전부 빼기 금지" → 최대 n-1
    if (_config.mode == GameMode.fibonacci) {
      _fibLimit = _rows[0] - 1;
    }

    // 월드 첫 판 = 가이드 판 ("읽기" → "하기")
    _guide = TutorialManager.nimGuide(widget.stageNumber, s);

    // (2026-09-15 대표님) 선공 선택 없음 — 모든 판은 플레이어가 먼저 둔다.
    // 초기 판은 NimEngine.generateStage 가 "선공 필승" 을 보장한다.
    _phase = GamePhase.playing;
    _currentTurn = TurnOwner.player;
    _losing = _calculateMidnightWinsState();
    _applyGuideHighlight();
    if (!widget.isDaily) _maybeShowRuleIntro();
  }

  /// 수업 첫 판: 규칙 설명 화면을 먼저 (한 번만). 다시 보기는 규칙 노트에서.
  bool _introVisible = false;
  void _maybeShowRuleIntro() {
    if (!TutorialManager.isTutorialStage(widget.stageNumber)) return;
    final int w = TutorialManager.worldOf(widget.stageNumber);
    if (widget.stageManager.ruleIntroSeen(w)) return;
    _introVisible = true; // 게임 화면 대신 바로 그린다 (푸시하면 게임 화면이 한 프레임 먼저 보임)
  }

  Widget _inlineIntro() => RuleIntroScreen(
        world: TutorialManager.worldOf(widget.stageNumber),
        localeProvider: widget.localeProvider,
        onDone: () {
          widget.stageManager.markRuleIntroSeen(TutorialManager.worldOf(widget.stageNumber));
          setState(() => _introVisible = false);
        },
      );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 표정 6종 프리로드 — 표정 전환 시 깜빡임/로드 지연 방지
    for (final f in [
      'default',
      'happy',
      'sleepy',
      'angry',
      'smug',
      'surprised'
    ]) {
      precacheImage(AssetImage('assets/midnight/$f.png'), context);
    }
  }

  /// 현재 가이드 문장 — 매 build 마다 현재 언어로 다시 읽는다.
  String get _guideText {
    final steps = TutorialManager.nimGuide(widget.stageNumber, s);
    if (_guideIndex >= steps.length) return '';
    return steps[_guideIndex].text;
  }

  void _advanceGuide() {
    setState(() {
      _guideIndex++;
      _applyGuideHighlight();
    });
  }

  /// act/follow 스텝이면 둬야 할 수를 하늘색으로 (setState 밖에서도 호출 가능).
  void _applyGuideHighlight() {
    final req = _guideRequired;
    if (req != null) _setHintFields(req);
  }

  /// 되감기·가이드용 순수 적용 — 화면 상태를 건드리지 않고 "이 수를 두면 어떤 판이 되나".
  /// 반환: (rows, 다음 피보나치 한도)
  (List<int>, int) _applied(List<int> rows, NimMove m) {
    final r = List<int>.from(rows);
    int fib = _fibLimit;
    if (m.isPepero) {
      r.removeAt(m.rowIndex);
      r.add(m.splitA);
      r.add(m.splitB);
      r.sort((x, y) => y.compareTo(x));
    } else if (m.isKayles) {
      r.removeAt(m.rowIndex);
      if (m.kaylesRight > 0) r.insert(m.rowIndex, m.kaylesRight);
      if (m.kaylesLeft > 0) r.insert(m.rowIndex, m.kaylesLeft);
    } else if (m.isWythoff) {
      r[0] -= m.takeA;
      r[1] -= m.takeB;
    } else {
      r[m.rowIndex] -= m.count;
      if (_config.mode == GameMode.fibonacci) fib = m.count * 2;
    }
    return (r, fib);
  }

  /// 플레이어가 수를 두기 직전에 호출 — 이기던 판을 지는 판으로 만들었으면 기록.
  void _recordPlayerMove(NimMove m) {
    if (_mistakeMove != null) return;
    final bool losingBefore = _engine.toMoveLoses(_rows, _config.mode,
        maxTake: _config.maxTake, fibLimit: _fibLimit);
    if (losingBefore) return; // 이미 지던 판 — 이 수는 실수가 아니다
    final best = _engine.bestMove(_rows, _config.mode,
        maxTake: _config.maxTake, fibLimit: _fibLimit);
    final (after, fib) = _applied(_rows, m);
    final bool aiLoses = _engine.toMoveLoses(after, _config.mode,
        maxTake: _config.maxTake, fibLimit: fib);
    if (!aiLoses) {
      _mistakeRows = List<int>.from(_rows);
      _mistakeMove = m;
      _mistakeBest = best;
      _mistakeFib = _fibLimit;
    }
  }

  String _describeMove(NimMove m, bool multi) {
    if (m.isPepero) return s.get('mvSplit', ['${m.splitA}', '${m.splitB}']);
    if (m.isWythoff) {
      if (m.takeA > 0 && m.takeB > 0) return s.get('mvBoth', ['${m.takeA}']);
      return s.get('mvTakeRow',
          ['${m.takeA > 0 ? m.takeA : m.takeB}', m.takeA > 0 ? '1' : '2']);
    }
    if (multi) return s.get('mvTakeRow', ['${m.count}', '${m.rowIndex + 1}']);
    return s.get('mvTake', ['${m.count}']);
  }

  /// "왜 졌지?" — 실수한 판으로 되돌려 빨강(실수)·하늘색(정답)을 같이 보여준다.
  void _startReplay() {
    final m = _mistakeMove;
    final best = _mistakeBest;
    final rows = _mistakeRows;
    if (m == null || best == null || rows == null) return;
    _haptic();
    setState(() {
      _replaying = true;
      _rows = List<int>.from(rows);
      _fibLimit = _mistakeFib;
      _selectedCount = 0;
      _selectedPile = -1;
      _kSelCount = 0;
      _wSelA = 0;
      _wSelB = 0;
      _setHintFields(best);
      _setWrongFields(m);
      _midnightFace = MidnightFace.confident;
      final bool multi = rows.length > 1;
      _say('replayHint', [_describeMove(m, multi), _describeMove(best, multi)]);
    });
  }

  void _sayGreeting() {
    if (widget.isDaily) {
      _say('dailyGreet');
      return;
    }
    _say(s.pickKey('greet', _rng));
  }

  String _getModeTitle() {
    switch (_config.mode) {
      case GameMode.singleRow:
        return s.get('modeSingleRow');
      case GameMode.doubleRow:
        return s.get('modeDoubleRow');
      case GameMode.pepero:
        return s.get('modePepero');
      case GameMode.tripleRow:
        return s.get('modeTripleRow');
      case GameMode.quadRow:
        return s.get('modeQuadRow');
      case GameMode.kayles:
        return s.get('modeKayles');
      case GameMode.wythoff:
        return s.get('modeWythoff');
      case GameMode.fibonacci:
        return s.get('modeFibonacci');
    }
  }

  /// 현재 판에서 "다음에 둘 사람 = 플레이어" 가 완벽한 예린에게 반드시 지는 상태인가.
  /// 전 모드 노멀 플레이 — 판정은 NimEngine.toMoveLoses 가 한 곳에서 한다.
  bool _calculateMidnightWinsState() => _engine.toMoveLoses(
        _rows,
        _config.mode,
        maxTake: _config.maxTake,
        fibLimit: _fibLimit,
      );

  /// 플레이어 턴 시작 시점에 Midnight의 표정/메시지를 업데이트.
  /// - midnightWins (XOR=0 / Grundy XOR=0): happy, 2턴 이상 연속시 confident
  /// - 그 외: neutral
  void _updateExpressionForPlayerTurn() {
    bool midnightWins = _calculateMidnightWinsState();

    setState(() {
      if (midnightWins) {
        _consecutiveLossTurns++;
        if (_consecutiveLossTurns >= 2) {
          _midnightFace = MidnightFace.confident;
          _say(s.pickKey('winLate', _rng));
        } else {
          _midnightFace = MidnightFace.happy1;
          _say(s.pickKey('winEarly', _rng));
        }
      } else {
        _consecutiveLossTurns = 0;
        _midnightFace = MidnightFace.neutral;
        _say('yourTurnNow');
      }
    });
  }

  bool _checkGameOver() {
    int total = _rows.isEmpty ? 0 : _rows.reduce((a, b) => a + b);
    // _checkGameOver 는 턴 토글 "후" 호출됨 → _currentTurn = 다음에 둘 사람.
    if (_config.mode == GameMode.pepero) {
      // 다음 차례가 못 쪼개면 그 사람이 패배.
      if (!_rows.any((p) => p >= 3)) {
        _endGame(_currentTurn != TurnOwner.player);
        return true;
      }
    } else if (total == 0) {
      // 노멀 플레이: 마지막을 가져간 쪽(= 방금 둔 쪽)이 승리.
      _endGame(_currentTurn != TurnOwner.player);
      return true;
    }
    return false;
  }

  void _endGame(bool playerWins) {
    _haptic(playerWins); // 승리 = 강하게, 패배 = 가볍게 (M3: 패배는 조용히)
    setState(() {
      _phase = GamePhase.gameOver;
      _playerWon = playerWins;
      if (playerWins) {
        _midnightFace = MidnightFace.worried2;
        _say(s.pickKey('lost', _rng));
        _consecutiveDefeats = 0;
      } else {
        _midnightFace = MidnightFace.happy2;
        _consecutiveDefeats++;
        _say(s.pickKey('won', _rng));
      }
    });

    if (playerWins) {
      final int before = widget.stageManager.worldClears(widget.stageNumber);
      if (widget.isDaily) {
        widget.stageManager.recordDailyWin();
      } else {
        widget.stageManager.clearStage(widget.stageNumber);
      }
      // 전면 광고: 3 스테이지 클리어마다 1회 (AdService 내부 카운터)
      AdService.instance.maybeShowInterstitialOnStageClear();
      Future.delayed(const Duration(milliseconds: 1100), () {
        if (!mounted) return;
        // 클리어 한마디 → (이 수업 5/10/15/20판째면 이야기) → 다음 스테이지 팝업
        final lines = <DialogueLine>[
          widget.isDaily
              ? DialogueLine(MidnightFace.happy2,
                  s.get('daily_win_${(widget.stageManager.dailyStreak % 3) + 1}'))
              : widget.stageNumber == 1
                  ? DialogueLine(MidnightFace.happy1, s.get('g1_win')) // 첫 승리: 왜 이겼는지
                  : Dialogue.afterClear(widget.stageNumber, s, _rng)
        ];
        // clearStage 뒤의 진행도. 이미 깬 판을 다시 깬 거면 수가 안 늘어 이야기도 없다.
        final int after = widget.stageManager.worldClears(widget.stageNumber);
        setState(() {
          _dialogue = lines;
          _dialogueTitle = null;
          _dialogueScene = null;
          _pendingScene = (widget.isDaily || after == before) ? null : Dialogue.sceneFor(after);
        });
      });
    }
  }

  int? _pendingScene;

  /// 한마디가 끝났을 때: 5·10·15·20판째면 미연시 화면으로 → 돌아오면 팝업.
  void _onDialogueDone() {
    final int? k = _pendingScene;
    setState(() {
      _dialogue = null;
      _dialogueTitle = null;
      _dialogueScene = null;
      _pendingScene = null;
    });
    if (k != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SceneScreen(
            world: Dialogue.worldOf(widget.stageNumber),
            scene: k,
            localeProvider: widget.localeProvider,
          ),
        ),
      ).then((_) {
        if (mounted) _showNextStageDialog();
      });
      return;
    }
    _showNextStageDialog();
  }

  void _showNextStageDialog() {
    // 7월드 140 + 버전2 보드 게임 5월드 100 = 240 (141부터는 보드 게임 화면으로 이어짐)
    bool hasNext = !widget.isDaily && widget.stageNumber < kTotalStages;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black38, // 뒤의 예린 얼굴이 비치게 살짝만
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, a1, a2, child) {
        return Transform.scale(
          scale: Curves.elasticOut.transform(a1.value),
          child: Opacity(opacity: a1.value, child: child),
        );
      },
      pageBuilder: (context, _, __) {
        // 팝업은 아래쪽(책상 자리)에 — 위쪽 예린 얼굴을 가리지 않는다
        return Align(
          alignment: const Alignment(0, 0.62),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _Pal.paper,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _Pal.frame, width: 3),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black54, blurRadius: 24, spreadRadius: 2),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 합격 도장 느낌
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: _Pal.win, width: 3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    s.get('stageClear'),
                    style: const TextStyle(
                      fontFamily: _mono,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: _Pal.win,
                      letterSpacing: 2,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.isDaily
                      ? s.get('dailyClear', ['${widget.stageManager.dailyStreak}'])
                      : s.get('stageClearDesc', ['${widget.stageNumber}']),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: _mono,
                    fontSize: 13,
                    color: _Pal.inkSoft,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
                // (2026-09-15 대표님) 클리어 팝업엔 예린 그림 없음 — 뒤의 큰 예린이 보이게.
                const SizedBox(height: 8),
                _storyLine(),
                const SizedBox(height: 20),
                if (hasNext) ...[
                  SizedBox(
                    width: double.infinity,
                    child: _StampButton(
                      label: s.get('nextStage'),
                      color: _Pal.gold,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            // 140 → 141 부터는 보드 게임 화면(버전2)
                            builder: (_) => stageScreenFor(
                              stageManager: widget.stageManager,
                              stageNumber: widget.stageNumber + 1,
                              localeProvider: widget.localeProvider,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: _Pal.inkSoft,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(
                      s.get('backToStageSelect'),
                      style: const TextStyle(fontFamily: _mono, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 팝업 안 이야기 줄 — "다음 이야기까지 4판" (이 수업 기준)
  Widget _storyLine() {
    if (widget.isDaily) return const SizedBox.shrink();
    final int left = Dialogue.untilNext(widget.stageManager.worldClears(widget.stageNumber));
    return Text(
      left > 0 ? s.get('storyNext', ['$left']) : s.get('storyWorldDone'),
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: _mono,
        fontSize: 12,
        color: _Pal.inkSoft,
        fontWeight: FontWeight.w700,
        decoration: TextDecoration.none,
      ),
    );
  }

  /// Take 버튼: 선택된 돌이 아래로 슈르륵 빠지는 애니메이션 후 실제 수를 둔다.
  void _confirmTake() {
    if (_phase != GamePhase.playing ||
        _currentTurn != TurnOwner.player ||
        _isAiAnimating ||
        _leaving ||
        _selectedCount < 1) return;
    _haptic(true); // 확정 순간 진동
    SfxService.instance.playTake(); // 내가 가져갈 때도 슉!
    setState(() => _leaving = true);
    Future.delayed(const Duration(milliseconds: 360), () {
      if (!mounted) return;
      setState(() => _leaving = false);
      _playerMove();
    });
  }

  void _playerMove() {
    _clearHint(); // 수를 두면 힌트 하이라이트 해제
    if (_phase != GamePhase.playing ||
        _currentTurn != TurnOwner.player ||
        _isAiAnimating) return;

    final int tookCount = _selectedCount;
    _recordPlayerMove(NimMove(rowIndex: _selectedRow, count: tookCount));

    setState(() {
      if (_config.mode == GameMode.pepero) {
        int pile = _rows[_selectedPile];
        int a = _splitA;
        int b = pile - a;
        _rows.removeAt(_selectedPile);
        _rows.add(a);
        _rows.add(b);
        _rows.sort((x, y) => y.compareTo(x));
      } else if (_config.mode == GameMode.singleRow ||
          _config.mode == GameMode.fibonacci) {
        _rows[0] -= _selectedCount;
        // 피보나치: 다음(한밤이) 턴 한도 = 내가 방금 가져간 수의 2배
        if (_config.mode == GameMode.fibonacci) {
          _fibLimit = tookCount * 2;
        }
      } else {
        _rows[_selectedRow] -= _selectedCount;
      }
      _turnCount++;
      _currentTurn = TurnOwner.midnight;
      _selectedCount = 0;
    });

    if (!_checkGameOver()) {
      // AI턴 진입 → 🤔 고민 표정 (대표님 원화 2)
      setState(() {
        _midnightFace = MidnightFace.thinking;
      });
      Future.delayed(const Duration(milliseconds: 1000), _midnightPlay);
    }
  }

  Future<void> _midnightPlay() async {
    if (_phase != GamePhase.playing) return;

    NimMove move;
    switch (_config.mode) {
      case GameMode.singleRow:
        move = _engine.singleRowAI(_rows[0], _config.maxTake);
        break;
      case GameMode.doubleRow:
      case GameMode.tripleRow:
      case GameMode.quadRow:
        move = _engine.multiRowAI(_rows);
        break;
      case GameMode.pepero:
        move = _engine.peperoAI(_rows);
        break;
      case GameMode.kayles:
        move = _engine.kaylesAI(_rows);
        break;
      case GameMode.wythoff:
        move = _engine.wythoffAI(_rows);
        break;
      case GameMode.fibonacci:
        move = _engine.fibonacciAI(_rows[0], _fibLimit);
        break;
    }

    // 가이드 판: 정해진 답수가 있으면 그대로. 없으면 초반 두 판은 "봐주기" —
    // 종반(남은 간식 ≤ 6 / 쪼갤 묶음 ≤ 2)에는 실수하지 않는다 (대표님: 끝나기 n수 전엔 실수 X).
    final scripted = _guideStep?.reply;
    if (scripted != null) {
      move = scripted;
    } else {
      final double br = TutorialManager.nimBlunderRate(widget.stageNumber);
      final bool endgame = _config.mode == GameMode.pepero
          ? _rows.where((p) => p >= 3).length <= 2
          : _rows.fold<int>(0, (a, b) => a + b) <= 6;
      final bool yerinWinning = !_engine.toMoveLoses(_rows, _config.mode,
          maxTake: _config.maxTake, fibLimit: _fibLimit);
      if (br > 0 && !endgame && yerinWinning && _rng.nextDouble() < br) {
        move = _engine.randomMove(_rows, _config.mode,
            maxTake: _config.maxTake, fibLimit: _fibLimit);
      }
    }

    _isAiAnimating = true;

    // Phase 1: "예린이 차례..." — 🤔 고민 표정 + 생각중 메시지 (0.5초 딜레이)
    setState(() {
      _midnightFace = MidnightFace.thinking;
      _say('midnightThinking');
    });
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted || _phase != GamePhase.playing) return;

    if (move.isPepero) {
      // 빼빼로: 한번에 분할 (순차 애니메이션 대상 아님). AI턴 중 표정은 neutral 유지.
      setState(() {
        _midnightFace = MidnightFace.neutral;
        _say('midnightSplit', ['${move.splitA}', '${move.splitB}']);
        _rows.removeAt(move.rowIndex);
        _rows.add(move.splitA);
        _rows.add(move.splitB);
        _rows.sort((x, y) => y.compareTo(x));
      });
    } else if (move.isKayles) {
      // 🧪 카일즈: 슉! x count 후 줄 분할 적용
      for (int i = 0; i < move.count; i++) {
        if (!mounted || _phase != GamePhase.playing) return;
        _spawnFlight();
        setState(() {
          _midnightFace = MidnightFace.neutral;
          _say('midnightTakeN', ['${i + 1}']);
        });
        await Future.delayed(const Duration(milliseconds: 400));
      }
      if (!mounted || _phase != GamePhase.playing) return;
      setState(() {
        // (대표님 7/24) 예린의 수도 제자리 분열 — 위아래로 나뉘어 추적 쉬움
        _rows.removeAt(move.rowIndex);
        if (move.kaylesRight > 0) _rows.insert(move.rowIndex, move.kaylesRight);
        if (move.kaylesLeft > 0) _rows.insert(move.rowIndex, move.kaylesLeft);
        _say('midnightTookTotal', ['${move.count}']);
      });
    } else if (move.isWythoff) {
      // 🧪 위토프: 각 무더기에서 하나씩 슉!
      final int steps = move.takeA > move.takeB ? move.takeA : move.takeB;
      for (int i = 0; i < steps; i++) {
        if (!mounted || _phase != GamePhase.playing) return;
        _spawnFlight();
        setState(() {
          if (i < move.takeA) _rows[0] -= 1;
          if (i < move.takeB) _rows[1] -= 1;
          _midnightFace = MidnightFace.neutral;
          _say('midnightTakeN', ['${i + 1}']);
        });
        await Future.delayed(const Duration(milliseconds: 400));
      }
      if (!mounted || _phase != GamePhase.playing) return;
      setState(() {
        if (move.takeA > 0 && move.takeB > 0) {
          _say('midnightTookBoth', ['${move.takeA}']);
        } else {
          _say('midnightTookTotal',
              ['${move.takeA > 0 ? move.takeA : move.takeB}']);
        }
      });
    } else {
      // Phase 2: 돌 1개씩 순차 제거 애니메이션
      // AI턴 중에는 개수와 무관하게 표정은 항상 neutral 고정
      for (int i = 0; i < move.count; i++) {
        if (!mounted || _phase != GamePhase.playing) return;
        _spawnFlight(); // 슉! — 돌이 한밤이 쪽으로 날아가는 연출 + 효과음
        setState(() {
          _rows[move.rowIndex] -= 1;
          _midnightFace = MidnightFace.neutral;
          if (_config.mode == GameMode.singleRow) {
            _say('midnightTakeN', ['${i + 1}']);
          } else {
            _say('midnightTakeFromRow', ['${i + 1}', '${move.rowIndex + 1}']);
          }
        });
        // 돌 1개당 0.4초 간격
        await Future.delayed(const Duration(milliseconds: 400));
      }
      if (!mounted || _phase != GamePhase.playing) return;

      // Phase 3: 총 가져간 수 카운터 표시
      setState(() {
        if (_config.mode == GameMode.singleRow) {
          _say('midnightTookTotal', ['${move.count}']);
        } else {
          _say('midnightTookFromRowTotal',
              ['${move.count}', '${move.rowIndex + 1}']);
        }
      });
    }

    // Phase 4: 종료 pause (0.3초) 후 턴 전환
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted || _phase != GamePhase.playing) return;

    setState(() {
      _turnCount++;
      _currentTurn = TurnOwner.player;
      _isAiAnimating = false;
      _selectedCount = 0; // 내 턴 시작: 미리선택 없음
      _kSelRow = -1;
      _kSelStart = -1;
      _kSelCount = 0;
      _wSelA = 0;
      _wSelB = 0;
      _selectedPile = -1; // 막대과자도 선택 초기화 (묶음 정렬로 인덱스가 바뀌므로)
      _splitA = 1;
      // 피보나치: 다음(내) 턴 한도 = 한밤이가 방금 가져간 수의 2배
      if (_config.mode == GameMode.fibonacci) {
        _fibLimit = move.count * 2;
      }
      // 가이드: act 스텝은 예린 답수까지가 한 스텝. follow 는 판이 끝날 때까지 유지.
      if (_guideStep?.kind == GuideKind.act) _guideIndex++;
      _applyGuideHighlight();
    });
    _refreshLosing();

    if (!_checkGameOver()) {
      // 플레이어 턴 시작 시점 → NIM XOR 기반 표정 결정
      _updateExpressionForPlayerTurn();
    }
  }

  /// 힌트 버튼 → "힌트 보기!" 확인 다이얼로그 → 광고 시청 후 힌트 공개.
  /// 광고만 보면 무제한 — 남은 개수 제한 없음. (광고 미준비/웹에서는 폴백으로 바로 공개)
  void _showHint() {
    if (_currentTurn != TurnOwner.player) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _Pal.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text(
          s.get('hintDialogTitle'),
          style: const TextStyle(
            fontFamily: _mono,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: _Pal.ink,
          ),
        ),
        content: Text(
          s.get('hintDialogBody'),
          style: const TextStyle(
            fontFamily: _mono,
            fontSize: 13.5,
            color: _Pal.inkSoft,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              s.get('cancel'),
              style: const TextStyle(fontFamily: _mono, color: _Pal.inkSoft),
            ),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _Pal.gold,
              foregroundColor: _Pal.ink,
            ),
            icon: const Icon(Icons.ondemand_video_rounded, size: 18),
            label: Text(
              s.get('hintWatchAd'),
              style: const TextStyle(
                  fontFamily: _mono, fontWeight: FontWeight.w800),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              // 광고 시청 완료 → 힌트 공개. 광고 미준비 시 폴백으로 바로 공개.
              final bool shown =
                  AdService.instance.showRewardedAd(onReward: _revealHint);
              if (!shown) _revealHint();
            },
          ),
        ],
      ),
    );
  }

  void _revealHint() {
    if (!mounted || _currentTurn != TurnOwner.player) {
      return;
    }

    // (id=1201) 4번: 현재 턴 플레이어가 이미 진 상태(nimSum=0/Grundy=0)인지 먼저 판정.
    final bool canWin = !_calculateMidnightWinsState();

    String hintText;
    if (!canWin) {
      hintText = s.get('hintLosingRetry');
    } else {
      NimMove hint;
      switch (_config.mode) {
        case GameMode.singleRow:
          hint = _engine.singleRowAI(_rows[0], _config.maxTake);
          break;
        case GameMode.doubleRow:
        case GameMode.tripleRow:
        case GameMode.quadRow:
          hint = _engine.multiRowAI(_rows);
          break;
        case GameMode.pepero:
          hint = _engine.peperoAI(_rows);
          break;
        case GameMode.kayles:
          hint = _engine.kaylesAI(_rows);
          break;
        case GameMode.wythoff:
          hint = _engine.wythoffAI(_rows);
          break;
        case GameMode.fibonacci:
          hint = _engine.fibonacciAI(_rows[0], _fibLimit);
          break;
      }

      // 판 위에 하늘색으로 추천 수 표시 (텍스트보다 이게 본체)
      _showHintOnBoard(hint);

      if (hint.isPepero) {
        hintText = s.get('hintPepero', ['${hint.splitA}', '${hint.splitB}']);
      } else if (hint.isWythoff) {
        hintText = s.get('hintMultiRow', [
          '${hint.takeA > 0 ? hint.takeA : hint.takeB}',
          hint.takeA > 0 ? '1' : '2'
        ]);
      } else if (_config.mode == GameMode.singleRow ||
          _config.mode == GameMode.fibonacci) {
        hintText = s.get('hintSingleRow', ['${hint.count}']);
      } else if (_config.mode == GameMode.kayles) {
        hintText = s.get('hintSingleRow', ['${hint.count}']);
      } else {
        hintText =
            s.get('hintMultiRow', ['${hint.count}', '${hint.rowIndex + 1}']);
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(hintText,
            style: const TextStyle(fontFamily: _mono, fontSize: 14)),
        backgroundColor: canWin ? _Pal.hint : _Pal.alarm,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        duration: Duration(seconds: canWin ? 3 : 5),
      ),
    );
  }

  // ── 힌트 하이라이트: 추천 수를 실제 판 위에 하늘색으로 표시 ──
  int _hintRow = -1; // 추천 줄 (-1 = 없음)
  int _hintCount = 0; // 추천 개수 (줄 끝에서부터)
  int _hintStart = -1; // 카일즈: 시작 인덱스
  int _hintSplitA = 0; // 막대과자: 쪼갤 위치
  Timer? _hintTimer;

  // ── 지고 있을 때 힌트 전구를 반짝이게 (광고 유도) ──
  bool _losing = false;

  /// 턴이 바뀔 때만 호출 (매 build 계산은 낭비)
  void _refreshLosing() {
    final bool lose = _phase == GamePhase.playing &&
        _currentTurn == TurnOwner.player &&
        _calculateMidnightWinsState();
    if (lose != _losing && mounted) setState(() => _losing = lose);
  }

  bool _isHintStone(int rowIdx, int i, int len) {
    if (_hintRow != rowIdx || _hintCount <= 0) return false;
    if (_hintStart >= 0) {
      return i >= _hintStart && i < _hintStart + _hintCount; // 카일즈
    }
    return i >= len - _hintCount; // 끝에서부터
  }

  void _clearHint() {
    _hintTimer?.cancel();
    if (_hintRow != -1 || _hintSplitA != 0) {
      setState(() {
        _hintRow = -1;
        _hintCount = 0;
        _hintStart = -1;
        _hintSplitA = 0;
      });
    }
  }

  void _showHintOnBoard(NimMove hint) {
    _hintTimer?.cancel();
    setState(() => _setHintFields(hint));
    // 자동 해제 없음 — 광고를 보고 얻은 힌트라 수를 둘 때까지 계속 보여준다.
  }

  void _setHintFields(NimMove hint) {
    if (hint.isPepero) {
      _hintRow = hint.rowIndex;
      _hintSplitA = hint.splitA;
      _hintCount = 0;
      _hintStart = -1;
    } else if (hint.isWythoff) {
      _hintRow = hint.takeA > 0 ? 0 : 1;
      _hintCount = hint.takeA > 0 ? hint.takeA : hint.takeB;
      _hintStart = -1;
      _hintSplitA = 0;
    } else if (hint.isKayles) {
      _hintRow = hint.rowIndex;
      _hintCount = hint.count;
      _hintStart = hint.kaylesLeft;
      _hintSplitA = 0;
    } else {
      _hintRow = hint.rowIndex;
      _hintCount = hint.count;
      _hintStart = -1;
      _hintSplitA = 0;
    }
  }

  // ── 되감기: 실수한 수를 빨갛게 ──
  int _wrongRow = -1;
  int _wrongCount = 0;
  int _wrongStart = -1;

  void _setWrongFields(NimMove m) {
    if (m.isPepero) {
      _wrongRow = -1; // 막대과자는 문장으로만
      _wrongCount = 0;
      _wrongStart = -1;
    } else if (m.isWythoff) {
      // 양쪽 동시면 첫 줄만 표시 (문장이 나머지를 설명)
      _wrongRow = m.takeA > 0 ? 0 : 1;
      _wrongCount = m.takeA > 0 ? m.takeA : m.takeB;
      _wrongStart = -1;
    } else if (m.isKayles) {
      _wrongRow = m.rowIndex;
      _wrongCount = m.count;
      _wrongStart = m.kaylesLeft;
    } else {
      _wrongRow = m.rowIndex;
      _wrongCount = m.count;
      _wrongStart = -1;
    }
  }

  bool _isWrongStone(int rowIdx, int i, int len) {
    if (_wrongRow != rowIdx || _wrongCount <= 0) return false;
    if (_wrongStart >= 0) return i >= _wrongStart && i < _wrongStart + _wrongCount;
    return i >= len - _wrongCount;
  }

  // ─────────────────────────────────────────────────────────────
  // BUILD — Papers-Please풍 심문 책상(탑뷰)
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_introVisible) return _inlineIntro();
    return Scaffold(
      backgroundColor: _Pal.deskBottom,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_Pal.deskTop, _Pal.deskBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _topBar(),
              Expanded(
                child: Stack(
                  children: [
                    _buildGameBoard(),
                    if (_guideReading) _buildGuideOverlay(),
                    if (_dialogue != null)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: DialogueBox(
                          lines: _dialogue!,
                          yerinName: s.get('nameMidnight'),
                          meName: s.get('nameYou'),
                          title: _dialogueTitle,
                          onLine: (l) => setState(() => _midnightFace = l.face),
                          onDone: _onDialogueDone,
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
  }

  /// 상단 바 — (2026-09-15 정보 다이어트) 뒤로 / 스테이지 번호 / 힌트 전구 / 메뉴.
  /// 월드 색 네모·모드 이름·톱니는 삭제. 규칙·설정·나가기는 메뉴 하나로.
  Widget _topBar() {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: _Pal.frame,
        border: Border(bottom: BorderSide(color: _Pal.frameHi, width: 2)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded,
                color: _Pal.cream, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            widget.isDaily
                ? s.get('dailyTitle')
                : s.get('stageLabel', ['${widget.stageNumber}']),
            style: const TextStyle(
              fontFamily: _mono,
              color: _Pal.cream,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          // 힌트 — 광고 보면 무제한. (지는 포지션 반짝임은 테스터 기간엔 끔)
          if (_phase == GamePhase.playing && _currentTurn == TurnOwner.player)
            _PulsingBulb(
              urgent: false,
              onTap: _showHint,
              tooltip: s.get('hintDialogTitle'),
            ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.only(right: 10),
            icon: const Icon(Icons.menu_rounded, size: 22, color: _Pal.cream),
            tooltip: s.get('menuTitle'),
            onPressed: _showMenu,
          ),
        ],
      ),
    );
  }

  /// 게임 중 메뉴 — 규칙 / 설정 / 스테이지 선택으로. (탑바 아이콘 3개 → 1개)
  void _showMenu() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _Pal.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: _Pal.frame, width: 3),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StampButton(
                label: s.get('rulesTitle'),
                icon: Icons.help_outline_rounded,
                color: _Pal.frameHi,
                onTap: () {
                  Navigator.pop(ctx);
                  _showModeRules();
                },
              ),
              const SizedBox(height: 10),
              _StampButton(
                label: s.get('settings'),
                icon: Icons.settings_rounded,
                color: _Pal.frameHi,
                onTap: () async {
                  Navigator.pop(ctx);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SettingsScreen(
                        localeProvider: widget.localeProvider,
                        onChanged: () {
                          if (mounted) setState(() {});
                        },
                        stageManager: widget.stageManager,
                      ),
                    ),
                  );
                  if (mounted) setState(() {});
                },
              ),
              const SizedBox(height: 10),
              _StampButton(
                label: s.get('backToStageSelect'),
                icon: Icons.grid_view_rounded,
                color: _Pal.frame,
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  s.get('menuResume'),
                  style: const TextStyle(
                      fontFamily: _mono, color: _Pal.inkSoft, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 현재 모드의 규칙 다이얼로그 — 탑바 ? 버튼.
  void _showModeRules() {
    String ruleKey;
    // {0} = 이 월드의 간식(+조사), {1} = 최대 개수 (한 줄 모드만 사용)
    List<String> ruleArgs = [s.snackObj(_snackKey)];
    switch (_config.mode) {
      case GameMode.singleRow:
        ruleKey = 'ruleSingleRow';
        ruleArgs = [s.snackObj(_snackKey), '${_config.maxTake}'];
        break;
      case GameMode.doubleRow:
        ruleKey = 'ruleDoubleRow';
        break;
      case GameMode.tripleRow:
        ruleKey = 'ruleTripleRow';
        break;
      case GameMode.quadRow:
        ruleKey = 'ruleQuadRow';
        break;
      case GameMode.pepero:
        ruleKey = 'rulePepero';
        break;
      case GameMode.kayles:
        ruleKey = 'ruleKayles';
        break;
      case GameMode.wythoff:
        ruleKey = 'ruleWythoff';
        break;
      case GameMode.fibonacci:
        ruleKey = 'ruleFibonacci';
        break;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _Pal.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Row(
          children: [
            const Icon(Icons.help_outline_rounded,
                size: 22, color: _Pal.inkSoft),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _getModeTitle(),
                style: const TextStyle(
                  fontFamily: _mono,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _Pal.ink,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          s.get(ruleKey, ruleArgs),
          style: const TextStyle(
            fontFamily: _mono,
            fontSize: 14.5,
            height: 1.6,
            color: _Pal.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _Pal.gold,
              foregroundColor: _Pal.ink,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.get('ok'),
                style: const TextStyle(
                    fontFamily: _mono, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  // ── (v2) 예린 찌르기 상호작용 ──
  bool _poked = false;
  String _pokeKey = 'pokeReact1';
  MidnightFace _pokeFace = MidnightFace.worried2;
  Timer? _pokeTimer;

  @override
  void dispose() {
    _pokeTimer?.cancel();
    _hintTimer?.cancel();
    super.dispose();
  }

  /// 예린을 탭하면 잠깐 눈을 찌푸리며 반응 — 1.6초 뒤 원래 표정/대사로.
  void _pokeYerin() {
    _haptic();
    final rnd = math.Random();
    const reactions = [
      ('pokeReact1', MidnightFace.worried2),
      ('pokeReact2', MidnightFace.worried1),
      ('pokeReact3', MidnightFace.confident),
    ];
    final pick = reactions[rnd.nextInt(reactions.length)];
    setState(() {
      _poked = true;
      _pokeKey = pick.$1;
      _pokeFace = pick.$2;
    });
    _pokeTimer?.cancel();
    _pokeTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _poked = false);
    });
  }

  /// 중앙 배치 고양이 — 배경 투명 PNG, 정적(붕붕 애니 제거).
  /// 발밑에 옅은 타원 그림자만 깔아 떠 보이지 않게 안착.
  Widget _catFigure({double size = 110}) {
    return SizedBox(
      width: size * 1.25,
      height: size + 10,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 스포트라이트: 어두운 책상에서 검은 도트 고양이가 묻히지 않게 (심문 조명 톤)
          Center(
            child: Container(
              width: size * 1.2,
              height: size * 1.2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFEADFC6).withOpacity(0.30),
                    const Color(0xFFC9A24B).withOpacity(0.12),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 0.78],
                ),
              ),
            ),
          ),
          // 바닥 그림자 (안정감)
          Positioned(
            bottom: 2,
            child: Container(
              width: size * 0.5,
              height: 9,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          // 예린 (정적, 투명 PNG) — 찌르면 잠깐 표정이 바뀐다. 튜토리얼 중엔 밝은 표정.
          MidnightCharacter(
            face: _poked
                ? _pokeFace
                : (_guideReading ? MidnightFace.happy1 : _midnightFace),
            size: size,
            animate: false,
          ),
        ],
      ),
    );
  }

  /// (v2) 예린 대사 말풍선 — 머리 위에 떠 있고 꼬리가 아래(예린)를 향한다.
  Widget _tauntBubble(String message) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Container(
            key: ValueKey(message),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: _Pal.paper,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _Pal.frame, width: 2),
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: _mono,
                fontSize: 14,
                height: 1.35,
                color: _Pal.ink,
              ),
            ),
          ),
        ),
        CustomPaint(size: const Size(16, 9), painter: _BubbleTailDown()),
      ],
    );
  }

  /// 읽기 스텝 오버레이 — 예린 얼굴·말풍선은 그대로, 책상 아래만 어둡게 + 다음 버튼.
  /// (화면에 예린은 항상 한 명 — 문장은 큰 예린의 말풍선에 뜬다)
  Widget _buildGuideOverlay() {
    final bool isLast = _guideIndex == _guide.length - 1;
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _advanceGuide,
        child: Column(
          children: [
            const SizedBox(height: _kDeskTop + 4),
            Expanded(
              child: Container(
                color: Colors.black.withOpacity(0.66),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StampButton(
                      label: isLast ? s.get('tutStart') : s.get('tutNext'),
                      color: _Pal.gold,
                      onTap: _advanceGuide,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_guide.length, (i) {
                        final active = i == _guideIndex;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: active ? 10 : 6,
                          height: active ? 10 : 6,
                          decoration: BoxDecoration(
                            color: active
                                ? _Pal.gold
                                : _Pal.cream.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// (2026-09-15 정보 다이어트) 규칙 칩 **하나**: "가져가는 법 · 승리 조건".
  /// 화면에 상시 보이는 유일한 규칙 문장이다.
  Widget _infoChips({required bool dark}) {
    String text;
    final String win = s.get('lastStoneWinChip', [s.snack(_snackKey)]);
    switch (_config.mode) {
      case GameMode.singleRow:
        text = '${s.get('takeRange', ['${_config.maxTake}'])} · $win';
        break;
      case GameMode.pepero:
        text = s.get('chipPepero');
        break;
      case GameMode.kayles:
        text = '${s.get('kaylesChip')} · $win';
        break;
      case GameMode.wythoff:
        text = '${s.get('wythoffChip')} · $win';
        break;
      case GameMode.fibonacci:
        // 턴마다 변하는 한도 — 칩이 실시간으로 갱신됨
        text = '${s.get('takeRange', ['$_fibLimit'])} · $win';
        break;
      default:
        text = '${s.get('takeAny')} · $win';
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: dark ? _Pal.deskBottom : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: dark ? _Pal.frameHi : _Pal.frame, width: 1.5),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: _mono,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: dark ? _Pal.cream : _Pal.ink,
        ),
      ),
    );
  }

  // ── 플레이 / 결과 = 책상 위 ─────────────────────────────────
  /// 책상 씬 (대표님 스케치): 한밤이가 테이블 맞은편에 앉아 **상반신만** 보이고,
  /// 하반신은 원근 책상의 먼 가장자리에 가려진다. overlay = 책상 위쪽 중앙 표시물.
  Widget _deskScene({required Widget overlay}) {
    return Expanded(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 0) 월드 배경 — assets/backgrounds/world{id}.png (미드저니)가 있으면 사용,
          //    없으면 코드 교실(칠판+창문+낙서)로 폴백. 캐릭터 PNG는 이 위에 얹힌다.
          Positioned.fill(
            child: Image.asset(
              'assets/backgrounds/world${worldForStage(widget.stageNumber).id}.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) =>
                  const CustomPaint(painter: _ClassroomPainter()),
            ),
          ),
          // 1) 예린 — (2026-09-15 대표님) 얼굴이 크게 보이는 게 최우선. 아래쪽은 책상에
          //    잘려도 된다. 원화(1080x1920)의 머리는 위에서 ~6%~36% 구간이라, 이미지
          //    높이 _kYerinH 로 두면 머리가 말풍선 아래(~128)부터 책상 위(~330)까지 찬다.
          Positioned(
            top: _kYerinTop,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _pokeYerin,
                child: _catFigure(size: _kYerinH),
              ),
            ),
          ),
          // 말풍선 — 예린 머리 위 중앙, 꼬리가 아래로. 튜토리얼 중엔 튜토리얼 문장이
          // 여기 뜬다 (예린이 직접 설명하는 연출 — 화면에 예린은 항상 한 명).
          Positioned(
            top: 46,
            left: 24,
            right: 24,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 330),
                child: _dialogue != null
                    ? const SizedBox.shrink()
                    : _tauntBubble(_poked
                        ? s.get(_pokeKey)
                        : (_guideSpeaking ? _guideText : _midnightMessage)),
              ),
            ),
          ),
          // 2) 턴 배너 — 맨 위 풀폭 (예린 위 레이어라 항상 보임)
          Positioned(top: 4, left: 10, right: 10, child: overlay),
          // 3) 테이블 — 캐릭터 하반신만 살짝 덮도록 아래쪽에 배치.
          //    (책상이 화면을 반 이상 먹으면 캐릭터가 얼굴만 남아 답답함)
          Positioned(
            top: _kDeskTop,
            bottom: 0,
            left: 28,
            right: 28,
            child: Align(
              alignment: Alignment.topCenter,
              child: FractionallySizedBox(
                heightFactor: 1.0,
                widthFactor: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    // 교실 책상 — 밝은 나무 + 진한 우드 테두리 (원화 스타일)
                    border: Border.all(color: _Pal.deskWoodDark, width: 3),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Positioned.fill(
                          child: CustomPaint(painter: _DeskPainter())),
                      Positioned.fill(child: _buildBoardArea()),
                      // 한밤이가 가져간 돌 — 하나씩 슉! 맞은편 고양이 쪽으로
                      for (final id in _flights)
                        Positioned.fill(
                          key: ValueKey('fly$id'),
                          child: IgnorePointer(child: _FlyingStone(seed: id)),
                        ),
                      // 내 손 — 돌을 집으면 아래에서 쓱 (스케치의 '손')
                      Positioned(
                        right: 30,
                        bottom: -6,
                        child: IgnorePointer(
                          child: AnimatedSlide(
                            offset: (_selectedCount > 0 || _leaving)
                                ? Offset.zero
                                : const Offset(0, 1.3),
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutBack,
                            child: CustomPaint(
                              size: const Size(64, 74),
                              painter: _PlayerHandPainter(),
                            ),
                          ),
                        ),
                      ),
                      // (제안 #8) 승리 시 별 파티클 — 패배는 조용하게
                      if (_phase == GamePhase.gameOver && _playerWon)
                        const Positioned.fill(
                          child: IgnorePointer(child: _WinBurst()),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameBoard() {
    return Column(
      children: [
        // (v2) 1순위: 턴 + 판 요약을 풀폭 배너로
        _deskScene(overlay: _turnStamp()),
        // (v2) 2순위: 규칙 칩 한 줄 (남은 돌은 배너로 승격됨)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: _infoChips(dark: true),
        ),
        // (대표님 7/24) 액션 바는 상대 턴에도 유지 — 책상 크기가 출렁이지 않게.
        // 예린 턴엔 반투명+터치 차단만.
        if (_phase == GamePhase.playing) _buildActionArea(),
        if (_phase == GamePhase.gameOver && !_playerWon)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (!_replaying) ...[
                  Expanded(
                    child: _StampButton(
                      label: s.get('whyLost'),
                      color: _Pal.hint,
                      icon: Icons.replay_rounded,
                      onTap: _mistakeMove != null
                          ? _startReplay
                          : () => setState(() {
                                _replaying = true;
                                _midnightFace = MidnightFace.neutral;
                                _say('replayNone');
                              }),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: _StampButton(
                    label: s.get('retry'),
                    color: _Pal.frameHi,
                    icon: Icons.refresh,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GameScreen(
                            stageManager: widget.stageManager,
                            stageNumber: widget.stageNumber,
                            localeProvider: widget.localeProvider,
                            dailyConfig: widget.dailyConfig,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StampButton(
                    label: s.get('goBack'),
                    color: _Pal.frame,
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// 이 스테이지의 간식 키 — 문구에 "쿠키/사탕/…"을 넣기 위한 것.
  /// 막대과자 월드는 전용 비주얼이라 'stick'.
  String get _snackKey => _config.mode == GameMode.pepero
      ? 'stick'
      : snackForStage(widget.stageNumber).name;

  /// (2026-09-15 정보 다이어트) 턴 배너·판 요약 삭제. 내 턴은 말풍선과 책상 테두리가,
  /// 남은 개수는 줄 옆 숫자가 말한다. 여기엔 **승리/패배 도장만** 결과 순간에 찍힌다.
  Widget _turnStamp() {
    if (_phase != GamePhase.gameOver || _replaying || _dialogue != null) {
      return const SizedBox.shrink();
    }
    final Color c = _playerWon ? _Pal.win : _Pal.alarm;
    final stamp = Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: c, width: 2.5),
          borderRadius: BorderRadius.circular(6),
          color: _Pal.deskBottom.withOpacity(0.88),
        ),
        child: Text(
          (_playerWon ? s.get('victory') : s.get('defeat')).toUpperCase(),
          style: TextStyle(
            fontFamily: _mono,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
            color: c,
          ),
        ),
      ),
    );
    if (_playerWon) {
      // 승리 도장은 "쾅" 찍히며 등장 — 패배는 조용하게
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
        builder: (_, v, child) => Transform.scale(
          scale: 2.2 - 1.2 * v.clamp(0.0, 1.0),
          child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
        ),
        child: stamp,
      );
    }
    return stamp;
  }

  Widget _buildBoardArea() {
    if (_config.mode == GameMode.pepero) {
      return _buildPeperoBoard();
    }
    if (_config.mode == GameMode.kayles) {
      return _buildKaylesBoard();
    }
    if (_config.mode == GameMode.wythoff) {
      return _buildWythoffBoard();
    }
    return _buildStonesBoard();
  }

  /// 돌을 탭해 가져갈 만큼 선택 (쥐었다 내려놓기).
  /// - 선택 안 된 돌을 탭: 그 돌 ~ 끝까지 집어 내려옴 (count = len - i)
  /// - 현재 "경계 돌"(가장 왼쪽으로 집힌 돌)을 다시 탭: 그 한 개를 내려놓음 (count - 1)
  ///   → 1개일 때 2개 만드는 돌과 2개일 때 1개 만드는 돌이 동일.
  void _selectStone(int rowIdx, int tappedIndex) {
    if (_phase != GamePhase.playing ||
        _currentTurn != TurnOwner.player ||
        _isAiAnimating ||
        _leaving) return;
    // 가이드 판: 어디를 눌러도 "둬야 할 수" 가 집힌다
    final req = _guideRequired;
    if (req != null) {
      _haptic();
      setState(() {
        _selectedRow = req.rowIndex;
        _selectedCount = req.count;
      });
      return;
    }
    final len = _rows[rowIdx];
    int count;
    final bool tappedBoundary = rowIdx == _selectedRow &&
        _selectedCount > 0 &&
        tappedIndex == len - _selectedCount;
    if (tappedBoundary) {
      count = _selectedCount - 1; // 내려놓기 (0까지 가능 = 전부 내려놓음)
    } else {
      count = len - tappedIndex; // 집기
    }
    if ((_config.mode == GameMode.singleRow ||
            _config.mode == GameMode.fibonacci) &&
        count > _effectiveMaxTake) {
      count = _effectiveMaxTake;
    }
    if (count < 0) count = 0;
    if (count > len) count = len;
    _haptic(); // 돌 집기/내려놓기 순간 가벼운 진동
    setState(() {
      _selectedRow = rowIdx;
      _selectedCount = count;
    });
  }

  /// (2026-09-15 대표님) 간식이 많아지면 한 줄에 억지로 욱여넣어 콩알만 해지던 것 →
  /// 한 줄이 perLine 개를 넘으면 **쟁반처럼 줄바꿈**한다. 셀은 최소 36px 를 지킨다.
  /// 여러 줄(님게임 2~3줄)일 땐 줄마다 테두리 쟁반 + 개수 라벨로 줄을 구분한다.
  /// 선택 규칙(끝에서부터 N개)은 읽는 순서 그대로라 줄바꿈해도 바뀌지 않는다.
  Widget _buildStonesBoard() {
    final bool multi = _rows.length > 1;
    return Center(
      child: LayoutBuilder(builder: (context, cons) {
        final double avail = cons.maxWidth - 32 - 40; // 패딩 + 개수 라벨 여유
        final int maxLen = _rows.fold(1, (m, r) => r > m ? r : m).clamp(1, 60);
        // 한 줄에 놓을 최대 개수 — 셀 30px 까지는 한 줄에 둔다 (세 줄 님게임의 8개가
        // 7+1 로 어색하게 갈라지지 않게). 그보다 많아야 줄바꿈.
        final int perLine = (avail / 30).floor().clamp(6, 12);
        final int cols = maxLen <= perLine ? maxLen : perLine;
        final double cell = (avail / cols).clamp(30.0, 46.0);
        int linesOf(int len) => len <= 0 ? 1 : ((len - 1) ~/ perLine) + 1;
        final int totalLines = _rows.fold(0, (s, r) => s + linesOf(r));
        final double trayPad = multi ? 12.0 : 0.0;
        final double lineH = ((cons.maxHeight - 24 - _rows.length * trayPad) /
                totalLines)
            .clamp(28.0, 52.0);
        final double stone =
            [cell - 8, lineH - 8, 36.0].reduce((a, b) => a < b ? a : b);

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_rows.length, (rowIdx) {
              final len = _rows[rowIdx];
              final isSelRow = _selectedRow == rowIdx;
              final int lines = linesOf(len);

              // 쟁반 너비는 모든 줄 동일(cols*cell) — 줄마다 들쭉날쭉하지 않게.
              // 여러 줄이면 왼쪽 정렬해서 "5 · 6 · 8" 차이가 눈에 보인다.
              final Widget stones = SizedBox(
                width: cols * cell,
                height: lines * lineH,
                child: Wrap(
                  alignment: multi ? WrapAlignment.start : WrapAlignment.center,
                  children: List.generate(len, (i) {
                    final bool selected =
                        isSelRow && i >= len - _selectedCount;
                    final bool danger = _isWrongStone(rowIdx, i, len);
                    return _Stone(
                      cell: cell,
                      cellH: lineH,
                      size: stone,
                      selected: selected,
                      leaving: _leaving && selected,
                      danger: danger,
                      hint: _isHintStone(rowIdx, i, len),
                      pointer: _guideRequired != null && _isHintStone(rowIdx, i, len),
                      kind: snackForStage(widget.stageNumber),
                      onTap: () => _selectStone(rowIdx, i),
                    );
                  }),
                ),
              );

              // 개수 라벨은 한 줄도 표시 — 쟁반 테두리는 여러 줄일 때만
              return Padding(
                padding: EdgeInsets.only(bottom: trayPad),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text(
                        '$len',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: _mono,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isSelRow
                              ? _Pal.gold
                              : _Pal.ink.withOpacity(0.7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: !multi
                              ? Colors.transparent
                              : isSelRow
                                  ? _Pal.gold.withOpacity(0.8)
                                  : _Pal.deskWoodDark.withOpacity(0.55),
                          width: 1.5,
                        ),
                      ),
                      child: stones,
                    ),
                  ],
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  // ── 🧪 카일즈: 아무 위치의 인접 1~2개 선택 ──
  void _selectKayles(int rowIdx, int i) {
    if (_phase != GamePhase.playing ||
        _currentTurn != TurnOwner.player ||
        _isAiAnimating ||
        _leaving) return;
    _haptic();
    final req = _guideRequired;
    if (req != null) {
      setState(() {
        _kSelRow = req.rowIndex;
        _kSelStart = req.kaylesLeft;
        _kSelCount = req.count;
      });
      return;
    }
    setState(() {
      final bool inSel = _kSelRow == rowIdx &&
          _kSelCount > 0 &&
          i >= _kSelStart &&
          i < _kSelStart + _kSelCount;
      if (inSel) {
        // 쥔 돌을 다시 탭 = 그 돌만 내려놓기
        if (_kSelCount == 2) {
          _kSelStart = (i == _kSelStart) ? _kSelStart + 1 : _kSelStart;
          _kSelCount = 1;
        } else {
          _kSelRow = -1;
          _kSelStart = -1;
          _kSelCount = 0;
        }
      } else if (_kSelRow == rowIdx &&
          _kSelCount == 1 &&
          (i == _kSelStart - 1 || i == _kSelStart + 1)) {
        // 옆에 붙은 돌 = 이어서 잡기 (최대 2개)
        _kSelStart = i < _kSelStart ? i : _kSelStart;
        _kSelCount = 2;
      } else {
        // 새로 집기
        _kSelRow = rowIdx;
        _kSelStart = i;
        _kSelCount = 1;
      }
    });
  }

  Widget _buildKaylesBoard() {
    return Center(
      child: LayoutBuilder(builder: (context, cons) {
        final int maxLen = _rows.fold(1, (m, r) => r > m ? r : m).clamp(1, 40);
        final double avail = cons.maxWidth - 32;
        final double cell = (avail / maxLen).clamp(24.0, 44.0);
        // 카일즈는 쪼개질수록 줄이 늘어난다 — 줄 높이를 적응시켜 책상 안에 유지
        final double rowH =
            ((cons.maxHeight - 46) / _rows.length).clamp(26.0, 50.0);
        final double stone =
            [cell - 8, rowH - 10, 34.0].reduce((a, b) => a < b ? a : b);
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  s.get('kaylesTapCta', [s.snackObj(_snackKey)]),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: _mono,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _Pal.cream.withOpacity(0.85),
                  ),
                ),
              ),
              ...List.generate(_rows.length, (rowIdx) {
                final len = _rows[rowIdx];
                final bool rowSel = _kSelRow == rowIdx && _kSelCount > 0;
                return SizedBox(
                  height: rowH,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // (v2) 줄별 개수 라벨
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          '$len',
                          style: TextStyle(
                            fontFamily: _mono,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: rowSel
                                ? _Pal.gold
                                : _Pal.cream.withOpacity(0.65),
                          ),
                        ),
                      ),
                      ...List.generate(len, (i) {
                        final bool selected = _kSelRow == rowIdx &&
                            i >= _kSelStart &&
                            i < _kSelStart + _kSelCount;
                        return _Stone(
                          cell: cell,
                          cellH: rowH,
                          size: stone,
                          selected: selected,
                          leaving: _leaving && selected,
                          danger: _isWrongStone(rowIdx, i, len),
                          hint: _isHintStone(rowIdx, i, len),
                          pointer: _guideRequired != null && _isHintStone(rowIdx, i, len),
                          kind: snackForStage(widget.stageNumber),
                          onTap: () => _selectKayles(rowIdx, i),
                        );
                      }),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildKaylesAction() {
    final bool hasSel = _kSelCount > 0 && _kSelRow >= 0;
    return _guideWrap(_buildKaylesButton(hasSel), hasSel);
  }

  Widget _buildKaylesButton(bool hasSel) {
    return SizedBox(
      width: double.infinity,
      child: _StampButton(
        label: hasSel
            ? s.get('takeNStones', ['$_kSelCount'])
            : s.get('pickFirstCta', [s.snackObj(_snackKey)]),
        color: hasSel ? _Pal.alarm : _Pal.frameHi,
        onTap: _confirmKayles,
      ),
    );
  }

  void _confirmKayles() {
    if (_phase != GamePhase.playing ||
        _currentTurn != TurnOwner.player ||
        _isAiAnimating ||
        _leaving ||
        _kSelCount < 1 ||
        _kSelRow < 0) return;
    _haptic(true);
    SfxService.instance.playTake();
    setState(() => _leaving = true);
    Future.delayed(const Duration(milliseconds: 360), () {
      if (!mounted) return;
      final int row = _kSelRow;
      final int left = _kSelStart;
      final int right = _rows[row] - (_kSelStart + _kSelCount);
      _recordPlayerMove(NimMove(
          rowIndex: row,
          count: _kSelCount,
          isKayles: true,
          kaylesLeft: left,
          kaylesRight: right));
      setState(() {
        _leaving = false;
        // (대표님 7/24) 분열은 제자리에서 위아래로 — 정렬하면 줄 위치가 튀어 헷갈림
        _rows.removeAt(row);
        if (right > 0) _rows.insert(row, right);
        if (left > 0) _rows.insert(row, left);
        _kSelRow = -1;
        _kSelStart = -1;
        _kSelCount = 0;
        _turnCount++;
        _currentTurn = TurnOwner.midnight;
      });
      if (!_checkGameOver()) {
        setState(() => _midnightFace = MidnightFace.thinking);
        Future.delayed(const Duration(milliseconds: 1000), _midnightPlay);
      }
    });
  }

  // ── 🧪 위토프: 두 무더기 suffix 선택 (한쪽만 or 양쪽 같은 개수) ──
  void _selectWythoff(int rowIdx, int i) {
    if (_phase != GamePhase.playing ||
        _currentTurn != TurnOwner.player ||
        _isAiAnimating ||
        _leaving) return;
    final req = _guideRequired;
    if (req != null) {
      _haptic();
      setState(() {
        _wSelA = req.takeA;
        _wSelB = req.takeB;
      });
      return;
    }
    final len = _rows[rowIdx];
    final int cur = rowIdx == 0 ? _wSelA : _wSelB;
    int count;
    final bool tappedBoundary = cur > 0 && i == len - cur;
    if (tappedBoundary) {
      count = cur - 1; // 내려놓기
    } else {
      count = len - i; // 집기
    }
    if (count < 0) count = 0;
    _haptic();
    setState(() {
      if (rowIdx == 0) {
        _wSelA = count;
      } else {
        _wSelB = count;
      }
    });
  }

  bool get _wythoffValid =>
      (_wSelA > 0 && _wSelB == 0) ||
      (_wSelA == 0 && _wSelB > 0) ||
      (_wSelA > 0 && _wSelA == _wSelB);

  Widget _buildWythoffBoard() {
    return Center(
      child: LayoutBuilder(builder: (context, cons) {
        final int maxLen = _rows.fold(1, (m, r) => r > m ? r : m).clamp(1, 40);
        final double avail = cons.maxWidth - 32 - 34;
        final double cell = (avail / maxLen).clamp(24.0, 44.0);
        final double rowH =
            ((cons.maxHeight - 24) / _rows.length).clamp(28.0, 52.0);
        final double stone =
            [cell - 8, rowH - 10, 34.0].reduce((a, b) => a < b ? a : b);
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_rows.length, (rowIdx) {
              final len = _rows[rowIdx];
              final int sel = rowIdx == 0 ? _wSelA : _wSelB;
              return SizedBox(
                height: rowH,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // (v2) 줄별 개수 라벨
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        '$len',
                        style: TextStyle(
                          fontFamily: _mono,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: sel > 0
                              ? _Pal.gold
                              : _Pal.cream.withOpacity(0.65),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(len, (i) {
                        final bool selected = i >= len - sel;
                        return _Stone(
                          cell: cell,
                          cellH: rowH,
                          size: stone,
                          selected: selected,
                          leaving: _leaving && selected,
                          danger: _isWrongStone(rowIdx, i, len),
                          hint: _isHintStone(rowIdx, i, len),
                          pointer: _guideRequired != null && _isHintStone(rowIdx, i, len),
                          kind: snackForStage(widget.stageNumber),
                          onTap: () => _selectWythoff(rowIdx, i),
                        );
                      }),
                    ),
                  ],
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildWythoffAction() {
    final bool any = _wSelA > 0 || _wSelB > 0;
    return _guideWrap(_buildWythoffButton(), any && _wythoffValid);
  }

  Widget _buildWythoffButton() {
    final bool any = _wSelA > 0 || _wSelB > 0;
    final bool valid = _wythoffValid;
    final int total = _wSelA + _wSelB;
    return SizedBox(
      width: double.infinity,
      child: !any
          ? _StampButton(
              label: s.get('pickFirstCta', [s.snackObj(_snackKey)]),
              color: _Pal.frameHi,
              onTap: () {},
            )
          : valid
              ? _StampButton(
                  label: s.get('takeNStones', ['$total']),
                  color: _Pal.alarm,
                  onTap: _confirmWythoff,
                )
              : Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _Pal.alarmHi, width: 2),
                  ),
                  child: Text(
                    s.get('wythoffInvalid'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: _mono,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _Pal.alarmHi,
                    ),
                  ),
                ),
    );
  }

  void _confirmWythoff() {
    if (_phase != GamePhase.playing ||
        _currentTurn != TurnOwner.player ||
        _isAiAnimating ||
        _leaving ||
        !_wythoffValid) return;
    _haptic(true);
    SfxService.instance.playTake();
    setState(() => _leaving = true);
    Future.delayed(const Duration(milliseconds: 360), () {
      if (!mounted) return;
      final int a = _wSelA, b = _wSelB;
      _recordPlayerMove(NimMove(isWythoff: true, takeA: a, takeB: b));
      setState(() {
        _leaving = false;
        _rows[0] -= a;
        _rows[1] -= b;
        _wSelA = 0;
        _wSelB = 0;
        _turnCount++;
        _currentTurn = TurnOwner.midnight;
      });
      if (!_checkGameOver()) {
        setState(() => _midnightFace = MidnightFace.thinking);
        Future.delayed(const Duration(milliseconds: 1000), _midnightPlay);
      }
    });
  }

  /// 빼빼로 보드 — 진짜 막대 비주얼.
  /// 묶음을 탭해 고르고(하늘색), 막대를 탭해 쪼갤 위치를 정한다(흰 분할선).
  /// 숫자는 부차적 정보로 작게만 표시.
  Widget _buildPeperoBoard() {
    final bool myTurn = _phase == GamePhase.playing &&
        _currentTurn == TurnOwner.player &&
        !_isAiAnimating;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 살아있는 묶음(쪼갤 수 있는 것)만 메인 무대에
          Wrap(
            spacing: 10,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              for (int i = 0; i < _rows.length; i++)
                if (_rows[i] >= 3) _peperoBundle(i, myTurn),
            ],
          ),
          // 1~2개짜리(더 못 쪼개는 조각)는 아래 트레이로 치워서 무대를 깔끔하게
          if (_rows.any((n) => n < 3)) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
              decoration: BoxDecoration(
                color: _Pal.deskBottom.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: _Pal.frame.withOpacity(0.8), width: 1.2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.get('peperoDeadTray'),
                    style: TextStyle(
                      fontFamily: _mono,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: _Pal.cream.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final n in _rows)
                        if (n < 3) _peperoDeadMini(n),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 트레이용 미니 묶음 — 상호작용 없음, 작게.
  Widget _peperoDeadMini(int n) {
    return Opacity(
      opacity: 0.65,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int k = 0; k < n; k++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: _peperoStick(7, 24, dim: true),
            ),
        ],
      ),
    );
  }

  /// 묶음 하나: 막대 Row + (선택 시) 흰 분할선 + 작은 개수 라벨.
  /// 막대과자 묶음 — 막대를 탭하면 "그 막대 뒤에서 자른다".
  /// 묶음을 미리 고르는 단계 없이 바로 자를 위치를 정한다(2탭이면 끝).
  /// 박스 높이는 항상 고정이라 고른다고 레이아웃이 밀리지 않는다.
  Widget _peperoBundle(int i, bool myTurn) {
    final int n = _rows[i];
    final bool splittable = n >= 3;
    final bool selected = i == _selectedPile && splittable;
    final int a = _splitA.clamp(1, n > 1 ? n - 1 : 1);
    // 힌트: 이 묶음을 어디서 쪼개야 하는지 하늘색으로 (광고 보고 얻은 정보)
    final bool hintPile = _hintRow == i && _hintSplitA > 0;
    final int hintAt = hintPile ? _hintSplitA.clamp(1, n > 1 ? n - 1 : 1) : -1;

    // 막대 크기 — 선택 여부와 무관하게 **고정**(출렁임 방지)
    final double stickW = n <= 8 ? 13 : (n <= 14 ? 10 : 8);
    const double stickH = 56;
    final double gap = n <= 14 ? 1.5 : 1.0;

    final children = <Widget>[];
    for (int k = 0; k < n; k++) {
      // 자를 자리 표시: 선택된 위치(가위) → 힌트 위치(하늘색)
      if (selected && k == a) {
        children.add(_scissorDivider(stickH));
      } else if (!selected && hintPile && k == hintAt) {
        children.add(_hintDivider(stickH));
      }

      // 이 막대 뒤에서 자르면 (k+1) / (n-k-1) — 같은 개수면 금지
      final int cutAt = k + 1;
      final bool wouldBeEqual = splittable && cutAt * 2 == n;
      final bool canCutHere =
          myTurn && splittable && cutAt < n && !wouldBeEqual;

      Widget stick = Padding(
        padding: EdgeInsets.symmetric(horizontal: gap),
        child: _peperoStick(stickW, stickH, dim: !splittable),
      );

      // 같은 개수가 되는 자리는 흐리게만 — 탭은 막혀 있다 (아이콘은 안 그림)
      if (myTurn && splittable && wouldBeEqual && cutAt < n) {
        stick = Opacity(opacity: 0.4, child: stick);
      }

      children.add(canCutHere
          ? GestureDetector(
              onTap: () {
                _haptic();
                final req = _guideRequired;
                setState(() {
                  if (req != null && req.isPepero) {
                    _selectedPile = req.rowIndex;
                    _splitA = req.splitA;
                  } else {
                    _selectedPile = i;
                    _splitA = cutAt;
                  }
                });
              },
              behavior: HitTestBehavior.opaque,
              child: stick,
            )
          : stick);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      padding: const EdgeInsets.fromLTRB(9, 9, 9, 5),
      decoration: BoxDecoration(
        color: selected
            ? _Pal.sky.withOpacity(0.10)
            : _Pal.deskBottom.withOpacity(0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (selected || hintPile)
              ? _Pal.sky
              : (splittable ? _Pal.frameHi : _Pal.frame),
          width: (selected || hintPile) ? 2.5 : 1.5,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: _Pal.sky.withOpacity(0.35),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: children,
          ),
          const SizedBox(height: 5),
          // 자른 결과를 막대 바로 밑에 — 아래 슬라이더를 볼 필요가 없다
          SizedBox(
            height: 16,
            child: selected
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$a',
                          style: const TextStyle(
                              fontFamily: _mono,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: _Pal.sky)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text('+',
                            style: TextStyle(
                                fontFamily: _mono,
                                fontSize: 12,
                                color: Colors.white70)),
                      ),
                      Text('${n - a}',
                          style: const TextStyle(
                              fontFamily: _mono,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: _Pal.sky)),
                    ],
                  )
                : Text('$n',
                    style: TextStyle(
                      fontFamily: _mono,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: splittable
                          ? _Pal.cream.withOpacity(0.7)
                          : _Pal.inkSoft,
                    )),
          ),
        ],
      ),
    );
  }

  /// 자를 자리 — 가위 아이콘이 달린 흰 선.
  Widget _scissorDivider(double h) {
    return SizedBox(
      width: 16,
      height: h + 20,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 3.5,
            height: h + 8,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                    color: Colors.white.withOpacity(0.55),
                    blurRadius: 6,
                    spreadRadius: 1),
              ],
            ),
          ),
          Positioned(
            top: 0,
            child:
                Text('✂', style: TextStyle(fontSize: 13, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// 힌트가 알려주는 쪼갤 위치 — 점선 느낌의 하늘색 선.
  Widget _hintDivider(double h) {
    final bar = _hintDividerBar(h);
    if (_guideRequired == null) return bar;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [bar, const Positioned(bottom: -30, child: _BouncingHand())],
    );
  }

  Widget _hintDividerBar(double h) {
    return Container(
      width: 3.5,
      height: h + 8,
      margin: const EdgeInsets.symmetric(horizontal: 3.5),
      decoration: BoxDecoration(
        color: _Pal.sky,
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: _Pal.sky.withOpacity(0.7),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  /// 빼빼로 막대 하나: 초코 몸통 + 비스킷 손잡이.
  Widget _peperoStick(double w, double h, {bool dim = false}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(w / 2),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dim
              ? const [
                  Color(0xFF4A3B2C),
                  Color(0xFF3A2E20),
                  Color(0xFF8C7A55),
                  Color(0xFF7A6A4A),
                ]
              : const [
                  Color(0xFF6B4226),
                  Color(0xFF3E2412),
                  Color(0xFFEAD3A2),
                  Color(0xFFD9B98A),
                ],
          stops: const [0.0, 0.60, 0.64, 1.0],
        ),
        border: Border.all(color: Colors.black.withOpacity(0.35), width: 1),
      ),
    );
  }

  Widget _buildActionArea() {
    // (대표님 7/24) 예린 턴에도 같은 높이로 유지 — 반투명+터치 차단만.
    final bool myTurn =
        _currentTurn == TurnOwner.player && !_isAiAnimating && !_leaving;
    return IgnorePointer(
      ignoring: !myTurn,
      child: Opacity(
        opacity: myTurn ? 1.0 : 0.45,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          constraints: const BoxConstraints(minHeight: 84),
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: _Pal.frame,
            border: Border(top: BorderSide(color: _Pal.frameHi, width: 2)),
          ),
          child: _config.mode == GameMode.pepero
              ? _buildPeperoAction()
              : _config.mode == GameMode.kayles
                  ? _buildKaylesAction()
                  : _config.mode == GameMode.wythoff
                      ? _buildWythoffAction()
                      : _buildStoneAction(),
        ),
      ),
    );
  }

  Widget _buildStoneAction() {
    int maxCanTake = _rows[_selectedRow];
    if (_config.mode == GameMode.singleRow ||
        _config.mode == GameMode.fibonacci) {
      maxCanTake = maxCanTake.clamp(1, _effectiveMaxTake);
    }
    if (_selectedCount > maxCanTake) _selectedCount = maxCanTake;
    if (_selectedCount < 0) _selectedCount = 0;
    final bool hasSel = _selectedCount > 0;

    // (2026-09-15 정보 다이어트) "가져갈 개수 / —" 라벨 줄 삭제. 버튼 하나가 전부.
    final Widget button = AnimatedScale(
      scale: hasSel ? 1.0 : 0.97,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      child: SizedBox(
        width: double.infinity,
        child: _StampButton(
          label: hasSel
              ? s.get('takeNStones', ['$_selectedCount'])
              : s.get('pickFirstCta', [s.snackObj(_snackKey)]),
          color: hasSel ? _Pal.alarm : _Pal.frameHi,
          onTap: _confirmTake,
        ),
      ),
    );
    return _guideWrap(button, hasSel);
  }

  /// 가이드 판: ① 하늘색 누르기 → ② 버튼 누르기 를 버튼 위에 적고, ②단계엔 버튼이 두근거린다.
  Widget _guideWrap(Widget button, bool hasSel) {
    if (_guideRequired == null) return button;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          hasSel ? s.get('guideConfirm') : s.get('guideTap', [s.snackObj(_snackKey)]),
          style: TextStyle(
            fontFamily: _mono,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: hasSel ? _Pal.gold : _Pal.sky,
          ),
        ),
        const SizedBox(height: 6),
        hasSel ? _Pulse(child: button) : button,
      ],
    );
  }

  /// 막대과자 액션 — 슬라이더 없음. 판 위에서 자를 곳을 정하고 여기선 확정만.
  Widget _buildPeperoAction() {
    final bool hasSel = _selectedPile >= 0 &&
        _selectedPile < _rows.length &&
        _rows[_selectedPile] >= 3;
    return _guideWrap(_buildPeperoButton(hasSel), hasSel);
  }

  Widget _buildPeperoButton(bool hasSel) {

    if (!hasSel) {
      // 아직 자를 곳을 안 골랐을 때 — 버튼 자리를 비워두지 않고 안내로 채운다
      return SizedBox(
        width: double.infinity,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _Pal.frameHi, width: 2),
          ),
          child: Text(
            s.get('peperoTapStick'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: _mono,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _Pal.cream.withOpacity(0.55),
            ),
          ),
        ),
      );
    }

    final int pile = _rows[_selectedPile];
    final int a = _splitA.clamp(1, pile - 1);
    final int b = pile - a;

    return SizedBox(
      width: double.infinity,
      child: _StampButton(
        label: s.get('splitAction', ['$a', '$b']),
        color: _Pal.alarm,
        onTap: () {
          if (a <= 0 || b <= 0 || a == b) return;
          _recordPlayerMove(NimMove(
              rowIndex: _selectedPile, splitA: a, splitB: b, isPepero: true));
          SfxService.instance.playTake();
          _haptic(true);
          _clearHint();
          setState(() {
            _rows.removeAt(_selectedPile);
            _rows.add(a);
            _rows.add(b);
            _rows.sort((x, y) => y.compareTo(x));
            _turnCount++;
            _currentTurn = TurnOwner.midnight;
            _selectedPile = -1;
            _splitA = 1;
          });
          if (!_checkGameOver()) {
            setState(() {
              _midnightFace = MidnightFace.thinking;
            });
            Future.delayed(const Duration(milliseconds: 1000), _midnightPlay);
          }
        },
      ),
    );
  }
}

/// 한밤이가 가져간 돌 — 보드 중앙에서 맞은편(위쪽) 고양이 방향으로 슉! 날아간다.
class _FlyingStone extends StatelessWidget {
  final int seed;
  const _FlyingStone({required this.seed});

  @override
  Widget build(BuildContext context) {
    // 시작 지점에 살짝 좌우 변화 (연속으로 날아갈 때 겹치지 않게)
    final double jx = ((seed % 3) - 1) * 0.18;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInQuad,
      builder: (_, t, __) {
        final align = Alignment.lerp(
          Alignment(jx, 0.1), // 보드 중앙(돌 근처)
          Alignment(jx * 0.3, -1.45), // 맞은편 상단 중앙 = 한밤이 쪽
          t,
        )!;
        return Align(
          alignment: align,
          child: Opacity(
            opacity: (1 - t * 0.7).clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 1.0 - 0.55 * t,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(-0.4, -0.5),
                    radius: 0.95,
                    colors: [Color(0xFFD9C7A0), Color(0xFF8C7A55)],
                  ),
                  border:
                      Border.all(color: const Color(0xFF5C4E33), width: 1.5),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 내 손 — 대표님 스케치처럼 삐죽삐죽한 손이 책상 아래에서 올라온다 (종이 실루엣 톤).
class _PlayerHandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = _Pal.paper;
    final line = Paint()
      ..color = _Pal.frame
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(w * 0.34, h) // 손목 왼쪽
      ..lineTo(w * 0.30, h * 0.52)
      // 삐죽 손가락 5개 (스케치 감성)
      ..lineTo(w * 0.06, h * 0.34)
      ..lineTo(w * 0.30, h * 0.36)
      ..lineTo(w * 0.22, h * 0.06)
      ..lineTo(w * 0.42, h * 0.30)
      ..lineTo(w * 0.50, h * 0.00)
      ..lineTo(w * 0.60, h * 0.30)
      ..lineTo(w * 0.78, h * 0.08)
      ..lineTo(w * 0.72, h * 0.38)
      ..lineTo(w * 0.96, h * 0.30)
      ..lineTo(w * 0.72, h * 0.54)
      ..lineTo(w * 0.68, h) // 손목 오른쪽
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// (제안 #8) 승리 별 파티클 — 중앙에서 8방향으로 퍼지는 골드 별.
class _WinBurst extends StatelessWidget {
  const _WinBurst();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOut,
      builder: (_, t, __) {
        return Stack(
          alignment: Alignment.center,
          children: List.generate(8, (i) {
            final a = i * math.pi / 4 + 0.4;
            final r = 30 + 90 * t;
            return Transform.translate(
              offset: Offset(math.cos(a) * r, math.sin(a) * r * 0.7),
              child: Opacity(
                opacity: (1 - t).clamp(0.0, 1.0),
                child: Text(
                  i.isEven ? '✦' : '⭐',
                  style: TextStyle(
                    fontSize: 16 + 8 * t,
                    color: _Pal.gold,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// 진행 로그 한 줄 — owner로 색상 결정 (언어 독립적).
// ─────────────────────────────────────────────────────────────
// 재사용 위젯 / 페인터
// ─────────────────────────────────────────────────────────────

/// 책상 위 돌 = 부감(탑뷰) 칩 토큰.
/// 월드별 간식 종류 — 단계가 바뀐 걸 한눈에 알 수 있게 모양·색이 다르다.
enum SnackKind { candy, chocolate, cookie, jelly, macaron, donut }

/// 스테이지(월드)에 맞는 간식 종류. 막대과자 월드는 별도 위젯이라 여기 없음.
SnackKind snackForStage(int stage) {
  const kinds = [
    SnackKind.candy, // 등교길
    SnackKind.chocolate, // 점심시간 옥상
    SnackKind.cookie, // 방과후 교실
    SnackKind.jelly, // (막대과자 월드는 별도)
    SnackKind.macaron, // 체육관
    SnackKind.donut, // 과학실
    SnackKind.jelly, // 뒤뜰 토끼장
  ];
  final w = (worldForStage(stage).id).clamp(0, kinds.length - 1);
  return kinds[w];
}

/// 간식 렌더러 — 종류마다 실루엣과 배색이 다르다.
/// selected(집은 상태)면 밝게, danger(가져가면 지는 것)면 붉게.
class _SnackPainter extends CustomPainter {
  final SnackKind kind;
  final bool selected;
  final bool danger;
  const _SnackPainter({
    required this.kind,
    required this.selected,
    required this.danger,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final c = Offset(w / 2, h / 2);
    final r = w / 2;

    // 공통 그림자
    canvas.drawCircle(
      c.translate(1, 2.5),
      r * 0.95,
      Paint()..color = Colors.black.withOpacity(selected ? 0.42 : 0.32),
    );

    // 배색: danger > selected > 종류 기본
    late Color main, dark, deco;
    if (danger) {
      main = const Color(0xFFE8776B);
      dark = const Color(0xFF9B3B2E);
      deco = const Color(0xFFFFD9D2);
    } else if (selected) {
      main = const Color(0xFFF6DEA6);
      dark = const Color(0xFFC9A24B);
      deco = const Color(0xFFFFF6DF);
    } else {
      switch (kind) {
        case SnackKind.candy:
          main = const Color(0xFFF5A3C7);
          dark = const Color(0xFFC96694);
          deco = const Color(0xFFFFF0F6);
          break;
        case SnackKind.chocolate:
          main = const Color(0xFF9A6842);
          dark = const Color(0xFF5E3A22);
          deco = const Color(0xFFC79366);
          break;
        case SnackKind.cookie:
          main = const Color(0xFFD9A566);
          dark = const Color(0xFF9A6E3C);
          deco = const Color(0xFF5A3A1E);
          break;
        case SnackKind.jelly:
          main = const Color(0xFF8FD98F);
          dark = const Color(0xFF4E9E52);
          deco = const Color(0xFFE4FBE4);
          break;
        case SnackKind.macaron:
          main = const Color(0xFFC9A8E6);
          dark = const Color(0xFF8E6BB0);
          deco = const Color(0xFFFCEFF8);
          break;
        case SnackKind.donut:
          main = const Color(0xFFF2C36B);
          dark = const Color(0xFFB8863A);
          deco = const Color(0xFFEF8FB4);
          break;
      }
    }

    final body = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.45),
        radius: 0.95,
        colors: [
          Color.lerp(main, Colors.white, 0.28)!,
          main,
          dark,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    final edge = Paint()
      ..color = dark
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 2.0 : 1.5;
    final decoP = Paint()..color = deco;

    switch (kind) {
      case SnackKind.chocolate:
        // 네모난 초콜릿 + 격자 홈
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: w * 0.88, height: h * 0.88),
          const Radius.circular(3),
        );
        canvas.drawRRect(rect, body);
        canvas.drawRRect(rect, edge);
        final line = Paint()
          ..color = dark.withOpacity(0.75)
          ..strokeWidth = 1.2;
        canvas.drawLine(
            Offset(c.dx, c.dy - r * 0.8), Offset(c.dx, c.dy + r * 0.8), line);
        canvas.drawLine(
            Offset(c.dx - r * 0.8, c.dy), Offset(c.dx + r * 0.8, c.dy), line);
        break;

      case SnackKind.cookie:
        // 동그란 쿠키 + 초코칩
        canvas.drawCircle(c, r * 0.92, body);
        canvas.drawCircle(c, r * 0.92, edge);
        final chip = Paint()..color = deco;
        const spots = [
          Offset(-0.32, -0.28),
          Offset(0.3, -0.12),
          Offset(-0.1, 0.32),
          Offset(0.26, 0.34),
        ];
        for (final s in spots) {
          canvas.drawCircle(c.translate(s.dx * r, s.dy * r), r * 0.13, chip);
        }
        break;

      case SnackKind.jelly:
        // 말랑한 젤리 — 둥근 사각 + 하이라이트
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: w * 0.84, height: h * 0.84),
          Radius.circular(r * 0.42),
        );
        canvas.drawRRect(rect, body);
        canvas.drawRRect(rect, edge);
        canvas.drawOval(
          Rect.fromCenter(
              center: c.translate(-r * 0.22, -r * 0.3),
              width: r * 0.5,
              height: r * 0.3),
          decoP..color = deco.withOpacity(0.85),
        );
        break;

      case SnackKind.macaron:
        // 마카롱 — 위아래 껍질 + 가운데 크림
        final top =
            Rect.fromLTWH(c.dx - r * 0.9, c.dy - r * 0.85, r * 1.8, r * 0.85);
        final bot =
            Rect.fromLTWH(c.dx - r * 0.9, c.dy + r * 0.12, r * 1.8, r * 0.8);
        canvas.drawRRect(
            RRect.fromRectAndRadius(top, Radius.circular(r * 0.45)), body);
        canvas.drawRRect(
            RRect.fromRectAndRadius(bot, Radius.circular(r * 0.45)), body);
        canvas.drawRect(
          Rect.fromCenter(
              center: c.translate(0, r * 0.02),
              width: r * 1.7,
              height: r * 0.3),
          decoP..color = deco,
        );
        break;

      case SnackKind.donut:
        // 도넛 — 가운데 구멍 + 분홍 글레이즈
        canvas.drawCircle(c, r * 0.92, body);
        canvas.drawCircle(c, r * 0.92, edge);
        canvas.drawCircle(
            c, r * 0.42, Paint()..color = const Color(0xFF3A332A));
        canvas.drawCircle(
          c,
          r * 0.7,
          Paint()
            ..color = deco.withOpacity(0.9)
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.34,
        );
        break;

      case SnackKind.candy:
        // 사탕 — 동그란 알 + 양쪽 포장 날개 + 소용돌이
        final wing = Paint()..color = dark;
        final lp = Path()
          ..moveTo(c.dx - r * 0.72, c.dy)
          ..lineTo(c.dx - r * 1.02, c.dy - r * 0.42)
          ..lineTo(c.dx - r * 1.02, c.dy + r * 0.42)
          ..close();
        final rp = Path()
          ..moveTo(c.dx + r * 0.72, c.dy)
          ..lineTo(c.dx + r * 1.02, c.dy - r * 0.42)
          ..lineTo(c.dx + r * 1.02, c.dy + r * 0.42)
          ..close();
        canvas.drawPath(lp, wing);
        canvas.drawPath(rp, wing);
        canvas.drawCircle(c, r * 0.75, body);
        canvas.drawCircle(c, r * 0.75, edge);
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: r * 0.42),
          -1.2,
          3.4,
          false,
          Paint()
            ..color = deco.withOpacity(0.9)
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.16
            ..strokeCap = StrokeCap.round,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _SnackPainter old) =>
      old.kind != kind || old.selected != selected || old.danger != danger;
}

/// selected → 내 쪽(아래)으로 살짝 내려오며 강조. leaving → 아래로 슈르륵 빠지며 사라짐.
/// cell = 히트 영역(개수 많으면 축소), size = 시각 크기.
class _Stone extends StatelessWidget {
  final double cell;
  final double cellH; // 세로 히트 영역 — 줄이 많으면 줄어든다
  final double size;
  final bool selected;
  final bool leaving;
  final bool danger; // 가져가면 지는 돌 (스테이지1 학습용) — 빨간 돌
  final bool hint; // 힌트 추천 — 하늘색 테두리 + 반짝임
  final bool pointer; // 가이드: 손가락이 위에서 콩콩
  final SnackKind kind; // 월드별 간식 종류
  final VoidCallback? onTap;
  const _Stone({
    this.cell = 44,
    this.cellH = 44,
    this.size = 34,
    required this.selected,
    required this.leaving,
    this.danger = false,
    this.hint = false,
    this.pointer = false,
    this.kind = SnackKind.candy,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double d = size;
    Widget token = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: d,
      height: d,
      child: CustomPaint(
        painter: _SnackPainter(
          kind: kind,
          selected: selected,
          danger: danger,
        ),
      ),
    );

    // 힌트: 하늘색 링 + 은은한 글로우로 "이걸 가져가" 표시
    if (hint) {
      token = Container(
        width: d + 10,
        height: d + 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _Pal.sky.withOpacity(0.28),
          border: Border.all(color: _Pal.sky, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: _Pal.sky.withOpacity(0.55),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(child: token),
      );
    }
    if (pointer) {
      token = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [token, Positioned(top: -d * 0.95, child: const _BouncingHand())],
      );
    }

    // (귀여움 규칙 T1) 히트 영역은 가능한 한 44dp — 돌이 많으면 화면에 맞게 축소.
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: cell,
        height: cellH,
        child: Center(
          child: AnimatedSlide(
            offset: leaving
                ? const Offset(0, 2.6)
                : (selected ? const Offset(0, 0.42) : Offset.zero),
            duration: Duration(milliseconds: leaving ? 340 : 170),
            curve: leaving ? Curves.easeIn : Curves.easeOutBack,
            child: AnimatedOpacity(
              opacity: leaving ? 0 : 1,
              duration: const Duration(milliseconds: 320),
              // (제안 #9) 집는 순간 통통 튀는 바운스 — 손맛
              child: AnimatedScale(
                scale: selected ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: token,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 탑뷰 책상 표면: 어두운 나무 + 미세 그리드 + 등록(+) 마크.
/// 교실 배경 — 대표님 원화(2026-07-08) 구도 재현:
/// 크림 벽 + 왼쪽 초록 칠판(나무 프레임) + 오른쪽 창문(구름 하늘 + 매직 낙서).
class _ClassroomPainter extends CustomPainter {
  const _ClassroomPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // 벽 — 위 크림, 아래 살짝 어둡게
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = _Pal.roomWall);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.52, w, h * 0.48),
        Paint()..color = _Pal.roomWallLow);
    // 벽 몰딩(허리선) 나무 띠
    canvas.drawRect(Rect.fromLTWH(0, h * 0.50, w, h * 0.025),
        Paint()..color = _Pal.woodFrame);

    // ── 왼쪽: 초록 칠판 ──
    final board = Rect.fromLTWH(-12, h * 0.03, w * 0.34, h * 0.42);
    // 나무 프레임 (칠판보다 살짝 크게)
    canvas.drawRRect(
      RRect.fromRectAndRadius(board.inflate(7), const Radius.circular(4)),
      Paint()..color = _Pal.woodFrame,
    );
    canvas.drawRect(board, Paint()..color = _Pal.chalkboard);
    // 칠판 음영 (원화의 대각 반사)
    final shade = Path()
      ..moveTo(board.left, board.bottom)
      ..lineTo(board.right, board.top + board.height * 0.35)
      ..lineTo(board.right, board.bottom)
      ..close();
    canvas.drawPath(
        shade, Paint()..color = _Pal.chalkboardDark.withOpacity(0.45));
    // 분필 받침대
    canvas.drawRect(
      Rect.fromLTWH(board.left, board.bottom + 7, board.width + 14, 6),
      Paint()..color = _Pal.woodFrame,
    );

    // ── 오른쪽: 창문 ──
    final win = Rect.fromLTWH(w * 0.42, h * 0.02, w * 0.62, h * 0.46);
    canvas.drawRRect(
      RRect.fromRectAndRadius(win.inflate(6), const Radius.circular(3)),
      Paint()..color = _Pal.windowFrame,
    );
    canvas.drawRect(win, Paint()..color = _Pal.windowGlass);

    // 구름 2덩이 — 크림 블롭 + 스케치 아크(원화의 러프 라인)
    final cloudPaint = Paint()..color = _Pal.cloud;
    void cloudAt(double cx, double cy, double s) {
      canvas.drawCircle(Offset(cx, cy), 16 * s, cloudPaint);
      canvas.drawCircle(Offset(cx + 18 * s, cy - 6 * s), 13 * s, cloudPaint);
      canvas.drawCircle(Offset(cx + 34 * s, cy + 2 * s), 15 * s, cloudPaint);
      canvas.drawCircle(Offset(cx + 16 * s, cy + 8 * s), 12 * s, cloudPaint);
    }

    cloudAt(win.left + win.width * 0.16, win.top + win.height * 0.30, 1.0);
    cloudAt(win.left + win.width * 0.58, win.top + win.height * 0.16, 1.15);
    // 스케치 라인 몇 개 (구름 테두리 일부만 — 손그림 느낌)
    final sketch = Paint()
      ..color = _Pal.sketchInk.withOpacity(0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
        Rect.fromCircle(
            center: Offset(
                win.left + win.width * 0.62, win.top + win.height * 0.12),
            radius: 15),
        3.4,
        1.8,
        false,
        sketch);
    canvas.drawArc(
        Rect.fromCircle(
            center: Offset(
                win.left + win.width * 0.20, win.top + win.height * 0.26),
            radius: 13),
        3.0,
        1.6,
        false,
        sketch);

    // 창살 (십자)
    final bar = Paint()..color = _Pal.windowFrame;
    canvas.drawRect(
        Rect.fromLTWH(win.left + win.width * 0.48, win.top, 5, win.height),
        bar);
    canvas.drawRect(
        Rect.fromLTWH(win.left, win.top + win.height * 0.62, win.width, 5),
        bar);

    // 🦑 유리 매직 낙서 — 원화의 오징어 낙서 오마주 (오른쪽 아래 유리칸)
    final doodle = Paint()
      ..color = _Pal.sketchInk.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final dx = win.left + win.width * 0.72;
    final dy = win.top + win.height * 0.76;
    // 머리(세모 두건) + 몸통
    final squid = Path()
      ..moveTo(dx - 10, dy - 6)
      ..quadraticBezierTo(dx - 4, dy - 22, dx + 2, dy - 8)
      ..quadraticBezierTo(dx + 12, dy - 14, dx + 10, dy - 2)
      ..quadraticBezierTo(dx + 14, dy + 6, dx + 4, dy + 6)
      ..quadraticBezierTo(dx - 8, dy + 8, dx - 10, dy - 6);
    canvas.drawPath(squid, doodle);
    // 다리 3개 (구불구불)
    for (int i = 0; i < 3; i++) {
      final lx = dx - 6 + i * 7.0;
      final leg = Path()
        ..moveTo(lx, dy + 6)
        ..quadraticBezierTo(lx - 3, dy + 12, lx + 1, dy + 16)
        ..quadraticBezierTo(lx + 4, dy + 19, lx + 2, dy + 22);
      canvas.drawPath(leg, doodle);
    }
    // 눈 2개
    final eye = Paint()..color = _Pal.sketchInk.withOpacity(0.8);
    canvas.drawCircle(Offset(dx - 3, dy - 3), 1.6, eye);
    canvas.drawCircle(Offset(dx + 5, dy - 3), 1.6, eye);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DeskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // (2026-07-08 교실 원화 스타일) 밝은 나무 책상 — 손그림 결 느낌
    final bg = Paint()..color = _Pal.deskWood;
    canvas.drawRect(Offset.zero & size, bg);

    // 나무 결 — 러프한 가로 스트로크 (원화의 연필 결 느낌)
    final grain = Paint()
      ..color = _Pal.deskWoodDark.withOpacity(0.35)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final rnd = math.Random(7); // 고정 시드 — 매 프레임 동일
    for (int i = 0; i < 14; i++) {
      final y = size.height * (0.08 + 0.9 * rnd.nextDouble());
      final x0 = size.width * (0.05 + 0.25 * rnd.nextDouble());
      final len = size.width * (0.15 + 0.45 * rnd.nextDouble());
      final bow = 2.0 + rnd.nextDouble() * 3.0;
      final path = Path()
        ..moveTo(x0, y)
        ..quadraticBezierTo(x0 + len / 2, y + bow, x0 + len, y);
      canvas.drawPath(path, grain..style = PaintingStyle.stroke);
    }

    // 아래쪽 살짝 어둡게 — 책상 두께감
    final shade = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          _Pal.deskWoodDark.withOpacity(0.25),
        ],
        stops: const [0.75, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, shade);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 말풍선 꼬리(왼쪽 방향 = 고양이 쪽) — 종이색 + 프레임 테두리.
/// 아래를 향하는 말풍선 꼬리 — (v2) 말풍선이 예린 머리 위에 떠 있을 때.
class _BubbleTailDown extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = _Pal.paper;
    final border = Paint()
      ..color = _Pal.frame
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0);
    canvas.drawPath(path, fill);
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 공통 "도장" 버튼 — 모노 타이포 + 베벨 테두리.
/// 가이드용 손가락 — 위아래로 콩콩. 하늘색 돌 위에 놓인다.
class _BouncingHand extends StatefulWidget {
  const _BouncingHand();
  @override
  State<_BouncingHand> createState() => _BouncingHandState();
}

class _BouncingHandState extends State<_BouncingHand> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 520))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, -8 * Curves.easeInOut.transform(_c.value)),
          child: child,
        ),
        child: const Text('👆', style: TextStyle(fontSize: 26)),
      ),
    );
  }
}

/// 가이드용 두근거림 — 눌러야 할 버튼을 살짝 키웠다 줄였다.
class _Pulse extends StatefulWidget {
  final Widget child;
  const _Pulse({required this.child});
  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Transform.scale(
        scale: 1.0 + 0.05 * Curves.easeInOut.transform(_c.value),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _StampButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final VoidCallback onTap;

  const _StampButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.black.withOpacity(0.35), width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: _Pal.cream, size: 18),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: _mono,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: _Pal.cream,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 힌트 전구 — 평소엔 조용한 아웃라인, **지는 포지션이면** 노란 불이 들어오며
/// 두근두근 커졌다 작아진다. "지금 힌트 보면 살 수 있는데?" 를 눈으로 알린다.
class _PulsingBulb extends StatefulWidget {
  final bool urgent;
  final VoidCallback onTap;
  final String tooltip;
  const _PulsingBulb({
    required this.urgent,
    required this.onTap,
    required this.tooltip,
  });

  @override
  State<_PulsingBulb> createState() => _PulsingBulbState();
}

class _PulsingBulbState extends State<_PulsingBulb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      duration: const Duration(milliseconds: 780),
      vsync: this,
    );
    if (widget.urgent) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _PulsingBulb old) {
    super.didUpdateWidget(old);
    if (widget.urgent && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.urgent && _c.isAnimating) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.urgent) {
      return IconButton(
        visualDensity: VisualDensity.compact,
        onPressed: widget.onTap,
        icon: const Icon(Icons.lightbulb_outline, size: 20, color: _Pal.gold),
        tooltip: widget.tooltip,
      );
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final double t = Curves.easeInOut.transform(_c.value);
        return IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: widget.onTap,
          tooltip: widget.tooltip,
          icon: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _Pal.gold.withOpacity(0.30 + 0.45 * t),
                  blurRadius: 8 + 12 * t,
                  spreadRadius: 1 + 3 * t,
                ),
              ],
            ),
            child: Transform.scale(
              scale: 1.0 + 0.22 * t,
              child: Icon(
                Icons.lightbulb,
                size: 20,
                color: Color.lerp(_Pal.gold, const Color(0xFFFFF1B8), t),
              ),
            ),
          ),
        );
      },
    );
  }
}
