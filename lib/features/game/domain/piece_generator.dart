import 'dart:math';

import 'block_piece.dart';
import 'game_engine.dart';
import 'piece_catalog.dart';

class PieceGenerator {
  PieceGenerator({Random? random, this.paletteCount = 7})
      : assert(paletteCount > 0),
        _random = random ?? Random();

  final Random _random;
  final int paletteCount;
  var _sequence = 0;

  /// Generates a visible batch of three fixed-orientation pieces.
  ///
  /// The batch is intentionally *not* forced to contain a currently playable
  /// shape. That keeps board-space management meaningful. Fairness comes from
  /// weighted difficulty gating: larger / awkward pieces only enter after the
  /// run has progressed.
  List<BlockPiece> nextTray(GameEngine engine) {
    final List<PieceShape> eligible =
        PieceCatalog.eligibleForMoves(engine.movesPlayed);
    return List<BlockPiece>.generate(
      3,
      (_) => _fromShape(_pickWeighted(eligible)),
      growable: false,
    );
  }

  PieceShape _pickWeighted(List<PieceShape> shapes) {
    final int totalWeight = shapes.fold<int>(
      0,
      (int total, PieceShape shape) => total + max(1, shape.weight),
    );
    var ticket = _random.nextInt(totalWeight);
    for (final PieceShape shape in shapes) {
      ticket -= max(1, shape.weight);
      if (ticket < 0) return shape;
    }
    return shapes.last;
  }

  BlockPiece _fromShape(PieceShape shape) {
    _sequence += 1;
    return BlockPiece(
      id: '${shape.id}-$_sequence',
      shapeId: shape.id,
      cells: shape.cells,
      paletteIndex: _random.nextInt(paletteCount),
    );
  }
}
