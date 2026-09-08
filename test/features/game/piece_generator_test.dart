import 'dart:math';

import 'package:blockiva/features/game/domain/game_engine.dart';
import 'package:blockiva/features/game/domain/game_snapshot.dart';
import 'package:blockiva/features/game/domain/piece_catalog.dart';
import 'package:blockiva/features/game/domain/piece_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('new tray always contains exactly three unique piece instances', () {
    final PieceGenerator generator = PieceGenerator(random: Random(7));
    final tray = generator.nextTray(GameEngine());

    expect(tray, hasLength(3));
    expect(tray.map((piece) => piece.id).toSet(), hasLength(3));
    expect(tray.every((piece) => piece.paletteIndex >= 0), isTrue);
    expect(tray.every((piece) => piece.paletteIndex < 7), isTrue);
  });

  test('early trays cannot use late-run large pieces', () {
    final Set<String> earlyIds = PieceCatalog.eligibleForMoves(0)
        .map((shape) => shape.id)
        .toSet();

    expect(earlyIds, isNot(contains('h5')));
    expect(earlyIds, isNot(contains('v5')));
    expect(earlyIds, isNot(contains('square3')));
  });

  test('late-run catalog unlocks long bars and 3x3 square', () {
    final Set<String> lateIds = PieceCatalog.eligibleForMoves(30)
        .map((shape) => shape.id)
        .toSet();

    expect(lateIds, containsAll(<String>['h5', 'v5', 'square3']));
    expect(PieceCatalog.shapes.length, greaterThanOrEqualTo(20));
  });

  test('generator can produce a batch even when board has no free cell', () {
    final GameEngine engine = GameEngine();
    final List<List<int?>> board = List<List<int?>>.generate(
      GameEngine.size,
      (_) => List<int?>.filled(GameEngine.size, 1),
    );
    engine.restore(
      GameSnapshot(
        board: board,
        score: 300,
        combo: 0,
        totalLinesCleared: 3,
        movesPlayed: 30,
      ),
    );

    final PieceGenerator generator = PieceGenerator(random: Random(11));
    final tray = generator.nextTray(engine);

    expect(tray, hasLength(3));
    expect(tray.any(engine.canPlaceAnywhere), isFalse);
  });
}
