import '../domain/block_piece.dart';
import '../domain/game_engine.dart';

/// Read-only move preview: never advances the engine or its score.
({Set<int> rows, Set<int> cols}) predictClears(
  GameEngine engine, BlockPiece piece, int row, int col,
) {
  final rows = <int>{};
  final cols = <int>{};
  if (!engine.canPlace(piece, row, col)) return (rows: rows, cols: cols);
  final added = piece.cells
      .map((cell) => (row + cell.row) * GameEngine.size + col + cell.col)
      .toSet();
  bool filled(int r, int c) =>
      engine.cellAt(r, c) != null || added.contains(r * GameEngine.size + c);
  for (int i = 0; i < GameEngine.size; i++) {
    if (List<bool>.generate(GameEngine.size, (j) => filled(i, j)).every((v) => v)) {
      rows.add(i);
    }
    if (List<bool>.generate(GameEngine.size, (j) => filled(j, i)).every((v) => v)) {
      cols.add(i);
    }
  }
  return (rows: rows, cols: cols);
}
