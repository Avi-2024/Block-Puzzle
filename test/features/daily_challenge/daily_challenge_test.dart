import 'package:blockiva/features/daily_challenge/domain/daily_challenge_definition.dart';
import 'package:blockiva/features/daily_challenge/domain/daily_piece_generator.dart';
import 'package:blockiva/features/game/domain/game_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('same local date produces identical challenge definition', () {
    final DailyChallengeDefinition morning =
        DailyChallengeDefinition.forDate(DateTime(2026, 9, 9, 8));
    final DailyChallengeDefinition night =
        DailyChallengeDefinition.forDate(DateTime(2026, 9, 9, 23, 59));

    expect(morning.dayKey, '2026-09-09');
    expect(morning.seed, night.seed);
    expect(morning.targetScore, night.targetScore);
    expect(morning.moveLimit, 30);
    expect(morning.rewardCoins, 125);
  });

  test('different dates produce different daily seeds', () {
    final DailyChallengeDefinition first =
        DailyChallengeDefinition.forDate(DateTime(2026, 9, 9));
    final DailyChallengeDefinition second =
        DailyChallengeDefinition.forDate(DateTime(2026, 9, 10));

    expect(first.seed, isNot(second.seed));
    expect(first.dayKey, isNot(second.dayKey));
  });

  test('daily generator is deterministic for the same seed and batch', () {
    final GameEngine firstEngine = GameEngine();
    final GameEngine secondEngine = GameEngine();
    final DailyPieceGenerator first = DailyPieceGenerator(seed: 20260909);
    final DailyPieceGenerator second = DailyPieceGenerator(seed: 20260909);

    final firstTray = first.nextTray(firstEngine);
    final secondTray = second.nextTray(secondEngine);

    expect(
      firstTray.map((piece) => piece.shapeId).toList(),
      secondTray.map((piece) => piece.shapeId).toList(),
    );
    expect(
      firstTray.map((piece) => piece.paletteIndex).toList(),
      secondTray.map((piece) => piece.paletteIndex).toList(),
    );
    expect(
      firstTray.map((piece) => piece.id).toList(),
      secondTray.map((piece) => piece.id).toList(),
    );
  });
}
