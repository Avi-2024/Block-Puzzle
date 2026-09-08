import 'package:blockiva/features/game/domain/block_piece.dart';
import 'package:blockiva/features/game/domain/cell_offset.dart';
import 'package:blockiva/features/game/presentation/board_drag_projector.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const Size board = Size.square(320);
  const BlockPiece square = BlockPiece(
    id: 'square',
    shapeId: 'square2',
    cells: <CellOffset>[
      CellOffset(0, 0),
      CellOffset(0, 1),
      CellOffset(1, 0),
      CellOffset(1, 1),
    ],
    paletteIndex: 0,
  );

  test('projects finger position to the same visual piece origin', () {
    // 40px cells. A 2x2 piece at row 3 / col 2 has center (120, 160).
    // Finger sits 76px below that visual center.
    final BoardDropOrigin? origin = BoardDragProjector.project(
      pointerInBoard: const Offset(120, 236),
      boardSize: board,
      piece: square,
    );

    expect(origin, const BoardDropOrigin(row: 3, col: 2));
  });

  test('returns null when lifted piece would be outside the board', () {
    final BoardDropOrigin? origin = BoardDragProjector.project(
      pointerInBoard: const Offset(10, 30),
      boardSize: board,
      piece: square,
    );

    expect(origin, isNull);
  });

  test('feedback cell size exactly matches board grid cell size', () {
    expect(BoardDragProjector.feedbackCellSize(board), 40);
  });
}
