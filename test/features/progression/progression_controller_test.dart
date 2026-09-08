import 'package:blockiva/core/storage/progression_repository.dart';
import 'package:blockiva/features/progression/application/progression_controller.dart';
import 'package:blockiva/features/progression/domain/progression_state.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryProgressionRepository implements ProgressionRepository {
  ProgressionState? stored;

  @override
  Future<ProgressionState?> load() async => stored;

  @override
  Future<void> save(ProgressionState state) async {
    stored = state;
  }
}

void main() {
  test('run reward grants coins and first-clear achievement once', () async {
    final MemoryProgressionRepository repo = MemoryProgressionRepository();
    final ProgressionController controller = ProgressionController(
      repository: repo,
      now: () => DateTime(2026, 9, 8, 12),
    );
    await controller.initialize();

    controller.recordMove(
      linesCleared: 1,
      combo: 1,
      currentScore: 500,
      bestScore: 500,
      gamesPlayed: 0,
    );
    expect(controller.coins, 25);
    expect(controller.isAchievementUnlocked('first_clear'), isTrue);

    final int runCoins = controller.recordRunCompleted(
      score: 500,
      linesCleared: 1,
      bestScore: 500,
      gamesPlayed: 1,
    );
    expect(runCoins, 14);
    expect(controller.coins, 39);

    controller.recordMove(
      linesCleared: 1,
      combo: 1,
      currentScore: 550,
      bestScore: 550,
      gamesPlayed: 1,
    );
    expect(controller.coins, 39);
  });

  test('daily streak increments on consecutive local days and resets after gap', () async {
    final MemoryProgressionRepository repo = MemoryProgressionRepository();
    DateTime now = DateTime(2026, 9, 8, 8);
    final ProgressionController controller = ProgressionController(
      repository: repo,
      now: () => now,
    );
    await controller.initialize();

    expect(controller.claimDailyReward(), 25);
    expect(controller.dailyStreak, 1);
    expect(controller.claimDailyReward(), 0);

    now = DateTime(2026, 9, 9, 22);
    expect(controller.claimDailyReward(), 30);
    expect(controller.dailyStreak, 2);

    now = DateTime(2026, 9, 12, 9);
    expect(controller.claimDailyReward(), 25);
    expect(controller.dailyStreak, 1);
  });

  test('seven-day streak unlocks achievement reward', () async {
    final MemoryProgressionRepository repo = MemoryProgressionRepository();
    DateTime now = DateTime(2026, 9, 1, 9);
    final ProgressionController controller = ProgressionController(
      repository: repo,
      now: () => now,
    );
    await controller.initialize();

    for (var day = 1; day <= 7; day++) {
      now = DateTime(2026, 9, day, 9);
      controller.claimDailyReward();
    }

    expect(controller.dailyStreak, 7);
    expect(controller.isAchievementUnlocked('streak_7'), isTrue);
    expect(controller.coins, 355 + 150);
  });

  test('theme unlock deducts once and later selection is free', () async {
    final MemoryProgressionRepository repo = MemoryProgressionRepository()
      ..stored = ProgressionState.initial().copyWith(coins: 1000);
    final ProgressionController controller = ProgressionController(
      repository: repo,
    );
    await controller.initialize();

    expect(controller.unlockAndSelectTheme('sunset'), isTrue);
    expect(controller.coins, 550);
    expect(controller.state.selectedThemeId, 'sunset');

    expect(controller.unlockAndSelectTheme('classic'), isTrue);
    expect(controller.coins, 550);
    expect(controller.unlockAndSelectTheme('sunset'), isTrue);
    expect(controller.coins, 550);
  });

  test('theme purchase fails without enough coins', () async {
    final ProgressionController controller = ProgressionController(
      repository: MemoryProgressionRepository(),
    );
    await controller.initialize();

    expect(controller.unlockAndSelectTheme('mint'), isFalse);
    expect(controller.state.selectedThemeId, 'classic');
  });
}
