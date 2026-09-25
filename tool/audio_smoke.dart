// Separate Android QA entrypoint; never included in the user gameplay route.
import 'dart:async';

import 'package:blockiva/core/audio/game_audio_service.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: Scaffold(body: Center(
    child: Text('Blockiva audio verification'),
  ))));
  final GameAudioService audio = GameAudioService();
  await audio.initialize();
  await audio.setEnabled(true);
  // Gives the host recorder a deterministic start marker to align the WAV.
  debugPrint('BLOCKIVA_AUDIO_READY');
  await Future<void>.delayed(const Duration(seconds: 3));
  for (final (String, Future<void> Function()) event in <(String, Future<void> Function())>[
    ('pickup', audio.playPickup),
    ('placement', audio.playPlacement),
    ('invalid', audio.playInvalid),
    ('clear', audio.playClear),
    ('combo', audio.playCombo),
    ('button', audio.playButton),
    ('game_over', audio.playGameOver),
    ('high_score', audio.playHighScore),
  ]) {
    debugPrint('BLOCKIVA_AUDIO_EVENT ${event.$1}');
    await event.$2();
    await Future<void>.delayed(const Duration(seconds: 2));
  }
  await audio.setEnabled(false);
  debugPrint('BLOCKIVA_AUDIO_MUTED');
  await audio.playPlacement();
  await audio.playClear();
  await audio.playCombo();
  await Future<void>.delayed(const Duration(seconds: 2));
  await audio.setEnabled(true);
  debugPrint('BLOCKIVA_AUDIO_UNMUTED');
  await audio.playPlacement();
  await Future<void>.delayed(const Duration(seconds: 2));
  await audio.dispose();
  debugPrint(audio.lastError == null
      ? 'BLOCKIVA_AUDIO_DONE' : 'BLOCKIVA_AUDIO_FAILED ${audio.lastError}');
}
