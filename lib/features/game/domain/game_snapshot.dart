class GameSnapshot {
  GameSnapshot({
    required List<List<int?>> board,
    required this.score,
    required this.combo,
    required this.totalLinesCleared,
    required this.movesPlayed,
  }) : board = board.map((List<int?> row) => List<int?>.from(row)).toList();

  final List<List<int?>> board;
  final int score;
  final int combo;
  final int totalLinesCleared;
  final int movesPlayed;
}
