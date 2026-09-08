import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/progression/domain/progression_state.dart';
import 'progression_repository.dart';

class SharedPreferencesProgressionRepository implements ProgressionRepository {
  SharedPreferencesProgressionRepository({SharedPreferencesAsync? preferences})
      : _providedPreferences = preferences;

  static const String _key = 'progression.state.v1';

  final SharedPreferencesAsync? _providedPreferences;
  SharedPreferencesAsync? _lazyPreferences;

  SharedPreferencesAsync get _preferences =>
      _providedPreferences ?? (_lazyPreferences ??= SharedPreferencesAsync());

  @override
  Future<ProgressionState?> load() async {
    final String? raw = await _preferences.getString(_key);
    if (raw == null || raw.isEmpty) return null;

    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) return null;
      return ProgressionState.fromJson(decoded);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> save(ProgressionState state) async {
    await _preferences.setString(_key, jsonEncode(state.toJson()));
  }
}
