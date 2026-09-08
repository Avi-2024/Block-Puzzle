import 'package:blockiva/core/storage/progression_repository.dart';
import 'package:blockiva/features/progression/application/progression_controller.dart';
import 'package:blockiva/features/progression/domain/progression_state.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryProgressionRepository implements ProgressionRepository {
  ProgressionState? stored;

  @override
  Future<ProgressionState?> load() async => stored;

  @override
  Future<void> save(ProgressionState state) async {
    stored = state;
  }
}

void main() {
  test('daily challenge reward can only settle once for the day', () async {
    final _MemoryProgressionRepository repository =
        _MemoryProgressionRepository();
    final ProgressionController controller = ProgressionController(
      repository: repository,
      now: () => DateTime(2026, 9, 9, 12),
    );
    await controller.initialize();

    expect(
      controller.completeDailyChallenge(
        dayKey: '2026-09-09',
        rewardCoins: 125,
      ),
      125,
    );
    expect(controller.coins, 125);
    expect(controller.dailyChallengesCompleted, 1);
    expect(controller.isDailyChallengeCompleted('2026-09-09'), isTrue);

    expect(
      controller.completeDailyChallenge(
        dayKey: '2026-09-09',
        rewardCoins: 125,
      ),
      0,
    );
    expect(controller.coins, 125);
    expect(controller.dailyChallengesCompleted, 1);
  });

  test('legacy progression payload migrates without daily challenge fields', () {
    final ProgressionState? state = ProgressionState.fromJson(
      <String, Object?>{
        'coins': 90,
        'dailyStreak': 2,
        'lastDailyClaimDay': '2026-09-08',
        'totalLinesCleared': 12,
        'highestCombo': 3,
        'unlockedAchievementIds': <Object?>['first_clear'],
        'unlockedThemeIds': <Object?>['classic'],
        'selectedThemeId': 'classic',
      },
    );

    expect(state, isNotNull);
    expect(state!.dailyChallengesCompleted, 0);
    expect(state.lastDailyChallengeCompletedDay, isNull);
    expect(state.coins, 90);
  });
}
