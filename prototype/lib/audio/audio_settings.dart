enum AudioBus { music, effects, voice }

// The approved female voice is the only runtime voice.
enum VoiceStyle { bright }

/// Volume is remembered independently of mute, so unmuting restores the mix.
class AudioSettings {
  const AudioSettings({
    this.music = .30,
    this.effects = .65,
    this.voice = .85,
    this.musicMuted = false,
    this.effectsMuted = false,
    this.voiceMuted = false,
    this.style = VoiceStyle.bright,
  });

  final double music, effects, voice;
  final bool musicMuted, effectsMuted, voiceMuted;
  final VoiceStyle style;

  double volume(AudioBus bus) => switch (bus) {
    AudioBus.music => music,
    AudioBus.effects => effects,
    AudioBus.voice => voice,
  };
  bool muted(AudioBus bus) => switch (bus) {
    AudioBus.music => musicMuted,
    AudioBus.effects => effectsMuted,
    AudioBus.voice => voiceMuted,
  };
  double gain(AudioBus bus) => muted(bus) ? 0 : volume(bus);
  bool get audible => AudioBus.values.any((bus) => gain(bus) > 0);

  AudioSettings change({
    AudioBus? bus,
    double? volume,
    bool? muted,
    VoiceStyle? style,
  }) {
    final level = volume == null || !volume.isFinite
        ? null
        : volume.clamp(0.0, 1.0);
    return AudioSettings(
      music: bus == AudioBus.music ? level ?? music : music,
      effects: bus == AudioBus.effects ? level ?? effects : effects,
      voice: bus == AudioBus.voice ? level ?? voice : voice,
      musicMuted: bus == AudioBus.music ? muted ?? musicMuted : musicMuted,
      effectsMuted: bus == AudioBus.effects
          ? muted ?? effectsMuted
          : effectsMuted,
      voiceMuted: bus == AudioBus.voice ? muted ?? voiceMuted : voiceMuted,
      style: style ?? this.style,
    );
  }

  Map<String, Object> toJson() => {
    'music': music,
    'effects': effects,
    'voice': voice,
    'musicMuted': musicMuted,
    'effectsMuted': effectsMuted,
    'voiceMuted': voiceMuted,
    'style': style.name,
  };

  static AudioSettings decode(Object? value) {
    if (value is! Map) return const AudioSettings();
    double level(String key, double fallback) {
      final v = value[key];
      return v is num && v.isFinite ? v.toDouble().clamp(0.0, 1.0) : fallback;
    }

    return AudioSettings(
      music: level('music', .30),
      effects: level('effects', .65),
      voice: level('voice', .85),
      musicMuted: value['musicMuted'] == true,
      effectsMuted: value['effectsMuted'] == true,
      voiceMuted: value['voiceMuted'] == true,
      // Older Warm selections migrate without changing volume or mute.
      style: VoiceStyle.bright,
    );
  }
}
