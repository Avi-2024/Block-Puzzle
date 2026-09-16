import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// SoundPool requires a file/URL source; raw byte sources fail on Android.
/// Keep each generated WAV for the lifetime of its preloaded native player.
class SfxSourceCache {
  Future<Directory>? _directory;

  Future<Source> source(String name, Uint8List bytes) async {
    final Directory directory = await (_directory ??=
        Directory.systemTemp.createTemp('blockiva-sfx-'));
    final File file = File('${directory.path}/$name.wav');
    await file.writeAsBytes(bytes, flush: true);
    return DeviceFileSource(file.path, mimeType: 'audio/wav');
  }

  Future<void> dispose() async {
    final Future<Directory>? pending = _directory;
    if (pending == null) return;
    final Directory directory = await pending;
    if (await directory.exists()) await directory.delete(recursive: true);
  }
}
