class ProgressionState {
  const ProgressionState({
    required this.coins,
    required this.dailyStreak,
    required this.lastDailyClaimDay,
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
        totalLinesCleared: 0,
        highestCombo: 0,
        unlockedAchievementIds: <String>{},
        unlockedThemeIds: <String>{'classic'},
        selectedThemeId: 'classic',
      );

  final int coins;
  final int dailyStreak;
  final String? lastDailyClaimDay;
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
      final Object? lastClaim = json['lastDailyClaimDay'];
      if (lastClaim != null && lastClaim is! String) return null;

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
