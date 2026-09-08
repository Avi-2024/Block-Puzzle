import 'dart:math';

import '../../game/domain/block_piece.dart';
import '../../game/domain/game_engine.dart';
import '../../game/domain/piece_catalog.dart';
import '../../game/domain/piece_generator.dart';

/// Stateless deterministic generator for Daily Challenge.
///
/// Each three-piece batch is derived from the challenge seed plus the current
/// batch index. That means restoring a partially completed challenge never
/// rewinds or changes the future tray sequence.
class DailyPieceGenerator extends PieceGenerator {
  DailyPieceGenerator({required this.seed, int paletteCount = 7})
      : super(random: Random(seed), paletteCount: paletteCount);

  final int seed;

  @override
  List<BlockPiece> nextTray(GameEngine engine) {
    final int batchIndex = engine.movesPlayed ~/ 3;
    final Random random = Random(_batchSeed(batchIndex));
    final List<PieceShape> eligible =
        PieceCatalog.eligibleForMoves(engine.movesPlayed);

    return List<BlockPiece>.generate(3, (int slot) {
      final PieceShape shape = _pickWeighted(eligible, random);
      return BlockPiece(
        id: 'daily-$seed-$batchIndex-$slot-${shape.id}',
        shapeId: shape.id,
        cells: shape.cells,
        paletteIndex: random.nextInt(paletteCount),
      );
    }, growable: false);
  }

  int _batchSeed(int batchIndex) {
    final int mixed = seed ^ ((batchIndex + 1) * 0x45D9F3B);
    return mixed & 0x7FFFFFFF;
  }

  PieceShape _pickWeighted(List<PieceShape> shapes, Random random) {
    final int totalWeight = shapes.fold<int>(
      0,
      (int total, PieceShape shape) => total + max(1, shape.weight),
    );
    var ticket = random.nextInt(totalWeight);
    for (final PieceShape shape in shapes) {
      ticket -= max(1, shape.weight);
      if (ticket < 0) return shape;
    }
    return shapes.last;
  }
}
