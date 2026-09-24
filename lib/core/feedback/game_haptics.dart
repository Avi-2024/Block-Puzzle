import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Native, event-only feedback. Never overrides the system vibration setting.
class GameHaptics {
  static const preferenceKey = 'settings.haptics_enabled';
  bool enabled = true;
  bool active = true;

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    enabled = preferences.getBool(preferenceKey) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    enabled = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(preferenceKey, value);
  }

  Future<void> selection() async {
    if (enabled && active) await HapticFeedback.selectionClick();
  }

  Future<void> impact() async {
    if (enabled && active) await HapticFeedback.lightImpact();
  }

  Future<void> reward() async {
    if (enabled && active) await HapticFeedback.mediumImpact();
  }
}
