import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/sua_character.dart';
import '../services/ai_engine.dart';
import '../services/game_save_service.dart';
import '../utils/design_system.dart';
import '../widgets/sua_widget.dart';
import '../widgets/stone_row_widget.dart';

/// 메인 게임 플레이 화면 - 누아르 도박판 레이아웃
/// 대표님 지시: 배경 + 왼쪽 난이도/플레이시간 + 우측상단 고양이 + 중앙 책상 + 하단 버튼
class GameScreen extends StatefulWidget {
  final int stageNumber;

  const GameScreen({super.key, required this.stageNumber});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameState _game;
  late SuaCharacter _night;
  String _dialogue = '';
  bool _showTurnChoice = true;
  bool _isAiThinking = false;
  int _selectedRowIndex = 0;
  int _selectedCount = 0;
  int _hintsUsedThisRound = 0;
  final Stopwatch _playTimer = Stopwatch();

  // 빼빼로(프레츠) 게임용
  int _selectedPeperoIndex = -1;
  int _splitValueA = 0;

  @override
  void initState() {
    super.initState();
    _game = GameState.fromStage(widget.stageNumber);
    _night = SuaCharacter();
    _dialogue = _night.getDialogue(
      isSuaTurn: false,
      suaIsWinning: false,
      isGameOver: false,
      suaWon: false,
      isGameStart: true,
    );
  }

  String get _playTimeText {
    final seconds = _playTimer.elapsed.inSeconds;
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  String get _difficultyText {
    final stage = widget.stageNumber;
    if (stage <= 20) return 'EASY';
    if (stage <= 40) return 'NORMAL';
    if (stage <= 60) return 'HARD';
    if (stage <= 80) return 'EXPERT';
    return 'MASTER';
  }

  Color get _difficultyColor {
    final stage = widget.stageNumber;
    if (stage <= 20) return DS.secondary;
    if (stage <= 40) return DS.primary;
    if (stage <= 60) return DS.warning;
    if (stage <= 80) return DS.error;
    return const Color(0xFF9B59B6);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // 전체 배경 - 어두운 골목
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D0D0D), Color(0xFF1A1209), Color(0xFF0D0D0D)],
          ),
        ),
        child: SafeArea(
          child: _showTurnChoice ? _buildTurnChoice() : _buildGameLayout(),
        ),
      ),
    );
  }

  /// 선공/후공 선택 화면
  Widget _buildTurnChoice() {
    return Padding(
      padding: const EdgeInsets.all(DS.spaceLG),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SuaWidget(sua: _night, dialogue: _dialogue),
          const SizedBox(height: DS.spaceXL),
          // 게임 정보
          Container(
            padding: const EdgeInsets.all(DS.spaceMD),
            decoration: DS.cardDecoration,
            child: Column(
              children: [
                Text(_game.mode.title, style: DS.heading3),
                const SizedBox(height: DS.spaceSM),
                Text(_game.mode.description,
                    style: DS.body, textAlign: TextAlign.center),
                const SizedBox(height: DS.spaceMD),
                _buildGameInfo(),
              ],
            ),
          ),
          const SizedBox(height: DS.spaceXL),
          Text('누가 먼저 배팅하겠나?',
              style: DS.heading3.copyWith(fontStyle: FontStyle.italic)),
          const SizedBox(height: DS.spaceMD),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _startGame(playerFirst: true),
                  style: DS.primaryButton,
                  child: const Text('내가 먼저'),
                ),
              ),
              const SizedBox(width: DS.spaceMD),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _startGame(playerFirst: false),
                  style: DS.secondaryButton,
                  child: const Text('깜냥이 먼저'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameInfo() {
    switch (_game.mode) {
      case GameMode.singleRow:
        return Text(
          '칩: ${_game.rows[0]}개 | 최대 ${_game.maxTake}개 가져가기',
          style: DS.bodyBold.copyWith(color: DS.primary),
        );
      case GameMode.doubleRow:
      case GameMode.tripleRow:
        final rowTexts = _game.rows
            .asMap()
            .entries
            .map((e) => '${e.key + 1}줄: ${e.value}개')
            .join(' | ');
        return Text(
          rowTexts,
          style: DS.bodyBold.copyWith(color: DS.primary),
        );
      case GameMode.pepero:
        return Text(
          '카드 묶음: ${_game.rows[0]}개',
          style: DS.bodyBold.copyWith(color: DS.primary),
        );
    }
  }

  /// 대표님 지시 레이아웃:
  /// - 왼쪽 상단: 난이도
  /// - 왼쪽: 플레이시간
  /// - 우측 상단: 고양이 캐릭터
  /// - 중앙: 책상 배경 위 게임
  /// - 하단: 버튼들
  Widget _buildGameLayout() {
    return Column(
      children: [
        // ── 상단 영역: 왼쪽(난이도+시간) / 우측(고양이+대사) ──
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: DS.spaceMD, vertical: DS.spaceSM),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 왼쪽: 난이도 + 플레이시간 + 뒤로가기
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 뒤로가기 버튼
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back_ios,
                            color: DS.textSecondary, size: 16),
                        Text('나가기',
                            style: TextStyle(
                                color: DS.textSecondary, fontSize: DS.fontSM)),
                      ],
                    ),
                  ),
                  const SizedBox(height: DS.spaceSM),
                  // 난이도 표시
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _difficultyColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(DS.radiusSM),
                      border: Border.all(color: _difficultyColor, width: 1),
                    ),
                    child: Text(
                      _difficultyText,
                      style: TextStyle(
                        color: _difficultyColor,
                        fontSize: DS.fontSM,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: DS.spaceXS),
                  // 스테이지 번호
                  Text(
                    'Stage ${widget.stageNumber}',
                    style: const TextStyle(
                      color: DS.primary,
                      fontSize: DS.fontLG,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: DS.spaceSM),
                  // 플레이시간
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          color: DS.textSecondary, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _playTimeText,
                        style: const TextStyle(
                          color: DS.textSecondary,
                          fontSize: DS.fontSM,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  // 힌트 버튼
                  if (!_game.isGameOver && _game.isPlayerTurn)
                    Padding(
                      padding: const EdgeInsets.only(top: DS.spaceSM),
                      child: GestureDetector(
                        onTap: _hintsUsedThisRound >= 3 ? null : _useHint,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: DS.panelBg,
                            borderRadius: BorderRadius.circular(DS.radiusSM),
                            border: Border.all(
                                color: DS.primaryDark.withOpacity(0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lightbulb_outline,
                                  color: _hintsUsedThisRound >= 3
                                      ? DS.inactive
                                      : DS.primary,
                                  size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '힌트 ${3 - _hintsUsedThisRound}',
                                style: TextStyle(
                                  color: _hintsUsedThisRound >= 3
                                      ? DS.inactive
                                      : DS.primary,
                                  fontSize: DS.fontXS,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              // 우측 상단: 고양이 캐릭터 + 대사
              Column(
                children: [
                  SuaWidget(sua: _night, dialogue: _dialogue, size: 70),
                  const SizedBox(height: DS.spaceXS),
                  // 턴 표시
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _game.isPlayerTurn
                          ? DS.primary.withOpacity(0.2)
                          : DS.secondary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(DS.radiusFull),
                      border: Border.all(
                        color: _game.isPlayerTurn ? DS.primary : DS.secondary,
                      ),
                    ),
                    child: Text(
                      _game.isGameOver
                          ? (_game.playerWon == true
                              ? '승리!'
                              : '패배...')
                          : (_game.isPlayerTurn
                              ? '네 차례'
                              : '깜냥이 차례'),
                      style: TextStyle(
                        color:
                            _game.isPlayerTurn ? DS.primary : DS.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: DS.fontSM,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── 중앙: 책상 배경 위 게임 보드 ──
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: DS.spaceMD),
            decoration: DS.feltTableDecoration,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DS.spaceMD),
              child: _game.mode == GameMode.pepero
                  ? _buildPeperoBoard()
                  : _buildStoneBoard(),
            ),
          ),
        ),

        // ── 하단: 액션 버튼들 ──
        const SizedBox(height: DS.spaceSM),
        if (!_game.isGameOver && _game.isPlayerTurn && !_isAiThinking)
          _buildActionButtons(),
        if (_game.isGameOver) _buildGameOverButtons(),
        if (_isAiThinking)
          Padding(
            padding: const EdgeInsets.all(DS.spaceMD),
            child: Text(
              '깜냥이가 생각 중...',
              style: DS.body.copyWith(fontStyle: FontStyle.italic),
            ),
          ),
        const SizedBox(height: DS.spaceMD),
      ],
    );
  }

  /// 돌(칩) 게임 보드
  Widget _buildStoneBoard() {
    return Column(
      children: _game.rows.asMap().entries.map((entry) {
        final idx = entry.key;
        final count = entry.value;
        return StoneRowWidget(
          rowIndex: idx,
          count: count,
          mode: _game.mode,
          selectedCount: idx == _selectedRowIndex ? _selectedCount : 0,
          isInteractive: _game.isPlayerTurn && !_isAiThinking,
          onCountChanged: (c) {
            setState(() {
              _selectedRowIndex = idx;
              final maxAllowed = _game.mode == GameMode.singleRow
                  ? _game.maxTake
                  : count;
              _selectedCount = c.clamp(1, maxAllowed);
            });
          },
        );
      }).toList(),
    );
  }

  /// 카드(빼빼로) 게임 보드
  Widget _buildPeperoBoard() {
    return Column(
      children: [
        Wrap(
          children: _game.rows.asMap().entries.map((entry) {
            return PeperoWidget(
              index: entry.key,
              size: entry.value,
              isSelected: entry.key == _selectedPeperoIndex,
              onTap: (_game.isPlayerTurn && !_isAiThinking && entry.value >= 3)
                  ? () {
                      setState(() {
                        _selectedPeperoIndex = entry.key;
                        _splitValueA = 1;
                      });
                    }
                  : null,
            );
          }).toList(),
        ),
        // 분할 슬라이더
        if (_selectedPeperoIndex >= 0 &&
            _selectedPeperoIndex < _game.rows.length)
          _buildSplitSlider(),
      ],
    );
  }

  Widget _buildSplitSlider() {
    final pile = _game.rows[_selectedPeperoIndex];
    final maxA = pile ~/ 2;

    return Container(
      margin: const EdgeInsets.only(top: DS.spaceMD),
      padding: const EdgeInsets.all(DS.spaceMD),
      decoration: DS.cardDecoration,
      child: Column(
        children: [
          Text('$pile를 어떻게 나눌까?', style: DS.bodyBold),
          const SizedBox(height: DS.spaceSM),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: DS.primary,
              inactiveTrackColor: DS.panelBg,
              thumbColor: DS.primaryDark,
              overlayColor: DS.primary.withOpacity(0.2),
            ),
            child: Slider(
              value: _splitValueA.toDouble(),
              min: 1,
              max: maxA.toDouble(),
              divisions: maxA > 1 ? maxA - 1 : 1,
              onChanged: (v) {
                final a = v.round();
                if (a != pile - a) {
                  setState(() => _splitValueA = a);
                }
              },
            ),
          ),
          Text(
            '$_splitValueA와 ${pile - _splitValueA}로 나누기',
            style: DS.heading3.copyWith(color: DS.primary),
          ),
        ],
      ),
    );
  }

  /// 하단 액션 버튼
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DS.spaceLG),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _selectedCount > 0 || _selectedPeperoIndex >= 0
              ? _playerMove
              : null,
          style: DS.primaryButton,
          child: Text(
            _game.mode == GameMode.pepero
                ? '나누기'
                : '$_selectedCount개 가져가기',
            style: const TextStyle(letterSpacing: 1),
          ),
        ),
      ),
    );
  }

  /// 게임 오버 버튼
  Widget _buildGameOverButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DS.spaceLG),
      child: Column(
        children: [
          if (_game.playerWon == true)
            Container(
              padding: const EdgeInsets.all(DS.spaceMD),
              decoration: BoxDecoration(
                color: DS.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(DS.radiusMD),
                border: Border.all(color: DS.primaryDark),
              ),
              child: Text(
                '이번 판은 네 승리다.',
                style: TextStyle(
                  color: DS.primary,
                  fontSize: DS.fontLG,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if (_game.playerWon == false)
            Container(
              padding: const EdgeInsets.all(DS.spaceMD),
              decoration: BoxDecoration(
                color: DS.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(DS.radiusMD),
                border: Border.all(color: DS.error.withOpacity(0.5)),
              ),
              child: const Text(
                '이번엔 내가 이겼군.',
                style: TextStyle(
                  color: DS.error,
                  fontSize: DS.fontLG,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: DS.spaceMD),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: DS.secondaryButton,
                  child: const Text('판 떠나기'),
                ),
              ),
              const SizedBox(width: DS.spaceMD),
              Expanded(
                child: ElevatedButton(
                  onPressed: _retryStage,
                  style: DS.primaryButton,
                  child: const Text('다시 배팅'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 게임 로직 ───

  void _startGame({required bool playerFirst}) {
    _playTimer.start();
    setState(() {
      _showTurnChoice = false;
      _game.isPlayerTurn = playerFirst;
      _updateNightState();
    });

    if (!playerFirst) {
      _aiMove();
    }
  }

  void _playerMove() {
    bool success;

    if (_game.mode == GameMode.pepero) {
      success = _game.makeMove(_selectedPeperoIndex, _splitValueA);
      _selectedPeperoIndex = -1;
    } else {
      success = _game.makeMove(_selectedRowIndex, _selectedCount);
      _selectedCount = 0;
    }

    if (!success) return;

    setState(() {
      _updateNightState();
    });

    if (_game.isGameOver) {
      _playTimer.stop();
      _handleGameOver();
    } else {
      _aiMove();
    }
  }

  Future<void> _aiMove() async {
    setState(() => _isAiThinking = true);

    await Future.delayed(const Duration(milliseconds: 800 + 400));

    if (!mounted) return;

    final move = AIEngine.getBestMove(_game);
    _game.makeMove(move.rowIndex, move.count);

    setState(() {
      _isAiThinking = false;
      _updateNightState();
    });

    if (_game.isGameOver) {
      _playTimer.stop();
      _handleGameOver();
    }
  }

  void _updateNightState() {
    final nightIsWinning = AIEngine.isAIWinning(_game);
    _night.updateEmotion(
      isSuaTurn: !_game.isPlayerTurn,
      suaIsWinning: nightIsWinning,
      isGameOver: _game.isGameOver,
      suaWon: _game.playerWon == false,
    );
    _dialogue = _night.getDialogue(
      isSuaTurn: !_game.isPlayerTurn,
      suaIsWinning: nightIsWinning,
      isGameOver: _game.isGameOver,
      suaWon: _game.playerWon == false,
      isGameStart: false,
    );
  }

  void _handleGameOver() {
    if (_game.playerWon == true) {
      GameSaveService.setMaxStageCleared(widget.stageNumber);
      final world = GameState.getWorldForStage(widget.stageNumber);
      if (GameSaveService.canUnlockNextWorld(world) && world < 4) {
        GameSaveService.unlockWorld(world + 1);
      }
    }
  }

  void _retryStage() {
    _playTimer.reset();
    setState(() {
      _game = GameState.fromStage(widget.stageNumber);
      _night = SuaCharacter();
      _showTurnChoice = true;
      _selectedCount = 0;
      _selectedRowIndex = 0;
      _selectedPeperoIndex = -1;
      _hintsUsedThisRound = 0;
      _dialogue = _night.getDialogue(
        isSuaTurn: false,
        suaIsWinning: false,
        isGameOver: false,
        suaWon: false,
        isGameStart: true,
      );
    });
  }

  void _useHint() {
    if (_hintsUsedThisRound >= 3) return;

    final hasKey = GameSaveService.adsRemoved || GameSaveService.hintKeys > 0;
    if (!hasKey && !GameSaveService.adsRemoved) {
      _showAdForHint();
      return;
    }

    if (!GameSaveService.adsRemoved) {
      GameSaveService.useHintKey();
    }

    _hintsUsedThisRound++;
    final hint = AIEngine.getHint(_game);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DS.panelBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DS.radiusMD),
          side: const BorderSide(color: DS.primaryDark),
        ),
        title: const Text('깜냥이의 귓속말',
            style: TextStyle(color: DS.primary)),
        content: Text(hint,
            style: DS.body.copyWith(fontSize: DS.fontLG, color: DS.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('알겠어', style: TextStyle(color: DS.primary)),
          ),
        ],
      ),
    );
  }

  void _showAdForHint() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DS.panelBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DS.radiusMD),
          side: const BorderSide(color: DS.primaryDark),
        ),
        title: const Text('힌트가 필요한가?',
            style: TextStyle(color: DS.primary)),
        content: const Text('광고를 시청하면 깜냥이가 귓속말을 해줄 거야.',
            style: TextStyle(color: DS.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('됐어', style: TextStyle(color: DS.inactive)),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: 광고 시청 로직
              GameSaveService.addHintKeys(1);
              Navigator.of(ctx).pop();
              _useHint();
            },
            style: DS.primaryButton.copyWith(
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
            child: const Text('광고 보기'),
          ),
        ],
      ),
    );
  }
}
