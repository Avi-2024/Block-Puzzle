import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/game/domain/game_session_state.dart';
import 'game_session_repository.dart';

class SharedPreferencesGameSessionRepository implements GameSessionRepository {
  SharedPreferencesGameSessionRepository({
    SharedPreferencesAsync? preferences,
    String key = defaultKey,
  })  : _preferences = preferences ?? SharedPreferencesAsync(),
        _key = key;

  static const String defaultKey = 'game.active_session.v1';

  final SharedPreferencesAsync _preferences;
  final String _key;

  @override
  Future<GameSessionState?> load() async {
    final String? raw = await _preferences.getString(_key);
    if (raw == null || raw.isEmpty) return null;

    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) return null;
      return GameSessionState.fromJson(decoded);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> save(GameSessionState state) async {
    await _preferences.setString(_key, jsonEncode(state.toJson()));
  }

  @override
  Future<void> clear() async {
    await _preferences.remove(_key);
  }
}
