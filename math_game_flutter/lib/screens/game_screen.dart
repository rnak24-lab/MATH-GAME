import 'package:flutter/material.dart';
import 'dart:async';
import '../game/stage_manager.dart';
import '../game/nim_engine.dart';
import '../models/game_state.dart';
import '../widgets/sua_character.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_strings.dart';

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
  int _totalInitialStones = 0;

  // Selection state
  int _selectedRow = 0;
  int _selectedCount = 1;
  int _selectedPile = 0;
  int _splitA = 1;

  // Sua state
  SuaFace _suaFace = SuaFace.neutral;
  String _suaMessage = '';

  // Hints
  int _hintsLeft = 3;

  @override
  void initState() {
    super.initState();
    _config = _engine.generateStage(widget.stageNumber);
    _rows = List.from(_config.rows);
    _totalInitialStones = _rows.reduce((a, b) => a + b);
    _suaMessage = _getGreeting();
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
    }
  }

  String _getModeRule() {
    switch (_config.mode) {
      case GameMode.singleRow:
        return s.get('ruleSingleRow', ['${_config.maxTake}']);
      case GameMode.doubleRow:
        return s.get('ruleDoubleRow');
      case GameMode.pepero:
        return s.get('rulePepero');
      case GameMode.tripleRow:
        return s.get('ruleTripleRow');
    }
  }

  void _updateSuaFace() {
    int remaining = _rows.reduce((a, b) => a + b);
    double progress = 1.0 - (remaining / _totalInitialStones);
    bool isLate = progress > 0.5;

    bool aiWinning;
    if (_config.mode == GameMode.singleRow) {
      int n = _rows[0];
      aiWinning = (n - 1) % (_config.maxTake + 1) == 0;
      if (_currentTurn == TurnOwner.sua) aiWinning = !aiWinning;
    } else {
      aiWinning = _engine.isAIWinning(_rows, _config.mode);
      if (_currentTurn == TurnOwner.player) aiWinning = !aiWinning;
    }

    setState(() {
      if (aiWinning) {
        _suaFace = isLate ? SuaFace.happy2 : SuaFace.happy1;
        List<String> msgKeys = isLate
            ? ['suaWinLate1', 'suaWinLate2', 'suaWinLate3']
            : ['suaWinEarly1', 'suaWinEarly2', 'suaWinEarly3'];
        _suaMessage = s.get(msgKeys[_turnCount % msgKeys.length]);
      } else {
        _suaFace = isLate ? SuaFace.worried2 : SuaFace.worried1;
        List<String> msgKeys = isLate
            ? ['suaLoseLate1', 'suaLoseLate2', 'suaLoseLate3']
            : ['suaLoseEarly1', 'suaLoseEarly2', 'suaLoseEarly3'];
        _suaMessage = s.get(msgKeys[_turnCount % msgKeys.length]);
      }
    });
  }

  void _chooseTurn(TurnOwner first) {
    setState(() {
      _currentTurn = first;
      _phase = GamePhase.playing;
      if (first == TurnOwner.player) {
        _suaFace = SuaFace.neutral;
        _suaMessage = s.get('turnPlayerFirst');
      } else {
        _suaFace = SuaFace.confident;
        _suaMessage = s.get('turnSuaFirst');
      }
    });

    if (first == TurnOwner.sua) {
      Future.delayed(const Duration(milliseconds: 800), _suaPlay);
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
    setState(() {
      _phase = GamePhase.gameOver;
      _playerWon = playerWins;
      if (playerWins) {
        _suaFace = SuaFace.worried2;
        _suaMessage = s.get('suaLost');
      } else {
        _suaFace = SuaFace.happy2;
        _suaMessage = s.get('suaWon');
      }
    });

    if (playerWins) {
      widget.stageManager.clearStage(widget.stageNumber);
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) _showNextStageDialog();
      });
    }
  }

  void _showNextStageDialog() {
    bool hasNext = widget.stageNumber < 100;

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
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B9D).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⭐', style: TextStyle(fontSize: 50)),
                const SizedBox(height: 12),
                Text(
                  s.get('stageClear'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF7C4DFF),
                    letterSpacing: 1,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s.get('stageClearDesc', ['${widget.stageNumber}']),
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 8),
                SuaCharacter(
                  face: SuaFace.worried1,
                  size: 80,
                  animate: false,
                ),
                const SizedBox(height: 8),
                Text(
                  s.get('suaNextTime'),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 24),
                if (hasNext) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B9D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            s.get('nextStage'),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
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
                      foregroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      s.get('backToStageSelect'),
                      style: const TextStyle(fontSize: 14),
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

  void _playerMove() {
    if (_phase != GamePhase.playing || _currentTurn != TurnOwner.player) return;

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
      _currentTurn = TurnOwner.sua;
      _selectedCount = 1;
    });

    if (!_checkGameOver()) {
      _updateSuaFace();
      Future.delayed(const Duration(milliseconds: 1000), _suaPlay);
    }
  }

  void _suaPlay() {
    if (_phase != GamePhase.playing) return;

    NimMove move;
    switch (_config.mode) {
      case GameMode.singleRow:
        move = _engine.singleRowAI(_rows[0], _config.maxTake);
        break;
      case GameMode.doubleRow:
      case GameMode.tripleRow:
        move = _engine.multiRowAI(_rows);
        break;
      case GameMode.pepero:
        move = _engine.peperoAI(_rows);
        break;
    }

    setState(() {
      if (move.isPepero) {
        _rows.removeAt(move.rowIndex);
        _rows.add(move.splitA);
        _rows.add(move.splitB);
        _rows.sort((x, y) => y.compareTo(x));
        _suaMessage = s.get('suaSplit', ['${move.splitA}', '${move.splitB}']);
      } else {
        _rows[move.rowIndex] -= move.count;
        if (_config.mode == GameMode.singleRow) {
          _suaMessage = s.get('suaTakeN', ['${move.count}']);
        } else {
          _suaMessage = s.get('suaTakeFromRow',
              ['${move.count}', '${move.rowIndex + 1}']);
        }
      }
      _turnCount++;
      _currentTurn = TurnOwner.player;
    });

    if (!_checkGameOver()) {
      _updateSuaFace();
    }
  }

  void _showHint() {
    if (_hintsLeft <= 0 || _currentTurn != TurnOwner.player) return;

    NimMove hint;
    switch (_config.mode) {
      case GameMode.singleRow:
        hint = _engine.singleRowAI(_rows[0], _config.maxTake);
        break;
      case GameMode.doubleRow:
      case GameMode.tripleRow:
        hint = _engine.multiRowAI(_rows);
        break;
      case GameMode.pepero:
        hint = _engine.peperoAI(_rows);
        break;
    }

    String hintText;
    if (hint.isPepero) {
      hintText = s.get('hintPepero', ['${hint.splitA}', '${hint.splitB}']);
    } else if (_config.mode == GameMode.singleRow) {
      hintText = s.get('hintSingleRow', ['${hint.count}']);
    } else {
      hintText = s.get('hintMultiRow',
          ['${hint.count}', '${hint.rowIndex + 1}']);
    }

    setState(() => _hintsLeft--);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(hintText, style: const TextStyle(fontSize: 15)),
        backgroundColor: const Color(0xFF7C4DFF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Stage ${widget.stageNumber}',
          style: const TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_phase == GamePhase.playing && _currentTurn == TurnOwner.player)
            TextButton.icon(
              onPressed: _hintsLeft > 0 ? _showHint : null,
              icon: const Icon(Icons.lightbulb_outline, size: 18),
              label: Text('$_hintsLeft'),
              style: TextButton.styleFrom(
                foregroundColor:
                    _hintsLeft > 0 ? const Color(0xFFFF9800) : Colors.grey,
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
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

  Widget _buildTurnChoice() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          SuaWithBubble(
            face: _suaFace,
            message: _suaMessage,
            size: 120,
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  _getModeTitle(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7C4DFF),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getModeRule(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s.get('initialState', [_rows.join(', ')]),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            s.get('whoGoesFirst'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _choiceButton(
                  s.get('meFirst'),
                  Icons.person,
                  const Color(0xFF42A5F5),
                  () => _chooseTurn(TurnOwner.player),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _choiceButton(
                  s.get('suaFirst'),
                  Icons.smart_toy,
                  const Color(0xFFFF6B9D),
                  () => _chooseTurn(TurnOwner.sua),
                ),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _choiceButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      shadowColor: color.withOpacity(0.4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameBoard() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SuaWithBubble(
            face: _suaFace,
            message: _suaMessage,
            size: 100,
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
          decoration: BoxDecoration(
            color: _phase == GamePhase.gameOver
                ? (_playerWon
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFF44336))
                : (_currentTurn == TurnOwner.player
                    ? const Color(0xFF42A5F5)
                    : const Color(0xFFFF6B9D)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _phase == GamePhase.gameOver
                ? (_playerWon ? s.get('victory') : s.get('defeat'))
                : (_currentTurn == TurnOwner.player
                    ? s.get('myTurn')
                    : s.get('suaTurn')),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        Expanded(child: _buildBoardArea()),
        if (_phase == GamePhase.playing && _currentTurn == TurnOwner.player)
          _buildActionArea(),
        if (_phase == GamePhase.gameOver && !_playerWon)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
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
                    icon: const Icon(Icons.refresh),
                    label: Text(s.get('retry')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF42A5F5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: Text(s.get('goBack')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBoardArea() {
    if (_config.mode == GameMode.pepero) {
      return _buildPeperoBoard();
    }
    return _buildStonesBoard();
  }

  Widget _buildStonesBoard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_rows.length, (rowIdx) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                if (_rows.length > 1)
                  Text(
                    s.get('rowLabel', ['${rowIdx + 1}']),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _selectedRow == rowIdx
                          ? const Color(0xFF7C4DFF)
                          : Colors.grey[500],
                    ),
                  ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: _rows.length > 1 && _currentTurn == TurnOwner.player
                      ? () => setState(() {
                            _selectedRow = rowIdx;
                            _selectedCount = 1;
                          })
                      : null,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _selectedRow == rowIdx
                          ? const Color(0xFF7C4DFF).withOpacity(0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: _selectedRow == rowIdx
                          ? Border.all(
                              color: const Color(0xFF7C4DFF).withOpacity(0.3),
                              width: 2)
                          : null,
                    ),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: List.generate(_rows[rowIdx], (i) {
                        bool isSelected = rowIdx == _selectedRow &&
                            i >= _rows[rowIdx] - _selectedCount;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFF6B9D)
                                : const Color(0xFF78909C),
                            shape: BoxShape.circle,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFFF6B9D)
                                          .withOpacity(0.4),
                                      blurRadius: 6,
                                    )
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.close,
                                  color: Colors.white, size: 16)
                              : null,
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPeperoBoard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            s.get('peperoBundles'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF8D6E63),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: List.generate(_rows.length, (i) {
              bool selectable = _rows[i] >= 3;
              bool selected = i == _selectedPile;
              return GestureDetector(
                onTap: selectable && _currentTurn == TurnOwner.player
                    ? () => setState(() {
                          _selectedPile = i;
                          _splitA = 1;
                        })
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF8D6E63).withOpacity(0.15)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF8D6E63)
                          : Colors.grey[300]!,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '🍫',
                        style: TextStyle(fontSize: selectable ? 28 : 20),
                      ),
                      Text(
                        s.get('nPieces', ['${_rows[i]}']),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: selectable
                              ? const Color(0xFF2C3E50)
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildActionArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _rows.length > 1
                  ? s.get('takeFromRow', ['${_selectedRow + 1}'])
                  : s.get('takeCount'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            Text(
              s.get('nPieces', ['$_selectedCount']),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFF6B9D),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: _selectedCount.toDouble(),
          min: 1,
          max: maxCanTake.toDouble(),
          divisions: maxCanTake > 1 ? maxCanTake - 1 : 1,
          activeColor: const Color(0xFFFF6B9D),
          onChanged: (val) => setState(() => _selectedCount = val.round()),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _playerMove,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B9D),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 4,
            ),
            child: Text(
              s.get('takeNStones', ['$_selectedCount']),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeperoAction() {
    if (_selectedPile >= _rows.length || _rows[_selectedPile] < 3) {
      return Center(
        child: Text(
          s.get('selectSplittable'),
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF8D6E63),
          ),
        ),
      );
    }

    int pile = _rows[_selectedPile];
    int maxSplitA = (pile - 1) ~/ 2;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              s.get('split'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            Text(
              '$_splitA + ${pile - _splitA}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8D6E63),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: _splitA.toDouble(),
          min: 1,
          max: maxSplitA.toDouble(),
          divisions: maxSplitA > 1 ? maxSplitA - 1 : 1,
          activeColor: const Color(0xFF8D6E63),
          onChanged: (val) {
            int a = val.round();
            int b = pile - a;
            if (a != b) {
              setState(() => _splitA = a);
            }
          },
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              int a = _splitA;
              int b = pile - a;
              if (a != b && a > 0 && b > 0) {
                setState(() {
                  _rows.removeAt(_selectedPile);
                  _rows.add(a);
                  _rows.add(b);
                  _rows.sort((x, y) => y.compareTo(x));
                  _turnCount++;
                  _currentTurn = TurnOwner.sua;
                  _selectedPile = 0;
                  _splitA = 1;
                });
                if (!_checkGameOver()) {
                  _updateSuaFace();
                  Future.delayed(
                      const Duration(milliseconds: 1000), _suaPlay);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8D6E63),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 4,
            ),
            child: Text(
              s.get('splitAction', ['$_splitA', '${pile - _splitA}']),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
