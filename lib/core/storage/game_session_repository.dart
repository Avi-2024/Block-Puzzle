import '../../features/game/domain/game_session_state.dart';

abstract interface class GameSessionRepository {
  Future<GameSessionState?> load();
  Future<void> save(GameSessionState state);
  Future<void> clear();
}
