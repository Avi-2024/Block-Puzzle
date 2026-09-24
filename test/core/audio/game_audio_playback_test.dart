import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:blockiva/core/audio/game_audio_service.dart';
import 'package:blockiva/core/audio/game_sound_player.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Player implements GameSoundPlayer {
  Source? source;
  int plays = 0;
  int stops = 0;
  int disposals = 0;
  Completer<void>? gate;

  @override
  Future<void> prepare(Source source, double volume) async {
    this.source = source;
    expect(volume, inInclusiveRange(0.0, 1.0));
  }

  @override
  Future<void> restart() async {
    plays++;
    await gate?.future;
  }

  @override
  Future<void> stop() async { stops++; }

  @override
  Future<void> dispose() async { disposals++; }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<_Player> players;
  late GameAudioService audio;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    players = <_Player>[];
    audio = GameAudioService(playerFactory: () {
      final _Player player = _Player();
      players.add(player);
      return player;
    });
  });
  tearDown(() => audio.dispose());

  test('preloads file sources supported by Android SoundPool only once', () async {
    await Future.wait(<Future<void>>[audio.initialize(), audio.initialize()]);
    expect(players, hasLength(8));
    for (final _Player player in players) {
      // Regression: BytesSource + lowLatency silently failed on Android.
      expect(player.source, isA<DeviceFileSource>());
      final File file = File((player.source! as DeviceFileSource).path);
      expect(await file.exists(), isTrue);
      final List<int> wav = await file.readAsBytes();
      expect(String.fromCharCodes(wav.take(4)), 'RIFF');
      expect(player.plays, 0);
    }
  });

  test('all feedback events play and reuse their prepared source', () async {
    await audio.initialize();
    await audio.playPickup();
    await audio.playPlacement();
    await audio.playInvalid();
    await audio.playClear();
    await audio.playCombo();
    await audio.playPlacement();
    expect(players.map((p) => p.plays), <int>[1, 2, 1, 1, 1, 0, 0, 0]);
    expect(players, hasLength(8));
    expect(audio.lastError, isNull);
  });

  test('saved mute suppresses the first event before initialization completes', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'settings.sound_enabled': false,
    });
    await audio.playPlacement();
    expect(audio.enabled, isFalse);
    expect(players.every((p) => p.plays == 0), isTrue);
    await audio.toggle();
    await audio.playPlacement();
    expect(players[1].plays, 1);
  });

  test('mute cancels queued plays and stops an in-flight native command', () async {
    await audio.initialize();
    players[1].gate = Completer<void>();
    final Future<void> first = audio.playPlacement();
    await Future<void>.delayed(Duration.zero);
    final Future<void> queued = audio.playPlacement();
    final Future<void> muted = audio.setEnabled(false);
    await Future<void>.delayed(Duration.zero);
    players[1].gate!.complete();
    await Future.wait(<Future<void>>[first, queued, muted]);
    expect(players[1].plays, 1);
    expect(players.every((p) => p.stops == 1), isTrue);
    await audio.playCombo();
    expect(players[4].plays, 0);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('settings.sound_enabled'), isFalse);
  });

  test('background stops sound without persisting mute; resume accepts new events', () async {
    await audio.initialize();
    await audio.playButton();
    await audio.setActive(false);
    await audio.playPlacement();
    expect(players[1].plays, 0);
    expect(players.every((p) => p.stops == 1), isTrue);
    expect(audio.enabled, isTrue);
    await audio.setActive(true);
    await audio.playGameOver();
    await audio.playHighScore();
    expect(players[6].plays, 1);
    expect(players[7].plays, 1);
  });

  test('rapid repeated requests coalesce rather than queue stale sounds', () async {
    await audio.initialize();
    players[1].gate = Completer<void>();
    final requests = List.generate(20, (_) => audio.playPlacement());
    await Future<void>.delayed(Duration.zero);
    expect(players[1].plays, 1);
    players[1].gate!.complete();
    await Future.wait(requests);
    await audio.playPlacement();
    expect(players[1].plays, 2);
  });

  test('dispose cancels queued playback and removes generated WAVs', () async {
    await audio.initialize();
    final List<String> files = players
        .map((p) => (p.source! as DeviceFileSource).path).toList();
    final Future<void> play = audio.playPlacement();
    await audio.dispose();
    await play;
    await audio.playCombo();
    expect(players.every((p) => p.plays == 0 && p.disposals == 1), isTrue);
    for (final String path in files) {
      expect(await File(path).exists(), isFalse);
    }
  });
}
