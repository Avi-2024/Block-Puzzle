class ProgressionState {
  const ProgressionState({
    required this.coins,
    required this.dailyStreak,
    required this.lastDailyClaimDay,
    required this.lastDailyChallengeCompletedDay,
    required this.dailyChallengesCompleted,
    required this.totalLinesCleared,
    required this.highestCombo,
    required this.unlockedAchievementIds,
    required this.unlockedThemeIds,
    required this.selectedThemeId,
  });

  factory ProgressionState.initial() => const ProgressionState(
        coins: 0,
        dailyStreak: 0,
        lastDailyClaimDay: null,
        lastDailyChallengeCompletedDay: null,
        dailyChallengesCompleted: 0,
        totalLinesCleared: 0,
        highestCombo: 0,
        unlockedAchievementIds: <String>{},
        unlockedThemeIds: <String>{'classic'},
        selectedThemeId: 'classic',
      );

  final int coins;
  final int dailyStreak;
  final String? lastDailyClaimDay;
  final String? lastDailyChallengeCompletedDay;
  final int dailyChallengesCompleted;
  final int totalLinesCleared;
  final int highestCombo;
  final Set<String> unlockedAchievementIds;
  final Set<String> unlockedThemeIds;
  final String selectedThemeId;

  ProgressionState copyWith({
    int? coins,
    int? dailyStreak,
    String? lastDailyClaimDay,
    bool clearLastDailyClaimDay = false,
    String? lastDailyChallengeCompletedDay,
    bool clearLastDailyChallengeCompletedDay = false,
    int? dailyChallengesCompleted,
    int? totalLinesCleared,
    int? highestCombo,
    Set<String>? unlockedAchievementIds,
    Set<String>? unlockedThemeIds,
    String? selectedThemeId,
  }) {
    return ProgressionState(
      coins: coins ?? this.coins,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      lastDailyClaimDay: clearLastDailyClaimDay
          ? null
          : lastDailyClaimDay ?? this.lastDailyClaimDay,
      lastDailyChallengeCompletedDay: clearLastDailyChallengeCompletedDay
          ? null
          : lastDailyChallengeCompletedDay ??
              this.lastDailyChallengeCompletedDay,
      dailyChallengesCompleted:
          dailyChallengesCompleted ?? this.dailyChallengesCompleted,
      totalLinesCleared: totalLinesCleared ?? this.totalLinesCleared,
      highestCombo: highestCombo ?? this.highestCombo,
      unlockedAchievementIds:
          unlockedAchievementIds ?? this.unlockedAchievementIds,
      unlockedThemeIds: unlockedThemeIds ?? this.unlockedThemeIds,
      selectedThemeId: selectedThemeId ?? this.selectedThemeId,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'coins': coins,
        'dailyStreak': dailyStreak,
        'lastDailyClaimDay': lastDailyClaimDay,
        'lastDailyChallengeCompletedDay': lastDailyChallengeCompletedDay,
        'dailyChallengesCompleted': dailyChallengesCompleted,
        'totalLinesCleared': totalLinesCleared,
        'highestCombo': highestCombo,
        'unlockedAchievementIds': unlockedAchievementIds.toList()..sort(),
        'unlockedThemeIds': unlockedThemeIds.toList()..sort(),
        'selectedThemeId': selectedThemeId,
      };

  static ProgressionState? fromJson(Map<String, Object?> json) {
    try {
      final int coins = _nonNegativeInt(json['coins']);
      final int dailyStreak = _nonNegativeInt(json['dailyStreak']);
      final int totalLinesCleared = _nonNegativeInt(json['totalLinesCleared']);
      final int highestCombo = _nonNegativeInt(json['highestCombo']);
      final int dailyChallengesCompleted =
          _optionalNonNegativeInt(json['dailyChallengesCompleted']);
      final Object? lastClaim = json['lastDailyClaimDay'];
      final Object? lastChallenge = json['lastDailyChallengeCompletedDay'];
      if (lastClaim != null && lastClaim is! String) return null;
      if (lastChallenge != null && lastChallenge is! String) return null;

      final Set<String> achievements = _stringSet(json['unlockedAchievementIds']);
      final Set<String> themes = _stringSet(json['unlockedThemeIds']);
      final Object? selectedTheme = json['selectedThemeId'];
      if (selectedTheme is! String || selectedTheme.isEmpty) return null;

      themes.add('classic');
      final String safeSelected = themes.contains(selectedTheme)
          ? selectedTheme
          : 'classic';

      return ProgressionState(
        coins: coins,
        dailyStreak: dailyStreak,
        lastDailyClaimDay: lastClaim as String?,
        lastDailyChallengeCompletedDay: lastChallenge as String?,
        dailyChallengesCompleted: dailyChallengesCompleted,
        totalLinesCleared: totalLinesCleared,
        highestCombo: highestCombo,
        unlockedAchievementIds: achievements,
        unlockedThemeIds: themes,
        selectedThemeId: safeSelected,
      );
    } on FormatException {
      return null;
    }
  }

  static int _nonNegativeInt(Object? value) {
    if (value is! int || value < 0) {
      throw const FormatException('Expected non-negative integer.');
    }
    return value;
  }

  static int _optionalNonNegativeInt(Object? value) {
    if (value == null) return 0;
    return _nonNegativeInt(value);
  }

  static Set<String> _stringSet(Object? value) {
    if (value is! List<Object?>) {
      throw const FormatException('Expected string list.');
    }
    final Set<String> result = <String>{};
    for (final Object? item in value) {
      if (item is! String || item.isEmpty) {
        throw const FormatException('Invalid string list item.');
      }
      result.add(item);
    }
    return result;
  }
}
