import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
    if (placed) setState(() => _preview = null);
  }

  void _restart() {
    setState(() => _preview = null);
    _controller.restart();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'BLOCKIVA',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: .8),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Restart',
            onPressed: _restart,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 18),
          child: Column(
            children: <Widget>[
              _ScoreBar(
                score: _controller.engine.score,
                bestScore: _controller.bestScore,
                combo: _controller.engine.combo,
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              _PieceTray(
                pieces: _controller.tray,
                enabled: !_controller.gameOver,
                onDragEnded: () => _setPreview(null, 0, 0),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _controller.gameOver
                    ? Padding(
                        key: const ValueKey<String>('game-over'),
                        padding: const EdgeInsets.only(top: 14),
                        child: _GameOverCard(
                          score: _controller.engine.score,
                          bestScore: _controller.bestScore,
                          canRevive: _controller.rewardedReviveReady,
                          onRestart: _restart,
                          onRevive: _controller.rewardedRevive,
                        ),
                      )
                    : const SizedBox(
                        key: ValueKey<String>('playing'),
                        height: 10,
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
        Expanded(child: _Metric(label: 'SCORE', value: '$score')),
        const SizedBox(width: 10),
        Expanded(child: _Metric(label: 'BEST', value: '$bestScore')),
        const SizedBox(width: 10),
        Expanded(
          child: _Metric(label: 'COMBO', value: combo > 0 ? 'x$combo' : '—'),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 1.3,
              color: Color(0xFF7E8BAA),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
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
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF24304E)),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Colors.black38,
              blurRadius: 28,
              offset: Offset(0, 10),
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

            Color background = AppTheme.surfaceSoft;
            if (paletteIndex != null) {
              background = AppTheme.piecePalette[paletteIndex];
            } else if (previewed) {
              background = preview!.valid
                  ? AppTheme.piecePalette[preview!.piece.paletteIndex]
                      .withValues(alpha: .44)
                  : AppTheme.danger.withValues(alpha: .42);
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
                  duration: const Duration(milliseconds: 90),
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(7),
                    border: previewed && preview!.valid
                        ? Border.all(
                            color: Colors.white.withValues(alpha: .22),
                            width: 1,
                          )
                        : null,
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
      height: 112,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: .7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: List<Widget>.generate(3, (int index) {
          final BlockPiece? piece = index < pieces.length ? pieces[index] : null;
          return Expanded(
            child: Center(
              child: piece == null
                  ? const SizedBox.shrink()
                  : Draggable<BlockPiece>(
                      data: piece,
                      maxSimultaneousDrags: enabled ? 1 : 0,
                      onDragEnd: (_) => onDragEnded(),
                      onDraggableCanceled: (_, __) => onDragEnded(),
                      feedback: Material(
                        color: Colors.transparent,
                        child: Transform.translate(
                          offset: const Offset(0, -54),
                          child: _PieceView(piece: piece, cellSize: 29),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: .18,
                        child: _PieceView(piece: piece, cellSize: 22),
                      ),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 120),
                        opacity: enabled ? 1 : .35,
                        child: _PieceView(piece: piece, cellSize: 22),
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
                color: color,
                borderRadius: BorderRadius.circular(6),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: color.withValues(alpha: .25),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}

class _GameOverCard extends StatelessWidget {
  const _GameOverCard({
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
  final Future<bool> Function() onRevive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF35415F)),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'NO MORE MOVES',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Clear space and chase a new best.',
                      style: TextStyle(color: Color(0xFF94A2C1), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                '$score',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          if (score >= bestScore && score > 0) ...<Widget>[
            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'NEW BEST SCORE',
                style: TextStyle(
                  color: AppTheme.success,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              if (canRevive) ...<Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await onRevive();
                    },
                    icon: const Icon(Icons.ondemand_video_rounded),
                    label: const Text('REVIVE'),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: onRestart,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('RESTART'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
