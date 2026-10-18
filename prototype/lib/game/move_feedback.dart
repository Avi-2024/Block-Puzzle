import 'puzzle.dart';

/// One reward decision for the written celebration and the female voice.
enum RewardKind { good, great, combo, amazing, incredible, newBest }

RewardKind? rewardForMove(PuzzleMove move, {int? previousScore}) {
  final best = move.state.startingBest;
  final before = previousScore ?? move.state.score - move.points;
  if (best > 0 && before <= best && move.state.score > best) {
    return RewardKind.newBest;
  }
  if (move.lines == 0) return null;
  return switch (move.state.combo) {
    <= 1 => move.lines > 1 ? RewardKind.great : RewardKind.good,
    2 => RewardKind.combo,
    3 => RewardKind.amazing,
    _ => RewardKind.incredible,
  };
}

/// A presentation-only colour projection. It never writes to a saved board or
/// calls the engine (which would consume a move or advance its random source).
class ClearFeedback {
  const ClearFeedback({
    this.color,
    this.rows = const {},
    this.columns = const {},
    this.cells = const {},
  });
  final int? color;
  final Set<int> rows, columns, cells;
  bool get isEmpty => cells.isEmpty;

  int colorAt(int index, int original) =>
      color != null && cells.contains(index) ? color! : original;

  factory ClearFeedback.preview(List<int> board, Piece piece, int x, int y) {
    if (!canPlace(board, piece, x, y)) return const ClearFeedback();
    final filled = List<int>.of(board);
    for (final cell in piece.cells) {
      filled[(y + cell.y) * 8 + x + cell.x] = piece.color;
    }
    final rows = <int>{}, columns = <int>{};
    for (var i = 0; i < 8; i++) {
      if (List.generate(8, (j) => filled[i * 8 + j]).every((v) => v >= 0)) {
        rows.add(i);
      }
      if (List.generate(8, (j) => filled[j * 8 + i]).every((v) => v >= 0)) {
        columns.add(i);
      }
    }
    return ClearFeedback(
      color: piece.color,
      rows: rows,
      columns: columns,
      cells: {
        for (final row in rows)
          for (var column = 0; column < 8; column++) row * 8 + column,
        for (final column in columns)
          for (var row = 0; row < 8; row++) row * 8 + column,
      },
    );
  }

  factory ClearFeedback.forMove(PuzzleMove move) => ClearFeedback(
    color: move.placed.isEmpty ? null : move.beforeClear[move.placed.first],
    rows: move.rows,
    columns: move.columns,
    cells: move.cleared,
  );
}
