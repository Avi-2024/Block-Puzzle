import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/storage/progression_repository.dart';
import '../domain/achievement_definition.dart';
import '../domain/game_theme_definition.dart';
import '../domain/progression_state.dart';
import '../domain/reward_policies.dart';

class ProgressionController extends ChangeNotifier {
  ProgressionController({
    required ProgressionRepository repository,
    DateTime Function()? now,
  })  : _repository = repository,
        _now = now ?? DateTime.now;

  final ProgressionRepository _repository;
  final DateTime Function() _now;

  ProgressionState state = ProgressionState.initial();
  bool initialized = false;

  var _observedBestScore = 0;
  var _observedGamesPlayed = 0;
  final List<String> _recentAchievementIds = <String>[];

  int get coins => state.coins;
  int get dailyStreak => state.dailyStreak;
  GameThemeDefinition get selectedTheme =>
      GameThemeCatalog.byId(state.selectedThemeId);

  bool get dailyRewardAvailable {
    if (!initialized) return false;
    return state.lastDailyClaimDay != _dayKey(_now());
  }

  int get nextDailyStreak {
    if (!initialized) return 1;
    final DateTime today = _localDay(_now());
    final String? last = state.lastDailyClaimDay;
    if (last == null) return 1;
    if (last == _dayKey(today)) return state.dailyStreak;
    if (last == _dayKey(today.subtract(const Duration(days: 1)))) {
      return state.dailyStreak + 1;
    }
    return 1;
  }

  int get nextDailyReward =>
      DailyRewardPolicy.rewardForStreak(nextDailyStreak);

  Future<void> initialize() async {
    if (initialized) return;
    state = await _repository.load() ?? ProgressionState.initial();
    initialized = true;
    notifyListeners();
  }

  void recordMove({
    required int linesCleared,
    required int combo,
    required int currentScore,
    required int bestScore,
    required int gamesPlayed,
  }) {
    if (!initialized) return;
    _observedBestScore = bestScore > _observedBestScore
        ? bestScore
        : _observedBestScore;
    _observedGamesPlayed = gamesPlayed > _observedGamesPlayed
        ? gamesPlayed
        : _observedGamesPlayed;

    final int nextLines = state.totalLinesCleared + linesCleared;
    final int nextCombo = combo > state.highestCombo ? combo : state.highestCombo;
    final ProgressionState before = state;
    state = state.copyWith(
      totalLinesCleared: nextLines,
      highestCombo: nextCombo,
    );
    _unlockEligible(
      bestScore: currentScore > _observedBestScore
          ? currentScore
          : _observedBestScore,
      gamesPlayed: _observedGamesPlayed,
    );
    if (!_sameState(before, state)) _commit();
  }

  int recordRunCompleted({
    required int score,
    required int linesCleared,
    required int bestScore,
    required int gamesPlayed,
  }) {
    if (!initialized) return 0;
    _observedBestScore = bestScore > _observedBestScore
        ? bestScore
        : _observedBestScore;
    _observedGamesPlayed = gamesPlayed > _observedGamesPlayed
        ? gamesPlayed
        : _observedGamesPlayed;

    final int reward = RunRewardPolicy.coinsForRun(
      score: score,
      linesCleared: linesCleared,
    );
    state = state.copyWith(coins: state.coins + reward);
    _unlockEligible(
      bestScore: _observedBestScore,
      gamesPlayed: _observedGamesPlayed,
    );
    _commit();
    return reward;
  }

  int claimDailyReward() {
    if (!dailyRewardAvailable) return 0;

    final int streak = nextDailyStreak;
    final int reward = DailyRewardPolicy.rewardForStreak(streak);
    state = state.copyWith(
      coins: state.coins + reward,
      dailyStreak: streak,
      lastDailyClaimDay: _dayKey(_now()),
    );
    _unlockEligible(
      bestScore: _observedBestScore,
      gamesPlayed: _observedGamesPlayed,
    );
    _commit();
    return reward;
  }

  bool unlockAndSelectTheme(String themeId) {
    if (!initialized) return false;
    final GameThemeDefinition theme = GameThemeCatalog.byId(themeId);
    final bool alreadyUnlocked = state.unlockedThemeIds.contains(theme.id);

    if (!alreadyUnlocked && state.coins < theme.unlockCost) return false;

    final Set<String> unlocked = Set<String>.from(state.unlockedThemeIds)
      ..add(theme.id);
    state = state.copyWith(
      coins: alreadyUnlocked ? state.coins : state.coins - theme.unlockCost,
      unlockedThemeIds: unlocked,
      selectedThemeId: theme.id,
    );
    _commit();
    return true;
  }

  List<String> takeRecentAchievementIds() {
    final List<String> result = List<String>.from(_recentAchievementIds);
    _recentAchievementIds.clear();
    return result;
  }

  bool isAchievementUnlocked(String id) =>
      state.unlockedAchievementIds.contains(id);

  bool isThemeUnlocked(String id) => state.unlockedThemeIds.contains(id);

  void _unlockEligible({required int bestScore, required int gamesPlayed}) {
    final Set<String> unlocked = Set<String>.from(state.unlockedAchievementIds);
    var rewardCoins = 0;

    for (final AchievementDefinition achievement in AchievementCatalog.all) {
      if (unlocked.contains(achievement.id)) continue;
      final bool eligible = switch (achievement.id) {
        'first_clear' => state.totalLinesCleared >= 1,
        'combo_3' => state.highestCombo >= 3,
        'score_1000' => bestScore >= 1000,
        'score_5000' => bestScore >= 5000,
        'ten_games' => gamesPlayed >= 10,
        'streak_7' => state.dailyStreak >= 7,
        _ => false,
      };
      if (!eligible) continue;
      unlocked.add(achievement.id);
      rewardCoins += achievement.rewardCoins;
      _recentAchievementIds.add(achievement.id);
    }

    if (rewardCoins > 0) {
      state = state.copyWith(
        coins: state.coins + rewardCoins,
        unlockedAchievementIds: unlocked,
      );
    }
  }

  void _commit() {
    unawaited(_repository.save(state));
    notifyListeners();
  }

  static bool _sameState(ProgressionState a, ProgressionState b) =>
      a.coins == b.coins &&
      a.dailyStreak == b.dailyStreak &&
      a.lastDailyClaimDay == b.lastDailyClaimDay &&
      a.totalLinesCleared == b.totalLinesCleared &&
      a.highestCombo == b.highestCombo &&
      setEquals(a.unlockedAchievementIds, b.unlockedAchievementIds) &&
      setEquals(a.unlockedThemeIds, b.unlockedThemeIds) &&
      a.selectedThemeId == b.selectedThemeId;

  static DateTime _localDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String _dayKey(DateTime value) {
    final DateTime day = _localDay(value);
    String two(int number) => number.toString().padLeft(2, '0');
    return '${day.year}-${two(day.month)}-${two(day.day)}';
  }
}
