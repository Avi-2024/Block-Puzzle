import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

abstract interface class GameSoundPlayer {
  Future<void> prepare(Source source, double volume);
  Future<void> restart();
  Future<void> stop();
  Future<void> dispose();
}

class NativeGameSoundPlayer implements GameSoundPlayer {
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<void> prepare(Source source, double volume) async {
    await _player.setAudioContext(AudioContext(
      android: const AudioContextAndroid(
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.game,
        audioFocus: AndroidAudioFocus.none,
      ),
      iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
    ));
    await _player.setPlayerMode(
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android
          ? PlayerMode.lowLatency
          : PlayerMode.mediaPlayer,
    );
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setVolume(volume);
    await _player.setSource(source);
  }

  @override
  Future<void> restart() async {
    // stop resets the SoundPool stream, while ReleaseMode.stop retains the
    // decoded sound. resume therefore avoids a file decode on every move.
    await _player.stop();
    await _player.resume();
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}
