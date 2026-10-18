import 'dart:async';

import 'package:flutter/foundation.dart';

import '../game/puzzle.dart';
import '../game/move_feedback.dart';
import 'audio_settings.dart';

export '../game/move_feedback.dart' show RewardKind;

enum GameEffect { pickup, place, invalid, clear, combo, record }

enum AudioSignal { interrupted, resumed }

/// The default output is silent: widget previews/tests never need a device.
/// The app entrypoint explicitly supplies NativeAudioOutput.
class GameAudioOutput {
  Stream<AudioSignal> get signals => const Stream.empty();
  Future<void> initialize() async {}
  Future<bool> focus(bool active) async => active;
  Future<void> effect(GameEffect effect, double volume) async {}

  /// Completes when speech finishes or is cancelled, not when it starts.
  Future<void> speak(
    VoiceStyle style,
    RewardKind callout,
    double volume,
  ) async {}
  Future<void> voiceVolume(double volume) async {}
  Future<void> effectsVolume(double volume) async {}
  Future<void> stopVoice() async {}
  Future<void> stopEffects() async {}
  Future<void> dispose() async {}
}

class GameAudio extends ChangeNotifier {
  GameAudio({
    required this.output,
    this.settings = const AudioSettings(),
    this.save,
  }) {
    _signals = output.signals.listen((event) {
      _interrupted = event == AudioSignal.interrupted;
      if (_interrupted) cancelFeedback();
      _reconcileFocus();
      _notify();
    });
  }

  final GameAudioOutput output;
  final Future<void> Function(AudioSettings)? save;
  AudioSettings settings;
  late final StreamSubscription<AudioSignal> _signals;
  Future<void> _focusWork = Future<void>.value();
  Timer? _voiceDelay, _cooldown;
  int _focusToken = 0, _voiceToken = 0, _saveToken = 0;
  bool _disposed = false, _ready = false, _active = false, _visible = true;
  bool _interrupted = false, _focused = false, _speaking = false;
  String? error;
  bool get paused => _interrupted;
  bool get speaking => _speaking;
  bool get _wanted =>
      _active && _visible && !_interrupted && settings.audible && !_disposed;
  bool get _canPlay => _wanted && _ready && _focused;

  Future<void> start({required bool active}) async {
    _active = active;
    try {
      await output.initialize();
      if (_disposed) return;
      _ready = true;
      _reconcileFocus();
    } catch (e) {
      _report(e);
    }
  }

  void setActive(bool value) {
    if (_disposed || _active == value) return;
    _active = value;
    if (!value) cancelFeedback();
    _reconcileFocus();
  }

  void setVisible(bool value) {
    if (_disposed || _visible == value) return;
    _visible = value;
    if (!value) cancelFeedback();
    _reconcileFocus();
  }

  /// Explicit recovery after permanent focus loss or a disconnected headset.
  void resume() {
    _interrupted = false;
    error = null;
    _reconcileFocus();
    _notify();
  }

  void _reconcileFocus() {
    final token = ++_focusToken;
    if (!_wanted) {
      _focused = false;
    }
    if (!_ready || _disposed) return;
    // Keep the existing focus request during a temporary interruption so the
    // OS can deliver its matching resume event. Background/mute still release it.
    if (_interrupted && _active && _visible && settings.audible) return;
    _focusWork = _focusWork
        .then((_) async {
          if (_disposed || token != _focusToken) return;
          final wanted = _wanted;
          final granted = await output.focus(wanted);
          if (_disposed || token != _focusToken) {
            if (granted) await output.focus(false);
            return;
          }
          _focused = wanted && granted;
          if (wanted && !granted) {
            _interrupted = true;
            _notify();
          }
        })
        .catchError((Object e) => _report(e));
  }

  void update(AudioSettings value) {
    if (_disposed) return;
    final old = settings;
    settings = value;
    if (old.style != value.style || value.gain(AudioBus.voice) == 0) {
      _cancelVoice();
    }
    _run(() => output.voiceVolume(value.gain(AudioBus.voice)));
    _run(() => output.effectsVolume(value.gain(AudioBus.effects)));
    if (value.gain(AudioBus.effects) == 0) _run(output.stopEffects);
    if (old.audible != value.audible) _reconcileFocus();
    _notify();
    final token = ++_saveToken;
    if (save != null) {
      unawaited(
        save!(value)
            .then((_) {
              if (!_disposed &&
                  token == _saveToken &&
                  error == 'Sound settings could not be saved.') {
                error = null;
                _notify();
              }
            })
            .catchError((Object e) {
              if (!_disposed && token == _saveToken) {
                error = 'Sound settings could not be saved.';
                _notify();
              }
            }),
      );
    }
  }

  void effect(GameEffect effect) {
    if (!_canPlay || settings.gain(AudioBus.effects) == 0) return;
    _run(() => output.effect(effect, settings.gain(AudioBus.effects)));
  }

  /// startingBest is persisted with the round. Crossing it exactly once avoids
  /// repeating "New best" on every move, even after an app restart or demo.
  void move(PuzzleState before, PuzzleMove move) {
    final reward = rewardForMove(move, previousScore: before.score);
    final record = reward == RewardKind.newBest;
    effect(
      record
          ? GameEffect.record
          : move.lines == 0
          ? GameEffect.place
          : move.state.combo > 1
          ? GameEffect.combo
          : GameEffect.clear,
    );
    if (reward != null) _say(reward, priority: record);
  }

  void previewVoice([RewardKind callout = RewardKind.amazing]) =>
      _say(callout, priority: true, delay: Duration.zero);

  void _say(
    RewardKind callout, {
    bool priority = false,
    Duration delay = const Duration(milliseconds: 160),
  }) {
    if (!_canPlay || settings.gain(AudioBus.voice) == 0) return;
    if (!priority && (_speaking || _cooldown?.isActive == true)) return;
    _cancelVoice();
    final token = ++_voiceToken;
    _voiceDelay = Timer(delay, () async {
      if (!_canPlay || token != _voiceToken) return;
      _speaking = true;
      _notify();
      try {
        await output.speak(
          settings.style,
          callout,
          settings.gain(AudioBus.voice),
        );
      } catch (e) {
        _report(e);
      } finally {
        if (!_disposed && token == _voiceToken) {
          _speaking = false;
          _cooldown = Timer(const Duration(milliseconds: 250), () {});
          _notify();
        }
      }
    });
  }

  void _cancelVoice() {
    _voiceToken++;
    _voiceDelay?.cancel();
    _cooldown?.cancel();
    _speaking = false;
    _run(output.stopVoice);
  }

  void cancelFeedback() {
    _cancelVoice();
    _run(output.stopEffects);
  }

  void _run(Future<void> Function() action) {
    if (_disposed) return;
    unawaited(Future<void>.sync(action).catchError((Object e) => _report(e)));
  }

  void _report(Object e) {
    debugPrint('Game audio unavailable: $e');
    if (_disposed) return;
    error = 'Audio is unavailable. You can keep playing.';
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _focusToken++;
    _voiceToken++;
    _voiceDelay?.cancel();
    _cooldown?.cancel();
    unawaited(_signals.cancel());
    // The backend invalidates pending decodes synchronously before disposal.
    unawaited(
      output.dispose().catchError(
        (Object e) => debugPrint('Audio disposal: $e'),
      ),
    );
    super.dispose();
  }
}
