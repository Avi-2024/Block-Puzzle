import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/ads/ad_service.dart';
import '../../../core/storage/shared_preferences_game_stats_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../application/game_session_controller.dart';
import '../domain/block_piece.dart';
import '../domain/game_engine.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameSessionController _controller;
  _PlacementPreview? _preview;
  String? _moveFeedback;
  var _feedbackToken = 0;

  @override
  void initState() {
    super.initState();
    _controller = GameSessionController(
      statsRepository: SharedPreferencesGameStatsRepository(),
      adService: kDebugMode
          ? const DebugRewardAdService()
          : const NoOpAdService(),
    )..addListener(_refresh);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _setPreview(BlockPiece? piece, int row, int col) {
    final _PlacementPreview? next = piece == null
        ? null
        : _PlacementPreview(
            piece: piece,
            row: row,
            col: col,
            valid: _controller.engine.canPlace(piece, row, col),
          );
    if (_preview == next) return;
    setState(() => _preview = next);
  }

  void _place(BlockPiece piece, int row, int col) {
    final bool placed = _controller.placePiece(piece, row, col);
    if (!placed) {
      HapticFeedback.lightImpact();
      return;
    }

    final move = _controller.lastMove;
    if (move != null && move.linesCleared > 0) {
      HapticFeedback.mediumImpact();
      final String label = move.linesCleared > 1
          ? '${move.linesCleared} LINES  •  COMBO x${move.combo}'
          : 'LINE CLEAR  •  +${move.scoreGained}';
      unawaited(_showMoveFeedback(label));
    } else {
      HapticFeedback.selectionClick();
    }

    setState(() => _preview = null);
  }

  Future<void> _showMoveFeedback(String label) async {
    final int token = ++_feedbackToken;
    setState(() => _moveFeedback = label);
    await Future<void>.delayed(const Duration(milliseconds: 760));
    if (!mounted || token != _feedbackToken) return;
    setState(() => _moveFeedback = null);
  }

  void _restart() {
    setState(() {
      _preview = null;
      _moveFeedback = null;
      _feedbackToken += 1;
    });
    _controller.restart();
    HapticFeedback.selectionClick();
  }

  Future<void> _confirmRestart() async {
    if (_controller.engine.score == 0) {
      _restart();
      return;
    }
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Restart this run?'),
          content: const Text(
            'Your current board will be cleared and a fresh puzzle will start.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('KEEP PLAYING'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('RESTART'),
            ),
          ],
        );
      },
    );
    if (confirmed == true && mounted) _restart();
  }

  Future<void> _revive() async {
    final bool revived = await _controller.rewardedRevive();
    if (!mounted || !revived) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _preview = null;
      _moveFeedback = 'BACK IN THE GAME!';
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
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFFF9F9FE),
              Color(0xFFF1EFFF),
              Color(0xFFFFF8F4),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  children: <Widget>[
                    _Header(onRestart: _confirmRestart),
                    const SizedBox(height: 12),
                    _ScoreBar(
                      score: _controller.engine.score,
                      bestScore: _controller.bestScore,
                      combo: _controller.engine.combo,
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Center(
                        child: _Board(
                          engine: _controller.engine,
                          preview: _preview,
                          onPreview: _setPreview,
                          onPlace: _place,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _PieceTray(
                      pieces: _controller.tray,
                      enabled: !_controller.gameOver,
                      onDragEnded: () => _setPreview(null, 0, 0),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 128,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
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
                            child: _FeedbackPill(label: _moveFeedback!),
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

class _Header extends StatelessWidget {
  const _Header({required this.onRestart});

  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _CircleButton(
          icon: Icons.arrow_back_rounded,
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(width: 12),
        const _TinyLogo(),
        const SizedBox(width: 9),
        const Expanded(
          child: Text(
            'BLOCKIVA',
            style: TextStyle(
              color: AppTheme.ink,
              fontWeight: FontWeight.w900,
              letterSpacing: .7,
              fontSize: 19,
            ),
          ),
        ),
        _CircleButton(
          icon: Icons.refresh_rounded,
          tooltip: 'Restart',
          onPressed: onRestart,
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: .88),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: AppTheme.ink),
          ),
        ),
      ),
    );
  }
}

class _TinyLogo extends StatelessWidget {
  const _TinyLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        itemCount: 4,
        itemBuilder: (BuildContext context, int index) {
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppTheme.pieceGradient(index),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        },
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

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({
    required this.score,
    required this.bestScore,
    required this.combo,
  });

  final int score;
  final int bestScore;
  final int combo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 5,
          child: _Metric(
            label: 'SCORE',
            value: '$score',
            icon: Icons.stars_rounded,
            accent: AppTheme.primary,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          flex: 4,
          child: _Metric(
            label: 'BEST',
            value: '$bestScore',
            icon: Icons.emoji_events_rounded,
            accent: AppTheme.warning,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          flex: 4,
          child: _Metric(
            label: 'COMBO',
            value: combo > 0 ? 'x$combo' : '—',
            icon: Icons.bolt_rounded,
            accent: combo > 0 ? AppTheme.accent : AppTheme.inkMuted,
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E9F3)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0D24263A),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 19, color: accent),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.1,
                    color: AppTheme.inkMuted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Text(
                    value,
                    key: ValueKey<String>(value),
                    maxLines: 1,
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({
    required this.engine,
    required this.preview,
    required this.onPreview,
    required this.onPlace,
  });

  final GameEngine engine;
  final _PlacementPreview? preview;
  final void Function(BlockPiece? piece, int row, int col) onPreview;
  final void Function(BlockPiece piece, int row, int col) onPlace;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .96),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFE0E3EF), width: 1.4),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x1F6C63FF),
              blurRadius: 32,
              offset: Offset(0, 16),
            ),
          ],
        ),
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

            LinearGradient? gradient;
            Color cellColor = AppTheme.surfaceSoft;
            if (paletteIndex != null) {
              gradient = AppTheme.pieceGradient(paletteIndex);
            } else if (validPreview) {
              cellColor = AppTheme.piecePalette[preview!.piece.paletteIndex]
                  .withValues(alpha: .28);
            } else if (invalidPreview) {
              cellColor = AppTheme.danger.withValues(alpha: .20);
            }

            return DragTarget<BlockPiece>(
              onWillAcceptWithDetails: (DragTargetDetails<BlockPiece> details) {
                onPreview(details.data, row, col);
                return engine.canPlace(details.data, row, col);
              },
              onMove: (DragTargetDetails<BlockPiece> details) {
                onPreview(details.data, row, col);
              },
              onLeave: (BlockPiece? data) => onPreview(null, 0, 0),
              onAcceptWithDetails: (DragTargetDetails<BlockPiece> details) {
                onPlace(details.data, row, col);
              },
              builder: (
                BuildContext context,
                List<BlockPiece?> candidates,
                List<dynamic> rejected,
              ) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 95),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: gradient == null ? cellColor : null,
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(8),
                    border: validPreview
                        ? Border.all(color: Colors.white, width: 1.3)
                        : invalidPreview
                            ? Border.all(color: AppTheme.danger, width: 1.1)
                            : null,
                    boxShadow: paletteIndex == null
                        ? null
                        : <BoxShadow>[
                            BoxShadow(
                              color: AppTheme.piecePalette[paletteIndex]
                                  .withValues(alpha: .20),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                  ),
                  child: paletteIndex == null
                      ? null
                      : Align(
                          alignment: const Alignment(-.35, -.55),
                          child: FractionallySizedBox(
                            widthFactor: .58,
                            heightFactor: .18,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .24),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _PieceTray extends StatelessWidget {
  const _PieceTray({
    required this.pieces,
    required this.enabled,
    required this.onDragEnded,
  });

  final List<BlockPiece?> pieces;
  final bool enabled;
  final VoidCallback onDragEnded;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE6E7F1)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1224263A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: List<Widget>.generate(3, (int index) {
          final BlockPiece? piece = index < pieces.length ? pieces[index] : null;
          return Expanded(
            child: Center(
              child: piece == null
                  ? Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSoft.withValues(alpha: .55),
                        borderRadius: BorderRadius.circular(13),
                      ),
                    )
                  : Draggable<BlockPiece>(
                      data: piece,
                      maxSimultaneousDrags: enabled ? 1 : 0,
                      onDragStarted: HapticFeedback.selectionClick,
                      onDragEnd: (DraggableDetails details) => onDragEnded(),
                      onDraggableCanceled: (Velocity velocity, Offset offset) {
                        onDragEnded();
                      },
                      feedback: Material(
                        color: Colors.transparent,
                        child: Transform.translate(
                          offset: const Offset(0, -68),
                          child: Transform.scale(
                            scale: 1.08,
                            child: _PieceView(piece: piece, cellSize: 31),
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: .14,
                        child: _PieceView(piece: piece, cellSize: 23),
                      ),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 120),
                        opacity: enabled ? 1 : .30,
                        child: _PieceView(piece: piece, cellSize: 23),
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
  const _PieceView({required this.piece, required this.cellSize});

  final BlockPiece piece;
  final double cellSize;

  @override
  Widget build(BuildContext context) {
    final Color color = AppTheme.piecePalette[piece.paletteIndex];
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
              margin: const EdgeInsets.all(1.4),
              decoration: BoxDecoration(
                gradient: AppTheme.pieceGradient(piece.paletteIndex),
                borderRadius: BorderRadius.circular(7),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: color.withValues(alpha: .24),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Align(
                alignment: const Alignment(-.25, -.55),
                child: FractionallySizedBox(
                  widthFactor: .60,
                  heightFactor: .17,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .28),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}

class _FeedbackPill extends StatelessWidget {
  const _FeedbackPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[AppTheme.primary, AppTheme.accent],
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x336C63FF),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          letterSpacing: .6,
          fontSize: 12,
        ),
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
    return ColoredBox(
      color: const Color(0x6624263A),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x3324263A),
                  blurRadius: 36,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: <Color>[AppTheme.primary, AppTheme.accent],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'NO MORE MOVES',
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Great run! Make some space and keep your score alive.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.inkMuted),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _ResultMetric(label: 'SCORE', value: '$score'),
                    const SizedBox(width: 12),
                    _ResultMetric(label: 'BEST', value: '$bestScore'),
                  ],
                ),
                if (score >= bestScore && score > 0) ...<Widget>[
                  const SizedBox(height: 12),
                  const Text(
                    '🏆  NEW BEST SCORE',
                    style: TextStyle(
                      color: AppTheme.success,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .6,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (canRevive) ...<Widget>[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 17),
                      ),
                      onPressed: onRevive,
                      icon: const Icon(Icons.ondemand_video_rounded),
                      label: const Text('WATCH AD & CONTINUE'),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.ink,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: const BorderSide(color: Color(0xFFE2E4EF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: onRestart,
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text(
                      'START NEW RUN',
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

class _ResultMetric extends StatelessWidget {
  const _ResultMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.inkMuted,
              fontSize: 9,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
