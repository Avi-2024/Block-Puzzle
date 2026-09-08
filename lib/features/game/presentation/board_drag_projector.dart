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
  static const double fingerLift = 76;

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

    final int col = ((pieceCenter.dx - (pieceWidth / 2)) / cellSize).round();
    final int row = ((pieceCenter.dy - (pieceHeight / 2)) / cellSize).round();

    final int maxCol = GameEngine.size - piece.width;
    final int maxRow = GameEngine.size - piece.height;
    if (row < 0 || col < 0 || row > maxRow || col > maxCol) return null;

    return BoardDropOrigin(row: row, col: col);
  }

  static double feedbackCellSize(Size boardSize) =>
      boardSize.width <= 0 ? 36 : boardSize.width / GameEngine.size;
}
