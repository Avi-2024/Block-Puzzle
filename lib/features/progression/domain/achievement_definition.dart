class AchievementDefinition {
  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardCoins,
  });

  final String id;
  final String title;
  final String description;
  final int rewardCoins;
}

abstract final class AchievementCatalog {
  static const AchievementDefinition firstClear = AchievementDefinition(
    id: 'first_clear',
    title: 'First Clear',
    description: 'Clear your first row or column.',
    rewardCoins: 25,
  );

  static const AchievementDefinition comboThree = AchievementDefinition(
    id: 'combo_3',
    title: 'Combo Maker',
    description: 'Reach a x3 clear combo.',
    rewardCoins: 50,
  );

  static const AchievementDefinition scoreOneK = AchievementDefinition(
    id: 'score_1000',
    title: 'Four Digits',
    description: 'Reach a score of 1,000.',
    rewardCoins: 50,
  );

  static const AchievementDefinition scoreFiveK = AchievementDefinition(
    id: 'score_5000',
    title: 'Block Master',
    description: 'Reach a score of 5,000.',
    rewardCoins: 100,
  );

  static const AchievementDefinition tenGames = AchievementDefinition(
    id: 'ten_games',
    title: 'Regular Player',
    description: 'Complete 10 runs.',
    rewardCoins: 100,
  );

  static const AchievementDefinition streakSeven = AchievementDefinition(
    id: 'streak_7',
    title: 'Seven Day Streak',
    description: 'Claim the daily reward 7 days in a row.',
    rewardCoins: 150,
  );

  static const List<AchievementDefinition> all = <AchievementDefinition>[
    firstClear,
    comboThree,
    scoreOneK,
    scoreFiveK,
    tenGames,
    streakSeven,
  ];
}
