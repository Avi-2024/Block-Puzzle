import 'dart:math';

import 'block_piece.dart';
import 'game_snapshot.dart';
import 'move_result.dart';

class GameEngine {
  GameEngine() { reset(); }

  static const int size = 8;

  late List<List<int?>> _board;
  int score = 0;
  int combo = 0;
  int totalLinesCleared = 0;
  int movesPlayed = 0;

  void reset() {
    _board = List<List<int?>>.generate(
      size,
      (_) => List<int?>.filled(size, null),
    );
    score = 0;
    combo = 0;
    totalLinesCleared = 0;
    movesPlayed = 0;
  }

  int? cellAt(int row, int col) {
    if (row < 0 || col < 0 || row >= size || col >= size) {
      throw RangeError('Cell ($row, $col) is outside the board.');
    }
    return _board[row][col];
  }

  bool canPlace(BlockPiece piece, int originRow, int originCol) {
    for (final cell in piece.cells) {
      final int row = originRow + cell.row;
      final int col = originCol + cell.col;
      if (row < 0 || col < 0 || row >= size || col >= size) return false;
      if (_board[row][col] != null) return false;
    }
    return true;
  }

  bool canPlaceAnywhere(BlockPiece piece) {
    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        if (canPlace(piece, row, col)) return true;
      }
    }
    return false;
  }

  bool anyPieceCanBePlaced(Iterable<BlockPiece> pieces) =>
      pieces.any(canPlaceAnywhere);

  MoveResult place(BlockPiece piece, int originRow, int originCol) {
    if (!canPlace(piece, originRow, originCol)) {
      return const MoveResult.rejected();
    }

    for (final cell in piece.cells) {
      _board[originRow + cell.row][originCol + cell.col] = piece.paletteIndex;
    }

    final int linesCleared = _clearCompletedLines();
    combo = linesCleared > 0 ? combo + 1 : 0;
    totalLinesCleared += linesCleared;
    movesPlayed += 1;

    final int placementPoints = piece.cells.length * 5;
    final int linePoints = linesCleared == 0
        ? 0
        : (linesCleared * 100) + (max(0, linesCleared - 1) * 50);
    final int comboMultiplier = max(1, combo);
    final int gained = placementPoints + (linePoints * comboMultiplier);
    score += gained;

    return MoveResult(
      accepted: true,
      placedCells: piece.cells.length,
      linesCleared: linesCleared,
      scoreGained: gained,
      combo: combo,
    );
  }

  GameSnapshot snapshot() => GameSnapshot(
        board: _board,
        score: score,
        combo: combo,
        totalLinesCleared: totalLinesCleared,
        movesPlayed: movesPlayed,
      );

  void restore(GameSnapshot snapshot) {
    if (snapshot.board.length != size ||
        snapshot.board.any((List<int?> row) => row.length != size)) {
      throw ArgumentError('Snapshot must contain an 8x8 board.');
    }
    _board = snapshot.board
        .map((List<int?> row) => List<int?>.from(row))
        .toList();
    score = snapshot.score;
    combo = snapshot.combo;
    totalLinesCleared = snapshot.totalLinesCleared;
    movesPlayed = snapshot.movesPlayed;
  }

  /// Opens enough board space after a rewarded revive while preserving score.
  bool reviveFor(Iterable<BlockPiece> remainingPieces) {
    final List<BlockPiece> pieces = remainingPieces.toList(growable: false);
    if (pieces.isEmpty) return false;
    if (anyPieceCanBePlaced(pieces)) return true;

    final List<int> rows = List<int>.generate(size, (int index) => index)
      ..sort((int a, int b) => _rowOccupancy(b).compareTo(_rowOccupancy(a)));
    final List<int> cols = List<int>.generate(size, (int index) => index)
      ..sort((int a, int b) => _colOccupancy(b).compareTo(_colOccupancy(a)));

    for (var index = 0; index < 2; index++) {
      _clearRow(rows[index]);
      if (anyPieceCanBePlaced(pieces)) {
        combo = 0;
        return true;
      }
      _clearCol(cols[index]);
      if (anyPieceCanBePlaced(pieces)) {
        combo = 0;
        return true;
      }
    }

    for (var row = 2; row <= 5; row++) {
      for (var col = 2; col <= 5; col++) {
        _board[row][col] = null;
      }
    }
    combo = 0;
    return anyPieceCanBePlaced(pieces);
  }

  int _clearCompletedLines() {
    final List<int> fullRows = <int>[];
    final List<int> fullCols = <int>[];

    for (var row = 0; row < size; row++) {
      if (_board[row].every((int? cell) => cell != null)) fullRows.add(row);
    }
    for (var col = 0; col < size; col++) {
      var full = true;
      for (var row = 0; row < size; row++) {
        if (_board[row][col] == null) {
          full = false;
          break;
        }
      }
      if (full) fullCols.add(col);
    }

    for (final int row in fullRows) {
      _clearRow(row);
    }
    for (final int col in fullCols) {
      _clearCol(col);
    }
    return fullRows.length + fullCols.length;
  }

  int _rowOccupancy(int row) =>
      _board[row].where((int? cell) => cell != null).length;

  int _colOccupancy(int col) {
    var count = 0;
    for (var row = 0; row < size; row++) {
      if (_board[row][col] != null) count += 1;
    }
    return count;
  }

  void _clearRow(int row) {
    for (var col = 0; col < size; col++) {
      _board[row][col] = null;
    }
  }

  void _clearCol(int col) {
    for (var row = 0; row < size; row++) {
      _board[row][col] = null;
    }
  }
}
