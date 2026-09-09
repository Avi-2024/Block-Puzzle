import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Small, offline-only game SFX service.
///
/// Sounds are synthesized into short WAV buffers at runtime, so Blockiva does
/// not depend on remote files, paid APIs, or third-party audio assets.
class GameAudioService {
  static const String _soundEnabledKey = 'settings.sound_enabled';

  final AudioPlayer _placementPlayer = AudioPlayer();
  final AudioPlayer _clearPlayer = AudioPlayer();
  final AudioPlayer _comboPlayer = AudioPlayer();

  late final Uint8List _placementBytes = _synthesizeTone(
    durationMs: 74,
    frequencies: const <double>[520, 780],
    volume: .34,
  );
  late final Uint8List _clearBytes = _synthesizeTone(
    durationMs: 190,
    frequencies: const <double>[620, 920, 1240, 1560],
    sweepHz: 280,
    volume: .36,
  );
  late final Uint8List _comboBytes = _synthesizeTone(
    durationMs: 265,
    frequencies: const <double>[680, 1010, 1320, 1700],
    sweepHz: 480,
    volume: .38,
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

  static Uint8List _synthesizeTone({
    required int durationMs,
    required List<double> frequencies,
    required double volume,
    double sweepHz = 0,
  }) {
    const int sampleRate = 22050;
    const int bytesPerSample = 2;
    final int sampleCount = (sampleRate * durationMs / 1000).round();
    final int dataLength = sampleCount * bytesPerSample;
    final ByteData wav = ByteData(44 + dataLength);

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
    wav.setUint32(24, sampleRate, Endian.little);
    wav.setUint32(28, sampleRate * bytesPerSample, Endian.little);
    wav.setUint16(32, bytesPerSample, Endian.little);
    wav.setUint16(34, 16, Endian.little);
    writeAscii(36, 'data');
    wav.setUint32(40, dataLength, Endian.little);

    for (var index = 0; index < sampleCount; index++) {
      final double progress = index / sampleCount;
      final double attack = math.min(1, progress / .06);
      final double release = math.min(1, (1 - progress) / .32);
      final double envelope = math.min(attack, release);
      final double seconds = index / sampleRate;

      var sample = 0.0;
      for (final double baseFrequency in frequencies) {
        final double frequency = baseFrequency + (sweepHz * progress);
        sample += math.sin(2 * math.pi * frequency * seconds);
      }
      sample /= frequencies.length;
      sample *= envelope * volume;

      final int pcm = (sample.clamp(-1.0, 1.0) * 32767).round();
      wav.setInt16(44 + (index * bytesPerSample), pcm, Endian.little);
    }

    return wav.buffer.asUint8List();
  }
}
