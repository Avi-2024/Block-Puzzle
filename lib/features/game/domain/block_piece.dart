import 'cell_offset.dart';

class BlockPiece {
  const BlockPiece({
    required this.id,
    required this.shapeId,
    required this.cells,
    required this.paletteIndex,
  });

  final String id;
  final String shapeId;
  final List<CellOffset> cells;
  final int paletteIndex;

  int get width {
    var maxCol = 0;
    for (final CellOffset cell in cells) {
      if (cell.col > maxCol) maxCol = cell.col;
    }
    return maxCol + 1;
  }

  int get height {
    var maxRow = 0;
    for (final CellOffset cell in cells) {
      if (cell.row > maxRow) maxRow = cell.row;
    }
    return maxRow + 1;
  }
}
