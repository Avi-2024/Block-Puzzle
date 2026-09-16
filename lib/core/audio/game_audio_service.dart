import 'dart:math' as math;


import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game_sound_player.dart';
import 'sfx_source.dart';

/// Small, offline-only game SFX service.
///
/// Sounds are synthesized into short WAV buffers at runtime, so Blockiva does
/// not depend on remote files, paid APIs, or third-party audio assets.
class GameAudioService {
  static const String _soundEnabledKey = 'settings.sound_enabled';
  static const int _sampleRate = 22050;
  static const int _bytesPerSample = 2;
  static const int _wavHeaderBytes = 44;
  static const int _pcmPeak = 32767;

  @visibleForTesting
  static const int wavSampleRateForTest = _sampleRate;

  @visibleForTesting
  static const int wavBytesPerSampleForTest = _bytesPerSample;

  @visibleForTesting
  static const int wavHeaderBytesForTest = _wavHeaderBytes;

  @visibleForTesting
  static const int wavPcmPeakForTest = _pcmPeak;

  GameAudioService({GameSoundPlayer Function()? playerFactory})
      : _playerFactory = playerFactory ?? NativeGameSoundPlayer.new;

  final GameSoundPlayer Function() _playerFactory;
  final SfxSourceCache _sources = SfxSourceCache();
  final Map<String, GameSoundPlayer> _players = <String, GameSoundPlayer>{};
  final Map<String, Future<void>> _pending = <String, Future<void>>{};
  Future<void>? _initialization;
  Future<void>? _disposal;
  bool _disposed = false;
  bool _enabled = true;
  int _generation = 0;
  String? lastError;

  bool get enabled => _enabled;

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    try {
      final SharedPreferences preferences = await SharedPreferences.getInstance();
      if (_disposed) return;
      _enabled = preferences.getBool(_soundEnabledKey) ?? true;
      for (final String name in <String>[
        'pickup', 'placement', 'invalid', 'clear', 'combo',
      ]) {
        if (_disposed) return;
        final GameSoundPlayer player = _playerFactory();
        _players[name] = player;
        final Source source = await _sources.source(name, _soundBytes(name));
        await player.prepare(source, name == 'pickup' ? .55 : .85);
      }
    } catch (error) {
      _report('initialize', error);
    }
  }

  Future<void> setEnabled(bool value) async {
    await initialize();
    if (_disposed) return;
    _enabled = value;
    _generation++;
    if (!value) {
      // Drain in-flight commands before stopping: a late native resume must
      // never undo mute. New requests are rejected immediately by _enabled.
      await Future.wait(_pending.values.toList());
      for (final GameSoundPlayer player in _players.values) {
        try {
          await player.stop();
        } catch (error) {
          _report('mute', error);
        }
      }
    }
    try {
      final SharedPreferences preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_soundEnabledKey, _enabled);
    } catch (error) {
      _report('save preference', error);
    }
  }

  Future<void> toggle() => setEnabled(!enabled);
  Future<void> playPickup() => _play('pickup');
  Future<void> playPlacement() => _play('placement');
  Future<void> playInvalid() => _play('invalid');
  Future<void> playClear() => _play('clear');
  Future<void> playCombo() => _play('combo');

  Future<void> _play(String name) {
    if (_disposed || !_enabled) return Future<void>.value();
    final int generation = _generation;
    final Future<void> command = (_pending[name] ?? Future<void>.value())
        .then((_) async {
      await initialize();
      if (_disposed || !_enabled || generation != _generation) return;
      try {
        await _players[name]?.restart();
      } catch (error) {
        _report(name, error);
      }
    });
    _pending[name] = command;
    return command;
  }

  void _report(String action, Object error) {
    lastError = '$action: $error';
    debugPrint('Blockiva audio error: $lastError');
  }

  Future<void> dispose() => _disposal ??= _dispose();

  Future<void> _dispose() async {
    _disposed = true;
    _generation++;
    await _initialization;
    await Future.wait(_pending.values.toList());
    for (final GameSoundPlayer player in _players.values) {
      try {
        await player.dispose();
      } catch (error) {
        _report('dispose', error);
      }
    }
    await _sources.dispose();
  }

  static Uint8List _soundBytes(String name) {
    switch (name) {
      case 'pickup':
        return _synthesizeTone(durationMs: 48,
          frequencies: const <double>[440, 660], volume: .42, sweepHz: 40);
      case 'invalid':
        return _synthesizeTone(durationMs: 95,
          frequencies: const <double>[180, 240], volume: .50, sweepHz: -65);
      case 'placement':
        return _synthesizeTone(durationMs: 82,
          frequencies: const <double>[540, 720, 980], volume: .60,
          sweepHz: 68, sparkle: .13, snap: .10);
      case 'clear':
        return _synthesizeTone(durationMs: 210,
          frequencies: const <double>[640, 920, 1220, 1640], volume: .65,
          sweepHz: 330, sparkle: .22, snap: .14);
      default:
        return _synthesizeTone(durationMs: 305,
          frequencies: const <double>[660, 980, 1320, 1760, 2120], volume: .68,
          sweepHz: 560, sparkle: .30, snap: .18);
    }
  }

  @visibleForTesting
  static Uint8List synthesizeToneForTest({
    required int durationMs,
    required List<double> frequencies,
    required double volume,
    double sweepHz = 0,
    double sparkle = 0,
    double snap = 0,
  }) =>
      _synthesizeTone(
        durationMs: durationMs,
        frequencies: frequencies,
        volume: volume,
        sweepHz: sweepHz,
        sparkle: sparkle,
        snap: snap,
      );

  static Uint8List _synthesizeTone({
    required int durationMs,
    required List<double> frequencies,
    required double volume,
    double sweepHz = 0,
    double sparkle = 0,
    double snap = 0,
  }) {
    final int sampleCount = (_sampleRate * durationMs / 1000).round();
    final int dataLength = sampleCount * _bytesPerSample;
    final ByteData wav = ByteData(_wavHeaderBytes + dataLength);

    void writeAscii(int offset, String text) {
      for (var index = 0; index < text.length; index++) {
        wav.setUint8(offset + index, text.codeUnitAt(index));
      }
    }

    writeAscii(0, 'RIFF');
    wav.setUint32(4, 36 + dataLength, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    wav.setUint32(16, 16, Endian.little);
    wav.setUint16(20, 1, Endian.little);
    wav.setUint16(22, 1, Endian.little);
    wav.setUint32(24, _sampleRate, Endian.little);
    wav.setUint32(28, _sampleRate * _bytesPerSample, Endian.little);
    wav.setUint16(32, _bytesPerSample, Endian.little);
    wav.setUint16(34, 16, Endian.little);
    writeAscii(36, 'data');
    wav.setUint32(40, dataLength, Endian.little);

    for (var index = 0; index < sampleCount; index++) {
      final double progress = index / sampleCount;
      final double attack = math.min(1, progress / .040);
      final double release = math.min(1, (1 - progress) / .38);
      final double envelope = math.min(attack, release);
      final double sparkleEnvelope = (1 - progress) * sparkle;
      final double snapEnvelope = math.max(0, 1 - (progress / .075)) * snap;
      final double seconds = index / _sampleRate;

      var sample = 0.0;
      for (final double baseFrequency in frequencies) {
        final double frequency = baseFrequency + (sweepHz * progress);
        final double phase = 2 * math.pi * frequency * seconds;
        final double snapPhase = 2 * math.pi * (frequency * 3.5 + 1800) * seconds;
        sample += math.sin(phase);
        sample += math.sin(phase * 2) * sparkleEnvelope;
        sample += math.sin(phase * 3) * sparkleEnvelope * .32;
        sample += math.sin(snapPhase) * snapEnvelope * .22;
      }
      sample /= frequencies.length;
      sample *= envelope * volume;

      final int pcm = (sample.clamp(-1.0, 1.0) * _pcmPeak).round();
      wav.setInt16(_wavHeaderBytes + (index * _bytesPerSample), pcm, Endian.little);
    }

    return wav.buffer.asUint8List();
  }
}
