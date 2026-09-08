import 'package:blockiva/features/game/domain/block_piece.dart';
import 'package:blockiva/features/game/domain/cell_offset.dart';
import 'package:blockiva/features/game/domain/game_engine.dart';
import 'package:blockiva/features/game/domain/game_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

const BlockPiece single = BlockPiece(
  id: 'single-test',
  shapeId: 'single',
  cells: <CellOffset>[CellOffset(0, 0)],
  paletteIndex: 0,
);

const BlockPiece square = BlockPiece(
  id: 'square-test',
  shapeId: 'square2',
  cells: <CellOffset>[
    CellOffset(0, 0),
    CellOffset(0, 1),
    CellOffset(1, 0),
    CellOffset(1, 1),
  ],
  paletteIndex: 1,
);

List<List<int?>> emptyBoard() => List<List<int?>>.generate(
      GameEngine.size,
      (_) => List<int?>.filled(GameEngine.size, null),
    );

void main() {
  group('GameEngine placement', () {
    test('accepts a valid piece and rejects overlap', () {
      final GameEngine engine = GameEngine();
      final first = engine.place(single, 0, 0);
      final second = engine.place(single, 0, 0);
      expect(first.accepted, isTrue);
      expect(first.placedCells, 1);
      expect(engine.cellAt(0, 0), 0);
      expect(second.accepted, isFalse);
      expect(engine.movesPlayed, 1);
    });

    test('rejects a piece outside board bounds', () {
      final GameEngine engine = GameEngine();
      expect(engine.canPlace(square, 7, 7), isFalse);
      expect(engine.place(square, 7, 7).accepted, isFalse);
    });
  });

  group('GameEngine line clearing and scoring', () {
    test('clears a completed row and reports its index', () {
      final GameEngine engine = GameEngine();
      final List<List<int?>> board = emptyBoard();
      for (var col = 0; col < 7; col++) {
        board[0][col] = 2;
      }
      engine.restore(
        GameSnapshot(
          board: board,
          score: 0,
          combo: 0,
          totalLinesCleared: 0,
          movesPlayed: 0,
        ),
      );
      final result = engine.place(single, 0, 7);
      expect(result.linesCleared, 1);
      expect(result.clearedRows, <int>[0]);
      expect(result.clearedCols, isEmpty);
      expect(result.scoreGained, 105);
      expect(engine.combo, 1);
      for (var col = 0; col < GameEngine.size; col++) {
        expect(engine.cellAt(0, col), isNull);
      }
    });

    test('reports simultaneous row and column clears', () {
      final GameEngine engine = GameEngine();
      final List<List<int?>> board = emptyBoard();
      for (var col = 0; col < 7; col++) {
        board[0][col] = 2;
      }
      for (var row = 1; row < 8; row++) {
        board[row][7] = 3;
      }
      engine.restore(
        GameSnapshot(
          board: board,
          score: 0,
          combo: 0,
          totalLinesCleared: 0,
          movesPlayed: 0,
        ),
      );
      final result = engine.place(single, 0, 7);
      expect(result.linesCleared, 2);
      expect(result.clearedRows, <int>[0]);
      expect(result.clearedCols, <int>[7]);
      expect(result.scoreGained, 255);
      expect(engine.totalLinesCleared, 2);
    });

    test('resets combo after a move that clears no line', () {
      final GameEngine engine = GameEngine();
      final List<List<int?>> board = emptyBoard();
      for (var col = 0; col < 7; col++) {
        board[0][col] = 1;
      }
      engine.restore(
        GameSnapshot(
          board: board,
          score: 0,
          combo: 0,
          totalLinesCleared: 0,
          movesPlayed: 0,
        ),
      );
      engine.place(single, 0, 7);
      expect(engine.combo, 1);
      engine.place(single, 3, 3);
      expect(engine.combo, 0);
    });
  });

  group('GameEngine snapshots and revive', () {
    test('snapshot is deep-copied and can be restored', () {
      final GameEngine engine = GameEngine();
      engine.place(single, 2, 2);
      final GameSnapshot snapshot = engine.snapshot();
      engine.place(single, 3, 3);
      engine.restore(snapshot);
      expect(engine.cellAt(2, 2), isNotNull);
      expect(engine.cellAt(3, 3), isNull);
      expect(engine.movesPlayed, 1);
    });

    test('rewarded revive creates a legal move without resetting score', () {
      final GameEngine engine = GameEngine();
      final List<List<int?>> board = List<List<int?>>.generate(
        GameEngine.size,
        (_) => List<int?>.filled(GameEngine.size, 1),
      );
      engine.restore(
        GameSnapshot(
          board: board,
          score: 2500,
          combo: 4,
          totalLinesCleared: 18,
          movesPlayed: 42,
        ),
      );
      expect(engine.canPlaceAnywhere(square), isFalse);
      expect(engine.reviveFor(<BlockPiece>[square]), isTrue);
      expect(engine.canPlaceAnywhere(square), isTrue);
      expect(engine.score, 2500);
      expect(engine.combo, 0);
    });
  });
}
