import 'package:blockiva/features/game/domain/block_piece.dart';
import 'package:blockiva/features/game/domain/cell_offset.dart';
import 'package:blockiva/features/game/domain/game_engine.dart';
import 'package:blockiva/features/game/domain/game_snapshot.dart';
import 'package:blockiva/features/game/presentation/clear_prediction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const piece = BlockPiece(id: 'one', shapeId: 'single',
    cells: <CellOffset>[CellOffset(0, 0)], paletteIndex: 2);

  test('cross prediction matches a real clear without mutating the session', () {
    final board = List.generate(8, (_) => List<int?>.filled(8, null));
    for (int i = 0; i < 8; i++) {
      if (i != 3) board[3][i] = 0;
      if (i != 3) board[i][3] = 1;
    }
    final engine = GameEngine()..restore(GameSnapshot(board: board,
      score: 70, combo: 2, totalLinesCleared: 2, movesPlayed: 5));
    final before = engine.snapshot();
    final prediction = predictClears(engine, piece, 3, 3);
    expect(prediction.rows, <int>{3});
    expect(prediction.cols, <int>{3});
    expect(engine.snapshot().board, before.board);
    expect(engine.score, 70);
    expect(engine.combo, 2);
    expect(engine.movesPlayed, 5);
    final result = engine.place(piece, 3, 3);
    expect(prediction.rows, result.clearedRows.toSet());
    expect(prediction.cols, result.clearedCols.toSet());
  });

  test('illegal and ordinary placements never predict a clear', () {
    final engine = GameEngine();
    expect(predictClears(engine, piece, -1, 0).rows, isEmpty);
    expect(predictClears(engine, piece, 0, 8).cols, isEmpty);
    expect(predictClears(engine, piece, 0, 0).rows, isEmpty);
    engine.place(piece, 0, 0);
    final blocked = predictClears(engine, piece, 0, 0);
    expect(blocked.rows, isEmpty);
    expect(blocked.cols, isEmpty);
  });
}
