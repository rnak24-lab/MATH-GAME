import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/board_games.dart';
import '../game/stage_manager.dart';
import '../game/tutorial_manager.dart';
import '../l10n/dialogue.dart';
import '../widgets/dialogue_box.dart';
import '../l10n/app_strings.dart';
import '../models/game_state.dart' show GamePhase;
import '../providers/locale_provider.dart';
import '../services/ad_service.dart';
import '../services/app_settings.dart';
import '../services/sfx_service.dart';
import '../widgets/midnight_character.dart';
import 'game_screen.dart' show GameScreen;
import 'settings_screen.dart';
import 'world_select_screen.dart' show worldForStage, WorldInfo;

/// 스테이지 번호로 알맞은 게임 화면을 고른다.
/// 1~140 = 님게임 계열(GameScreen), 141~240 = 보드 게임 5종(BoardGameScreen).
Widget stageScreenFor({
  required StageManager stageManager,
  required int stageNumber,
  required LocaleProvider localeProvider,
}) {
  if (isBoardStage(stageNumber)) {
    return BoardGameScreen(
      stageManager: stageManager,
      stageNumber: stageNumber,
      localeProvider: localeProvider,
    );
  }
  return GameScreen(
    stageManager: stageManager,
    stageNumber: stageNumber,
    localeProvider: localeProvider,
  );
}

// game_screen.dart 의 _Pal 과 같은 값 (형제 화면이라 톤을 맞춘다)
class _P {
  static const deskTop = Color(0xFF3A332A);
  static const deskBottom = Color(0xFF241F18);
  static const paper = Color(0xFFC8B790);
  static const frame = Color(0xFF4A3D2C);
  static const frameHi = Color(0xFF6E5C42);
  static const cream = Color(0xFFEADFC6);
  static const ink = Color(0xFF332817);
  static const inkSoft = Color(0xFF6A5A3F);
  static const gold = Color(0xFFC9A24B);
  static const alarm = Color(0xFF9B3B2E);
  static const alarmHi = Color(0xFFE0574A);
  static const win = Color(0xFF5E7D52);
  static const sky = Color(0xFF79C6EA);
  static const hint = Color(0xFF3D8FB8);
  static const deskWood = Color(0xFFD9A05B);
  static const deskWoodDark = Color(0xFFB98443);
  static const choco = Color(0xFF6B4226);
  static const chocoHi = Color(0xFF8B5E3C);
}

const String _mono = 'NeoDGM';
const double _kDeskTop = 340; // game_screen 과 동일 — 캐릭터가 같은 만큼 보인다
// 예린 크기·위치 — game_screen 과 같은 값 (얼굴이 말풍선 아래~책상 위를 채운다)
const double _kYerinH = 530;
const double _kYerinTop = 83 - _kYerinH * 0.065; // 대표님: 가슴팍까지 보이게 위로

class BoardGameScreen extends StatefulWidget {
  final StageManager stageManager;
  final int stageNumber;
  final LocaleProvider localeProvider;

  const BoardGameScreen({
    super.key,
    required this.stageManager,
    required this.stageNumber,
    required this.localeProvider,
  });

  @override
  State<BoardGameScreen> createState() => _BoardGameScreenState();
}

class _BoardGameScreenState extends State<BoardGameScreen> {
  late BoardGame _game;
  AppStrings get s => widget.localeProvider.strings;
  BoardKind get kind => _game.kind;

  GamePhase _phase = GamePhase.playing;
  bool _playerWon = false;
  int _turnCount = 0;
  bool _aiBusy = false;

  // 예린
  MidnightFace _face = MidnightFace.neutral;
  String? _msgKey;
  List<String> _msgArgs = const [];
  bool _msgAutoHint = false;
  int _lossTurns = 0;
  int _defeats = 0;

  bool _poked = false;
  String _pokeKey = 'pokeReact1';
  MidnightFace _pokeFace = MidnightFace.worried2;
  Timer? _pokeTimer;

  // ── 가이드 (월드 첫 판): 규칙 읽기 → "하늘색 따라 두기" ──
  List<GuideStep> _guide = const [];
  int _guideIndex = 0;
  bool get _guideActive => _guideIndex < _guide.length;
  GuideStep? get _guideStep => _guideActive ? _guide[_guideIndex] : null;
  bool get _guideReading => _guideStep?.kind == GuideKind.read;
  bool get _guideFollow => _guideStep?.kind == GuideKind.follow;
  bool get _guideSpeaking =>
      _guideActive && (_guideReading || (_game.toMove == 0 && !_aiBusy));

  // ── 패배 되감기 (종반 = 판정이 정확한 구간에서만 기록) ──
  BoardGame? _mistakeGame;
  BoardMove? _mistakeMove;
  BoardMove? _mistakeBest;
  BoardMove? _wrong;
  bool _replaying = false;

  // ── 클리어 뒤 미연시식 대화 ──
  List<DialogueLine>? _dialogue;
  String? _dialogueTitle;
  int? _dialogueScene;
  int? _pendingScene;
  bool _levelUp = false;

  // 힌트 / 전구
  BoardMove? _hint;
  bool _losing = false;

  // 스프라우트: 첫 번째로 고른 점
  int _selPoint = -1;

  double get _blunder => blunderRateForStage(widget.stageNumber);

  String get _message {
    if (_msgKey == null) return '';
    String m = s.get(_msgKey!, _msgArgs);
    if (_msgAutoHint) {
      m = '$m\n\n${TutorialManager.autoHintOnConsecutiveLoss(widget.stageNumber, s)}';
    }
    return m;
  }

  void _say(String key, [List<String> args = const [], bool autoHint = false]) {
    _msgKey = key;
    _msgArgs = args;
    _msgAutoHint = autoHint;
  }

  void _haptic([bool strong = false]) {
    if (!AppSettings.instance.haptics) return;
    strong ? HapticFeedback.mediumImpact() : HapticFeedback.selectionClick();
  }

  @override
  void initState() {
    super.initState();
    _game = BoardGame.forStage(widget.stageNumber);
    const keys = ['greetReady', 'greetWin', 'greetConfident', 'greetLetsGo'];
    final k = keys[widget.stageNumber % keys.length];
    if (k == 'greetReady') {
      _say(k, ['${widget.stageNumber}']);
    } else {
      _say(k);
    }
    _guide = TutorialManager.boardGuide(widget.stageNumber, s);
    // (2026-09-15 대표님) 선공 선택 없음 — 항상 플레이어가 먼저. 심은 예린이
    // 한 줄을 미리 그어 둔 판(BoardGame.forStage)이라 그 사실을 첫 대사로 알린다.
    _game.toMove = 0;
    if (kind == BoardKind.sim) _say('simOpening');
    _losing = _game.toMoveIsLosing();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final f in ['default', 'happy', 'sleepy', 'angry', 'smug', 'surprised']) {
      precacheImage(AssetImage('assets/midnight/$f.png'), context);
    }
  }

  @override
  void dispose() {
    _pokeTimer?.cancel();
    super.dispose();
  }

  // ── 진행 ────────────────────────────────────────────────────────────
  String get _modeTitle {
    switch (kind) {
      case BoardKind.chomp:
        return s.get('modeChomp');
      case BoardKind.dotsBoxes:
        return s.get('modeDots');
      case BoardKind.sim:
        return s.get('modeSim');
      case BoardKind.sprouts:
        return s.get('modeSprouts');
      case BoardKind.hex:
        return s.get('modeHex');
    }
  }

  String get _ruleKey {
    switch (kind) {
      case BoardKind.chomp:
        return 'ruleChomp';
      case BoardKind.dotsBoxes:
        return 'ruleDots';
      case BoardKind.sim:
        return 'ruleSim';
      case BoardKind.sprouts:
        return 'ruleSprouts';
      case BoardKind.hex:
        return 'ruleHex';
    }
  }

  List<String> get _chipKeys {
    switch (kind) {
      case BoardKind.chomp:
        return ['chipChomp1', 'chipChomp2'];
      case BoardKind.dotsBoxes:
        return ['chipDots1', 'chipDots2'];
      case BoardKind.sim:
        return ['chipSim1', 'chipSim2'];
      case BoardKind.sprouts:
        return ['chipSprouts1', 'chipSprouts2'];
      case BoardKind.hex:
        return ['chipHex1', 'chipHex2'];
    }
  }

  String get _cta {
    switch (kind) {
      case BoardKind.chomp:
        return s.get('ctaChomp');
      case BoardKind.dotsBoxes:
        return s.get('ctaDots');
      case BoardKind.sim:
        return s.get('ctaSim');
      case BoardKind.sprouts:
        return _selPoint >= 0 ? s.get('ctaSprouts2') : s.get('ctaSprouts');
      case BoardKind.hex:
        return s.get('ctaHex');
    }
  }

  String _summary() {
    if (_game is DotsBoxesGame) {
      final g = _game as DotsBoxesGame;
      return '${g.score[0]} : ${g.score[1]}';
    }
    return _game.summary();
  }

  bool get _myTurn =>
      _phase == GamePhase.playing && _game.toMove == 0 && !_aiBusy;

  /// 현재 가이드 문장 — 매 build 마다 현재 언어로 다시 읽는다.
  String get _guideText {
    final steps = TutorialManager.boardGuide(widget.stageNumber, s);
    if (_guideIndex >= steps.length) return '';
    return steps[_guideIndex].text;
  }

  void _advanceGuide() {
    setState(() {
      _guideIndex++;
      _applyGuideHighlight();
    });
  }

  /// follow 스텝이면 최선 수를 하늘색으로
  void _applyGuideHighlight() {
    if (_guideFollow && _game.toMove == 0 && !_game.isOver) _hint = _game.bestMove();
  }

  /// 플레이어 수 직전 — 종반(판정 정확)에서 이기던 판을 지는 판으로 만들면 기록.
  void _recordPlayerMove(BoardMove m) {
    if (_mistakeMove != null || !_game.inEndgame()) return;
    if (_game.toMoveIsLosing()) return;
    final best = _game.bestMove();
    final after = _game.clone()..apply(m);
    if (after.isOver || after.toMove != 1) return; // 끝났거나 "한 번 더" — 판정 생략
    if (!after.toMoveIsLosing()) {
      _mistakeGame = _game.clone();
      _mistakeMove = m;
      _mistakeBest = best;
    }
  }

  void _startReplay() {
    final g = _mistakeGame;
    if (g == null) {
      setState(() {
        _replaying = true;
        _face = MidnightFace.neutral;
        _say('replayNone');
      });
      return;
    }
    _haptic();
    setState(() {
      _replaying = true;
      _game = g.clone();
      _hint = _mistakeBest;
      _wrong = _mistakeMove;
      _selPoint = -1;
      _face = MidnightFace.confident;
      _say('replayHintBoard');
    });
  }

  /// 판 위를 눌렀을 때 — 종류별로 "수" 로 바뀐 것이 들어온다.
  void _onBoardMove(BoardMove m) {
    if (!_myTurn || _guideReading) return;
    if (!_game.legalMoves().contains(m)) return;
    if (_guideFollow && _hint != null && m != _hint) return; // 가이드: 하늘색만
    _recordPlayerMove(m);
    _haptic(true);
    SfxService.instance.playTake();
    final bool wasDots = _game is DotsBoxesGame;
    final int before = wasDots ? (_game as DotsBoxesGame).score[0] : 0;
    setState(() {
      _hint = null;
      _selPoint = -1;
      _game.apply(m);
      _turnCount++;
    });
    if (_game.isOver) {
      _endGame(_game.winner == 0);
      return;
    }
    if (_game.toMove == 0) {
      // 점과 상자: 상자를 먹어서 한 번 더
      setState(() {
        _say('dotsExtraTurn');
        _face = MidnightFace.worried1;
        _applyGuideHighlight();
      });
      return;
    }
    if (wasDots && (_game as DotsBoxesGame).score[0] > before) {
      // (안전장치) 먹었는데 턴이 넘어간 경우는 없음
    }
    setState(() => _face = MidnightFace.thinking);
    Future.delayed(const Duration(milliseconds: 900), _aiPlay);
  }

  void _aiPlay() {
    if (!mounted || _phase != GamePhase.playing || _game.toMove != 1) return;
    setState(() => _aiBusy = true);
    final m = _game.aiMove(_blunder);
    if (m.a < 0) {
      setState(() => _aiBusy = false);
      return;
    }
    SfxService.instance.playTake();
    setState(() {
      _game.apply(m);
      _turnCount++;
    });
    if (_game.isOver) {
      setState(() => _aiBusy = false);
      _endGame(_game.winner == 0);
      return;
    }
    if (_game.toMove == 1) {
      // 점과 상자: 예린이 상자를 먹어 한 번 더
      setState(() {
        _say('midnightWinEarly3');
        _face = MidnightFace.happy1;
      });
      Future.delayed(const Duration(milliseconds: 650), () {
        if (mounted) _aiPlay();
      });
      return;
    }
    setState(() {
      _aiBusy = false;
      _applyGuideHighlight();
    });
    _refreshLosing();
    _updateExpressionForPlayerTurn();
  }

  void _refreshLosing() {
    final lose = _phase == GamePhase.playing &&
        _game.toMove == 0 &&
        _game.toMoveIsLosing();
    if (lose != _losing && mounted) setState(() => _losing = lose);
  }

  void _updateExpressionForPlayerTurn() {
    final bool midnightWins = _losing;
    setState(() {
      if (midnightWins) {
        _lossTurns++;
        if (_lossTurns >= 2) {
          _face = MidnightFace.confident;
          const keys = ['midnightWinLate1', 'midnightWinLate2', 'midnightWinLate3'];
          _say(keys[_turnCount % keys.length]);
        } else {
          _face = MidnightFace.happy1;
          const keys = ['midnightWinEarly1', 'midnightWinEarly2', 'midnightWinEarly3'];
          _say(keys[_turnCount % keys.length]);
        }
      } else {
        _lossTurns = 0;
        _face = MidnightFace.neutral;
        _say('yourTurnNow');
      }
    });
  }

  void _endGame(bool playerWins) {
    _haptic(playerWins);
    setState(() {
      _phase = GamePhase.gameOver;
      _playerWon = playerWins;
      _hint = null;
      _selPoint = -1;
      if (playerWins) {
        _face = MidnightFace.worried2;
        _say('midnightLost');
        _defeats = 0;
      } else {
        _face = MidnightFace.happy2;
        _defeats++;
        final bool autoHint =
            _defeats >= 2 && TutorialManager.isTutorialStage(widget.stageNumber);
        _say('midnightWon', const [], autoHint);
      }
    });
    if (playerWins) {
      final int levelBefore = widget.stageManager.affinityLevel;
      final int nth = widget.stageManager.worldClears(widget.stageNumber);
      widget.stageManager.clearStage(widget.stageNumber).then((_) {
        if (!mounted) return;
        _levelUp = widget.stageManager.affinityLevel > levelBefore;
      });
      AdService.instance.maybeShowInterstitialOnStageClear();
      Future.delayed(const Duration(milliseconds: 1100), () {
        if (!mounted) return;
        setState(() {
          _dialogue = [Dialogue.afterClear(widget.stageNumber, nth, s)];
          _dialogueTitle = null;
          _dialogueScene = null;
          _pendingScene = widget.stageManager.pendingScene;
        });
      });
    }
  }

  void _onDialogueDone() {
    final int? scene = _pendingScene;
    if (_dialogueScene != null) widget.stageManager.markSceneSeen(_dialogueScene!);
    if (scene != null && _dialogueScene == null) {
      setState(() {
        _dialogue = Dialogue.scene(scene, s);
        _dialogueTitle = Dialogue.sceneTitle(scene, s);
        _dialogueScene = scene;
        _pendingScene = null;
      });
      return;
    }
    setState(() {
      _dialogue = null;
      _dialogueTitle = null;
      _dialogueScene = null;
    });
    _showNextStageDialog();
  }

  Widget _affinityLine() {
    final sm = widget.stageManager;
    final String next = sm.pointsToNextLevel > 0
        ? s.get('affinityNext', ['${sm.pointsToNextLevel}'])
        : s.get('affinityMax');
    return Column(mainAxisSize: MainAxisSize.min, children: [
      if (_levelUp)
        Text(s.get('affinityUp'),
            style: const TextStyle(
                fontFamily: _mono,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: _P.alarm,
                decoration: TextDecoration.none)),
      Text(
        '♥ ${s.get('affinityLabel')} ${s.get('affinityLevel', ['${sm.affinityLevel}'])} · $next',
        textAlign: TextAlign.center,
        style: const TextStyle(
            fontFamily: _mono,
            fontSize: 12,
            color: _P.inkSoft,
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.none),
      ),
    ]);
  }

  void _showNextStageDialog() {
    final bool hasNext = widget.stageNumber < kTotalStages;
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black38, // 뒤의 예린 얼굴이 비치게
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, a1, a2, child) => Transform.scale(
        scale: Curves.elasticOut.transform(a1.value),
        child: Opacity(opacity: a1.value, child: child),
      ),
      // 팝업은 아래쪽(책상 자리) — 위쪽 예린 얼굴을 가리지 않는다
      pageBuilder: (context, _, __) => Align(
        alignment: const Alignment(0, 0.62),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _P.paper,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _P.frame, width: 3),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 24, spreadRadius: 2),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: _P.win, width: 3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  s.get('stageClear'),
                  style: const TextStyle(
                    fontFamily: _mono,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: _P.win,
                    letterSpacing: 2,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                s.get('stageClearDesc', ['${widget.stageNumber}']),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: _mono,
                  fontSize: 13,
                  color: _P.inkSoft,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
              // 클리어 팝업엔 예린 그림 없음 — 뒤의 큰 예린이 보이게
              const SizedBox(height: 8),
              _affinityLine(),
              const SizedBox(height: 20),
              if (hasNext) ...[
                SizedBox(
                  width: double.infinity,
                  child: _Stamp(
                    label: s.get('nextStage'),
                    color: _P.gold,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
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
                    foregroundColor: _P.inkSoft,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(s.get('backToStageSelect'),
                      style: const TextStyle(fontFamily: _mono, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 힌트 (광고) ───────────────────────────────────────────────────────
  void _showHint() {
    if (!_myTurn) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _P.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text(s.get('hintDialogTitle'),
            style: const TextStyle(
                fontFamily: _mono,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _P.ink)),
        content: Text(s.get('hintDialogBody'),
            style: const TextStyle(
                fontFamily: _mono,
                fontSize: 13.5,
                color: _P.inkSoft,
                fontWeight: FontWeight.w600)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.get('cancel'),
                style: const TextStyle(fontFamily: _mono, color: _P.inkSoft)),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
                backgroundColor: _P.gold, foregroundColor: _P.ink),
            icon: const Icon(Icons.ondemand_video_rounded, size: 18),
            label: Text(s.get('hintWatchAd'),
                style: const TextStyle(
                    fontFamily: _mono, fontWeight: FontWeight.w800)),
            onPressed: () {
              Navigator.pop(ctx);
              final shown =
                  AdService.instance.showRewardedAd(onReward: _revealHint);
              if (!shown) _revealHint();
            },
          ),
        ],
      ),
    );
  }

  void _revealHint() {
    if (!mounted || !_myTurn) return;
    final bool losing = _game.toMoveIsLosing();
    String text;
    if (losing) {
      text = s.get('hintLosingRetry');
    } else {
      final m = _game.bestMove();
      setState(() => _hint = m);
      text = s.get('hintBoard');
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text, style: const TextStyle(fontFamily: _mono, fontSize: 14)),
      backgroundColor: losing ? _P.alarm : _P.hint,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      duration: Duration(seconds: losing ? 5 : 3),
    ));
  }

  void _showModeRules() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _P.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Row(children: [
          const Icon(Icons.help_outline_rounded, color: _P.ink),
          const SizedBox(width: 8),
          Expanded(
              child: Text(_modeTitle,
                  style: const TextStyle(
                      fontFamily: _mono,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: _P.ink))),
        ]),
        content: Text(s.get(_ruleKey),
            style: const TextStyle(
                fontFamily: _mono,
                fontSize: 14,
                height: 1.5,
                color: _P.ink,
                fontWeight: FontWeight.w600)),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: _P.gold, foregroundColor: _P.ink),
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.get('ok'),
                style: const TextStyle(
                    fontFamily: _mono, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _pokeYerin() {
    _haptic();
    const reactions = [
      ('pokeReact1', MidnightFace.worried2),
      ('pokeReact2', MidnightFace.worried1),
      ('pokeReact3', MidnightFace.confident),
    ];
    final pick = reactions[math.Random().nextInt(reactions.length)];
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

  // ── 화면 ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final WorldInfo w = worldForStage(widget.stageNumber);
    return Scaffold(
      backgroundColor: _P.deskBottom,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_P.deskTop, _P.deskBottom],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            _topBar(),
            Expanded(
              child: Stack(children: [
                _gameBoard(w),
                if (_guideReading) _guideOverlay(),
                if (_dialogue != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: DialogueBox(
                      key: ValueKey(_dialogueScene ?? -1),
                      lines: _dialogue!,
                      speaker: s.get('nameMidnight'),
                      title: _dialogueTitle,
                      onFace: (f) => setState(() => _face = f),
                      onDone: _onDialogueDone,
                    ),
                  ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  /// 상단 바 — (2026-09-15 정보 다이어트) 뒤로 / 스테이지 번호 / 힌트 전구 / 메뉴.
  Widget _topBar() {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: _P.frame,
        border: Border(bottom: BorderSide(color: _P.frameHi, width: 2)),
      ),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: _P.cream, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        Text(s.get('stageLabel', ['${widget.stageNumber}']),
            style: const TextStyle(
                fontFamily: _mono,
                color: _P.cream,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: 1.5)),
        const Spacer(),
        if (_phase == GamePhase.playing && _game.toMove == 0)
          _Bulb(urgent: false, onTap: _showHint, tooltip: s.get('hintDialogTitle')),
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.only(right: 10),
          icon: const Icon(Icons.menu_rounded, size: 22, color: _P.cream),
          tooltip: s.get('menuTitle'),
          onPressed: _showMenu,
        ),
      ]),
    );
  }

  /// 게임 중 메뉴 — 규칙 / 설정 / 스테이지 선택으로.
  void _showMenu() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _P.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: _P.frame, width: 3),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Stamp(
                label: s.get('rulesTitle'),
                icon: Icons.help_outline_rounded,
                color: _P.frameHi,
                onTap: () {
                  Navigator.pop(ctx);
                  _showModeRules();
                },
              ),
              const SizedBox(height: 10),
              _Stamp(
                label: s.get('settings'),
                icon: Icons.settings_rounded,
                color: _P.frameHi,
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
              _Stamp(
                label: s.get('backToStageSelect'),
                icon: Icons.grid_view_rounded,
                color: _P.frame,
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(s.get('menuResume'),
                    style: const TextStyle(
                        fontFamily: _mono, color: _P.inkSoft, fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// (2026-09-15 정보 다이어트) 턴 배너 삭제 — 결과 도장만 승리/패배 순간에 찍힌다.
  Widget _turnStamp() {
    if (_phase != GamePhase.gameOver || _replaying || _dialogue != null) {
      return const SizedBox.shrink();
    }
    final Color c = _playerWon ? _P.win : _P.alarm;
    final stamp = Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: c, width: 2.5),
          borderRadius: BorderRadius.circular(6),
          color: _P.deskBottom.withOpacity(0.88),
        ),
        child: Text((_playerWon ? s.get('victory') : s.get('defeat')).toUpperCase(),
            style: TextStyle(
                fontFamily: _mono,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                color: c)),
      ),
    );
    if (_playerWon) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
        builder: (_, v, child) => Transform.scale(
            scale: 2.2 - 1.2 * v.clamp(0.0, 1.0),
            child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
        child: stamp,
      );
    }
    return stamp;
  }

  /// (2026-09-15 정보 다이어트) 규칙 칩 하나. 점과 상자는 점수(나 : 예린)를 덧붙인다.
  Widget _chips() {
    final keys = _chipKeys;
    String text = '${s.get(keys[0])} · ${s.get(keys[1])}';
    if (_game is DotsBoxesGame) text = '$text · ${_summary()}';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _P.deskBottom,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _P.frameHi, width: 1.5),
      ),
      child: Text(text,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontFamily: _mono,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _P.cream)),
    );
  }

  Widget _gameBoard(WorldInfo w) {
    return Column(children: [
      _deskScene(w, overlay: _turnStamp()),
      Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: _chips()),
      if (_phase == GamePhase.playing) _actionArea(),
      if (_phase == GamePhase.gameOver && !_playerWon)
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            if (!_replaying) ...[
              Expanded(
                child: _Stamp(
                  label: s.get('whyLost'),
                  color: _P.hint,
                  icon: Icons.replay_rounded,
                  onTap: _startReplay,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: _Stamp(
                label: s.get('retry'),
                color: _P.frameHi,
                icon: Icons.refresh,
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BoardGameScreen(
                      stageManager: widget.stageManager,
                      stageNumber: widget.stageNumber,
                      localeProvider: widget.localeProvider,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Stamp(
                  label: s.get('goBack'),
                  color: _P.frame,
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.pop(context)),
            ),
          ]),
        ),
    ]);
  }

  Widget _actionArea() {
    final bool my = _myTurn;
    return IgnorePointer(
      ignoring: !my,
      child: Opacity(
        opacity: my ? 1.0 : 0.45,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          constraints: const BoxConstraints(minHeight: 84),
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: _P.frame,
            border: Border(top: BorderSide(color: _P.frameHi, width: 2)),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _P.frameHi, width: 1.5),
            ),
            child: Text(_cta,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: _mono,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _P.cream)),
          ),
        ),
      ),
    );
  }

  Widget _deskScene(WorldInfo w, {required Widget overlay}) {
    return Expanded(
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned.fill(
          child: Image.asset(
            'assets/backgrounds/world${w.id}.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (_, __, ___) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: w.bgGradient,
                ),
              ),
            ),
          ),
        ),
        // 예린 — 얼굴이 크게. 아래는 책상에 잘려도 됨 (game_screen 과 동일 규칙)
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
        // 말풍선 — 튜토리얼 중엔 튜토리얼 문장 (화면에 예린은 한 명)
        Positioned(
          top: 46,
          left: 24,
          right: 24,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 330),
              child: _dialogue != null
                  ? const SizedBox.shrink()
                  : _bubble(_poked
                      ? s.get(_pokeKey)
                      : (_guideSpeaking ? _guideText : _message)),
            ),
          ),
        ),
        Positioned(top: 4, left: 10, right: 10, child: overlay),
        Positioned(
          top: _kDeskTop,
          bottom: 0,
          left: 28,
          right: 28,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _P.deskWoodDark, width: 3),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4)),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(children: [
              Positioned.fill(child: CustomPaint(painter: _DeskPainter())),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: _BoardView(
                    game: _game,
                    hint: _hint,
                    wrong: _wrong,
                    selPoint: _selPoint,
                    enabled: _myTurn && !_guideReading,
                    onMove: _onBoardMove,
                    onSelectPoint: (i) => setState(() => _selPoint = i),
                  ),
                ),
              ),
              if (_phase == GamePhase.gameOver && _playerWon)
                const Positioned.fill(child: IgnorePointer(child: _WinBurst())),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _catFigure({double size = 110}) {
    return SizedBox(
      width: size * 1.25,
      height: size + 10,
      child: Stack(alignment: Alignment.bottomCenter, children: [
        Center(
          child: Container(
            width: size * 1.2,
            height: size * 1.2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFFEADFC6).withOpacity(0.30),
                const Color(0xFFC9A24B).withOpacity(0.12),
                Colors.transparent,
              ], stops: const [0.0, 0.45, 0.78]),
            ),
          ),
        ),
        Positioned(
          bottom: 2,
          child: Container(
            width: size * 0.5,
            height: 9,
            decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20)),
          ),
        ),
        MidnightCharacter(
            face: _poked
                ? _pokeFace
                : (_guideReading ? MidnightFace.happy1 : _face),
            size: size,
            animate: false),
      ]),
    );
  }

  Widget _bubble(String message) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Container(
          key: ValueKey(message),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: _P.paper,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _P.frame, width: 2),
          ),
          child: Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: _mono, fontSize: 14, height: 1.35, color: _P.ink)),
        ),
      ),
      CustomPaint(size: const Size(16, 9), painter: _TailDown()),
    ]);
  }

  /// 읽기 스텝 오버레이 — 책상 아래만 어둡게 + 다음 버튼 (예린은 한 명, 문장은 말풍선에)
  Widget _guideOverlay() {
    final bool isLast = _guideIndex == _guide.length - 1;
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _advanceGuide,
        child: Column(children: [
          const SizedBox(height: _kDeskTop + 4),
          Expanded(
            child: Container(
              color: Colors.black.withOpacity(0.66),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _Stamp(
                    label: isLast ? s.get('tutStart') : s.get('tutNext'),
                    color: _P.gold,
                    onTap: _advanceGuide),
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
                          color: active ? _P.gold : _P.cream.withOpacity(0.4),
                          shape: BoxShape.circle),
                    );
                  }),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 판 위젯 — 그리기와 탭 판정이 같은 기하(_Layout)를 쓴다.
// ═══════════════════════════════════════════════════════════════════════════
class _BoardView extends StatelessWidget {
  final BoardGame game;
  final BoardMove? hint;
  final BoardMove? wrong; // 되감기: 실수한 수 (빨강)
  final int selPoint;
  final bool enabled;
  final void Function(BoardMove) onMove;
  final void Function(int) onSelectPoint;

  const _BoardView({
    required this.game,
    required this.hint,
    this.wrong,
    required this.selPoint,
    required this.enabled,
    required this.onMove,
    required this.onSelectPoint,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, cons) {
      final size = Size(cons.maxWidth, cons.maxHeight);
      final lay = _Layout(game, size);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: !enabled
            ? null
            : (d) {
                final p = d.localPosition;
                if (game is SproutsGame) {
                  final i = lay.hitPoint(p);
                  if (i < 0) return;
                  final g = game as SproutsGame;
                  if (selPoint < 0) {
                    if (g.deg[i] < 3) onSelectPoint(i);
                  } else if (i == selPoint) {
                    onSelectPoint(-1);
                  } else {
                    final a = math.min(selPoint, i), b = math.max(selPoint, i);
                    if (g.isLegal(a, b)) {
                      onMove(BoardMove(a, b));
                    } else if (g.deg[i] < 3) {
                      onSelectPoint(i);
                    }
                  }
                  return;
                }
                final m = lay.hitMove(p);
                if (m != null) onMove(m);
              },
        child: CustomPaint(
          size: size,
          painter: _BoardPainter(game, lay, hint, selPoint, wrong),
        ),
      );
    });
  }
}

class _Layout {
  final BoardGame g;
  final Size size;
  _Layout(this.g, this.size);

  double get w => size.width;
  double get h => size.height;

  // ── 춉
  double get cCell {
    final c = g as ChompGame;
    return math.min((w - 8) / c.colsN, (h - 8) / c.rowsN).clamp(16.0, 56.0);
  }

  Offset get cOrigin {
    final c = g as ChompGame;
    return Offset((w - cCell * c.colsN) / 2, (h - cCell * c.rowsN) / 2);
  }

  Rect chompRect(int r, int c) => Rect.fromLTWH(
      cOrigin.dx + c * cCell + 2, cOrigin.dy + r * cCell + 2, cCell - 4, cCell - 4);

  // ── 점과 상자
  double get dGap {
    final d = g as DotsBoxesGame;
    return math.min((w - 28) / d.C, (h - 28) / d.R).clamp(22.0, 90.0);
  }

  Offset get dOrigin {
    final d = g as DotsBoxesGame;
    return Offset((w - dGap * d.C) / 2, (h - dGap * d.R) / 2);
  }

  Offset dot(int r, int c) => dOrigin + Offset(c * dGap, r * dGap);

  List<Offset> edgeEnds(int e) {
    final d = g as DotsBoxesGame;
    if (d.isH(e)) {
      final r = e ~/ d.C, c = e % d.C;
      return [dot(r, c), dot(r, c + 1)];
    }
    final k = e - d.hCount;
    final r = k ~/ (d.C + 1), c = k % (d.C + 1);
    return [dot(r, c), dot(r + 1, c)];
  }

  // ── 심
  Offset get sCenter => Offset(w / 2, h / 2);
  double get sR => math.min(w, h) * 0.42 - 6;
  Offset simPt(int i) {
    final a = -math.pi / 2 + i * math.pi / 3;
    return sCenter + Offset(sR * math.cos(a), sR * math.sin(a));
  }

  // ── 스프라우트
  Offset sproutPt(int i) {
    final sp = g as SproutsGame;
    return Offset(16 + sp.px[i] * (w - 32), 16 + sp.py[i] * (h - 32));
  }

  // ── 헥스 (뾰족한 꼭짓점이 위)
  double get hw {
    final n = (g as HexGame).n;
    final byW = (w - 10) / (n + (n - 1) * 0.5);
    final byH = (h - 10) / ((1 + (n - 1) * 0.75) * 1.1547);
    return math.min(byW, byH);
  }

  double get hh => hw * 1.1547;

  Offset get hOrigin {
    final n = (g as HexGame).n;
    final totalW = hw * (n + (n - 1) * 0.5);
    final totalH = hh * (1 + (n - 1) * 0.75);
    return Offset((w - totalW) / 2, (h - totalH) / 2);
  }

  Offset hexCenter(int r, int c) =>
      hOrigin + Offset(hw / 2 + c * hw + r * hw / 2, hh / 2 + r * hh * 0.75);

  Path hexPath(Offset c) {
    final p = Path();
    for (int i = 0; i < 6; i++) {
      final a = -math.pi / 2 + i * math.pi / 3;
      final pt = c + Offset(hw / 2 * 0.96 * math.cos(a), hh / 2 * 0.96 * math.sin(a));
      if (i == 0) {
        p.moveTo(pt.dx, pt.dy);
      } else {
        p.lineTo(pt.dx, pt.dy);
      }
    }
    p.close();
    return p;
  }

  static double _distSeg(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final t = ((p - a).dx * ab.dx + (p - a).dy * ab.dy) / (ab.dx * ab.dx + ab.dy * ab.dy);
    final tt = t.clamp(0.0, 1.0);
    return (p - (a + ab * tt)).distance;
  }

  /// 탭 위치 → 수. 없으면 null.
  BoardMove? hitMove(Offset p) {
    if (g is ChompGame) {
      final c = g as ChompGame;
      final cx = ((p.dx - cOrigin.dx) / cCell).floor();
      final cy = ((p.dy - cOrigin.dy) / cCell).floor();
      if (cx < 0 || cy < 0 || cx >= c.colsN || cy >= c.rowsN) return null;
      if (!c.cellAlive(cy, cx)) return null;
      return BoardMove(cy, cx);
    }
    if (g is DotsBoxesGame) {
      final d = g as DotsBoxesGame;
      int best = -1;
      double bestD = dGap * 0.42;
      for (int e = 0; e < d.edgeCount; e++) {
        if (d.drawn[e]) continue;
        final ends = edgeEnds(e);
        final dist = _distSeg(p, ends[0], ends[1]);
        if (dist < bestD) {
          bestD = dist;
          best = e;
        }
      }
      return best < 0 ? null : BoardMove(best);
    }
    if (g is SimGame) {
      final sg = g as SimGame;
      int best = -1;
      double bestD = 16;
      for (int e = 0; e < 15; e++) {
        if (sg.color[e] >= 0) continue;
        final a = SimGame.edges[e];
        final dist = _distSeg(p, simPt(a[0]), simPt(a[1]));
        if (dist < bestD) {
          bestD = dist;
          best = e;
        }
      }
      return best < 0 ? null : BoardMove(best);
    }
    if (g is HexGame) {
      final hx = g as HexGame;
      int best = -1;
      double bestD = hw * 0.5;
      for (int i = 0; i < hx.cells.length; i++) {
        final dist = (p - hexCenter(i ~/ hx.n, i % hx.n)).distance;
        if (dist < bestD) {
          bestD = dist;
          best = i;
        }
      }
      if (best < 0 || hx.cells[best] >= 0) return null;
      return BoardMove(best);
    }
    return null;
  }

  int hitPoint(Offset p) {
    final sp = g as SproutsGame;
    int best = -1;
    double bestD = 26;
    for (int i = 0; i < sp.pointCount; i++) {
      final d = (p - sproutPt(i)).distance;
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }
}

class _BoardPainter extends CustomPainter {
  final BoardGame g;
  final _Layout lay;
  final BoardMove? hint;
  final int selPoint;
  final BoardMove? wrong;
  _BoardPainter(this.g, this.lay, this.hint, this.selPoint, [this.wrong]);

  bool _isWrong(int a, [int b = 0]) => wrong != null && wrong!.a == a && wrong!.b == b;

  static const Color _me = _P.gold;
  static const Color _ai = _P.alarmHi;

  @override
  void paint(Canvas canvas, Size size) {
    if (g is ChompGame) return _chomp(canvas);
    if (g is DotsBoxesGame) return _dots(canvas);
    if (g is SimGame) return _sim(canvas);
    if (g is SproutsGame) return _sprouts(canvas);
    if (g is HexGame) return _hex(canvas);
  }

  void _text(Canvas c, String t, Offset center, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(
          text: t,
          style: TextStyle(fontSize: size, color: color, fontFamily: _mono,
              fontWeight: FontWeight.w800)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _chomp(Canvas c) {
    final g0 = g as ChompGame;
    for (int r = 0; r < g0.rowsN; r++) {
      for (int col = 0; col < g0.colsN; col++) {
        final rect = lay.chompRect(r, col);
        final rr = RRect.fromRectAndRadius(rect, const Radius.circular(5));
        if (!g0.cellAlive(r, col)) {
          c.drawRRect(rr, Paint()..color = _P.deskWoodDark.withOpacity(0.18));
          continue;
        }
        final poison = r == 0 && col == 0;
        c.drawRRect(rr, Paint()..color = poison ? _P.alarm : _P.choco);
        c.drawRRect(
            rr.deflate(3),
            Paint()
              ..color = poison ? _P.alarmHi : _P.chocoHi
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5);
        if (poison) _text(c, '☠', rect.center, rect.width * 0.5, _P.cream);
        if (hint != null && hint!.a == r && hint!.b == col) {
          c.drawRRect(
              rr.inflate(2),
              Paint()
                ..color = _P.sky
                ..style = PaintingStyle.stroke
                ..strokeWidth = 4);
        }
        if (_isWrong(r, col)) {
          c.drawRRect(
              rr.inflate(2),
              Paint()
                ..color = _P.alarmHi
                ..style = PaintingStyle.stroke
                ..strokeWidth = 4);
        }
      }
    }
  }

  void _dots(Canvas c) {
    final d = g as DotsBoxesGame;
    final gap = lay.dGap;
    // 상자
    for (int r = 0; r < d.R; r++) {
      for (int col = 0; col < d.C; col++) {
        final o = d.owner[r * d.C + col];
        if (o < 0) continue;
        final rect = Rect.fromPoints(lay.dot(r, col), lay.dot(r + 1, col + 1)).deflate(gap * 0.14);
        c.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)),
            Paint()..color = (o == 0 ? _me : _ai).withOpacity(0.55));
      }
    }
    // 변
    for (int e = 0; e < d.edgeCount; e++) {
      final ends = lay.edgeEnds(e);
      final isHint = hint != null && hint!.a == e;
      final isWrong = _isWrong(e);
      final paint = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = d.drawn[e] ? 4 : ((isHint || isWrong) ? 4 : 2)
        ..color = d.drawn[e]
            ? _P.ink
            : isWrong
                ? _P.alarmHi
                : (isHint ? _P.sky : _P.deskWoodDark.withOpacity(0.35));
      c.drawLine(ends[0], ends[1], paint);
    }
    // 점
    for (int r = 0; r <= d.R; r++) {
      for (int col = 0; col <= d.C; col++) {
        c.drawCircle(lay.dot(r, col), 4.5, Paint()..color = _P.ink);
      }
    }
  }

  void _sim(Canvas c) {
    final sg = g as SimGame;
    // 진 쪽 삼각형 찾기 (끝났을 때만)
    Set<int> tri = {};
    if (sg.isOver && sg.winner != null) {
      final loser = 1 - sg.winner!;
      outer:
      for (int a = 0; a < 6; a++) {
        for (int b = a + 1; b < 6; b++) {
          for (int k = b + 1; k < 6; k++) {
            final e1 = SimGame.edgeIndex(a, b), e2 = SimGame.edgeIndex(b, k), e3 = SimGame.edgeIndex(a, k);
            if (sg.color[e1] == loser && sg.color[e2] == loser && sg.color[e3] == loser) {
              tri = {e1, e2, e3};
              break outer;
            }
          }
        }
      }
    }
    for (int e = 0; e < 15; e++) {
      final a = SimGame.edges[e];
      final p1 = lay.simPt(a[0]), p2 = lay.simPt(a[1]);
      final col = sg.color[e];
      final isHint = hint != null && hint!.a == e;
      final isWrong = _isWrong(e);
      if (tri.contains(e)) {
        c.drawLine(p1, p2, Paint()
          ..color = _P.alarmHi.withOpacity(0.45)
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round);
      }
      c.drawLine(
          p1,
          p2,
          Paint()
            ..strokeCap = StrokeCap.round
            ..strokeWidth = col >= 0 ? 4.5 : ((isHint || isWrong) ? 4 : 2)
            ..color = col == 0
                ? _me
                : col == 1
                    ? _ai
                    : isWrong
                        ? _P.alarmHi
                        : (isHint ? _P.sky : _P.deskWoodDark.withOpacity(0.45)));
    }
    for (int i = 0; i < 6; i++) {
      c.drawCircle(lay.simPt(i), 8, Paint()..color = _P.ink);
      c.drawCircle(lay.simPt(i), 8, Paint()
        ..color = _P.cream
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
    }
  }

  void _sprouts(Canvas c) {
    final sp = g as SproutsGame;
    for (final sgm in sp.segs) {
      c.drawLine(lay.sproutPt(sgm[0]), lay.sproutPt(sgm[1]), Paint()
        ..color = _P.ink
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round);
    }
    // 선택했을 때 이을 수 있는 점 표시
    final legal = <int>{};
    if (selPoint >= 0) {
      for (int j = 0; j < sp.pointCount; j++) {
        if (j == selPoint) continue;
        if (sp.isLegal(math.min(selPoint, j), math.max(selPoint, j))) legal.add(j);
      }
    }
    for (int i = 0; i < sp.pointCount; i++) {
      final p = lay.sproutPt(i);
      final dead = sp.deg[i] >= 3;
      final r = i < 5 && sp.segs.isEmpty ? 9.0 : 7.5;
      c.drawCircle(p, r, Paint()..color = dead ? _P.deskWoodDark : _P.cream);
      c.drawCircle(p, r, Paint()
        ..color = dead ? _P.deskWoodDark : _P.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5);
      if (i == selPoint) {
        c.drawCircle(p, r + 6, Paint()
          ..color = _me
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
      } else if (legal.contains(i)) {
        c.drawCircle(p, 4, Paint()..color = _me);
      }
      if (hint != null && (hint!.a == i || hint!.b == i)) {
        c.drawCircle(p, r + 6, Paint()
          ..color = _P.sky
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
      }
    }
    if (hint != null) {
      c.drawLine(lay.sproutPt(hint!.a), lay.sproutPt(hint!.b), Paint()
        ..color = _P.sky.withOpacity(0.7)
        ..strokeWidth = 3);
    }
    if (wrong != null) {
      c.drawLine(lay.sproutPt(wrong!.a), lay.sproutPt(wrong!.b), Paint()
        ..color = _P.alarmHi.withOpacity(0.7)
        ..strokeWidth = 3);
    }
  }

  void _hex(Canvas c) {
    final hx = g as HexGame;
    final n = hx.n;
    // 목표 변 표시 — 나(좌우)=금색, 예린(위아래)=빨강
    final tl = lay.hexCenter(0, 0) + Offset(-lay.hw / 2, -lay.hh / 2);
    final tr = lay.hexCenter(0, n - 1) + Offset(lay.hw / 2, -lay.hh / 2);
    final bl = lay.hexCenter(n - 1, 0) + Offset(-lay.hw / 2, lay.hh / 2);
    final br = lay.hexCenter(n - 1, n - 1) + Offset(lay.hw / 2, lay.hh / 2);
    final edge = Paint()
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    c.drawLine(tl, tr, edge..color = _ai.withOpacity(0.8));
    c.drawLine(bl, br, edge..color = _ai.withOpacity(0.8));
    c.drawLine(tl, bl, edge..color = _me.withOpacity(0.9));
    c.drawLine(tr, br, edge..color = _me.withOpacity(0.9));
    for (int i = 0; i < hx.cells.length; i++) {
      final center = lay.hexCenter(i ~/ n, i % n);
      final path = lay.hexPath(center);
      final v = hx.cells[i];
      c.drawPath(path, Paint()
        ..color = v == 0 ? _me : (v == 1 ? _ai : _P.cream.withOpacity(0.85)));
      c.drawPath(path, Paint()
        ..color = _P.ink.withOpacity(0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2);
      if (hint != null && hint!.a == i) {
        c.drawPath(path, Paint()
          ..color = _P.sky
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5);
      }
      if (_isWrong(i)) {
        c.drawPath(path, Paint()
          ..color = _P.alarmHi
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// 공통 소품 (game_screen.dart 와 동일한 룩)
// ═══════════════════════════════════════════════════════════════════════════
class _DeskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _P.deskWood);
    final grain = Paint()
      ..color = _P.deskWoodDark.withOpacity(0.35)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final rnd = math.Random(7);
    for (int i = 0; i < 14; i++) {
      final y = size.height * (0.08 + 0.9 * rnd.nextDouble());
      final x0 = size.width * (0.05 + 0.25 * rnd.nextDouble());
      final len = size.width * (0.15 + 0.45 * rnd.nextDouble());
      final bow = 2.0 + rnd.nextDouble() * 3.0;
      canvas.drawPath(
          Path()
            ..moveTo(x0, y)
            ..quadraticBezierTo(x0 + len / 2, y + bow, x0 + len, y),
          grain);
    }
    canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, _P.deskWoodDark.withOpacity(0.25)],
            stops: const [0.75, 1.0],
          ).createShader(Offset.zero & size));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TailDown extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0);
    canvas.drawPath(path, Paint()..color = _P.paper);
    canvas.drawPath(
        path,
        Paint()
          ..color = _P.frame
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Stamp extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final VoidCallback onTap;
  const _Stamp({required this.label, required this.color, required this.onTap, this.icon});

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
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (icon != null) ...[
              Icon(icon, color: _P.cream, size: 18),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontFamily: _mono,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: _P.cream)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _WinBurst extends StatelessWidget {
  const _WinBurst();
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOut,
      builder: (_, t, __) => Stack(
        alignment: Alignment.center,
        children: List.generate(8, (i) {
          final a = i * math.pi / 4 + 0.4;
          final r = 30 + 90 * t;
          return Transform.translate(
            offset: Offset(math.cos(a) * r, math.sin(a) * r * 0.7),
            child: Opacity(
              opacity: (1 - t).clamp(0.0, 1.0),
              child: Text(i.isEven ? '✦' : '⭐',
                  style: TextStyle(fontSize: 16 + 8 * t, color: _P.gold)),
            ),
          );
        }),
      ),
    );
  }
}

class _Bulb extends StatefulWidget {
  final bool urgent;
  final VoidCallback onTap;
  final String tooltip;
  const _Bulb({required this.urgent, required this.onTap, required this.tooltip});
  @override
  State<_Bulb> createState() => _BulbState();
}

class _BulbState extends State<_Bulb> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(duration: const Duration(milliseconds: 780), vsync: this);
    if (widget.urgent) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _Bulb old) {
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
        icon: const Icon(Icons.lightbulb_outline, size: 20, color: _P.gold),
        tooltip: widget.tooltip,
      );
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_c.value);
        return IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: widget.onTap,
          tooltip: widget.tooltip,
          icon: Container(
            decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
              BoxShadow(
                  color: _P.gold.withOpacity(0.30 + 0.45 * t),
                  blurRadius: 8 + 12 * t,
                  spreadRadius: 1 + 3 * t),
            ]),
            child: Transform.scale(
              scale: 1.0 + 0.22 * t,
              child: Icon(Icons.lightbulb,
                  size: 20, color: Color.lerp(_P.gold, const Color(0xFFFFF1B8), t)),
            ),
          ),
        );
      },
    );
  }
}
