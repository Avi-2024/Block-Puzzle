import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../domain/block_piece.dart';
import '../domain/game_engine.dart';

class BoardDropOrigin {
  const BoardDropOrigin({required this.row, required this.col});

  final int row;
  final int col;

  @override
  bool operator ==(Object other) =>
      other is BoardDropOrigin && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);
}

/// Converts the user's finger position into the exact board origin used by
/// both preview and final placement.
///
/// The piece is intentionally rendered above the finger. [fingerLift] is the
/// same vertical offset used by the draggable feedback, so the visual piece
/// and the logical board ghost stay locked together.
abstract final class BoardDragProjector {
  /// Keeps the lifted piece visible above the player's finger on Android.
  ///
  /// The value is intentionally a little higher than the original prototype
  /// offset, because the V2 tiles are glossier/chunkier and need more breathing
  /// room while dragging.
  static const double fingerLift = 84;

  /// Allows the piece to snap at the board edge before disappearing.
  ///
  /// Without this tolerance, preview can flicker when the user approaches the
  /// first/last row or column. The final origin is still clamped to the board,
  /// so this improves feel without weakening placement validation.
  static const double edgeSnapSlackCells = .72;

  static BoardDropOrigin? project({
    required Offset pointerInBoard,
    required Size boardSize,
    required BlockPiece piece,
    double lift = fingerLift,
  }) {
    if (boardSize.width <= 0 || boardSize.height <= 0) return null;

    final double cellSize = boardSize.width / GameEngine.size;
    final Offset pieceCenter = pointerInBoard.translate(0, -lift);
    final double pieceWidth = piece.width * cellSize;
    final double pieceHeight = piece.height * cellSize;
    final double pieceLeft = pieceCenter.dx - (pieceWidth / 2);
    final double pieceTop = pieceCenter.dy - (pieceHeight / 2);
    final double slack = cellSize * edgeSnapSlackCells;

    if (pieceLeft > boardSize.width + slack ||
        pieceTop > boardSize.height + slack ||
        pieceLeft + pieceWidth < -slack ||
        pieceTop + pieceHeight < -slack) {
      return null;
    }

    final int maxCol = GameEngine.size - piece.width;
    final int maxRow = GameEngine.size - piece.height;
    final int col = math.max(0, math.min(maxCol, (pieceLeft / cellSize).round()));
    final int row = math.max(0, math.min(maxRow, (pieceTop / cellSize).round()));

    return BoardDropOrigin(row: row, col: col);
  }

  static double feedbackCellSize(Size boardSize) =>
      boardSize.width <= 0 ? 36 : boardSize.width / GameEngine.size;
}
