import 'package:blockiva/features/game/domain/block_piece.dart';
import 'package:blockiva/features/game/domain/cell_offset.dart';
import 'package:blockiva/features/game/presentation/piece_tray.dart';
import 'package:blockiva/features/game/presentation/piece_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const horizontal = BlockPiece(
  id: 'h5',
  shapeId: 'h5',
  cells: <CellOffset>[
    CellOffset(0, 0),
    CellOffset(0, 1),
    CellOffset(0, 2),
    CellOffset(0, 3),
    CellOffset(0, 4),
  ],
  paletteIndex: 0,
);
const vertical = BlockPiece(
  id: 'v5',
  shapeId: 'v5',
  cells: <CellOffset>[
    CellOffset(0, 0),
    CellOffset(1, 0),
    CellOffset(2, 0),
    CellOffset(3, 0),
    CellOffset(4, 0),
  ],
  paletteIndex: 2,
);
const corner = BlockPiece(
  id: 'corner',
  shapeId: 'corner3_tl',
  cells: <CellOffset>[CellOffset(0, 0), CellOffset(0, 1), CellOffset(1, 0)],
  paletteIndex: 4,
);

void main() {
  for (final double width in <double>[292, 332, 402]) {
    testWidgets('all long pieces fit inside a ${width}px tray', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: PieceTray(
                  pieces: const <BlockPiece>[horizontal, vertical, corner],
                  enabled: true,
                  feedbackCellSize: () => 40,
                  onDragStarted: () {},
                  onDragUpdate: (_, _) {},
                  onDragEnded: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      final Rect tray = tester.getRect(find.byType(PieceTray));
      for (var index = 0; index < 3; index++) {
        final Rect piece = tester.getRect(find.byType(PieceView).at(index));
        expect(piece.left, greaterThanOrEqualTo(tray.left + width / 3 * index));
        expect(
          piece.right,
          lessThanOrEqualTo(tray.left + width / 3 * (index + 1)),
        );
        expect(piece.top, greaterThanOrEqualTo(tray.top));
        expect(piece.bottom, lessThanOrEqualTo(tray.bottom));
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('one finger owns preview and release across the tray', (
    tester,
  ) async {
    final updates = <BlockPiece>[];
    final ends = <BlockPiece>[];
    var starts = 0;
    var boardCellSize = 38.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 332,
              child: PieceTray(
                pieces: const <BlockPiece>[horizontal, vertical, corner],
                enabled: true,
                feedbackCellSize: () => boardCellSize,
                onDragStarted: () => starts++,
                onDragUpdate: (piece, _) => updates.add(piece),
                onDragEnded: ends.add,
              ),
            ),
          ),
        ),
      ),
    );
    // Simulate the board becoming measurable after the initial screen build.
    boardCellSize = 41;
    final first = await tester.startGesture(
      tester.getCenter(find.byKey(const ObjectKey(horizontal))),
      pointer: 1,
    );
    await first.moveBy(const Offset(0, -45));
    await tester.pump();
    final feedback = find.byWidgetPredicate(
      (widget) => widget is PieceView && widget.elevated,
    );
    expect(tester.getSize(feedback).width, 5 * 41);

    final second = await tester.startGesture(
      tester.getCenter(find.byKey(const ObjectKey(vertical))),
      pointer: 2,
    );
    await second.moveBy(const Offset(0, -60));
    await tester.pump();
    await first.moveBy(const Offset(0, -30));
    await second.up();
    expect(ends, isEmpty);
    await first.up();
    await tester.pumpAndSettle();
    expect(starts, 1);
    expect(updates, isNotEmpty);
    expect(updates.every((piece) => identical(piece, horizontal)), isTrue);
    expect(ends, <BlockPiece>[horizontal]);

    await tester.drag(
      find.byKey(const ObjectKey(vertical)),
      const Offset(0, -50),
    );
    await tester.pumpAndSettle();
    expect(starts, 2);
    expect(ends.last, same(vertical));
    expect(tester.takeException(), isNull);
  });

  testWidgets('system pointer cancellation never commits a drop', (tester) async {
    var cancellations = 0;
    final ends = <BlockPiece>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Center(child: SizedBox(
        width: 332,
        child: PieceTray(
          pieces: const <BlockPiece?>[corner, null, null],
          enabled: true,
          feedbackCellSize: () => 40,
          onDragStarted: () {},
          onDragUpdate: (_, _) {},
          onDragEnded: ends.add,
          onDragCancelled: () => cancellations++,
        ),
      ))),
    ));
    // Small pieces retain their normal size rather than reserving room for a
    // five-cell shape that is not in this tray.
    expect(tester.getSize(find.byType(PieceView).first), const Size(50, 50));
    final piece = find.byType(Draggable<BlockPiece>).first;
    final gesture = await tester.startGesture(tester.getCenter(piece));
    await gesture.moveBy(const Offset(0, -50));
    await tester.pump();
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(cancellations, 1);
    expect(ends, isEmpty);
    expect(find.byWidgetPredicate((widget) =>
      widget is PieceView && widget.elevated), findsNothing);
    await tester.drag(piece, const Offset(0, -50));
    await tester.pumpAndSettle();
    expect(ends, <BlockPiece>[corner]);
    expect(tester.takeException(), isNull);
  });
}
