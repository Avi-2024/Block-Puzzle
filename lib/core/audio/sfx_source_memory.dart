import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SfxSourceCache {
  Future<Source> source(String name, Uint8List bytes) async =>
      BytesSource(bytes, mimeType: 'audio/wav');

  Future<void> dispose() async {}
}
