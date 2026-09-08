import 'dart:math';

abstract final class RunRewardPolicy {
  static int coinsForRun({required int score, required int linesCleared}) {
    final int scoreBonus = min(40, score ~/ 250);
    final int lineBonus = min(30, linesCleared * 2);
    return 10 + scoreBonus + lineBonus;
  }
}

abstract final class DailyRewardPolicy {
  static const List<int> rewards = <int>[25, 30, 35, 40, 50, 75, 100];

  static int rewardForStreak(int streak) {
    if (streak <= 0) return rewards.first;
    return rewards[min(streak, rewards.length) - 1];
  }
}
