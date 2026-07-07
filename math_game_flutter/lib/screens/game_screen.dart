import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import '../services/app_settings.dart';
import '../services/sfx_service.dart';
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
  int _splitA = 1;

  // Midnight state
  MidnightFace _midnightFace = MidnightFace.neutral;
  String _midnightMessage = '';
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
  bool _logOpen = false;

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
    _midnightMessage = _getGreeting();

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
      _midnightMessage = s.get('turnPlayerFirst');
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

  String _getGreeting() {
    List<String> greetingKeys = [
      'greetReady',
      'greetWin',
      'greetConfident',
      'greetLetsGo',
    ];
    String key = greetingKeys[widget.stageNumber % greetingKeys.length];
    if (key == 'greetReady') {
      return s.get(key, ['${widget.stageNumber}']);
    }
    return s.get(key);
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
          _midnightMessage = s.get(keys[_turnCount % keys.length]);
        } else {
          _midnightFace = MidnightFace.happy1;
          List<String> keys = [
            'midnightWinEarly1',
            'midnightWinEarly2',
            'midnightWinEarly3'
          ];
          _midnightMessage = s.get(keys[_turnCount % keys.length]);
        }
      } else {
        _consecutiveLossTurns = 0;
        _midnightFace = MidnightFace.neutral;
        _midnightMessage = s.get('yourTurnNow');
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
        _midnightMessage = s.get('turnPlayerFirst');
      } else {
        // AI가 선공: AI턴 중 표정은 neutral 고정
        _midnightFace = MidnightFace.neutral;
        _midnightMessage = s.get('turnMidnightFirst');
      }
    });

    if (first == TurnOwner.midnight) {
      Future.delayed(const Duration(milliseconds: 800), _midnightPlay);
    }
  }

  bool _checkGameOver() {
    int total = _rows.reduce((a, b) => a + b);

    if (_config.mode == GameMode.pepero) {
      bool canSplit = _rows.any((p) => p >= 3);
      if (!canSplit) {
        _endGame(_currentTurn == TurnOwner.player);
        return true;
      }
    } else {
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
        _midnightMessage = s.get('midnightLost');
        _consecutiveDefeats = 0;
      } else {
        _midnightFace = MidnightFace.happy2;
        _midnightMessage = s.get('midnightWon');
        _consecutiveDefeats++;
        // 자동 힌트: 스테이지 1은 첫 패배 즉시, 그 외 튜토리얼 스테이지는 2연패 시
        final int hintAfter = widget.stageNumber == 1 ? 1 : 2;
        if (_consecutiveDefeats >= hintAfter &&
            TutorialManager.isTutorialStage(widget.stageNumber)) {
          _midnightMessage =
              '${s.get('midnightWon')}\n\n${TutorialManager.autoHintOnConsecutiveLoss(widget.stageNumber, s)}';
        }
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
    bool hasNext = widget.stageNumber < 80;

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
      } else if (_config.mode == GameMode.singleRow) {
        _rows[0] -= _selectedCount;
      } else {
        _rows[_selectedRow] -= _selectedCount;
      }
      _turnCount++;
      _currentTurn = TurnOwner.midnight;
      _selectedCount = 0;
    });

    if (!_checkGameOver()) {
      // AI턴 진입 시 표정은 neutral 유지 (생각중 메시지만)
      setState(() {
        _midnightFace = MidnightFace.neutral;
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
    }

    _isAiAnimating = true;

    // Phase 1: "Midnight의 차례..." 표시 (0.5초 딜레이)
    setState(() {
      _midnightFace = MidnightFace.neutral;
      _midnightMessage = s.get('midnightThinking');
    });
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted || _phase != GamePhase.playing) return;

    if (move.isPepero) {
      // 빼빼로: 한번에 분할 (순차 애니메이션 대상 아님). AI턴 중 표정은 neutral 유지.
      setState(() {
        _midnightFace = MidnightFace.neutral;
        _midnightMessage =
            s.get('midnightSplit', ['${move.splitA}', '${move.splitB}']);
        _rows.removeAt(move.rowIndex);
        _rows.add(move.splitA);
        _rows.add(move.splitB);
        _rows.sort((x, y) => y.compareTo(x));
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
            _midnightMessage = s.get('midnightTakeN', ['${i + 1}']);
          } else {
            _midnightMessage = s.get(
                'midnightTakeFromRow', ['${i + 1}', '${move.rowIndex + 1}']);
          }
        });
        // 돌 1개당 0.4초 간격
        await Future.delayed(const Duration(milliseconds: 400));
      }
      if (!mounted || _phase != GamePhase.playing) return;

      // Phase 3: 총 가져간 수 카운터 표시
      setState(() {
        if (_config.mode == GameMode.singleRow) {
          _midnightMessage = s.get('midnightTookTotal', ['${move.count}']);
        } else {
          _midnightMessage = s.get('midnightTookFromRowTotal',
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
            : (_rows.length > 1
                ? '$mnName  −${move.count} · R${move.rowIndex + 1}'
                : '$mnName  −${move.count}'));

    setState(() {
      _turnCount++;
      _currentTurn = TurnOwner.player;
      _isAiAnimating = false;
      _selectedCount = 0; // 내 턴 시작: 미리선택 없음
    });

    if (!_checkGameOver()) {
      // 플레이어 턴 시작 시점 → NIM XOR 기반 표정 결정
      _updateExpressionForPlayerTurn();
    }
  }

  void _showHint() {
    if (_hintsLeft <= 0 || _currentTurn != TurnOwner.player) return;

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
      }

      if (hint.isPepero) {
        hintText = s.get('hintPepero', ['${hint.splitA}', '${hint.splitB}']);
      } else if (_config.mode == GameMode.singleRow) {
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
              _statusTicker(),
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
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _hintsLeft > 0 ? _showHint : null,
                icon: Icon(Icons.lightbulb_outline,
                    size: 18, color: _hintsLeft > 0 ? _Pal.gold : _Pal.inkSoft),
                label: Text('$_hintsLeft',
                    style: TextStyle(
                        fontFamily: _mono,
                        color: _hintsLeft > 0 ? _Pal.gold : _Pal.inkSoft,
                        fontWeight: FontWeight.w800)),
              ),
            ),
        ],
      ),
    );
  }

  /// 하단 상태 티커: 날짜/턴/모드 규칙을 흐르는 정보 바.
  Widget _statusTicker() {
    String status;
    if (_phase == GamePhase.gameOver) {
      status = _playerWon ? s.get('victory') : s.get('defeat');
    } else if (_phase == GamePhase.turnChoice) {
      status = s.get('whoGoesFirst');
    } else {
      status = _currentTurn == TurnOwner.player
          ? s.get('myTurn')
          : s.get('midnightTurn');
    }
    return Container(
      height: 26,
      decoration: const BoxDecoration(
        color: _Pal.deskBottom,
        border: Border(top: BorderSide(color: _Pal.frame, width: 2)),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        '▸ ${s.get('caseLabel', [
              widget.stageNumber.toString().padLeft(3, '0')
            ])}   ·   $status',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: _mono,
          color: _Pal.inkSoft,
          fontSize: 11,
          letterSpacing: 0.5,
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
          // 고양이 (정적, 투명 도트 에셋)
          MidnightCharacter(face: _midnightFace, size: size, animate: false),
        ],
      ),
    );
  }

  /// 고양이 도발 말풍선 — 꼬리가 왼쪽(고양이)을 향하는 가로 배치용.
  Widget _tauntBubble(String message) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(size: const Size(9, 16), painter: _BubbleTailLeft()),
        Flexible(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Container(
              key: ValueKey(message),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: _Pal.paper,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _Pal.frame, width: 2),
              ),
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: _mono,
                  fontSize: 13,
                  height: 1.35,
                  color: _Pal.ink,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTutorialOverlay() {
    if (_tutorialIndex >= _tutorialSteps.length) {
      return const SizedBox.shrink();
    }
    final step = _tutorialSteps[_tutorialIndex];
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
          overlay: Row(
            children: [
              // "누가 먼저 할까?" 골드 도장
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: _Pal.gold, width: 2.5),
                  borderRadius: BorderRadius.circular(4),
                  color: _Pal.gold.withOpacity(0.12),
                ),
                child: Text(
                  s.get('whoGoesFirst'),
                  style: const TextStyle(
                    fontFamily: _mono,
                    fontSize: 14,
                    letterSpacing: 2,
                    color: _Pal.gold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _infoChips(dark: true),
            ],
          ),
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

  /// 정보 칩 2개: [남은 돌 N] [한 번에 1~M개] — 게임 내내 숫자 정보 상시 노출.
  Widget _infoChips({required bool dark}) {
    final int total = _rows.fold(0, (a, b) => a + b);
    String qty;
    switch (_config.mode) {
      case GameMode.singleRow:
        qty = s.get('takeRange', ['${_config.maxTake}']);
        break;
      case GameMode.pepero:
        qty = s.get('peperoChip');
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
        chip(s.get('stonesLeft', ['$total'])),
        const SizedBox(width: 8),
        chip(qty),
        // 빼빼로 핵심 규칙은 칩으로 상시 노출 — "같은 개수 ❌"
        if (_config.mode == GameMode.pepero) ...[
          const SizedBox(width: 8),
          chip(s.get('peperoNoEqualChip')),
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
          // 1) 도장/칩 — 맨 위
          Positioned(
            top: 2,
            left: 8,
            right: 8,
            child: Center(
              child: FittedBox(fit: BoxFit.scaleDown, child: overlay),
            ),
          ),
          // 2) 한밤이 — 왼쪽으로 비켜 앉아서 말풍선 자리 확보 (하반신은 테이블에 가려 상반신만)
          Positioned(
            top: 38,
            left: 18,
            child: _catFigure(size: 140),
          ),
          // 말풍선 — 고양이 오른쪽, 넓게 (꼬리가 고양이 쪽)
          Positioned(
            top: 48,
            left: 162,
            right: 10,
            child: Align(
              alignment: Alignment.topLeft,
              child: _tauntBubble(_midnightMessage),
            ),
          ),
          // 3) 테이블 — 평평(원근 X), 좌우 여백 + 세로 80%로 축소 (판 크기 다이어트)
          Positioned(
            top: 130,
            bottom: 0,
            left: 28,
            right: 28,
            child: Align(
              alignment: Alignment.topCenter,
              child: FractionallySizedBox(
                heightFactor: 0.8,
                widthFactor: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _Pal.frame, width: 3),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black54,
                          blurRadius: 12,
                          offset: Offset(0, 4)),
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
        _deskScene(
          overlay: Row(
            children: [
              _turnStamp(),
              const SizedBox(width: 8),
              _infoChips(dark: true),
            ],
          ),
        ),
        // 진행 로그 / 선공 패널 — 액션 바 바로 위 (엄지 근처)
        _logPanel(),
        const SizedBox(height: 4),
        if (_phase == GamePhase.playing && _currentTurn == TurnOwner.player)
          _buildActionArea(),
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
        if (_phase == GamePhase.gameOver) const Center(child: BannerAdWidget()),
      ],
    );
  }

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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: c, width: 2.5),
        borderRadius: BorderRadius.circular(4),
        color: c.withOpacity(0.12),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontFamily: _mono,
          fontSize: 14,
          letterSpacing: 2,
          color: c == _Pal.gold ? _Pal.gold : c,
        ),
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

  /// 진행 로그 + 선공자 패널 (접었다 펴기). 세로폰 공간 절약 위해 기본 접힘.
  Widget _logPanel() {
    final String first = _firstMover == null ? '—' : _nameOf(_firstMover!);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _Pal.deskBottom,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _Pal.frame, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => _logOpen = !_logOpen),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  Text(
                    '▸ ${s.get('logLabel')}',
                    style: const TextStyle(
                      fontFamily: _mono,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: _Pal.gold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    s.get('logFirst', [first]),
                    style: const TextStyle(
                      fontFamily: _mono,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _Pal.cream,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    s.get('movesCount',
                        ['${_moveLog.where((e) => e.owner != null).length}']),
                    style: const TextStyle(
                      fontFamily: _mono,
                      fontSize: 10,
                      color: _Pal.inkSoft,
                    ),
                  ),
                  Icon(
                    _logOpen
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 18,
                    color: _Pal.cream,
                  ),
                ],
              ),
            ),
          ),
          if (_logOpen)
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 92),
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: ListView(
                reverse: true,
                shrinkWrap: true,
                children: _moveLog.reversed.map((e) {
                  final Color c = e.owner == TurnOwner.midnight
                      ? const Color(0xFFD98A6E)
                      : (e.owner == TurnOwner.player
                          ? _Pal.gold
                          : _Pal.inkSoft);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1.5),
                    child: Text(
                      e.text,
                      style: TextStyle(
                        fontFamily: _mono,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: c,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBoardArea() {
    if (_config.mode == GameMode.pepero) {
      return _buildPeperoBoard();
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
    if (_config.mode == GameMode.singleRow && count > _config.maxTake) {
      count = _config.maxTake;
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
                    if (multi)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          'R${rowIdx + 1}',
                          style: TextStyle(
                            fontFamily: _mono,
                            fontSize: 13,
                            color: isSelRow
                                ? _Pal.gold
                                : _Pal.cream.withOpacity(0.45),
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
          Wrap(
            spacing: 10,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.end,
            children:
                List.generate(_rows.length, (i) => _peperoBundle(i, myTurn)),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: _Pal.frame,
        border: Border(top: BorderSide(color: _Pal.frameHi, width: 2)),
      ),
      child: _config.mode == GameMode.pepero
          ? _buildPeperoAction()
          : _buildStoneAction(),
    );
  }

  Widget _buildStoneAction() {
    int maxCanTake = _rows[_selectedRow];
    if (_config.mode == GameMode.singleRow) {
      maxCanTake = maxCanTake.clamp(1, _config.maxTake);
    }
    if (_selectedCount > maxCanTake) _selectedCount = maxCanTake;
    if (_selectedCount < 0) _selectedCount = 0;
    final bool hasSel = _selectedCount > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              hasSel
                  ? (_rows.length > 1
                      ? s.get('takeFromRow', ['${_selectedRow + 1}'])
                      : s.get('takeCount'))
                  : s.get('tapToSelect'),
              style: TextStyle(
                fontFamily: _mono,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: hasSel ? _Pal.cream : _Pal.cream.withOpacity(0.55),
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
                          _midnightFace = MidnightFace.neutral;
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
class _DeskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF2B251D);
    canvas.drawRect(Offset.zero & size, bg);

    // 미세 그리드
    final grid = Paint()
      ..color = _Pal.grid
      ..strokeWidth = 1;
    const step = 38.0;
    for (double x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // 등록(+) 마크 — 모서리 안쪽
    final mark = Paint()
      ..color = const Color(0x33E8DCC0)
      ..strokeWidth = 1.5;
    const m = 22.0;
    const pad = 18.0;
    void plus(double cx, double cy) {
      canvas.drawLine(Offset(cx - m / 2, cy), Offset(cx + m / 2, cy), mark);
      canvas.drawLine(Offset(cx, cy - m / 2), Offset(cx, cy + m / 2), mark);
    }

    plus(pad + 8, pad + 8);
    plus(size.width - pad - 8, pad + 8);
    plus(pad + 8, size.height - pad - 8);
    plus(size.width - pad - 8, size.height - pad - 8);
    plus(size.width / 2, size.height / 2);

    // 가장자리 비네팅
    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, Colors.black.withOpacity(0.45)],
        stops: const [0.6, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 말풍선 꼬리(왼쪽 방향 = 고양이 쪽) — 종이색 + 프레임 테두리.
class _BubbleTailLeft extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = _Pal.paper;
    final border = Paint()
      ..color = _Pal.frame
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height);
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
