import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'puzzle.dart';

class PuzzleStore {
  PuzzleStore(this.preferences);
  final SharedPreferences preferences;
  static const sessionKey = 'puzzle.prototype.session.v1';
  static const bestKey = 'puzzle.prototype.best';
  Future<void> _writes = Future<void>.value();
  PuzzleState load(PuzzleEngine engine) {
    final best = preferences.getInt(bestKey) ?? 0;
    try {
      final raw = preferences.getString(sessionKey);
      final state = raw == null ? null : PuzzleState.decode(jsonDecode(raw));
      if (state != null) {
        return PuzzleState(board: state.board, tray: state.tray,
          score: state.score, best: max(best, state.best), combo: state.combo, moves: state.moves);
      }
    } on FormatException { /* A damaged session must not prevent startup. */ }
    return engine.fresh(best: best);
  }
  Future<void> save(PuzzleState state) {
    final encoded = jsonEncode(state.toJson());
    _writes = _writes.catchError((Object _) {}).then((_) async {
      await preferences.setString(sessionKey, encoded);
      await preferences.setInt(bestKey, state.best);
    });
    return _writes;
  }
  bool get haptics => preferences.getBool('puzzle.prototype.haptics') ?? true;
  bool get reduceMotion => preferences.getBool('puzzle.prototype.reduce_motion') ?? false;
  Future<void> setHaptics(bool value) async { await preferences.setBool('puzzle.prototype.haptics', value); }
  Future<void> setReduceMotion(bool value) async { await preferences.setBool('puzzle.prototype.reduce_motion', value); }
}
