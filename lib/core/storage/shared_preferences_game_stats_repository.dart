import 'package:shared_preferences/shared_preferences.dart';

import 'game_stats_repository.dart';

class SharedPreferencesGameStatsRepository implements GameStatsRepository {
  SharedPreferencesGameStatsRepository({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _bestScoreKey = 'game.best_score.v1';
  static const String _gamesPlayedKey = 'game.games_played.v1';

  final SharedPreferencesAsync _preferences;

  @override
  Future<int> loadBestScore() async =>
      await _preferences.getInt(_bestScoreKey) ?? 0;

  @override
  Future<int> loadGamesPlayed() async =>
      await _preferences.getInt(_gamesPlayedKey) ?? 0;

  @override
  Future<void> saveBestScore(int value) async {
    await _preferences.setInt(_bestScoreKey, value);
  }

  @override
  Future<void> saveGamesPlayed(int value) async {
    await _preferences.setInt(_gamesPlayedKey, value);
  }
}
