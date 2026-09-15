import 'dart:math';

import 'package:blockiva/features/game/domain/block_piece.dart';
import 'package:blockiva/features/game/domain/game_engine.dart';
import 'package:blockiva/features/game/domain/game_snapshot.dart';
import 'package:blockiva/features/game/domain/piece_catalog.dart';

// Independent board oracle. Run with: dart run tool/verify_game_rules.dart
// This checks correctness, not device FPS or human-player difficulty.
void main() {
  final random = Random(15092026);
  var checks = 0;
  for (var sample = 0; sample < 2048; sample++) {
    final density = sample % 9 / 10;
    final board = List.generate(8, (_) => List<int?>.generate(
      8, (_) => random.nextDouble() < density ? random.nextInt(7) : null,
    ));
    final engine = GameEngine()..restore(GameSnapshot(
      board: board, score: 0, combo: 0, totalLinesCleared: 0, movesPlayed: 0,
    ));
    for (final shape in PieceCatalog.shapes) {
      final piece = BlockPiece(
        id: shape.id, shapeId: shape.id, cells: shape.cells, paletteIndex: 1,
      );
      var hasMove = false;
      for (var row = 0; row < 8; row++) {
        for (var col = 0; col < 8; col++) {
          final legal = piece.cells.every((cell) =>
            row + cell.row < 8 && col + cell.col < 8 &&
            board[row + cell.row][col + cell.col] == null);
          require(engine.canPlace(piece, row, col) == legal,
            'placement mismatch: sample=$sample shape=${shape.id} at $row,$col');
          hasMove = hasMove || legal;
          checks++;
        }
      }
      require(engine.canPlaceAnywhere(piece) == hasMove,
        'legal-move mismatch: sample=$sample shape=${shape.id}');
    }
    final shape = PieceCatalog.shapes[random.nextInt(PieceCatalog.shapes.length)];
    final piece = BlockPiece(
      id: shape.id, shapeId: shape.id, cells: shape.cells, paletteIndex: 2,
    );
    final row = random.nextInt(10) - 1;
    final col = random.nextInt(10) - 1;
    final expected = board.map((row) => List<int?>.from(row)).toList();
    final legal = piece.cells.every((cell) =>
      row + cell.row >= 0 && col + cell.col >= 0 &&
      row + cell.row < 8 && col + cell.col < 8 &&
      board[row + cell.row][col + cell.col] == null);
    final rows = <int>[];
    final cols = <int>[];
    if (legal) {
      for (final cell in piece.cells) {
        expected[row + cell.row][col + cell.col] = 2;
      }
      for (var i = 0; i < 8; i++) {
        if (expected[i].every((cell) => cell != null)) rows.add(i);
        if (List.generate(8, (j) => expected[j][i]).every((cell) => cell != null)) {
          cols.add(i);
        }
      }
      for (var r = 0; r < 8; r++) {
        for (var c = 0; c < 8; c++) {
          if (rows.contains(r) || cols.contains(c)) expected[r][c] = null;
        }
      }
    }
    final result = engine.place(piece, row, col);
    require(result.accepted == legal, 'acceptance mismatch: sample=$sample');
    require(result.linesCleared == rows.length + cols.length,
      'simultaneous-clear mismatch: sample=$sample');
    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        require(engine.cellAt(r, c) == expected[r][c],
          'board/no-gravity mismatch: sample=$sample at $r,$c');
      }
    }
    require(engine.movesPlayed == (legal ? 1 : 0), 'rejected move mutated count');
    if (!legal) require(engine.score == 0, 'rejected move mutated score');
  }
  // ignore: avoid_print
  print('PASS: 2048 seeded boards, $checks placement checks; legal-move detection, '
      'simultaneous clears, rejected moves and no-gravity verified.');
}

void require(bool condition, String message) {
  if (!condition) throw StateError(message);
}
