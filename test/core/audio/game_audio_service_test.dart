import 'dart:typed_data';

import 'package:blockiva/core/audio/game_audio_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String ascii(Uint8List bytes, int start, int end) =>
      String.fromCharCodes(bytes.sublist(start, end));

  test('synthesized tone writes a valid mono 16-bit wav header', () {
    const int durationMs = 120;
    final Uint8List bytes = GameAudioService.synthesizeToneForTest(
      durationMs: durationMs,
      frequencies: const <double>[520, 780],
      volume: .32,
      sweepHz: 80,
      sparkle: .12,
      snap: .10,
    );
    final ByteData data = ByteData.sublistView(bytes);
    final int expectedSampleCount = (22050 * durationMs / 1000).round();
    final int expectedDataLength = expectedSampleCount * 2;

    expect(ascii(bytes, 0, 4), 'RIFF');
    expect(ascii(bytes, 8, 12), 'WAVE');
    expect(ascii(bytes, 12, 16), 'fmt ');
    expect(ascii(bytes, 36, 40), 'data');
    expect(data.getUint16(20, Endian.little), 1);
    expect(data.getUint16(22, Endian.little), 1);
    expect(data.getUint32(24, Endian.little), 22050);
    expect(data.getUint16(34, Endian.little), 16);
    expect(data.getUint32(40, Endian.little), expectedDataLength);
    expect(bytes.length, 44 + expectedDataLength);
  });

  test('synthesized tone contains audible non-silent pcm samples', () {
    final Uint8List bytes = GameAudioService.synthesizeToneForTest(
      durationMs: 90,
      frequencies: const <double>[640, 920, 1220],
      volume: .34,
      sweepHz: 180,
      sparkle: .18,
      snap: .14,
    );
    final ByteData data = ByteData.sublistView(bytes);

    var peak = 0;
    for (var offset = 44; offset < bytes.length; offset += 2) {
      final int sample = data.getInt16(offset, Endian.little).abs();
      if (sample > peak) peak = sample;
    }

    expect(peak, greaterThan(0));
    expect(peak, lessThanOrEqualTo(32767));
  });
}
