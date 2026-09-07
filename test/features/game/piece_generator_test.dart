import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:blockiva/features/game/domain/game_engine.dart';
import 'package:blockiva/features/game/domain/game_snapshot.dart';
import 'package:blockiva/features/game/domain/piece_generator.dart';

void main() {
  test('new tray contains at least one currently playable piece when possible', () {
    final GameEngine engine = GameEngine();
    final List<List<int?>> board = List<List<int?>>.generate(
      GameEngine.size,
      (_) => List<int?>.filled(GameEngine.size, 1),
    );
    board[0][0] = null;
    engine.restore(GameSnapshot(
      board: board,
      score: 0,
      combo: 0,
      totalLinesCleared: 0,
      movesPlayed: 0,
    ));
    final PieceGenerator generator = PieceGenerator(random: Random(7));
    final tray = generator.nextTray(engine);
    expect(tray.length, 3);
    expect(tray.any(engine.canPlaceAnywhere), isTrue);
  });
}
