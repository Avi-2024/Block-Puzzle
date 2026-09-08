import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/ads/ad_service.dart';
import '../../../core/audio/game_audio_service.dart';
import '../../../core/storage/game_stats_repository.dart';
import '../../../core/storage/shared_preferences_game_session_repository.dart';
import '../../../core/storage/shared_preferences_game_stats_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../daily_challenge/domain/daily_challenge_definition.dart';
import '../../daily_challenge/domain/daily_piece_generator.dart';
import '../../progression/application/progression_runtime.dart';
import '../application/game_session_controller.dart';
import '../domain/block_piece.dart';
import '../domain/game_engine.dart';
import 'board_drag_projector.dart';

class UnifiedGameScreen extends StatefulWidget {
  const UnifiedGameScreen.endless({super.key}) : dailyChallenge = null;

  const UnifiedGameScreen.daily({
    required DailyChallengeDefinition challenge,
    super.key,
  }) : dailyChallenge = challenge;

  final DailyChallengeDefinition? dailyChallenge;

  bool get isDaily => dailyChallenge != null;

  @override
  State<UnifiedGameScreen> createState() => _UnifiedGameScreenState();
}

class _UnifiedGameScreenState extends State<UnifiedGameScreen> {
  final GlobalKey _boardGridKey = GlobalKey(debugLabel: 'blockiva-board-grid');
  late final GameSessionController _controller;
  late final GameAudioService _audio;

  _PlacementPreview? _preview;
  String? _moveFeedback;
  Set<int> _clearedRows = <int>{};
  Set<int> _clearedCols = <int>{};
  var _feedbackToken = 0;
  var _clearFlashToken = 0;
  var _boardPulse = false;
  var _dailyFinished = false;
  var _dailySuccess = false;
  var _dailyRewardGranted = 0;

  DailyChallengeDefinition? get _daily => widget.dailyChallenge;

  bool get _terminal => widget.isDaily ? _dailyFinished : _controller.gameOver;

  int get _dailyMovesLeft {
    final DailyChallengeDefinition? daily = _daily;
    if (daily == null) return 0;
    return math.max(0, daily.moveLimit - _controller.engine.movesPlayed);
  }

  @override
  void initState() {
    super.initState();
    _audio = GameAudioService();
    unawaited(_initializeAudio());

    final DailyChallengeDefinition? daily = _daily;
    if (daily == null) {
      _controller = GameSessionController(
        statsRepository: SharedPreferencesGameStatsRepository(),
        adService: kDebugMode
            ? const DebugRewardAdService()
            : const NoOpAdService(),
        progressionController: ProgressionRuntime.instance.controller,
      );
    } else {
      _controller = GameSessionController(
        statsRepository: _IsolatedDailyStatsRepository(),
        sessionRepository: SharedPreferencesGameSessionRepository(
          key: 'game.daily.${daily.dayKey}.v1',
        ),
        adService: const NoOpAdService(),
        pieceGenerator: DailyPieceGenerator(seed: daily.seed),
      );
    }

    _controller.addListener(_refresh);
    unawaited(_initializeController());
  }

  Future<void> _initializeController() async {
    await _controller.initialize();
    if (!mounted) return;
    _evaluateDailyOutcome(playFeedback: false);
    setState(() {});
  }

  Future<void> _initializeAudio() async {
    await _audio.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_refresh)
      ..dispose();
    unawaited(_audio.dispose());
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  RenderBox? get _boardBox {
    final BuildContext? context = _boardGridKey.currentContext;
    if (context == null) return null;
    final RenderObject? object = context.findRenderObject();
    return object is RenderBox && object.hasSize ? object : null;
  }

  double get _feedbackCellSize {
    final RenderBox? box = _boardBox;
    return box == null ? 38 : BoardDragProjector.feedbackCellSize(box.size);
  }

  void _updateDragPreview(BlockPiece piece, Offset globalPointer) {
    if (_terminal) return;
    final RenderBox? box = _boardBox;
    if (box == null) return;

    final BoardDropOrigin? origin = BoardDragProjector.project(
      pointerInBoard: box.globalToLocal(globalPointer),
      boardSize: box.size,
      piece: piece,
    );
    if (origin == null) {
      _setPreview(null);
      return;
    }

    _setPreview(
      _PlacementPreview(
        piece: piece,
        row: origin.row,
        col: origin.col,
        valid: _controller.engine.canPlace(piece, origin.row, origin.col),
      ),
    );
  }

  void _setPreview(_PlacementPreview? next) {
    if (!mounted || _preview == next) return;
    setState(() => _preview = next);
  }

  void _finishDrag(BlockPiece piece) {
    final _PlacementPreview? preview = _preview;
    if (!_terminal &&
        preview != null &&
        preview.piece.id == piece.id &&
        preview.valid) {
      _place(piece, preview.row, preview.col);
      return;
    }
    HapticFeedback.lightImpact();
    _setPreview(null);
  }

  void _place(BlockPiece piece, int row, int col) {
    if (_terminal) return;
    final bool placed = _controller.placePiece(piece, row, col);
    if (!placed) {
      HapticFeedback.lightImpact();
      _setPreview(null);
      return;
    }

    final move = _controller.lastMove;
    if (move != null && move.linesCleared > 0) {
      HapticFeedback.mediumImpact();
      unawaited(_pulseBoard());
      unawaited(_flashClearedLines(move.clearedRows, move.clearedCols));
      unawaited(move.combo > 1 ? _audio.playCombo() : _audio.playClear());
      final String label = move.combo > 1
          ? 'COMBO x${move.combo}  +${move.scoreGained}'
          : move.linesCleared > 1
              ? '${move.linesCleared} LINES  +${move.scoreGained}'
              : '+${move.scoreGained}';
      unawaited(_showMoveFeedback(label));
    } else {
      HapticFeedback.selectionClick();
      unawaited(_audio.playPlacement());
    }

    _setPreview(null);
    _evaluateDailyOutcome();
  }

  void _evaluateDailyOutcome({bool playFeedback = true}) {
    final DailyChallengeDefinition? daily = _daily;
    if (daily == null || !_controller.initialized) return;

    final bool wasFinished = _dailyFinished;
    final bool alreadyCompleted = ProgressionRuntime.instance.controller
        .isDailyChallengeCompleted(daily.dayKey);
    final bool targetReached = _controller.engine.score >= daily.targetScore;
    final bool movesExhausted =
        _controller.engine.movesPlayed >= daily.moveLimit;
    final bool noMoves = _controller.gameOver;

    _dailySuccess = alreadyCompleted || targetReached;
    _dailyFinished = _dailySuccess || movesExhausted || noMoves;

    if (targetReached && !alreadyCompleted) {
      _dailyRewardGranted = ProgressionRuntime.instance.controller
          .completeDailyChallenge(
        dayKey: daily.dayKey,
        rewardCoins: daily.rewardCoins,
      );
    }

    if (!wasFinished && _dailyFinished && playFeedback) {
      if (_dailySuccess) {
        HapticFeedback.heavyImpact();
        unawaited(_audio.playCombo());
      } else {
        HapticFeedback.mediumImpact();
      }
    }
  }

  Future<void> _pulseBoard() async {
    if (!mounted) return;
    setState(() => _boardPulse = true);
    await Future<void>.delayed(const Duration(milliseconds: 115));
    if (mounted) setState(() => _boardPulse = false);
  }

  Future<void> _flashClearedLines(List<int> rows, List<int> cols) async {
    final int token = ++_clearFlashToken;
    if (mounted) {
      setState(() {
        _clearedRows = rows.toSet();
        _clearedCols = cols.toSet();
      });
    }
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted || token != _clearFlashToken) return;
    setState(() {
      _clearedRows = <int>{};
      _clearedCols = <int>{};
    });
  }

  Future<void> _showMoveFeedback(String label) async {
    final int token = ++_feedbackToken;
    setState(() => _moveFeedback = label);
    await Future<void>.delayed(const Duration(milliseconds: 760));
    if (!mounted || token != _feedbackToken) return;
    setState(() => _moveFeedback = null);
  }

  Future<void> _toggleSound() async {
    await _audio.toggle();
    if (!mounted) return;
    setState(() {});
    if (_audio.enabled) unawaited(_audio.playPlacement());
  }

  void _restart() {
    final DailyChallengeDefinition? daily = _daily;
    if (daily != null &&
        ProgressionRuntime.instance.controller
            .isDailyChallengeCompleted(daily.dayKey)) {
      return;
    }

    setState(() {
      _preview = null;
      _moveFeedback = null;
      _clearedRows = <int>{};
      _clearedCols = <int>{};
      _boardPulse = false;
      _dailyFinished = false;
      _dailySuccess = false;
      _dailyRewardGranted = 0;
      _feedbackToken += 1;
      _clearFlashToken += 1;
    });
    _controller.restart();
    HapticFeedback.selectionClick();
    unawaited(_audio.playPlacement());
  }

  Future<void> _confirmRestart() async {
    if (_controller.engine.score == 0 && _controller.engine.movesPlayed == 0) {
      _restart();
      return;
    }

    final bool? confirmed = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (BuildContext context) => _RestartSheet(
        daily: widget.isDaily,
        onCancel: () => Navigator.of(context).pop(false),
        onRestart: () => Navigator.of(context).pop(true),
      ),
    );
    if (confirmed == true && mounted) _restart();
  }

  Future<void> _revive() async {
    final bool revived = await _controller.rewardedRevive();
    if (!mounted || !revived) return;
    HapticFeedback.heavyImpact();
    unawaited(_audio.playCombo());
    setState(() {
      _preview = null;
      _moveFeedback = 'CONTINUE!';
    });
    final int token = ++_feedbackToken;
    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (mounted && token == _feedbackToken) {
      setState(() => _moveFeedback = null);
    }
  }

  void _back() {
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.initialized) {
      return const Scaffold(
        backgroundColor: AppTheme.gameBackgroundBottom,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    Widget content = Scaffold(
      backgroundColor: AppTheme.gameBackgroundBottom,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              AppTheme.gameBackgroundTop,
              AppTheme.gameBackgroundBottom,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                child: Column(
                  children: <Widget>[
                    _GameHeader(
                      daily: widget.isDaily,
                      soundEnabled: _audio.enabled,
                      onLeftAction: widget.isDaily ? _back : _toggleSound,
                      onRestart: _confirmRestart,
                    ),
                    const SizedBox(height: 2),
                    _ScoreDisplay(
                      score: _controller.engine.score,
                      bestScore: _controller.bestScore,
                      daily: _daily,
                      movesLeft: _dailyMovesLeft,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Center(
                        child: AnimatedScale(
                          scale: _boardPulse ? 1.012 : 1,
                          duration: const Duration(milliseconds: 130),
                          curve: Curves.easeOutBack,
                          child: _Board(
                            gridKey: _boardGridKey,
                            engine: _controller.engine,
                            preview: _preview,
                            clearedRows: _clearedRows,
                            clearedCols: _clearedCols,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _PieceTray(
                      pieces: _controller.tray,
                      enabled: !_terminal,
                      feedbackCellSize: _feedbackCellSize,
                      onDragStarted: () => HapticFeedback.selectionClick(),
                      onDragUpdate: _updateDragPreview,
                      onDragEnded: _finishDrag,
                    ),
                  ],
                ),
              ),
              Positioned(
                top: widget.isDaily ? 125 : 105,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: _moveFeedback == null
                        ? const SizedBox.shrink()
                        : Center(
                            key: ValueKey<String>(_moveFeedback!),
                            child: _MoveBurst(label: _moveFeedback!),
                          ),
                  ),
                ),
              ),
              if (!widget.isDaily && _controller.gameOver)
                Positioned.fill(
                  child: _EndlessGameOverOverlay(
                    score: _controller.engine.score,
                    bestScore: _controller.bestScore,
                    coinsEarned: _controller.runCoinsAwarded,
                    canRevive: _controller.rewardedReviveReady,
                    onRestart: _restart,
                    onRevive: _revive,
                  ),
                ),
              if (widget.isDaily && _dailyFinished)
                Positioned.fill(
                  child: _DailyOutcomeOverlay(
                    challenge: _daily!,
                    success: _dailySuccess,
                    score: _controller.engine.score,
                    rewardGranted: _dailyRewardGranted,
                    movesPlayed: _controller.engine.movesPlayed,
                    onRetry: _dailySuccess ? null : _restart,
                    onBack: _back,
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (widget.isDaily) {
      final selected = ProgressionRuntime.instance.controller.selectedTheme;
      if (selected.id != 'classic') {
        content = ColorFiltered(
          colorFilter: ColorFilter.mode(
            Color(selected.backgroundTop),
            BlendMode.hue,
          ),
          child: content,
        );
      }
    }
    return content;
  }
}

class _PlacementPreview {
  const _PlacementPreview({
    required this.piece,
    required this.row,
    required this.col,
    required this.valid,
  });

  final BlockPiece piece;
  final int row;
  final int col;
  final bool valid;

  bool contains(int row, int col) => piece.cells.any(
        (cell) => this.row + cell.row == row && this.col + cell.col == col,
      );

  @override
  bool operator ==(Object other) =>
      other is _PlacementPreview &&
      other.piece.id == piece.id &&
      other.row == row &&
      other.col == col &&
      other.valid == valid;

  @override
  int get hashCode => Object.hash(piece.id, row, col, valid);
}

class _GameHeader extends StatelessWidget {
  const _GameHeader({
    required this.daily,
    required this.soundEnabled,
    required this.onLeftAction,
    required this.onRestart,
  });

  final bool daily;
  final bool soundEnabled;
  final VoidCallback onLeftAction;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Row(
        children: <Widget>[
          _HudButton(
            icon: daily
                ? Icons.arrow_back_rounded
                : soundEnabled
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
            tooltip: daily
                ? 'Back to endless'
                : soundEnabled
                    ? 'Mute sound'
                    : 'Enable sound',
            onPressed: onLeftAction,
          ),
          Expanded(
            child: Text(
              daily ? 'DAILY CHALLENGE' : 'BLOCKIVA',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.gameText,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.7,
              ),
            ),
          ),
          _HudButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Restart',
            onPressed: onRestart,
          ),
        ],
      ),
    );
  }
}

class _HudButton extends StatelessWidget {
  const _HudButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: .10),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, color: AppTheme.gameText, size: 22),
          ),
        ),
      ),
    );
  }
}

class _ScoreDisplay extends StatelessWidget {
  const _ScoreDisplay({
    required this.score,
    required this.bestScore,
    required this.daily,
    required this.movesLeft,
  });

  final int score;
  final int bestScore;
  final DailyChallengeDefinition? daily;
  final int movesLeft;

  @override
  Widget build(BuildContext context) {
    final DailyChallengeDefinition? challenge = daily;
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              challenge == null
                  ? Icons.emoji_events_rounded
                  : Icons.flag_rounded,
              color: AppTheme.warning,
              size: 17,
            ),
            const SizedBox(width: 5),
            Text(
              challenge == null ? '$bestScore' : 'TARGET ${challenge.targetScore}',
              style: const TextStyle(
                color: AppTheme.gameTextMuted,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 1),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child: Text(
            '$score',
            key: ValueKey<int>(score),
            style: const TextStyle(
              color: AppTheme.gameText,
              fontSize: 42,
              height: .95,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.5,
              shadows: <Shadow>[
                Shadow(
                  color: Color(0x55000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
          ),
        ),
        if (challenge != null) ...<Widget>[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '$movesLeft MOVES LEFT  •  +${challenge.rewardCoins} COINS',
              style: const TextStyle(
                color: AppTheme.gameTextMuted,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: .25,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({
    required this.gridKey,
    required this.engine,
    required this.preview,
    required this.clearedRows,
    required this.clearedCols,
  });

  final GlobalKey gridKey;
  final GameEngine engine;
  final _PlacementPreview? preview;
  final Set<int> clearedRows;
  final Set<int> clearedCols;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: AppTheme.gameBoard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: .10)),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x55030D22),
              blurRadius: 22,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: RepaintBoundary(
          key: gridKey,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: GameEngine.size,
            ),
            itemCount: GameEngine.size * GameEngine.size,
            itemBuilder: (BuildContext context, int index) {
              final int row = index ~/ GameEngine.size;
              final int col = index % GameEngine.size;
              final int? paletteIndex = engine.cellAt(row, col);
              final bool previewed = preview?.contains(row, col) ?? false;
              final bool valid = previewed && (preview?.valid ?? false);
              final bool invalid = previewed && !(preview?.valid ?? true);
              return _BoardCell(
                paletteIndex: paletteIndex,
                previewPaletteIndex: valid ? preview!.piece.paletteIndex : null,
                invalidPreview: invalid,
                clearFlash:
                    clearedRows.contains(row) || clearedCols.contains(col),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BoardCell extends StatelessWidget {
  const _BoardCell({
    required this.paletteIndex,
    required this.previewPaletteIndex,
    required this.invalidPreview,
    required this.clearFlash,
  });

  final int? paletteIndex;
  final int? previewPaletteIndex;
  final bool invalidPreview;
  final bool clearFlash;

  @override
  Widget build(BuildContext context) {
    final bool occupied = paletteIndex != null;
    final bool validPreview = previewPaletteIndex != null;
    final int? visualPalette = paletteIndex ?? previewPaletteIndex;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 90),
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: clearFlash
            ? const Color(0xFFFFEB8A)
            : visualPalette == null
                ? invalidPreview
                    ? const Color(0xFF6B3854)
                    : AppTheme.gameCell
                : null,
        gradient: clearFlash || visualPalette == null
            ? null
            : AppTheme.pieceGradient(visualPalette),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: clearFlash
              ? Colors.white
              : invalidPreview
                  ? const Color(0xFFFF8B9B)
                  : occupied || validPreview
                      ? Colors.white.withValues(alpha: .20)
                      : AppTheme.gameCellEdge.withValues(alpha: .65),
          width: clearFlash || invalidPreview ? 1.2 : .7,
        ),
      ),
      child: visualPalette == null || clearFlash
          ? null
          : Opacity(
              opacity: validPreview && !occupied ? .58 : 1,
              child: const _TileGloss(),
            ),
    );
  }
}

class _TileGloss extends StatelessWidget {
  const _TileGloss();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Align(
          alignment: const Alignment(0, -.82),
          child: FractionallySizedBox(
            widthFactor: .70,
            heightFactor: .12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .34),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            widthFactor: .82,
            heightFactor: .11,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PieceTray extends StatelessWidget {
  const _PieceTray({
    required this.pieces,
    required this.enabled,
    required this.feedbackCellSize,
    required this.onDragStarted,
    required this.onDragUpdate,
    required this.onDragEnded,
  });

  final List<BlockPiece?> pieces;
  final bool enabled;
  final double feedbackCellSize;
  final VoidCallback onDragStarted;
  final void Function(BlockPiece piece, Offset globalPointer) onDragUpdate;
  final void Function(BlockPiece piece) onDragEnded;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 116,
      child: Row(
        children: List<Widget>.generate(3, (int index) {
          final BlockPiece? piece = index < pieces.length ? pieces[index] : null;
          return Expanded(
            child: Center(
              child: piece == null
                  ? const SizedBox.shrink()
                  : Draggable<BlockPiece>(
                      data: piece,
                      rootOverlay: true,
                      dragAnchorStrategy: pointerDragAnchorStrategy,
                      maxSimultaneousDrags: enabled ? 1 : 0,
                      hitTestBehavior: HitTestBehavior.opaque,
                      onDragStarted: onDragStarted,
                      onDragUpdate: (DragUpdateDetails details) {
                        onDragUpdate(piece, details.globalPosition);
                      },
                      onDragEnd: (_) => onDragEnded(piece),
                      feedback: Material(
                        color: Colors.transparent,
                        child: Transform.translate(
                          offset: Offset(
                            -(piece.width * feedbackCellSize) / 2,
                            -(piece.height * feedbackCellSize) / 2 -
                                BoardDragProjector.fingerLift,
                          ),
                          child: _PieceView(
                            piece: piece,
                            cellSize: feedbackCellSize,
                            elevated: true,
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: .10,
                        child: _PieceView(piece: piece, cellSize: 25),
                      ),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 100),
                        opacity: enabled ? 1 : .28,
                        child: _PieceView(piece: piece, cellSize: 25),
                      ),
                    ),
            ),
          );
        }),
      ),
    );
  }
}

class _PieceView extends StatelessWidget {
  const _PieceView({
    required this.piece,
    required this.cellSize,
    this.elevated = false,
  });

  final BlockPiece piece;
  final double cellSize;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final Color color = AppTheme.piecePalette[
      piece.paletteIndex % AppTheme.piecePalette.length
    ];
    return SizedBox(
      width: piece.width * cellSize,
      height: piece.height * cellSize,
      child: Stack(
        children: piece.cells.map((cell) {
          return Positioned(
            left: cell.col * cellSize,
            top: cell.row * cellSize,
            width: cellSize,
            height: cellSize,
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                gradient: AppTheme.pieceGradient(piece.paletteIndex),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .20),
                  width: .8,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: color.withValues(alpha: elevated ? .42 : .20),
                    blurRadius: elevated ? 12 : 5,
                    offset: Offset(0, elevated ? 7 : 3),
                  ),
                ],
              ),
              child: const _TileGloss(),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}

class _MoveBurst extends StatelessWidget {
  const _MoveBurst({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppTheme.warning,
        fontSize: 20,
        fontWeight: FontWeight.w900,
        shadows: <Shadow>[
          Shadow(color: Color(0xAA07162F), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
    );
  }
}

class _RestartSheet extends StatelessWidget {
  const _RestartSheet({
    required this.daily,
    required this.onCancel,
    required this.onRestart,
  });

  final bool daily;
  final VoidCallback onCancel;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: BoxDecoration(
        color: AppTheme.gameBoard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: .10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            daily ? 'Restart today’s challenge?' : 'Restart this run?',
            style: const TextStyle(
              color: AppTheme.gameText,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            daily
                ? 'The same deterministic challenge will start from move 1.'
                : 'Your current board and score will be cleared.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.gameTextMuted),
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: TextButton(
                  onPressed: onCancel,
                  child: const Text('KEEP PLAYING'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: onRestart,
                  child: const Text('RESTART'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EndlessGameOverOverlay extends StatelessWidget {
  const _EndlessGameOverOverlay({
    required this.score,
    required this.bestScore,
    required this.coinsEarned,
    required this.canRevive,
    required this.onRestart,
    required this.onRevive,
  });

  final int score;
  final int bestScore;
  final int coinsEarned;
  final bool canRevive;
  final VoidCallback onRestart;
  final Future<void> Function() onRevive;

  @override
  Widget build(BuildContext context) {
    return _OverlayCard(
      icon: Icons.grid_off_rounded,
      title: 'NO MORE MOVES',
      subtitle: coinsEarned > 0
          ? '+$coinsEarned coins earned this run'
          : 'Keep this run alive or start fresh.',
      score: score,
      secondary: 'BEST $bestScore',
      children: <Widget>[
        if (canRevive) ...<Widget>[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: const Color(0xFF062419),
                padding: const EdgeInsets.symmetric(vertical: 17),
              ),
              onPressed: onRevive,
              icon: const Icon(Icons.play_circle_fill_rounded),
              label: const Text('WATCH AD & CONTINUE'),
            ),
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onRestart,
            icon: const Icon(Icons.replay_rounded),
            label: const Text('NEW GAME'),
          ),
        ),
      ],
    );
  }
}

class _DailyOutcomeOverlay extends StatelessWidget {
  const _DailyOutcomeOverlay({
    required this.challenge,
    required this.success,
    required this.score,
    required this.rewardGranted,
    required this.movesPlayed,
    required this.onRetry,
    required this.onBack,
  });

  final DailyChallengeDefinition challenge;
  final bool success;
  final int score;
  final int rewardGranted;
  final int movesPlayed;
  final VoidCallback? onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return _OverlayCard(
      icon: success ? Icons.workspace_premium_rounded : Icons.flag_rounded,
      title: success ? 'DAILY COMPLETE!' : 'CHALLENGE OVER',
      subtitle: success
          ? rewardGranted > 0
              ? '+$rewardGranted coins added'
              : 'Today’s reward is already secured.'
          : 'Target ${challenge.targetScore} • ${math.min(movesPlayed, challenge.moveLimit)}/${challenge.moveLimit} moves',
      score: score,
      secondary: success
          ? 'COME BACK TOMORROW'
          : '${math.max(0, challenge.targetScore - score)} MORE POINTS NEEDED',
      children: <Widget>[
        if (onRetry != null) ...<Widget>[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('TRY AGAIN'),
            ),
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('BACK TO ENDLESS'),
          ),
        ),
      ],
    );
  }
}

class _OverlayCard extends StatelessWidget {
  const _OverlayCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.score,
    required this.secondary,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int score;
  final String secondary;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.gameOverlay,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 390),
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
            decoration: BoxDecoration(
              color: AppTheme.gameBoard,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withValues(alpha: .12)),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x88030D22),
                  blurRadius: 32,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, color: AppTheme.warning, size: 42),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.gameText,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.gameTextMuted),
                ),
                const SizedBox(height: 18),
                Text(
                  '$score',
                  style: const TextStyle(
                    color: AppTheme.gameText,
                    fontSize: 46,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  secondary,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.gameTextMuted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 22),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IsolatedDailyStatsRepository implements GameStatsRepository {
  var _best = 0;
  var _games = 0;

  @override
  Future<int> loadBestScore() async => _best;

  @override
  Future<int> loadGamesPlayed() async => _games;

  @override
  Future<void> saveBestScore(int value) async => _best = value;

  @override
  Future<void> saveGamesPlayed(int value) async => _games = value;
}
