import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:puzzle_prototype/audio/audio_settings.dart';
import 'package:puzzle_prototype/audio/game_audio.dart';
import 'package:puzzle_prototype/game/puzzle.dart';
import 'package:puzzle_prototype/game/puzzle_store.dart';

class FakeAudioOutput extends GameAudioOutput {
  final events = StreamController<AudioSignal>.broadcast(sync: true);
  final words = <(VoiceStyle, Callout)>[];
  final effects = <GameEffect>[];
  final focusCalls = <bool>[];
  Completer<void>? loading, speech;
  Completer<bool>? focusPending;
  bool playing = false, disposed = false, denyFocus = false;
  double musicGain = 0, voiceGain = 0, effectsGain = 0;
  int overlappingVoices = 0;
  @override
  Stream<AudioSignal> get signals => events.stream;
  @override
  Future<void> initialize() async {
    await loading?.future;
  }

  @override
  Future<bool> focus(bool active) async {
    focusCalls.add(active);
    return active && !denyFocus && (await focusPending?.future ?? true);
  }

  @override
  Future<void> music(bool playing, double volume) async {
    this.playing = playing;
    musicGain = volume;
  }

  @override
  Future<void> effect(GameEffect effect, double volume) async {
    effects.add(effect);
    effectsGain = volume;
  }

  @override
  Future<void> speak(VoiceStyle style, Callout callout, double volume) {
    if (speech != null) overlappingVoices++;
    words.add((style, callout));
    voiceGain = volume;
    speech = Completer<void>();
    return speech!.future;
  }

  void completeSpeech() {
    final pending = speech;
    speech = null;
    pending?.complete();
  }

  @override
  Future<void> stopVoice() async => completeSpeech();
  @override
  Future<void> voiceVolume(double value) async {
    voiceGain = value;
  }

  @override
  Future<void> effectsVolume(double value) async {
    effectsGain = value;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    playing = false;
    completeSpeech();
    await events.close();
  }
}

PuzzleState state({int score = 100, int best = 1000, int combo = 0}) =>
    PuzzleState(
      board: List.filled(64, -1),
      tray: const [Piece(0, 0), null, null],
      score: score,
      best: best,
      startingBest: best,
      combo: combo,
    );

PuzzleMove reward({
  int chain = 1,
  int lines = 1,
  int score = 210,
  int best = 1000,
}) => PuzzleMove(
  state: state(score: score, best: best, combo: chain),
  beforeClear: List.filled(64, -1),
  placed: const {0},
  cleared: const {0},
  rows: Set.of(List.generate(lines, (i) => i)),
  columns: const {},
  points: 110,
);

void main() {
  test('older male voice settings migrate to the female voice without losing the mix', () async {
    SharedPreferences.setMockInitialValues({
      PuzzleStore.audioKey: jsonEncode({
        'style': 'warm', 'music': .2, 'effects': .4, 'voice': .6,
        'musicMuted': true, 'voiceMuted': true,
      }),
    });
    final store = PuzzleStore(await SharedPreferences.getInstance());
    expect(VoiceStyle.values, [VoiceStyle.bright]);
    expect(store.audio.style, VoiceStyle.bright);
    expect(store.audio.music, .2);
    expect(store.audio.effects, .4);
    expect(store.audio.voice, .6);
    expect(store.audio.musicMuted, isTrue);
    expect(store.audio.voiceMuted, isTrue);
    await store.setAudio(store.audio);
    expect(jsonDecode(store.preferences.getString(PuzzleStore.audioKey)!)['style'], 'bright');
  });
  test(
    'audio settings survive rapid writes independently of the saved game',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = PuzzleStore(await SharedPreferences.getInstance());
      await store.save(reviewScene());
      final savedGame = store.preferences.getString(PuzzleStore.sessionKey);
      final writes = <Future<void>>[];
      for (var i = 0; i < 20; i++) {
        writes.add(
          store.setAudio(
            AudioSettings(
              music: i / 20,
              voiceMuted: true,
              style: VoiceStyle.bright,
            ),
          ),
        );
      }
      await Future.wait(writes);
      final restored = PuzzleStore(await SharedPreferences.getInstance());
      expect(restored.audio.music, .95);
      expect(restored.audio.effects, .65);
      expect(restored.audio.voiceMuted, isTrue);
      expect(restored.audio.voice, .85);
      expect(restored.audio.style, VoiceStyle.bright);
      expect(store.preferences.getString(PuzzleStore.sessionKey), savedGame);
      expect(
        restored.audio
            .change(bus: AudioBus.voice, muted: false)
            .gain(AudioBus.voice),
        .85,
      );
    },
  );

  test(
    'damaged settings, nonfinite values and older installs use safe defaults',
    () async {
      SharedPreferences.setMockInitialValues({PuzzleStore.audioKey: '{bad'});
      final store = PuzzleStore(await SharedPreferences.getInstance());
      expect(store.audio.music, .30);
      await store.preferences.setString(
        PuzzleStore.audioKey,
        jsonEncode({
          'music': 9,
          'effects': -4,
          'voice': 'loud',
          'style': 'unknown',
          'musicMuted': 'yes',
        }),
      );
      expect(store.audio.music, 1);
      expect(store.audio.effects, 0);
      expect(store.audio.voice, .85);
      expect(store.audio.style, VoiceStyle.bright);
      expect(store.audio.musicMuted, isFalse);
      expect(AudioSettings.decode({'voice': double.nan}).voice, .85);
    },
  );

  testWidgets(
    'reward tiers, one spoken channel and music ducking follow real events',
    (tester) async {
      final output = FakeAudioOutput();
      final game = GameAudio(output: output);
      await game.start(active: true);
      await tester.pump();
      expect(output.playing, isTrue);
      expect(output.musicGain, .30);
      for (final item in [
        (1, 1, Callout.good),
        (1, 2, Callout.great),
        (2, 1, Callout.combo),
        (3, 1, Callout.amazing),
        (4, 1, Callout.incredible),
      ]) {
        game.move(state(), reward(chain: item.$1, lines: item.$2));
        await tester.pump(const Duration(milliseconds: 180));
        expect(output.words.last.$2, item.$3);
        expect(output.musicGain, .15);
        game.move(
          state(),
          reward(chain: 3),
        ); // Rapid clear must not layer voices.
        await tester.pump(const Duration(milliseconds: 180));
        expect(output.words.last.$2, item.$3);
        output.completeSpeech();
        await tester.pump();
        expect(output.musicGain, .30);
        await tester.pump(const Duration(milliseconds: 260));
      }
      expect(output.words.length, 5);
      expect(output.overlappingVoices, 0);
      game.dispose();
      await tester.pump();
    },
  );

  testWidgets(
    'new best interrupts a lower reward only at the round threshold',
    (tester) async {
      final output = FakeAudioOutput();
      final audio = GameAudio(output: output);
      await audio.start(active: true);
      await tester.pump();
      audio.previewVoice(Callout.good);
      await tester.pump(const Duration(milliseconds: 20));
      audio.move(state(score: 950), reward(score: 1060));
      await tester.pump(const Duration(milliseconds: 180));
      expect(output.words.map((word) => word.$2), [
        Callout.good,
        Callout.newBest,
      ]);
      expect(output.effects.last, GameEffect.record);
      expect(output.overlappingVoices, 0);
      output.completeSpeech();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 260));
      // A reloaded round preserves startingBest and must not repeat the record.
      final restored = PuzzleState.decode(state(score: 1060).toJson())!;
      audio.move(restored, reward(score: 1100, lines: 0));
      await tester.pump(const Duration(milliseconds: 200));
      expect(output.words.length, 2);
      audio.dispose();
      await tester.pump();
    },
  );

  testWidgets(
    'mute and background cancel delayed and active female speech',
    (tester) async {
      final output = FakeAudioOutput();
      final audio = GameAudio(output: output);
      await audio.start(active: true);
      await tester.pump();
      audio.move(state(), reward());
      audio.update(audio.settings.change(bus: AudioBus.voice, muted: true));
      await tester.pump(const Duration(milliseconds: 200));
      expect(output.words, isEmpty);
      expect(output.playing, isTrue);
      audio.effect(GameEffect.place);
      await tester.pump();
      expect(output.effects, contains(GameEffect.place));
      audio.update(
        audio.settings.change(
          bus: AudioBus.voice,
          muted: false,
          style: VoiceStyle.bright,
        ),
      );
      audio.previewVoice();
      await tester.pump(const Duration(milliseconds: 20));
      expect(output.words.last.$1, VoiceStyle.bright);
      audio.update(audio.settings.change(bus: AudioBus.music, volume: .6));
      await tester.pump();
      expect(output.musicGain, .3); // Changed level stays ducked during speech.
      audio.setActive(false);
      await tester.pump();
      expect(output.playing, isFalse);
      expect(output.speech, isNull);
      final count = output.words.length;
      audio.previewVoice();
      audio.setActive(true);
      await tester.pump();
      expect(output.words.length, count);
      expect(output.musicGain, .6);
      expect(output.playing, isTrue);
      audio.dispose();
      await tester.pump();
    },
  );

  testWidgets(
    'late startup and focus grants cannot start audio in background',
    (tester) async {
      final output = FakeAudioOutput()..loading = Completer<void>();
      final audio = GameAudio(output: output);
      unawaited(audio.start(active: true));
      audio.setActive(false);
      output.loading!.complete();
      await tester.pump();
      expect(output.playing, isFalse);
      output.focusPending = Completer<bool>();
      audio.setActive(true);
      await tester.pump();
      audio.setActive(false);
      output.focusPending!.complete(true);
      await tester.pump();
      expect(output.playing, isFalse);
      audio.dispose();
      await tester.pump();
      expect(output.disposed, isTrue);
    },
  );

  testWidgets(
    'focus loss, denied focus and hidden routes stay silent until allowed',
    (tester) async {
      final output = FakeAudioOutput();
      final audio = GameAudio(output: output);
      await audio.start(active: true);
      await tester.pump();
      output.events.add(AudioSignal.interrupted);
      await tester.pump();
      expect(output.playing, isFalse);
      expect(output.focusCalls, [
        true,
      ]); // Preserve request for OS resume callback.
      audio.setActive(false);
      output.events.add(AudioSignal.resumed);
      await tester.pump();
      expect(output.playing, isFalse);
      audio.setVisible(false);
      audio.setActive(true);
      await tester.pump();
      expect(output.playing, isFalse);
      output.denyFocus = true;
      audio.setVisible(true);
      await tester.pump();
      expect(audio.paused, isTrue);
      expect(output.playing, isFalse);
      output.denyFocus = false;
      audio.resume();
      await tester.pump();
      expect(output.playing, isTrue);
      audio.dispose();
      await tester.pump();
    },
  );
}
