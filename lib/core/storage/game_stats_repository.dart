abstract interface class GameStatsRepository {
  Future<int> loadBestScore();
  Future<int> loadGamesPlayed();
  Future<void> saveBestScore(int value);
  Future<void> saveGamesPlayed(int value);
}
