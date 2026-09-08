class MoveResult {
  const MoveResult({
    required this.accepted,
    required this.placedCells,
    required this.linesCleared,
    required this.clearedRows,
    required this.clearedCols,
    required this.scoreGained,
    required this.combo,
  });

  const MoveResult.rejected()
      : accepted = false,
        placedCells = 0,
        linesCleared = 0,
        clearedRows = const <int>[],
        clearedCols = const <int>[],
        scoreGained = 0,
        combo = 0;

  final bool accepted;
  final int placedCells;
  final int linesCleared;
  final List<int> clearedRows;
  final List<int> clearedCols;
  final int scoreGained;
  final int combo;
}
