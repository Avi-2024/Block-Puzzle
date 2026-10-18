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
  final words = <(VoiceStyle, RewardKind)>[];
  final effects = <GameEffect>[];
  final focusCalls = <bool>[];
  Completer<void>? loading, speech;
  Completer<bool>? focusPending;
  bool disposed = false, denyFocus = false;
  double voiceGain = 0, effectsGain = 0;
  int overlappingVoices = 0;
  @override
  Stream<AudioSignal> get signals => events.stream;
  @override
  Future<void> initialize() async { await loading?.future; }
  @override
  Future<bool> focus(bool active) async {
    focusCalls.add(active);
    return active && !denyFocus && (await focusPending?.future ?? true);
  }
  @override
  Future<void> effect(GameEffect effect, double volume) async {
    effects.add(effect);
    effectsGain = volume;
  }
  @override
  Future<void> speak(VoiceStyle style, RewardKind callout, double volume) {
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
  Future<void> voiceVolume(double value) async { voiceGain = value; }
  @override
  Future<void> effectsVolume(double value) async { effectsGain = value; }
  @override
  Future<void> dispose() async {
    disposed = true;
    completeSpeech();
    await events.close();
  }
}

PuzzleState state({int score = 100, int best = 1000, int combo = 0}) => PuzzleState(
  board: List.filled(64, -1), tray: const [Piece(0, 0), null, null],
  score: score, best: best, startingBest: best, combo: combo,
);
PuzzleMove reward({int chain = 1, int lines = 1, int score = 210, int best = 1000}) => PuzzleMove(
  state: state(score: score, best: best, combo: chain),
  beforeClear: List.filled(64, -1), placed: const {0}, cleared: const {0},
  rows: Set.of(List.generate(lines, (i) => i)), columns: const {}, points: 110,
);

void main() {
  test('legacy music is discarded while the female voice and saved mix survive', () async {
    SharedPreferences.setMockInitialValues({PuzzleStore.audioKey: jsonEncode({
      'style': 'warm', 'music': .9, 'musicMuted': false,
      'effects': .4, 'voice': .6, 'effectsMuted': true, 'voiceMuted': true,
    })});
    final store = PuzzleStore(await SharedPreferences.getInstance());
    expect(AudioBus.values, [AudioBus.effects, AudioBus.voice]);
    expect(VoiceStyle.values, [VoiceStyle.bright]);
    expect(store.audio.style, VoiceStyle.bright);
    expect(store.audio.effects, .4);
    expect(store.audio.voice, .6);
    expect(store.audio.effectsMuted, isTrue);
    expect(store.audio.voiceMuted, isTrue);
    expect(store.audio.audible, isFalse); // Old music cannot keep audio active.
    await store.setAudio(store.audio);
    final saved = jsonDecode(store.preferences.getString(PuzzleStore.audioKey)!);
    expect(saved['style'], 'bright');
    expect(saved.containsKey('music'), isFalse);
    expect(saved.containsKey('musicMuted'), isFalse);
  });

  test('rapid mix writes survive independently of the saved game', () async {
    SharedPreferences.setMockInitialValues({});
    final store = PuzzleStore(await SharedPreferences.getInstance());
    await store.save(reviewScene());
    final savedGame = store.preferences.getString(PuzzleStore.sessionKey);
    await Future.wait(List.generate(20, (i) => store.setAudio(
      AudioSettings(effects: i / 20, voiceMuted: true))));
    final restored = PuzzleStore(await SharedPreferences.getInstance());
    expect(restored.audio.effects, .95);
    expect(restored.audio.voiceMuted, isTrue);
    expect(restored.audio.voice, .85);
    expect(store.preferences.getString(PuzzleStore.sessionKey), savedGame);
    expect(restored.audio.change(bus: AudioBus.voice, muted: false).gain(AudioBus.voice), .85);
  });

  test('damaged settings and nonfinite levels use safe defaults', () async {
    SharedPreferences.setMockInitialValues({PuzzleStore.audioKey: '{bad'});
    final store = PuzzleStore(await SharedPreferences.getInstance());
    expect(store.audio.effects, .65);
    await store.preferences.setString(PuzzleStore.audioKey, jsonEncode({
      'music': 9, 'effects': -4, 'voice': 'loud', 'style': 'unknown',
    }));
    expect(store.audio.effects, 0);
    expect(store.audio.voice, .85);
    expect(store.audio.style, VoiceStyle.bright);
    expect(AudioSettings.decode({'voice': double.nan}).voice, .85);
    expect(AudioSettings.decode({'voice': 9}).voice, 1);
  });

  testWidgets('reward tiers use one spoken channel without overlapping words', (tester) async {
    final output = FakeAudioOutput();
    final audio = GameAudio(output: output);
    await audio.start(active: true);
    await tester.pump();
    for (final item in [(1, 1, RewardKind.good), (1, 2, RewardKind.great),
      (2, 1, RewardKind.combo), (3, 1, RewardKind.amazing), (4, 1, RewardKind.incredible)]) {
      audio.move(state(), reward(chain: item.$1, lines: item.$2));
      await tester.pump(const Duration(milliseconds: 180));
      expect(output.words.last.$2, item.$3);
      audio.move(state(), reward(chain: 3));
      await tester.pump(const Duration(milliseconds: 180));
      expect(output.words.last.$2, item.$3);
      output.completeSpeech();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 260));
    }
    expect(output.words.length, 5);
    expect(output.overlappingVoices, 0);
    audio.dispose();
    await tester.pump();
  });

  testWidgets('new best interrupts a lower reward only once at the round threshold', (tester) async {
    final output = FakeAudioOutput();
    final game = GameAudio(output: output);
    await game.start(active: true);
    await tester.pump();
    game.previewVoice(RewardKind.good);
    await tester.pump(const Duration(milliseconds: 20));
    game.move(state(score: 950), reward(score: 1060));
    await tester.pump(const Duration(milliseconds: 180));
    expect(output.words.map((word) => word.$2), [RewardKind.good, RewardKind.newBest]);
    expect(output.effects.last, GameEffect.record);
    expect(output.overlappingVoices, 0);
    output.completeSpeech();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));
    game.move(PuzzleState.decode(state(score: 1060).toJson())!, reward(score: 1100, lines: 0));
    await tester.pump(const Duration(milliseconds: 200));
    expect(output.words.length, 2);
    game.dispose();
    await tester.pump();
  });

  testWidgets('voice mute and background cancel delayed and active speech', (tester) async {
    final output = FakeAudioOutput();
    final audio = GameAudio(output: output);
    await audio.start(active: true);
    await tester.pump();
    audio.move(state(), reward());
    audio.update(audio.settings.change(bus: AudioBus.voice, muted: true));
    await tester.pump(const Duration(milliseconds: 200));
    expect(output.words, isEmpty);
    audio.effect(GameEffect.place);
    await tester.pump();
    expect(output.effects, [GameEffect.clear, GameEffect.place]);
    audio.update(audio.settings.change(bus: AudioBus.voice, muted: false));
    audio.previewVoice();
    await tester.pump(const Duration(milliseconds: 20));
    audio.update(audio.settings.change(bus: AudioBus.voice, volume: .6));
    await tester.pump();
    expect(output.voiceGain, .6);
    audio.setActive(false);
    await tester.pump();
    expect(output.focusCalls.last, isFalse);
    expect(output.speech, isNull);
    final count = output.words.length;
    audio.previewVoice();
    audio.setActive(true);
    await tester.pump();
    expect(output.words.length, count);
    audio.effect(GameEffect.place);
    await tester.pump();
    expect(output.effects.length, 3);
    audio.dispose();
    await tester.pump();
  });

  testWidgets('late initialization and focus grants cannot play while backgrounded', (tester) async {
    final output = FakeAudioOutput()..loading = Completer<void>();
    final audio = GameAudio(output: output);
    unawaited(audio.start(active: true));
    audio.setActive(false);
    output.loading!.complete();
    await tester.pump();
    audio.previewVoice();
    expect(output.words, isEmpty);
    output.focusPending = Completer<bool>();
    audio.setActive(true);
    await tester.pump();
    audio.setActive(false);
    output.focusPending!.complete(true);
    await tester.pump();
    expect(output.focusCalls.last, isFalse);
    audio.effect(GameEffect.place);
    expect(output.effects, isEmpty);
    audio.dispose();
    await tester.pump();
    expect(output.disposed, isTrue);
  });

  testWidgets('interruptions and hidden routes stay silent until focus is restored', (tester) async {
    final output = FakeAudioOutput();
    final audio = GameAudio(output: output);
    await audio.start(active: true);
    await tester.pump();
    output.events.add(AudioSignal.interrupted);
    await tester.pump();
    audio.effect(GameEffect.place);
    expect(output.effects, isEmpty);
    expect(output.focusCalls, [true]); // Keep request for OS resume callback.
    audio.setActive(false);
    output.events.add(AudioSignal.resumed);
    await tester.pump();
    expect(output.focusCalls.last, isFalse);
    audio.setVisible(false);
    audio.setActive(true);
    await tester.pump();
    audio.previewVoice();
    expect(output.words, isEmpty);
    output.denyFocus = true;
    audio.setVisible(true);
    await tester.pump();
    expect(audio.paused, isTrue);
    output.denyFocus = false;
    audio.resume();
    await tester.pump();
    audio.effect(GameEffect.place);
    await tester.pump();
    expect(output.effects, [GameEffect.place]);
    audio.dispose();
    await tester.pump();
  });
}
