import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/ads/ad_service.dart';
import '../../../core/audio/game_audio_service.dart';
import '../../../core/storage/shared_preferences_game_stats_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../application/game_session_controller.dart';
import '../domain/block_piece.dart';
import '../domain/game_engine.dart';
import 'board_drag_projector.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
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

  @override
  void initState() {
    super.initState();
    _audio = GameAudioService();
    unawaited(_initializeAudio());

    _controller = GameSessionController(
      statsRepository: SharedPreferencesGameStatsRepository(),
      adService: kDebugMode
          ? const DebugRewardAdService()
          : const NoOpAdService(),
    )..addListener(_refresh);
    _controller.initialize();
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
    final BuildContext? boardContext = _boardGridKey.currentContext;
    if (boardContext == null) return null;
    final RenderObject? renderObject = boardContext.findRenderObject();
    return renderObject is RenderBox && renderObject.hasSize ? renderObject : null;
  }

  double get _feedbackCellSize {
    final RenderBox? boardBox = _boardBox;
    if (boardBox == null) return 38;
    return BoardDragProjector.feedbackCellSize(boardBox.size);
  }

  void _updateDragPreview(BlockPiece piece, Offset globalPointer) {
    final RenderBox? boardBox = _boardBox;
    if (boardBox == null) return;

    final Offset pointerInBoard = boardBox.globalToLocal(globalPointer);
    final BoardDropOrigin? origin = BoardDragProjector.project(
      pointerInBoard: pointerInBoard,
      boardSize: boardBox.size,
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
    if (_preview == next || !mounted) return;
    setState(() => _preview = next);
  }

  void _finishDrag(BlockPiece piece) {
    final _PlacementPreview? preview = _preview;
    if (preview != null && preview.piece.id == piece.id && preview.valid) {
      _place(piece, preview.row, preview.col);
      return;
    }

    HapticFeedback.lightImpact();
    _setPreview(null);
  }

  void _place(BlockPiece piece, int row, int col) {
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

      if (move.combo > 1) {
        unawaited(_audio.playCombo());
      } else {
        unawaited(_audio.playClear());
      }

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
    setState(() {
      _preview = null;
      _moveFeedback = null;
      _clearedRows = <int>{};
      _clearedCols = <int>{};
      _boardPulse = false;
      _feedbackToken += 1;
      _clearFlashToken += 1;
    });
    _controller.restart();
    HapticFeedback.selectionClick();
    unawaited(_audio.playPlacement());
  }

  Future<void> _confirmRestart() async {
    if (_controller.engine.score == 0) {
      _restart();
      return;
    }

    final bool? confirmed = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (BuildContext sheetContext) {
        return _RestartSheet(
          onCancel: () => Navigator.of(sheetContext).pop(false),
          onRestart: () => Navigator.of(sheetContext).pop(true),
        );
      },
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

  @override
  Widget build(BuildContext context) {
    if (!_controller.initialized) {
      return const Scaffold(
        backgroundColor: AppTheme.gameBackgroundBottom,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
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
                      soundEnabled: _audio.enabled,
                      onToggleSound: _toggleSound,
                      onRestart: _confirmRestart,
                    ),
                    const SizedBox(height: 2),
                    _ScoreDisplay(
                      score: _controller.engine.score,
                      bestScore: _controller.bestScore,
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
                      enabled: !_controller.gameOver,
                      feedbackCellSize: _feedbackCellSize,
                      onDragStarted: () => HapticFeedback.selectionClick(),
                      onDragUpdate: _updateDragPreview,
                      onDragEnded: _finishDrag,
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 105,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return ScaleTransition(
                        scale: CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutBack,
                        ),
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: _moveFeedback == null
                        ? const SizedBox.shrink()
                        : Center(
                            key: ValueKey<String>(_moveFeedback!),
                            child: _MoveBurst(label: _moveFeedback!),
                          ),
                  ),
                ),
              ),
              if (_controller.gameOver)
                Positioned.fill(
                  child: _GameOverOverlay(
                    score: _controller.engine.score,
                    bestScore: _controller.bestScore,
                    canRevive: _controller.rewardedReviveReady,
                    onRestart: _restart,
                    onRevive: _revive,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
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

  bool contains(int targetRow, int targetCol) => piece.cells.any(
        (cell) => row + cell.row == targetRow && col + cell.col == targetCol,
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
    required this.soundEnabled,
    required this.onToggleSound,
    required this.onRestart,
  });

  final bool soundEnabled;
  final VoidCallback onToggleSound;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Row(
        children: <Widget>[
          _HudButton(
            icon: soundEnabled
                ? Icons.volume_up_rounded
                : Icons.volume_off_rounded,
            tooltip: soundEnabled ? 'Mute sound' : 'Enable sound',
            onPressed: onToggleSound,
          ),
          const Expanded(
            child: Text(
              'BLOCKIVA',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.gameText,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.2,
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
  const _ScoreDisplay({required this.score, required this.bestScore});

  final int score;
  final int bestScore;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.emoji_events_rounded,
              color: AppTheme.warning,
              size: 17,
            ),
            const SizedBox(width: 5),
            Text(
              '$bestScore',
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
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(scale: animation, child: child);
          },
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
          border: Border.all(
            color: Colors.white.withValues(alpha: .10),
            width: 1.2,
          ),
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
              final bool validPreview = previewed && (preview?.valid ?? false);
              final bool invalidPreview = previewed && !(preview?.valid ?? true);
              final bool clearFlash =
                  clearedRows.contains(row) || clearedCols.contains(col);

              return _BoardCell(
                paletteIndex: paletteIndex,
                previewPaletteIndex:
                    validPreview ? preview!.piece.paletteIndex : null,
                invalidPreview: invalidPreview,
                clearFlash: clearFlash,
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
      curve: Curves.easeOut,
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
        boxShadow: clearFlash
            ? const <BoxShadow>[
                BoxShadow(color: Color(0x99FFF0A8), blurRadius: 10),
              ]
            : occupied
                ? <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .18),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
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
                      onDragEnd: (DraggableDetails details) {
                        onDragEnded(piece);
                      },
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
        clipBehavior: Clip.none,
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
        letterSpacing: .5,
        shadows: <Shadow>[
          Shadow(color: Color(0xAA07162F), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
    );
  }
}

class _RestartSheet extends StatelessWidget {
  const _RestartSheet({required this.onCancel, required this.onRestart});

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
          const Text(
            'Restart this run?',
            style: TextStyle(
              color: AppTheme.gameText,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Your current board and score will be cleared.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.gameTextMuted),
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: TextButton(
                  onPressed: onCancel,
                  child: const Text(
                    'KEEP PLAYING',
                    style: TextStyle(color: AppTheme.gameText),
                  ),
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

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({
    required this.score,
    required this.bestScore,
    required this.canRevive,
    required this.onRestart,
    required this.onRevive,
  });

  final int score;
  final int bestScore;
  final bool canRevive;
  final VoidCallback onRestart;
  final Future<void> Function() onRevive;

  @override
  Widget build(BuildContext context) {
    final bool newBest = score >= bestScore && score > 0;
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
                const Icon(
                  Icons.grid_off_rounded,
                  color: AppTheme.warning,
                  size: 42,
                ),
                const SizedBox(height: 12),
                const Text(
                  'NO MORE MOVES',
                  style: TextStyle(
                    color: AppTheme.gameText,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .4,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Keep this run alive or start fresh.',
                  style: TextStyle(color: AppTheme.gameTextMuted),
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
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: AppTheme.warning,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'BEST $bestScore',
                      style: const TextStyle(
                        color: AppTheme.gameTextMuted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                if (newBest) ...<Widget>[
                  const SizedBox(height: 8),
                  const Text(
                    'NEW BEST!',
                    style: TextStyle(
                      color: AppTheme.success,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
                const SizedBox(height: 22),
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
                      label: const Text(
                        'WATCH AD & CONTINUE',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.gameText,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: .18),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: onRestart,
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text(
                      'NEW GAME',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
