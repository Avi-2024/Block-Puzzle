class DailyChallengeDefinition {
  const DailyChallengeDefinition({
    required this.dayKey,
    required this.seed,
    required this.moveLimit,
    required this.targetScore,
    required this.rewardCoins,
  });

  final String dayKey;
  final int seed;
  final int moveLimit;
  final int targetScore;
  final int rewardCoins;

  static DailyChallengeDefinition forDate(DateTime value) {
    final DateTime day = DateTime(value.year, value.month, value.day);
    String two(int number) => number.toString().padLeft(2, '0');
    final String key = '${day.year}-${two(day.month)}-${two(day.day)}';
    final int seed = day.year * 10000 + day.month * 100 + day.day;
    final int weekdayBias = day.weekday * 25;
    return DailyChallengeDefinition(
      dayKey: key,
      seed: seed,
      moveLimit: 30,
      targetScore: 900 + weekdayBias,
      rewardCoins: 125,
    );
  }
}
