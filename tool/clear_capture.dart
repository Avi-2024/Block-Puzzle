// Android visual QA entrypoint. Seeds two almost-complete rows, then launches
// the real game so adb gestures can capture a clear followed by COMBO +2.
// This file is never used by the production main.dart entrypoint.
import 'package:blockiva/core/storage/shared_preferences_game_session_repository.dart';
import 'package:blockiva/features/game/domain/block_piece.dart';
import 'package:blockiva/features/game/domain/cell_offset.dart';
import 'package:blockiva/features/game/domain/game_session_state.dart';
import 'package:blockiva/features/game/domain/game_snapshot.dart';
import 'package:blockiva/main.dart' as blockiva;
import 'package:flutter/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final board = List<List<int?>>.generate(8, (_) => List<int?>.filled(8, null));
  for (final row in <int>[3, 4]) {
    for (var col = 0; col < 8; col++) {
      if (col != 3 && col != 4) board[row][col] = row == 3 ? 4 : 2;
    }
  }
  await SharedPreferencesGameSessionRepository().save(GameSessionState(
    snapshot: GameSnapshot(
      board: board, score: 0, combo: 0, totalLinesCleared: 0, movesPlayed: 0,
    ),
    tray: const <BlockPiece>[
      BlockPiece(id: 'qa-h2-first', shapeId: 'h2',
        cells: <CellOffset>[CellOffset(0, 0), CellOffset(0, 1)], paletteIndex: 3),
      BlockPiece(id: 'qa-h2-second', shapeId: 'h2',
        cells: <CellOffset>[CellOffset(0, 0), CellOffset(0, 1)], paletteIndex: 1),
      BlockPiece(id: 'qa-single', shapeId: 'single',
        cells: <CellOffset>[CellOffset(0, 0)], paletteIndex: 6),
    ],
    gameOver: false, revivesUsed: 0,
  ));
  await blockiva.main();
}
