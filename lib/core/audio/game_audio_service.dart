import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  final AudioPlayer _placementPlayer = AudioPlayer();
  final AudioPlayer _clearPlayer = AudioPlayer();
  final AudioPlayer _comboPlayer = AudioPlayer();

  late final Uint8List _placementBytes = _synthesizeTone(
    durationMs: 82,
    frequencies: const <double>[540, 720, 980],
    sweepHz: 68,
    volume: .32,
    sparkle: .13,
    snap: .10,
  );
  late final Uint8List _clearBytes = _synthesizeTone(
    durationMs: 210,
    frequencies: const <double>[640, 920, 1220, 1640],
    sweepHz: 330,
    volume: .35,
    sparkle: .22,
    snap: .14,
  );
  late final Uint8List _comboBytes = _synthesizeTone(
    durationMs: 305,
    frequencies: const <double>[660, 980, 1320, 1760, 2120],
    sweepHz: 560,
    volume: .36,
    sparkle: .30,
    snap: .18,
  );

  bool enabled = true;

  Future<void> initialize() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    enabled = preferences.getBool(_soundEnabledKey) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    enabled = value;
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_soundEnabledKey, value);
  }

  Future<void> toggle() => setEnabled(!enabled);

  Future<void> playPlacement() => _play(
        _placementPlayer,
        _placementBytes,
        volume: .42,
      );

  Future<void> playClear() => _play(
        _clearPlayer,
        _clearBytes,
        volume: .56,
      );

  Future<void> playCombo() => _play(
        _comboPlayer,
        _comboBytes,
        volume: .62,
      );

  Future<void> _play(
    AudioPlayer player,
    Uint8List bytes, {
    required double volume,
  }) async {
    if (!enabled) return;
    try {
      await player.stop();
      await player.play(
        BytesSource(bytes, mimeType: 'audio/wav'),
        volume: volume,
        mode: PlayerMode.lowLatency,
      );
    } catch (_) {
      // Audio must never be able to interrupt gameplay.
    }
  }

  Future<void> dispose() async {
    await Future.wait(<Future<void>>[
      _placementPlayer.dispose(),
      _clearPlayer.dispose(),
      _comboPlayer.dispose(),
    ]);
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
