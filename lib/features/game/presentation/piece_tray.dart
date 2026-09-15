import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/block_piece.dart';
import 'board_drag_projector.dart';
import 'piece_view.dart';

/// Owns the single active drag across all three tray slots.
class PieceTray extends StatefulWidget {
  const PieceTray({
    required this.pieces,
    required this.enabled,
    required this.feedbackCellSize,
    required this.onDragStarted,
    required this.onDragUpdate,
    required this.onDragEnded,
    super.key,
  });

  final List<BlockPiece?> pieces;
  final bool enabled;
  // Read after layout, when the feedback is built, including on the first move.
  final double Function() feedbackCellSize;
  final VoidCallback onDragStarted;
  final void Function(BlockPiece piece, Offset globalPointer) onDragUpdate;
  final void Function(BlockPiece piece) onDragEnded;

  @override
  State<PieceTray> createState() => _PieceTrayState();
}

class _PieceTrayState extends State<PieceTray> {
  BlockPiece? _activePiece;

  void _start(BlockPiece piece) {
    if (_activePiece != null || !widget.enabled) return;
    setState(() => _activePiece = piece);
    widget.onDragStarted();
  }

  void _end(BlockPiece piece) {
    if (!identical(_activePiece, piece)) return;
    setState(() => _activePiece = null);
    if (widget.enabled) widget.onDragEnded(piece);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 116,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // Reserve space for every 5-cell shape in both directions. Uniform
          // cells keep the three pieces comparable on narrow phones.
          final double cellSize = math
              .min(
                25,
                math.min(
                  (constraints.maxWidth / 3 - 12) / 5,
                  (constraints.maxHeight - 12) / 5,
                ),
              )
              .clamp(1.0, 25.0).toDouble();
          return Row(
            children: List<Widget>.generate(3, (int index) {
              final BlockPiece? piece = index < widget.pieces.length
                  ? widget.pieces[index]
                  : null;
              return Expanded(
                child: Center(
                  child: piece == null
                      ? const SizedBox.shrink()
                      : Draggable<BlockPiece>(
                          key: ObjectKey(piece),
                          data: piece,
                          rootOverlay: true,
                          dragAnchorStrategy: pointerDragAnchorStrategy,
                          maxSimultaneousDrags:
                              widget.enabled &&
                                  (_activePiece == null ||
                                      identical(_activePiece, piece))
                              ? 1
                              : 0,
                          hitTestBehavior: HitTestBehavior.opaque,
                          onDragStarted: () => _start(piece),
                          onDragUpdate: (DragUpdateDetails details) {
                            if (identical(_activePiece, piece) &&
                                widget.enabled) {
                              widget.onDragUpdate(
                                piece,
                                details.globalPosition,
                              );
                            }
                          },
                          onDragEnd: (_) => _end(piece),
                          feedback: Builder(
                            builder: (BuildContext context) {
                              final double size = widget.feedbackCellSize();
                              return Material(
                                color: Colors.transparent,
                                child: Transform.translate(
                                  offset: Offset(
                                    -(piece.width * size) / 2,
                                    -(piece.height * size) / 2 -
                                        BoardDragProjector.fingerLift,
                                  ),
                                  child: PieceView(
                                    piece: piece,
                                    cellSize: size,
                                    elevated: true,
                                  ),
                                ),
                              );
                            },
                          ),
                          childWhenDragging: Opacity(
                            opacity: .10,
                            child: PieceView(piece: piece, cellSize: cellSize),
                          ),
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 100),
                            opacity: widget.enabled ? 1 : .28,
                            child: PieceView(piece: piece, cellSize: cellSize),
                          ),
                        ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
