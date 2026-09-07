import 'dart:math';

import 'block_piece.dart';
import 'game_engine.dart';
import 'piece_catalog.dart';

class PieceGenerator {
  PieceGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;
  var _sequence = 0;

  List<BlockPiece> nextTray(GameEngine engine) {
    final List<PieceShape> playableShapes = PieceCatalog.shapes.where((PieceShape shape) {
      final BlockPiece probe = BlockPiece(
        id: 'probe',
        shapeId: shape.id,
        cells: shape.cells,
        paletteIndex: 0,
      );
      return engine.canPlaceAnywhere(probe);
    }).toList(growable: false);

    final List<BlockPiece> tray = <BlockPiece>[];
    if (playableShapes.isNotEmpty) {
      tray.add(_fromShape(playableShapes[_random.nextInt(playableShapes.length)]));
    } else {
      tray.add(_randomPiece());
    }
    tray.add(_randomPiece());
    tray.add(_randomPiece());
    tray.shuffle(_random);
    return tray;
  }

  BlockPiece _randomPiece() =>
      _fromShape(PieceCatalog.shapes[_random.nextInt(PieceCatalog.shapes.length)]);

  BlockPiece _fromShape(PieceShape shape) {
    _sequence += 1;
    return BlockPiece(
      id: '${shape.id}-$_sequence',
      shapeId: shape.id,
      cells: shape.cells,
      paletteIndex: _random.nextInt(6),
    );
  }
}
