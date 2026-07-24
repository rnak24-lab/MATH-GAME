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
import '../widgets/banner_ad_widget.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_strings.dart';
import '../services/ad_service.dart';
import '../game/tutorial_manager.dart';
import 'world_select_screen.dart' show worldForStage, WorldInfo;

/// Papers-Please풍 "심문 책상" 탑뷰 팔레트 (sepia noir).
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
  static const sky = Color(0xFF79C6EA); // 빼빼로 선택(하늘색)
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

  const GameScreen({
    super.key,
    required this.stageManager,
    required this.stageNumber,
    required this.localeProvider,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final NimEngine _engine = NimEngine();
  late StageConfig _config;
  AppStrings get s => widget.localeProvider.strings;

  // Game state
  GamePhase _phase = GamePhase.turnChoice;
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

  /// 마지막 돌 = 승리(normal play) 모드인가? (기본 님 모드는 마지막 돌 = 패배)
  bool get _isNormalPlay =>
      _config.mode == GameMode.kayles ||
      _config.mode == GameMode.wythoff ||
      _config.mode == GameMode.fibonacci;

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
  bool _msgAppendAutoHint = false; // 패배 시 자동 힌트 덧붙임 여부

  String get _midnightMessage {
    if (_msgKey == null) return '';
    String m = s.get(_msgKey!, _msgArgs);
    if (_msgAppendAutoHint) {
      m = '$m\n\n${TutorialManager.autoHintOnConsecutiveLoss(widget.stageNumber, s)}';
    }
    return m;
  }

  /// 말풍선 대사 설정 (setState 밖에서도 호출 가능 — 호출부가 setState 책임)
  void _say(String key,
      [List<String> args = const [], bool appendAutoHint = false]) {
    _msgKey = key;
    _msgArgs = args;
    _msgAppendAutoHint = appendAutoHint;
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

  // 진행 로그 / 선공자 — 로그는 (주체, 텍스트) 구조로 저장해 언어 무관하게 색상 결정
  TurnOwner? _firstMover;
  final List<_LogEntry> _moveLog = [];

  void _addLog(TurnOwner? owner, String text) {
    _moveLog.add(_LogEntry(owner, text));
  }

  String _nameOf(TurnOwner owner) =>
      owner == TurnOwner.player ? s.get('nameYou') : s.get('nameMidnight');

  /// (귀여움 규칙) 진동 효과 — 설정에서 끌 수 있음.
  void _haptic([bool strong = false]) {
    if (!AppSettings.instance.haptics) return;
    strong ? HapticFeedback.mediumImpact() : HapticFeedback.selectionClick();
  }

  // 플레이어 턴 시작 시 NIM 패배 상태 연속 카운트 (happy → confident 전환용)
  int _consecutiveLossTurns = 0;

  // Hints
  int _hintsLeft = 3;

  // Tutorial (예린 시나리오, 월드별 1라운드만 활성)
  List<TutorialStep> _tutorialSteps = const [];
  int _tutorialIndex = 0;
  bool _tutorialActive = false;

  // 연속 패배 추적 (2회 연속 패배 시 자동 힌트)
  int _consecutiveDefeats = 0;

  @override
  void initState() {
    super.initState();
    _config = _engine.generateStage(widget.stageNumber);
    _rows = List.from(_config.rows);
    _sayGreeting();
    // 피보나치: 첫 수는 "전부 빼기 금지" → 최대 n-1
    if (_config.mode == GameMode.fibonacci) {
      _fibLimit = _rows[0] - 1;
    }

    // 월드별 1라운드 튜토리얼 활성화 여부 판정
    if (TutorialManager.isTutorialStage(widget.stageNumber)) {
      _tutorialSteps = TutorialManager.entrySteps(widget.stageNumber, s);
      _tutorialActive = _tutorialSteps.isNotEmpty;
    }

    // (2026-07-02) 스테이지 1 = 튜토리얼 전용: 선공 선택 화면 없이 바로 플레이어 선공.
    // 돌 3개 + "2개 집어봐" 지시 → 따라 하면 무조건 승리.
    if (widget.stageNumber == 1) {
      _phase = GamePhase.playing;
      _currentTurn = TurnOwner.player;
      _firstMover = TurnOwner.player;
      _moveLog.add(_LogEntry(null, s.get('logStart', [s.get('nameYou')])));
      _say('turnPlayerFirst');
    }
  }

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

  void _advanceTutorial() {
    setState(() {
      _tutorialIndex++;
      if (_tutorialIndex >= _tutorialSteps.length) {
        _tutorialActive = false;
      }
    });
  }

  void _sayGreeting() {
    List<String> greetingKeys = [
      'greetReady',
      'greetWin',
      'greetConfident',
      'greetLetsGo',
    ];
    String key = greetingKeys[widget.stageNumber % greetingKeys.length];
    if (key == 'greetReady') {
      _say(key, ['${widget.stageNumber}']);
    } else {
      _say(key);
    }
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

  /// 현재 rows 상태에서 "다음에 둘 사람 = player"가 반드시 패배하는지 (= Midnight이 이기는 상태).
  /// NIM XOR 판정. singleRow는 별도 공식 ((n-1) % (maxTake+1) == 0).
  /// pepero는 Grundy 수 XOR == 0 이면 현재 턴 플레이어 패배 확정 (둘 수 없는 쪽이 짐 = normal play).
  bool _calculateMidnightWinsState() {
    if (_config.mode == GameMode.pepero) {
      // 게임 종료 직전: 분할 가능한 돌이 없으면 현재 턴 player가 이미 진 상황이므로 Midnight이 이김.
      bool canSplit = _rows.any((p) => p >= 3);
      if (!canSplit) return true;
      // NimEngine.isAIWinning은 "방금 둔 쪽이 유리" = "다음 턴 플레이어 패배 확정" 동일 의미.
      return _engine.isAIWinning(_rows, GameMode.pepero);
    }
    if (_config.mode == GameMode.kayles || _config.mode == GameMode.wythoff) {
      return _engine.isAIWinning(_rows, _config.mode);
    }
    if (_config.mode == GameMode.fibonacci) {
      return _engine.fibonacciLosing(_rows[0], _fibLimit);
    }
    if (_config.mode == GameMode.singleRow) {
      int n = _rows[0];
      if (n <= 0) return false;
      return (n - 1) % (_config.maxTake + 1) == 0;
    }
    // doubleRow / tripleRow / quadRow: nim XOR == 0 이면 현재 턴 플레이어 패배 확정
    int nimSum = 0;
    for (int r in _rows) {
      nimSum ^= r;
    }
    return nimSum == 0;
  }

  /// (id=1201) 이 스테이지의 "초기 상태"에서 선공 플레이어가 이기는가?
  /// 힌트에서 "다시 도전할 때 선공/후공 어느 쪽을 고르면 되는지" 계산용.
  ///  - singleRow: (n-1) % (maxTake+1) != 0 이면 선공 승.
  ///  - multiRow (double/triple/quad): nimSum != 0 이면 선공 승.
  ///  - pepero: Grundy XOR != 0 이면 선공 승.
  bool _initialFirstPlayerWins() {
    final initRows = _config.rows;
    if (_config.mode == GameMode.singleRow) {
      int n = initRows[0];
      if (n <= 0) return false;
      return (n - 1) % (_config.maxTake + 1) != 0;
    }
    if (_config.mode == GameMode.kayles || _config.mode == GameMode.wythoff) {
      return !_engine.isAIWinning(initRows, _config.mode);
    }
    if (_config.mode == GameMode.fibonacci) {
      return !_engine.fibonacciLosing(initRows[0], initRows[0] - 1);
    }
    if (_config.mode == GameMode.pepero) {
      // 분할 불가 상태면 선공이 즉시 짐.
      if (initRows.every((p) => p < 3)) return false;
      // isAIWinning true = "방금 둔 쪽 유리 = 다음 턴 플레이어 패배" = Grundy XOR == 0
      // → 초기 상태에서 Grundy XOR == 0 이면 "선공(=첫 수를 두는 플레이어)"은 진다.
      return !_engine.isAIWinning(initRows, GameMode.pepero);
    }
    int nimSum = 0;
    for (int r in initRows) {
      nimSum ^= r;
    }
    return nimSum != 0;
  }

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
          List<String> keys = [
            'midnightWinLate1',
            'midnightWinLate2',
            'midnightWinLate3'
          ];
          _say(keys[_turnCount % keys.length]);
        } else {
          _midnightFace = MidnightFace.happy1;
          List<String> keys = [
            'midnightWinEarly1',
            'midnightWinEarly2',
            'midnightWinEarly3'
          ];
          _say(keys[_turnCount % keys.length]);
        }
      } else {
        _consecutiveLossTurns = 0;
        _midnightFace = MidnightFace.neutral;
        _say('yourTurnNow');
      }
    });
  }

  void _chooseTurn(TurnOwner first) {
    setState(() {
      _currentTurn = first;
      _phase = GamePhase.playing;
      _consecutiveLossTurns = 0;
      _selectedCount = 0;
      _firstMover = first;
      _moveLog.clear();
      _addLog(null, s.get('logStart', [_nameOf(first)]));
      if (first == TurnOwner.player) {
        // 첫 턴: NIM 판정 기반 표정 (player가 지는 상태면 happy, 아니면 neutral)
        bool midnightWins = _calculateMidnightWinsState();
        if (midnightWins) {
          _consecutiveLossTurns = 1;
          _midnightFace = MidnightFace.happy1;
        } else {
          _midnightFace = MidnightFace.neutral;
        }
        _say('turnPlayerFirst');
      } else {
        // AI가 선공: 첫 수 고민부터 시작
        _midnightFace = MidnightFace.thinking;
        _say('turnMidnightFirst');
      }
    });

    if (first == TurnOwner.midnight) {
      Future.delayed(const Duration(milliseconds: 800), _midnightPlay);
    }
  }

  bool _checkGameOver() {
    int total = _rows.isEmpty ? 0 : _rows.reduce((a, b) => a + b);

    if (_config.mode == GameMode.pepero) {
      bool canSplit = _rows.any((p) => p >= 3);
      if (!canSplit) {
        // _checkGameOver는 턴 토글 "후" 호출됨 → _currentTurn = 다음에 둘 사람.
        // 다음 차례가 못 쪼개면 그 사람이 패배. (2026-07-24 반전 버그 수정)
        _endGame(_currentTurn != TurnOwner.player);
        return true;
      }
    } else if (_isNormalPlay) {
      // 🧪 normal play: 마지막 돌을 가져간 쪽(= 방금 둔 쪽)이 승리
      if (total == 0) {
        _endGame(_currentTurn != TurnOwner.player);
        return true;
      }
    } else {
      // misère: 마지막 돌을 가져간 쪽이 패배
      if (total == 0) {
        _endGame(_currentTurn == TurnOwner.player);
        return true;
      }
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
        _say('midnightLost');
        _consecutiveDefeats = 0;
      } else {
        _midnightFace = MidnightFace.happy2;
        _consecutiveDefeats++;
        // 자동 힌트: 스테이지 1은 첫 패배 즉시, 그 외 튜토리얼 스테이지는 2연패 시
        final int hintAfter = widget.stageNumber == 1 ? 1 : 2;
        final bool autoHint = _consecutiveDefeats >= hintAfter &&
            TutorialManager.isTutorialStage(widget.stageNumber);
        _say('midnightWon', const [], autoHint);
      }
    });

    if (playerWins) {
      widget.stageManager.clearStage(widget.stageNumber);
      // 전면 광고: 3 스테이지 클리어마다 1회 (AdService 내부 카운터)
      AdService.instance.maybeShowInterstitialOnStageClear();
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) _showNextStageDialog();
      });
    }
  }

  void _showNextStageDialog() {
    // 정식 7월드 140스테이지 (2026-07-24 확정)
    bool hasNext = widget.stageNumber < 140;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, a1, a2, child) {
        return Transform.scale(
          scale: Curves.elasticOut.transform(a1.value),
          child: Opacity(opacity: a1.value, child: child),
        );
      },
      pageBuilder: (context, _, __) {
        return Center(
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
                  s.get('stageClearDesc', ['${widget.stageNumber}']),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: _mono,
                    fontSize: 13,
                    color: _Pal.inkSoft,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 6),
                MidnightCharacter(
                  face: MidnightFace.worried1,
                  size: 76,
                  animate: false,
                ),
                const SizedBox(height: 4),
                Text(
                  s.get('midnightNextTime'),
                  style: const TextStyle(
                    fontFamily: _mono,
                    fontSize: 12,
                    color: _Pal.inkSoft,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.none,
                  ),
                ),
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
                            builder: (_) => GameScreen(
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
    if (_phase != GamePhase.playing ||
        _currentTurn != TurnOwner.player ||
        _isAiAnimating) return;

    final int tookCount = _selectedCount;
    final int tookRow = _selectedRow;
    final bool multi = _rows.length > 1;
    _addLog(
        TurnOwner.player,
        multi
            ? '${_nameOf(TurnOwner.player)}  −$tookCount · R${tookRow + 1}'
            : '${_nameOf(TurnOwner.player)}  −$tookCount');

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

    final mnName = _nameOf(TurnOwner.midnight);
    _addLog(
        TurnOwner.midnight,
        move.isPepero
            ? '$mnName  ${move.splitA}+${move.splitB}'
            : move.isKayles
                ? '$mnName  −${move.count} ✂'
                : move.isWythoff
                    ? '$mnName  −${move.takeA}/−${move.takeB}'
                    : (_rows.length > 1
                        ? '$mnName  −${move.count} · R${move.rowIndex + 1}'
                        : '$mnName  −${move.count}'));

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
      // 피보나치: 다음(내) 턴 한도 = 한밤이가 방금 가져간 수의 2배
      if (_config.mode == GameMode.fibonacci) {
        _fibLimit = move.count * 2;
      }
    });

    if (!_checkGameOver()) {
      // 플레이어 턴 시작 시점 → NIM XOR 기반 표정 결정
      _updateExpressionForPlayerTurn();
    }
  }

  /// 힌트 버튼 → "힌트 보기!" 확인 다이얼로그 → 광고 시청 후 힌트 공개.
  /// (광고 미준비/웹에서는 폴백으로 바로 공개)
  void _showHint() {
    if (_hintsLeft <= 0 || _currentTurn != TurnOwner.player) return;
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
          s.get('hintDialogBody', ['$_hintsLeft']),
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
    if (!mounted || _hintsLeft <= 0 || _currentTurn != TurnOwner.player) {
      return;
    }

    // (id=1201) 4번: 현재 턴 플레이어가 이미 진 상태(nimSum=0/Grundy=0)인지 먼저 판정.
    final bool canWin = !_calculateMidnightWinsState();

    String hintText;
    if (!canWin) {
      bool initialFirstPlayerWins = _initialFirstPlayerWins();
      String advice =
          initialFirstPlayerWins ? s.get('meFirst') : s.get('midnightFirst');
      hintText = s.get('hintLosingNextChoice', [advice]);
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

    setState(() => _hintsLeft--);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(hintText,
            style: const TextStyle(fontFamily: _mono, fontSize: 14)),
        backgroundColor: canWin ? _Pal.frame : _Pal.alarm,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        duration: Duration(seconds: canWin ? 3 : 5),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // BUILD — Papers-Please풍 심문 책상(탑뷰)
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final WorldInfo worldInfo = worldForStage(widget.stageNumber);
    final Color accent = worldInfo.bgGradient.first;

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
              _topBar(accent),
              Expanded(
                child: Stack(
                  children: [
                    _buildBody(),
                    if (_tutorialActive) _buildTutorialOverlay(),
                  ],
                ),
              ),
              _recordLine(),
              // 하단 상시 배너 광고
              const Center(child: BannerAdWidget()),
            ],
          ),
        ),
      ),
    );
  }

  /// 상단 바: 뒤로 / 스테이지·모드 / 힌트 — 어두운 나무 패널 + 모노 타이포.
  Widget _topBar(Color accent) {
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
          Container(width: 10, height: 10, color: accent),
          const SizedBox(width: 8),
          Text(
            s.get('stageLabel', ['${widget.stageNumber}']),
            style: const TextStyle(
              fontFamily: _mono,
              color: _Pal.cream,
              fontWeight: FontWeight.w800,
              fontSize: 15,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '· ${_getModeTitle()}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: _mono,
                color: _Pal.gold,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_phase == GamePhase.playing && _currentTurn == TurnOwner.player)
            TextButton.icon(
              onPressed: _hintsLeft > 0 ? _showHint : null,
              icon: Icon(Icons.lightbulb_outline,
                  size: 18, color: _hintsLeft > 0 ? _Pal.gold : _Pal.inkSoft),
              label: Text('$_hintsLeft',
                  style: TextStyle(
                      fontFamily: _mono,
                      color: _hintsLeft > 0 ? _Pal.gold : _Pal.inkSoft,
                      fontWeight: FontWeight.w800)),
            ),
          // ? 게임 규칙 — 언제든 현재 모드 규칙 확인
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.help_outline_rounded,
                size: 20, color: _Pal.cream),
            tooltip: s.get('rulesTitle'),
            onPressed: _showModeRules,
          ),
          // (v2) 음소거는 설정 안으로 — 탑바 아이콘 3개로 다이어트
          // 설정 — 게임 중 언제든 진입
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.only(right: 10),
            icon:
                const Icon(Icons.settings_rounded, size: 20, color: _Pal.gold),
            tooltip: s.get('settings'),
            onPressed: () async {
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
              if (mounted) setState(() {}); // 언어/사운드 변경 반영
            },
          ),
        ],
      ),
    );
  }

  /// 현재 모드의 규칙 다이얼로그 — 탑바 ? 버튼.
  void _showModeRules() {
    String ruleKey;
    List<String> ruleArgs = const [];
    switch (_config.mode) {
      case GameMode.singleRow:
        ruleKey = 'ruleSingleRow';
        ruleArgs = ['${_config.maxTake}'];
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

  /// (v2) 기록 한 줄 — #767676 회색으로 존재감만. 최근 수순이 앞에 온다.
  Widget _recordLine() {
    final moves = _moveLog.where((e) => e.owner != null).toList();
    final String recent =
        moves.reversed.take(3).map((e) => e.text).join('  ←  ');
    final String first = _firstMover == null
        ? ''
        : ' · ${s.get('logFirst', [_nameOf(_firstMover!)])}';
    return Container(
      height: 22,
      decoration: const BoxDecoration(
        color: _Pal.deskBottom,
        border: Border(top: BorderSide(color: _Pal.frame, width: 1)),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        '${s.get('logLabel')}$first${recent.isEmpty ? '' : '  ·  $recent'}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: _mono,
          color: Color(0xFF767676),
          fontSize: 10,
          letterSpacing: 0.3,
        ),
      ),
    );
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
          // 예린 (정적, 투명 PNG) — 찌르면 잠깐 표정이 바뀐다
          MidnightCharacter(
            face: _poked ? _pokeFace : _midnightFace,
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

  Widget _buildTutorialOverlay() {
    if (_tutorialIndex >= _tutorialSteps.length) {
      return const SizedBox.shrink();
    }
    // 매 build마다 현재 언어로 재해석 — 게임 중 언어 변경 즉시 반영
    final steps = TutorialManager.entrySteps(widget.stageNumber, s);
    final step = steps[_tutorialIndex];
    final bool isLast = _tutorialIndex == _tutorialSteps.length - 1;
    return Positioned.fill(
      child: GestureDetector(
        onTap: _advanceTutorial,
        child: Container(
          color: Colors.black.withOpacity(0.66),
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MidnightWithBubble(
                  face: isLast ? MidnightFace.confident : MidnightFace.happy1,
                  message: step.text,
                  size: 140,
                ),
                const SizedBox(height: 20),
                _StampButton(
                  label: isLast ? s.get('tutStart') : s.get('tutNext'),
                  color: _Pal.gold,
                  onTap: _advanceTutorial,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_tutorialSteps.length, (i) {
                    final active = i == _tutorialIndex;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 10 : 6,
                      height: active ? 10 : 6,
                      decoration: BoxDecoration(
                        color: active ? _Pal.gold : _Pal.cream.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case GamePhase.turnChoice:
        return _buildTurnChoice();
      case GamePhase.playing:
      case GamePhase.gameOver:
        return _buildGameBoard();
    }
  }

  // ── 선공 선택 — 플레이와 똑같은 책상 씬 위에서 (대표님: "돌 선택할 때부터 이 모양") ──
  Widget _buildTurnChoice() {
    return Column(
      children: [
        _deskScene(
          // (v2) "누가 먼저 할까?" — 풀폭 배너 (플레이 중 턴 배너와 같은 자리)
          overlay: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              border: Border.all(color: _Pal.gold, width: 2.5),
              borderRadius: BorderRadius.circular(6),
              color: _Pal.deskBottom.withOpacity(0.88),
            ),
            child: Row(
              children: [
                Text(
                  s.get('whoGoesFirst'),
                  style: const TextStyle(
                    fontFamily: _mono,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: _Pal.gold,
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _boardSummary(),
                      style: const TextStyle(
                        fontFamily: _mono,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: _Pal.cream,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: _infoChips(dark: true),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: _StampButton(
                  label: s.get('meFirst'),
                  color: _Pal.frameHi,
                  icon: Icons.person,
                  onTap: () => _chooseTurn(TurnOwner.player),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StampButton(
                  label: s.get('midnightFirst'),
                  color: _Pal.alarm,
                  icon: Icons.pets,
                  onTap: () => _chooseTurn(TurnOwner.midnight),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// (v2) 규칙 칩 한 줄: [한 번에 1~M개] [승리 조건] — 남은 돌은 턴 배너가 담당.
  Widget _infoChips({required bool dark}) {
    String qty;
    switch (_config.mode) {
      case GameMode.singleRow:
        qty = s.get('takeRange', ['${_config.maxTake}']);
        break;
      case GameMode.pepero:
        qty = s.get('peperoChip');
        break;
      case GameMode.kayles:
        qty = s.get('kaylesChip');
        break;
      case GameMode.wythoff:
        qty = s.get('wythoffChip');
        break;
      case GameMode.fibonacci:
        // 🧪 턴마다 변하는 한도 — 칩이 실시간으로 갱신됨
        qty = s.get('takeRange', ['$_fibLimit']);
        break;
      default:
        qty = s.get('takeAny');
    }
    Widget chip(String t) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: dark ? _Pal.deskBottom : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border:
                Border.all(color: dark ? _Pal.frameHi : _Pal.frame, width: 1.5),
          ),
          child: Text(
            t,
            style: TextStyle(
              fontFamily: _mono,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: dark ? _Pal.cream : _Pal.ink,
            ),
          ),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        chip(qty),
        // 빼빼로 핵심 규칙은 칩으로 상시 노출 — "같은 개수 ❌"
        if (_config.mode == GameMode.pepero) ...[
          const SizedBox(width: 8),
          chip(s.get('peperoNoEqualChip')),
        ],
        // 승리 조건 상시 노출 — normal play(마지막 돌 승리) vs misère(패배)
        if (_isNormalPlay) ...[
          const SizedBox(width: 8),
          chip(s.get('lastStoneWinChip')),
        ] else if (_config.mode != GameMode.pepero) ...[
          const SizedBox(width: 8),
          chip(s.get('lastStoneLoseChip')),
        ],
      ],
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
          // 1) 예린 — 중앙에 크게, 가슴 아래까지 (진짜 마주 앉아 대결하는 느낌)
          //    하반신은 테이블(top:258)에 가려진다. (v2: 더 키움 + 탭 상호작용)
          Positioned(
            top: 22,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _pokeYerin,
                child: _catFigure(size: 335),
              ),
            ),
          ),
          // 말풍선 — (v2) 예린 머리 위 중앙, 꼬리가 아래로
          Positioned(
            top: 46,
            left: 30,
            right: 30,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child:
                    _tauntBubble(_poked ? s.get(_pokeKey) : _midnightMessage),
              ),
            ),
          ),
          // 2) 턴 배너 — 맨 위 풀폭 (예린 위 레이어라 항상 보임)
          Positioned(top: 4, left: 10, right: 10, child: overlay),
          // 3) 테이블 — 예린 가슴 아래에서 시작 (평평, 남은 영역 꽉 채움)
          Positioned(
            top: 258,
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

  /// (v2) 게임판 요약 — 모드마다 형태가 달라도 배너 오른쪽 한 자리를 쓴다.
  /// 한줄="남은 돌 3", 여러줄/카일즈="3 · 5 · 7", 위토프="3 · 5", 빼빼로="막대 3개".
  String _boardSummary() {
    switch (_config.mode) {
      case GameMode.pepero:
        return s.get('sticksLeft', ['${_rows.length}']);
      case GameMode.wythoff:
        return _rows.map((r) => '$r').join(' · ');
      default:
        if (_rows.length == 1) {
          return s.get('stonesLeft', ['${_rows.first}']);
        }
        return _rows.map((r) => '$r').join(' · ');
    }
  }

  /// (v2) 턴 배너 — 1순위 정보(누구 턴 + 판 요약)를 풀폭으로 크게.
  Widget _turnStamp() {
    final bool over = _phase == GamePhase.gameOver;
    final Color c = over
        ? (_playerWon ? _Pal.win : _Pal.alarm)
        : (_currentTurn == TurnOwner.player ? _Pal.gold : _Pal.alarm);
    final String label = over
        ? (_playerWon ? s.get('victory') : s.get('defeat'))
        : (_currentTurn == TurnOwner.player
            ? s.get('myTurn')
            : s.get('midnightTurn'));
    final stamp = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        border: Border.all(color: c, width: 2.5),
        borderRadius: BorderRadius.circular(6),
        color: _Pal.deskBottom.withOpacity(0.88),
      ),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: _mono,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: c == _Pal.gold ? _Pal.gold : c,
            ),
          ),
          const Spacer(),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _boardSummary(),
                style: const TextStyle(
                  fontFamily: _mono,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: _Pal.cream,
                ),
              ),
            ),
          ),
        ],
      ),
    );
    // (제안 #8) 승리 도장은 "쾅" 찍히며 등장 — 패배는 조용하게 (M3)
    if (over && _playerWon) {
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

  Widget _buildStonesBoard() {
    final bool multi = _rows.length > 1;
    return Center(
      child: LayoutBuilder(builder: (context, cons) {
        // (폰 스케일) 돌이 절대 줄바꿈되지 않도록 — 가장 긴 줄 기준으로 셀 크기 적응.
        final int maxLen = _rows.fold(1, (m, r) => r > m ? r : m).clamp(1, 40);
        final double avail =
            cons.maxWidth - 32 - (multi ? 34 : 0); // 패딩 + R라벨 여유
        final double cell = (avail / maxLen).clamp(24.0, 44.0);
        final double stone = (cell - 8).clamp(16.0, 34.0);
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_rows.length, (rowIdx) {
              final len = _rows[rowIdx];
              final isSelRow = _selectedRow == rowIdx;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // (v2) 줄별 개수 라벨 — 게임판이 숫자를 직접 담당
                    if (multi)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          '$len',
                          style: TextStyle(
                            fontFamily: _mono,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isSelRow
                                ? _Pal.gold
                                : _Pal.cream.withOpacity(0.65),
                          ),
                        ),
                      ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(len, (i) {
                        final bool selected =
                            isSelRow && i >= len - _selectedCount;
                        // (스테이지1 튜토리얼) 마지막에 남는 돌 = 가져가면 지는 돌.
                        // 빨간 돌로 표시해 "저건 상대에게 남겨야 한다"를 눈으로 배우게.
                        final bool danger = widget.stageNumber == 1 && i == 0;
                        return _Stone(
                          cell: cell,
                          size: stone,
                          selected: selected,
                          leaving: _leaving && selected,
                          danger: danger,
                          onTap: () => _selectStone(rowIdx, i),
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

  // ── 🧪 카일즈: 아무 위치의 인접 1~2개 선택 ──
  void _selectKayles(int rowIdx, int i) {
    if (_phase != GamePhase.playing ||
        _currentTurn != TurnOwner.player ||
        _isAiAnimating ||
        _leaving) return;
    _haptic();
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
        final double stone = (cell - 8).clamp(16.0, 34.0);
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  s.get('kaylesTapCta'),
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
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
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
                          size: stone,
                          selected: selected,
                          leaving: _leaving && selected,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              s.get('takeCount'),
              style: const TextStyle(
                fontFamily: _mono,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _Pal.cream,
              ),
            ),
            Text(
              hasSel ? s.get('nPieces', ['$_kSelCount']) : '—',
              style: const TextStyle(
                fontFamily: _mono,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _Pal.gold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: hasSel
              ? _StampButton(
                  label: s.get('takeNStones', ['$_kSelCount']),
                  color: _Pal.alarm,
                  onTap: _confirmKayles,
                )
              : Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _Pal.frameHi, width: 1.5),
                  ),
                  child: Text(
                    s.get('tapToSelectCta'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: _mono,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _Pal.cream,
                    ),
                  ),
                ),
        ),
      ],
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
      final int took = _kSelCount;
      _addLog(TurnOwner.player, '${_nameOf(TurnOwner.player)}  −$took ✂');
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
        final double stone = (cell - 8).clamp(16.0, 34.0);
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_rows.length, (rowIdx) {
              final len = _rows[rowIdx];
              final int sel = rowIdx == 0 ? _wSelA : _wSelB;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
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
                          size: stone,
                          selected: selected,
                          leaving: _leaving && selected,
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
    final bool valid = _wythoffValid;
    final int total = _wSelA + _wSelB;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              s.get('takeCount'),
              style: const TextStyle(
                fontFamily: _mono,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _Pal.cream,
              ),
            ),
            Text(
              'R1 −$_wSelA · R2 −$_wSelB',
              style: TextStyle(
                fontFamily: _mono,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: !any
                    ? _Pal.cream.withOpacity(0.5)
                    : valid
                        ? _Pal.gold
                        : _Pal.alarmHi,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: !any
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _Pal.frameHi, width: 1.5),
                  ),
                  child: Text(
                    s.get('tapToSelectCta'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: _mono,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _Pal.cream,
                    ),
                  ),
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
        ),
      ],
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
      _addLog(TurnOwner.player, '${_nameOf(TurnOwner.player)}  −$a/−$b');
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
    final bool hasSel = _selectedPile >= 0 &&
        _selectedPile < _rows.length &&
        _rows[_selectedPile] >= 3;

    String guide = '';
    bool guideAlarm = false;
    if (myTurn) {
      if (!hasSel) {
        guide = s.get('peperoTapBundle');
      } else {
        final int pile = _rows[_selectedPile];
        final int a = _splitA.clamp(1, pile - 1);
        if (a * 2 == pile) {
          guide = s.get('peperoNoEqual');
          guideAlarm = true;
        } else {
          guide = s.get('peperoTapStick');
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (guide.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                guide,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: _mono,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color:
                      guideAlarm ? _Pal.alarmHi : _Pal.cream.withOpacity(0.9),
                ),
              ),
            ),
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
  Widget _peperoBundle(int i, bool myTurn) {
    final int n = _rows[i];
    final bool splittable = n >= 3;
    final bool selected = i == _selectedPile && splittable;
    final int a = _splitA.clamp(1, n > 1 ? n - 1 : 1);
    final bool equal = selected && a * 2 == n;

    // 막대 크기 적응 (묶음 최대 20개, 폰 폭 기준)
    final double stickW = n <= 8 ? 13 : (n <= 14 ? 10 : 8);
    final double stickH = selected ? 60 : 44;
    final double gap = n <= 14 ? 1.5 : 1.0;

    final children = <Widget>[];
    for (int k = 0; k < n; k++) {
      if (selected && k == a) children.add(_splitDivider(stickH, equal));
      final stick = Padding(
        padding: EdgeInsets.symmetric(horizontal: gap),
        child: _peperoStick(stickW, stickH, dim: !splittable),
      );
      // 선택된 묶음에서는 막대를 직접 탭해 쪼갤 위치 지정
      children.add(selected && myTurn
          ? GestureDetector(
              onTap: () {
                _haptic();
                setState(() => _splitA = (k + 1).clamp(1, n - 1));
              },
              behavior: HitTestBehavior.opaque,
              child: stick,
            )
          : stick);
    }

    return GestureDetector(
      onTap: myTurn && splittable && !selected
          ? () {
              _haptic();
              setState(() {
                _selectedPile = i;
                _splitA = 1;
              });
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.fromLTRB(9, 9, 9, 5),
        decoration: BoxDecoration(
          color: selected
              ? _Pal.sky.withOpacity(0.10)
              : _Pal.deskBottom.withOpacity(0.55),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                selected ? _Pal.sky : (splittable ? _Pal.frameHi : _Pal.frame),
            width: selected ? 2.5 : 1.5,
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
            const SizedBox(height: 4),
            // 숫자는 부차적 — 작게
            Text(
              selected ? '$a + ${n - a}' : '$n',
              style: TextStyle(
                fontFamily: _mono,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: selected
                    ? (equal ? _Pal.alarmHi : Colors.white)
                    : (splittable ? _Pal.cream.withOpacity(0.7) : _Pal.inkSoft),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 쪼갤 위치 표시 — 흰 분할선 (같은 개수면 빨강 = 금지).
  Widget _splitDivider(double h, bool equal) {
    final Color c = equal ? _Pal.alarmHi : Colors.white;
    return Container(
      width: 3.5,
      height: h + 8,
      margin: const EdgeInsets.symmetric(horizontal: 3.5),
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(color: c.withOpacity(0.55), blurRadius: 6, spreadRadius: 1),
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
          constraints: BoxConstraints(
              minHeight: _config.mode == GameMode.pepero ? 158 : 116),
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // (대표님 7/24) 라벨 줄 항상 렌더 — 선택 여부로 높이가 출렁이지 않게
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              hasSel && _rows.length > 1
                  ? s.get('takeFromRow', ['${_selectedRow + 1}'])
                  : s.get('takeCount'),
              style: const TextStyle(
                fontFamily: _mono,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _Pal.cream,
              ),
            ),
            Text(
              hasSel ? s.get('nPieces', ['$_selectedCount']) : '—',
              style: TextStyle(
                fontFamily: _mono,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: hasSel ? _Pal.gold : _Pal.inkSoft,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // (제안 #7) 비활성 시 행동 유도 문구, 선택 시 살짝 커지며 강조
        AnimatedScale(
          scale: hasSel ? 1.0 : 0.97,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutBack,
          child: SizedBox(
            width: double.infinity,
            child: _StampButton(
              label: hasSel
                  ? s.get('takeNStones', ['$_selectedCount'])
                  : s.get('tapToSelectCta'),
              color: hasSel ? _Pal.alarm : _Pal.frameHi,
              onTap: _confirmTake,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeperoAction() {
    if (_selectedPile < 0 ||
        _selectedPile >= _rows.length ||
        _rows[_selectedPile] < 3) {
      return Center(
        child: Text(
          s.get('selectSplittable'),
          style: const TextStyle(
            fontFamily: _mono,
            fontSize: 13,
            color: _Pal.cream,
          ),
        ),
      );
    }

    final int pile = _rows[_selectedPile];
    final int a = _splitA.clamp(1, pile - 1);
    final int b = pile - a;
    final bool equal = a == b;
    final int maxSplitA = (pile - 1) ~/ 2;
    // 슬라이더는 항상 "작은 쪽" 기준 (위 UI에서 4+1처럼 큰 쪽을 골라도 동기화)
    final double sliderVal =
        (a < b ? a : b).clamp(1, maxSplitA > 0 ? maxSplitA : 1).toDouble();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              s.get('split'),
              style: const TextStyle(
                fontFamily: _mono,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _Pal.cream,
              ),
            ),
            Text(
              '$a + $b',
              style: TextStyle(
                fontFamily: _mono,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: equal ? _Pal.alarmHi : _Pal.gold,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: equal ? _Pal.alarmHi : _Pal.gold,
            inactiveTrackColor: _Pal.deskBottom,
            thumbColor: equal ? _Pal.alarmHi : _Pal.gold,
          ),
          child: Slider(
            value: sliderVal,
            min: 1,
            max: maxSplitA > 0 ? maxSplitA.toDouble() : 1,
            divisions: maxSplitA > 1 ? maxSplitA - 1 : 1,
            onChanged: (val) {
              int na = val.round();
              if (na != pile - na) {
                setState(() => _splitA = na);
              }
            },
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: equal
              // 같은 개수 = 금지 — 버튼 대신 경고 (규칙을 그 자리에서 학습)
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _Pal.alarmHi, width: 2),
                  ),
                  child: Text(
                    s.get('peperoNoEqual'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: _mono,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _Pal.alarmHi,
                    ),
                  ),
                )
              : _StampButton(
                  label: s.get('splitAction', ['$a', '$b']),
                  color: _Pal.alarm,
                  onTap: () {
                    if (a > 0 && b > 0 && a != b) {
                      _addLog(TurnOwner.player,
                          '${_nameOf(TurnOwner.player)}  $a+$b');
                      SfxService.instance.playTake();
                      _haptic(true);
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
                        Future.delayed(
                            const Duration(milliseconds: 1000), _midnightPlay);
                      }
                    }
                  },
                ),
        ),
      ],
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
class _LogEntry {
  final TurnOwner? owner; // null = 시스템(시작 등)
  final String text;
  const _LogEntry(this.owner, this.text);
}

// ─────────────────────────────────────────────────────────────
// 재사용 위젯 / 페인터
// ─────────────────────────────────────────────────────────────

/// 책상 위 돌 = 부감(탑뷰) 칩 토큰.
/// selected → 내 쪽(아래)으로 살짝 내려오며 강조. leaving → 아래로 슈르륵 빠지며 사라짐.
/// cell = 히트 영역(개수 많으면 축소), size = 시각 크기.
class _Stone extends StatelessWidget {
  final double cell;
  final double size;
  final bool selected;
  final bool leaving;
  final bool danger; // 가져가면 지는 돌 (스테이지1 학습용) — 빨간 돌
  final VoidCallback? onTap;
  const _Stone({
    this.cell = 44,
    this.size = 34,
    required this.selected,
    required this.leaving,
    this.danger = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double d = size;
    final token = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: d,
      height: d,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.4, -0.5),
          radius: 0.95,
          colors: selected
              ? const [Color(0xFFF0D49A), Color(0xFFC9A24B)]
              : danger
                  ? const [Color(0xFFCC7261), Color(0xFF9B3B2E)]
                  : const [Color(0xFFD9C7A0), Color(0xFF8C7A55)],
        ),
        border: Border.all(
          color: selected
              ? const Color(0xFF8A6A20)
              : danger
                  ? const Color(0xFF5E1F15)
                  : const Color(0xFF5C4E33),
          width: selected ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(selected ? 0.5 : 0.4),
            blurRadius: selected ? 6 : 3,
            offset: Offset(1, selected ? 4 : 2),
          ),
        ],
      ),
    );

    // (귀여움 규칙 T1) 히트 영역은 가능한 한 44dp — 돌이 많으면 화면에 맞게 축소.
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: cell,
        height: 44,
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
