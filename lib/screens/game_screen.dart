import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/sua_character.dart';
import '../services/ai_engine.dart';
import '../services/game_save_service.dart';
import '../utils/design_system.dart';
import '../widgets/sua_widget.dart';
import '../widgets/stone_row_widget.dart';

/// 메인 게임 플레이 화면
class GameScreen extends StatefulWidget {
  final int stageNumber;

  const GameScreen({super.key, required this.stageNumber});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameState _game;
  late SuaCharacter _sua;
  String _dialogue = '';
  bool _showTurnChoice = true;
  bool _isAiThinking = false;
  int _selectedRowIndex = 0;
  int _selectedCount = 0;
  int _hintsUsedThisRound = 0;

  // 빼빼로 게임용
  int _selectedPeperoIndex = -1;
  int _splitValueA = 0;

  @override
  void initState() {
    super.initState();
    _game = GameState.fromStage(widget.stageNumber);
    _sua = SuaCharacter();
    _dialogue = _sua.getDialogue(
      isSuaTurn: false,
      suaIsWinning: false,
      isGameOver: false,
      suaWon: false,
      isGameStart: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final worldColor = DS.getWorldColor(
      GameState.getWorldForStage(widget.stageNumber),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Stage ${widget.stageNumber}',
          style: TextStyle(color: worldColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          // 힌트 버튼
          if (!_game.isGameOver && _game.isPlayerTurn)
            IconButton(
              onPressed: _hintsUsedThisRound >= 3 ? null : _useHint,
              icon: const Icon(Icons.lightbulb_outline),
              tooltip: '힌트 (${3 - _hintsUsedThisRound}회 남음)',
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              worldColor.withOpacity(0.1),
              worldColor.withOpacity(0.03),
            ],
          ),
        ),
        child: SafeArea(
          child: _showTurnChoice ? _buildTurnChoice() : _buildGameBoard(),
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
          SuaWidget(sua: _sua, dialogue: _dialogue),
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
          const Text('누가 먼저 시작할까요?', style: DS.heading3),
          const SizedBox(height: DS.spaceMD),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _startGame(playerFirst: true),
                  style: DS.primaryButton,
                  child: const Text('내가 먼저!'),
                ),
              ),
              const SizedBox(width: DS.spaceMD),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _startGame(playerFirst: false),
                  style: DS.secondaryButton,
                  child: const Text('수아 먼저!'),
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
          '돌: ${_game.rows[0]}개 | 최대 ${_game.maxTake}개 가져가기',
          style: DS.bodyBold.copyWith(color: DS.secondary),
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
          style: DS.bodyBold.copyWith(color: DS.secondary),
        );
      case GameMode.pepero:
        return Text(
          '빼빼로 묶음: ${_game.rows[0]}개',
          style: DS.bodyBold.copyWith(color: DS.secondary),
        );
    }
  }

  /// 게임 보드 화면
  Widget _buildGameBoard() {
    return Column(
      children: [
        // 수아 캐릭터 영역
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DS.spaceMD),
          child: SuaWidget(sua: _sua, dialogue: _dialogue, size: 80),
        ),
        const SizedBox(height: DS.spaceSM),
        // 턴 표시
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _game.isPlayerTurn ? DS.success : DS.secondary,
            borderRadius: BorderRadius.circular(DS.radiusFull),
          ),
          child: Text(
            _game.isGameOver
                ? (_game.playerWon == true ? '🎉 승리!' : '😢 패배...')
                : (_game.isPlayerTurn ? '🎯 내 차례' : '💭 수아 차례'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: DS.spaceSM),
        // 게임 보드
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: DS.spaceMD),
            child: _game.mode == GameMode.pepero
                ? _buildPeperoBoard()
                : _buildStoneBoard(),
          ),
        ),
        // 액션 버튼 영역
        if (!_game.isGameOver && _game.isPlayerTurn && !_isAiThinking)
          _buildActionButtons(),
        if (_game.isGameOver) _buildGameOverButtons(),
        const SizedBox(height: DS.spaceMD),
      ],
    );
  }

  /// 돌 게임 보드
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

  /// 빼빼로 게임 보드
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
    final maxA = pile ~/ 2; // a < b 조건

    return Container(
      margin: const EdgeInsets.only(top: DS.spaceMD),
      padding: const EdgeInsets.all(DS.spaceMD),
      decoration: DS.cardDecoration,
      child: Column(
        children: [
          Text('$pile를 어떻게 나눌까?', style: DS.bodyBold),
          const SizedBox(height: DS.spaceSM),
          Slider(
            value: _splitValueA.toDouble(),
            min: 1,
            max: maxA.toDouble(),
            divisions: maxA > 1 ? maxA - 1 : 1,
            activeColor: DS.primary,
            onChanged: (v) {
              final a = v.round();
              if (a != pile - a) {
                setState(() => _splitValueA = a);
              }
            },
          ),
          Text(
            '$_splitValueA와 ${pile - _splitValueA}로 나누기',
            style: DS.heading3.copyWith(color: DS.primary),
          ),
        ],
      ),
    );
  }

  /// 액션 버튼
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
                ? '나누기!'
                : '$_selectedCount개 가져가기!',
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
                color: DS.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(DS.radiusMD),
                border: Border.all(color: DS.success),
              ),
              child: const Text(
                '🎉 축하해! 수아를 이겼어!',
                style: TextStyle(
                  color: DS.success,
                  fontSize: DS.fontLG,
                  fontWeight: FontWeight.bold,
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
                  child: const Text('돌아가기'),
                ),
              ),
              const SizedBox(width: DS.spaceMD),
              Expanded(
                child: ElevatedButton(
                  onPressed: _retryStage,
                  style: DS.primaryButton,
                  child: const Text('다시 하기'),
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
    setState(() {
      _showTurnChoice = false;
      _game.isPlayerTurn = playerFirst;
      _updateSuaState();
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
      _updateSuaState();
    });

    if (_game.isGameOver) {
      _handleGameOver();
    } else {
      _aiMove();
    }
  }

  Future<void> _aiMove() async {
    setState(() => _isAiThinking = true);

    // AI "생각하는" 딜레이
    await Future.delayed(const Duration(milliseconds: 800 + 400));

    if (!mounted) return;

    final move = AIEngine.getBestMove(_game);
    _game.makeMove(move.rowIndex, move.count);

    setState(() {
      _isAiThinking = false;
      _updateSuaState();
    });

    if (_game.isGameOver) {
      _handleGameOver();
    }
  }

  void _updateSuaState() {
    final suaIsWinning = AIEngine.isAIWinning(_game);
    _sua.updateEmotion(
      isSuaTurn: !_game.isPlayerTurn,
      suaIsWinning: suaIsWinning,
      isGameOver: _game.isGameOver,
      suaWon: _game.playerWon == false,
    );
    _dialogue = _sua.getDialogue(
      isSuaTurn: !_game.isPlayerTurn,
      suaIsWinning: suaIsWinning,
      isGameOver: _game.isGameOver,
      suaWon: _game.playerWon == false,
      isGameStart: false,
    );
  }

  void _handleGameOver() {
    if (_game.playerWon == true) {
      GameSaveService.setMaxStageCleared(widget.stageNumber);
      // 월드 해금 체크
      final world = GameState.getWorldForStage(widget.stageNumber);
      if (GameSaveService.canUnlockNextWorld(world) && world < 4) {
        GameSaveService.unlockWorld(world + 1);
      }
    }
  }

  void _retryStage() {
    setState(() {
      _game = GameState.fromStage(widget.stageNumber);
      _sua = SuaCharacter();
      _showTurnChoice = true;
      _selectedCount = 0;
      _selectedRowIndex = 0;
      _selectedPeperoIndex = -1;
      _hintsUsedThisRound = 0;
      _dialogue = _sua.getDialogue(
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DS.radiusLG),
        ),
        title: const Text('💡 수아의 비밀 힌트'),
        content: Text(hint, style: DS.body.copyWith(fontSize: DS.fontLG)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('고마워!'),
          ),
        ],
      ),
    );
  }

  void _showAdForHint() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DS.radiusLG),
        ),
        title: const Text('🔑 힌트 열쇠가 필요해요!'),
        content: const Text('광고를 시청하면 힌트 열쇠를 받을 수 있어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('다음에'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: 광고 시청 로직
              GameSaveService.addHintKeys(1);
              Navigator.of(ctx).pop();
              _useHint();
            },
            style: DS.primaryButton.copyWith(
              padding: WidgetStatePropertyAll(
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
            child: const Text('광고 보기'),
          ),
        ],
      ),
    );
  }
}
