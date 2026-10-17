import 'dart:async';

import 'package:audio_session/audio_session.dart' as session;
import 'package:audioplayers/audioplayers.dart';

import 'audio_settings.dart';
import 'game_audio.dart';

/// One focus owner for the whole game. Individual players must not steal focus
/// from each other when a block effect and an announcement play together.
class NativeAudioOutput extends GameAudioOutput {
  final _signals = StreamController<AudioSignal>.broadcast();
  final _subscriptions = <StreamSubscription<dynamic>>[];
  final _effects = <GameEffect, _PlayerSlot>{};
  _PlayerSlot? _music, _voice;
  session.AudioSession? _session;
  Future<void>? _initializing;
  Completer<void>? _spoken;
  bool _disposed = false;

  @override
  Stream<AudioSignal> get signals => _signals.stream;
  static String voicePath(VoiceStyle style, Callout callout) =>
      'audio/voice/${style.name}/${callout == Callout.newBest ? 'new-best' : callout.name}.ogg';
  static String effectPath(GameEffect effect) =>
      'audio/effects/${effect.name}.wav';
  static const musicPath = 'audio/music/ocean-steps.ogg';

  @override
  Future<void> initialize() => _initializing ??= _initialize();

  Future<void> _initialize() async {
    final context = AudioContext(
      android: const AudioContextAndroid(
        usageType: AndroidUsageType.game,
        audioFocus: AndroidAudioFocus.none,
        stayAwake: false,
      ),
      iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
    );
    await AudioPlayer.global.setAudioContext(context);
    if (_disposed) return;
    _session = await session.AudioSession.instance;
    await _session!.configure(
      const session.AudioSessionConfiguration(
        avAudioSessionCategory: session.AVAudioSessionCategory.ambient,
        avAudioSessionMode: session.AVAudioSessionMode.defaultMode,
        androidAudioAttributes: session.AndroidAudioAttributes(
          contentType: session.AndroidAudioContentType.music,
          usage: session.AndroidAudioUsage.game,
        ),
        androidAudioFocusGainType: session.AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ),
    );
    if (_disposed) return;
    _subscriptions.add(
      _session!.interruptionEventStream.listen((event) {
        if (_disposed) return;
        if (event.begin) {
          _signals.add(AudioSignal.interrupted);
        } else if (event.type != session.AudioInterruptionType.unknown) {
          _signals.add(AudioSignal.resumed);
        }
      }),
    );
    _subscriptions.add(
      _session!.becomingNoisyEventStream.listen((_) {
        if (!_disposed) _signals.add(AudioSignal.interrupted);
      }),
    );
    _music = _PlayerSlot(loop: true);
    _voice = _PlayerSlot();
    for (final effect in GameEffect.values) {
      _effects[effect] = _PlayerSlot(lowLatency: true);
    }
    _subscriptions.add(
      _voice!.player.onPlayerComplete.listen((_) => _finishSpeech()),
    );
    // These small bundled files are available offline. Prewarm SoundPool and
    // cache voice clips before gameplay so a drop never waits for a download.
    await AudioCache.instance.loadAll([
      musicPath,
      for (final style in VoiceStyle.values)
        for (final callout in Callout.values) voicePath(style, callout),
      for (final effect in GameEffect.values) effectPath(effect),
    ]);
    if (_disposed) return;
    await Future.wait([
      _music!.prepare(musicPath, context),
      _voice!.configure(
        context.copy(
          android: context.android.copy(contentType: AndroidContentType.speech),
        ),
      ),
      for (final effect in GameEffect.values)
        _effects[effect]!.prepare(
          effectPath(effect),
          context.copy(
            android: context.android.copy(
              contentType: AndroidContentType.sonification,
            ),
          ),
        ),
    ]);
  }

  @override
  Future<bool> focus(bool active) async {
    if (_disposed || _session == null) return false;
    final granted = await _session!.setActive(active);
    if (_disposed && active) {
      await _session!.setActive(false);
      return false;
    }
    return granted;
  }

  @override
  Future<void> music(bool playing, double volume) async {
    if (_disposed) return;
    await _music?.music(playing, volume);
  }

  @override
  Future<void> effect(GameEffect effect, double volume) async {
    if (_disposed) return;
    await _effects[effect]?.play(effectPath(effect), volume);
  }

  @override
  Future<void> speak(VoiceStyle style, Callout callout, double volume) async {
    if (_disposed || _voice == null) return;
    _finishSpeech();
    final done = _spoken = Completer<void>();
    try {
      await _voice!.play(voicePath(style, callout), volume);
      // All approved clips are under one second. A missing native completion
      // must never leave the music permanently ducked.
      await done.future.timeout(const Duration(seconds: 3));
    } finally {
      if (identical(_spoken, done)) {
        _finishSpeech();
        await _voice?.stop();
      }
    }
  }

  void _finishSpeech() {
    final done = _spoken;
    _spoken = null;
    if (done != null && !done.isCompleted) done.complete();
  }

  @override
  Future<void> voiceVolume(double volume) async => _voice?.gain(volume);
  @override
  Future<void> effectsVolume(double volume) async {
    for (final player in _effects.values) {
      player.gain(volume);
    }
  }

  @override
  Future<void> stopVoice() async {
    _finishSpeech();
    await _voice?.stop();
  }

  @override
  Future<void> stopEffects() async {
    await Future.wait(_effects.values.map((player) => player.stop()));
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _finishSpeech();
    // Invalidate pending native preparation before awaiting anything.
    final stopping = <Future<void>>[
      if (_music != null) _music!.stop(),
      if (_voice != null) _voice!.stop(),
      for (final player in _effects.values) player.stop(),
    ];
    await Future.wait(stopping.map((work) => work.catchError((Object _) {})));
    try {
      await _initializing;
    } catch (_) {
      /* Initialization may have failed. */
    }
    await Future.wait(_subscriptions.map((sub) => sub.cancel()));
    await Future.wait(
      <Future<void>>[
        if (_music != null) _music!.dispose(),
        if (_voice != null) _voice!.dispose(),
        for (final player in _effects.values) player.dispose(),
      ].map((work) => work.catchError((Object _) {})),
    );
    await _session?.setActive(false);
    await _signals.close();
  }
}

/// Serializes a native player and invalidates obsolete async starts. A mute,
/// background event or new clip cannot be undone by an older file decode.
class _PlayerSlot {
  _PlayerSlot({this.loop = false, this.lowLatency = false});
  final bool loop, lowLatency;
  final player = AudioPlayer();
  Future<void> _tail = Future<void>.value();
  int _revision = 0, _gainRevision = 0;
  bool _disposed = false;
  String? _asset;
  double _volume = 0, _appliedVolume = 0;
  Timer? _ramp;

  Future<void> _queue(Future<void> Function() work) {
    final result = _tail.catchError((Object _) {}).then((_) async {
      if (!_disposed) await work();
    });
    // Observe every failure even when a gain ramp does not await the result.
    _tail = result.catchError((Object _) {});
    return result;
  }

  Future<void> configure(AudioContext context) => _queue(() async {
    await player.setAudioContext(context);
    if (lowLatency) await player.setPlayerMode(PlayerMode.lowLatency);
    await player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
    await player.setVolume(0);
  });

  Future<void> prepare(String path, AudioContext context) async {
    await configure(context);
    await _queue(() async {
      await player.setSource(AssetSource(path));
      _asset = path;
    });
  }

  Future<void> play(String path, double volume) {
    final token = ++_revision;
    gain(volume);
    return _queue(() async {
      if (token != _revision) return;
      await player.stop();
      if (token != _revision) return;
      if (_asset != path) {
        await player.setSource(AssetSource(path));
        _asset = path;
      }
      if (token != _revision) return;
      await player.setVolume(_volume);
      if (token != _revision || _volume == 0) return;
      await player.resume();
      if (token != _revision) await player.pause();
    });
  }

  Future<void> music(bool playing, double volume) {
    final token = ++_revision;
    gain(volume, smooth: playing);
    return _queue(() async {
      if (token != _revision) return;
      if (!playing || volume == 0) {
        await player.pause();
      } else if (player.state != PlayerState.playing && _asset != null) {
        await player.setVolume(_volume);
        if (token != _revision) return;
        await player.resume();
        if (token != _revision) await player.pause();
      }
    });
  }

  void gain(double target, {bool smooth = false}) {
    if (_disposed) return;
    _volume = target;
    _ramp?.cancel();
    final token = ++_gainRevision;
    final from = _appliedVolume;
    void apply(double value) {
      unawaited(
        _queue(() async {
          if (token != _gainRevision) return;
          await player.setVolume(value);
          _appliedVolume = value;
        }).catchError((Object _) {}),
      );
    }

    if (!smooth || target == 0 || player.state != PlayerState.playing) {
      apply(target);
      return;
    }
    final steps = target < from ? 4 : 10; // 80 ms duck / 200 ms return.
    var step = 0;
    _ramp = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      step++;
      apply(from + (target - from) * step / steps);
      if (step >= steps) timer.cancel();
    });
  }

  Future<void> stop() {
    _revision++;
    _ramp?.cancel();
    return _queue(player.stop);
  }

  Future<void> dispose() async {
    _revision++;
    _gainRevision++;
    _ramp?.cancel();
    _disposed = true;
    await _tail;
    await player.dispose();
  }
}
