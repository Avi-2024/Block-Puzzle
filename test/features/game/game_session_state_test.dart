import 'package:blockiva/features/game/domain/block_piece.dart';
import 'package:blockiva/features/game/domain/cell_offset.dart';
import 'package:blockiva/features/game/domain/game_session_state.dart';
import 'package:blockiva/features/game/domain/game_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('session state round-trips board, nullable tray and revive usage', () {
    final List<List<int?>> board = List<List<int?>>.generate(
      8,
      (_) => List<int?>.filled(8, null),
    );
    board[2][3] = 6;
    const BlockPiece piece = BlockPiece(
      id: 'h2-42',
      shapeId: 'h2',
      cells: <CellOffset>[CellOffset(0, 0), CellOffset(0, 1)],
      paletteIndex: 6,
    );
    final GameSessionState source = GameSessionState(
      snapshot: GameSnapshot(
        board: board,
        score: 725,
        combo: 2,
        totalLinesCleared: 6,
        movesPlayed: 15,
      ),
      tray: <BlockPiece?>[piece, null, piece],
      gameOver: false,
      revivesUsed: 1,
    );

    final GameSessionState? restored = GameSessionState.fromJson(source.toJson());

    expect(restored, isNotNull);
    expect(restored!.snapshot.board[2][3], 6);
    expect(restored.snapshot.score, 725);
    expect(restored.tray[1], isNull);
    expect(restored.tray.first!.shapeId, 'h2');
    expect(restored.tray.first!.paletteIndex, 6);
    expect(restored.tray.first!.cells.length, 2);
    expect(restored.revivesUsed, 1);
  });

  test('rejects palette indexes outside supported range', () {
    final List<List<int?>> board = List<List<int?>>.generate(
      8,
      (_) => List<int?>.filled(8, null),
    );
    board[0][0] = 7;

    expect(
      GameSessionState.fromJson(<String, Object?>{
        'version': 1,
        'board': board,
        'score': 0,
        'combo': 0,
        'totalLinesCleared': 0,
        'movesPlayed': 0,
        'tray': <Object?>[
          <String, Object?>{
            'id': 'single-1',
            'shapeId': 'single',
            'paletteIndex': 0,
            'cells': <Object?>[
              <Object?>[0, 0],
            ],
          },
          null,
          null,
        ],
        'gameOver': false,
        'revivesUsed': 0,
      }),
      isNull,
    );
  });

  test('rejects unknown schema and malformed payload', () {
    expect(GameSessionState.fromJson(<String, Object?>{'version': 99}), isNull);
    expect(
      GameSessionState.fromJson(<String, Object?>{
        'version': 1,
        'board': <Object?>[],
        'tray': <Object?>[],
      }),
      isNull,
    );
  });
}
