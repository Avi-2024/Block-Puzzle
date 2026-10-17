import 'package:flutter/material.dart';

import '../audio/audio_settings.dart';
import '../audio/game_audio.dart';
import 'puzzle_theme.dart';

class SoundSheet extends StatelessWidget {
  const SoundSheet({super.key, required this.audio});
  final GameAudio audio;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: audio,
    builder: (context, _) {
      final p = PuzzleTheme.of(context), settings = audio.settings;
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Sound & voice',
                      style: TextStyle(
                        color: p.ink,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close sound settings',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Text('Your game. Your mix.', style: TextStyle(color: p.muted)),
              const SizedBox(height: 18),
              if (audio.paused || audio.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          audio.error ?? 'Audio paused by your device.',
                          style: TextStyle(color: p.muted),
                        ),
                      ),
                      if (audio.paused)
                        TextButton(
                          onPressed: audio.resume,
                          child: const Text('Resume audio'),
                        ),
                    ],
                  ),
                ),
              for (final bus in AudioBus.values)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.fromLTRB(14, 4, 8, 8),
                  decoration: BoxDecoration(
                    color: p.ink.withValues(alpha: .04),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: p.line.withValues(alpha: .6)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            switch (bus) {
                              AudioBus.music => Icons.music_note_rounded,
                              AudioBus.effects => Icons.auto_awesome_rounded,
                              AudioBus.voice => Icons.record_voice_over_rounded,
                            },
                            size: 20,
                            color: p.accent,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _label(bus),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            key: ValueKey('mute-${bus.name}'),
                            tooltip:
                                '${settings.muted(bus) ? 'Unmute' : 'Mute'} ${bus.name}',
                            isSelected: settings.muted(bus),
                            onPressed: () => audio.update(
                              settings.change(
                                bus: bus,
                                muted: !settings.muted(bus),
                              ),
                            ),
                            icon: Icon(
                              settings.muted(bus)
                                  ? Icons.volume_off_rounded
                                  : Icons.volume_up_rounded,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              key: ValueKey('volume-${bus.name}'),
                              value: settings.volume(bus),
                              divisions: 20,
                              label: '${(settings.volume(bus) * 100).round()}%',
                              semanticFormatterCallback: (value) =>
                                  '${_label(bus)} ${(value * 100).round()} percent',
                              onChanged: (value) => audio.update(
                                audio.settings.change(
                                  bus: bus,
                                  volume: value,
                                  muted: false,
                                ),
                              ),
                              onChangeEnd: (_) {
                                if (bus == AudioBus.effects)
                                  audio.effect(GameEffect.place);
                                if (bus == AudioBus.voice) audio.previewVoice();
                              },
                            ),
                          ),
                          SizedBox(
                            width: 45,
                            child: Text(
                              settings.muted(bus)
                                  ? 'Off'
                                  : '${(settings.volume(bus) * 100).round()}%',
                              style: TextStyle(color: p.muted, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'VOICE STYLE',
                style: TextStyle(
                  color: p.muted,
                  fontSize: 11,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<VoiceStyle>(
                  segments: const [
                    ButtonSegment(
                      value: VoiceStyle.bright,
                      label: Text('Bright'),
                    ),
                    ButtonSegment(value: VoiceStyle.warm, label: Text('Warm')),
                  ],
                  selected: {settings.style},
                  onSelectionChanged: (value) {
                    audio.update(settings.change(style: value.first));
                  },
                ),
              ),
              const SizedBox(height: 14),
              Text(
                settings.gain(AudioBus.voice) == 0
                    ? 'Unmute Voice or raise its volume to preview.'
                    : 'Tap a word to hear it.',
                style: TextStyle(color: p.muted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final word in Callout.values)
                    ActionChip(
                      label: Text(switch (word) {
                        Callout.good => 'Good',
                        Callout.great => 'Great',
                        Callout.combo => 'Combo',
                        Callout.amazing => 'Amazing',
                        Callout.incredible => 'Incredible',
                        Callout.newBest => 'New best',
                      }),
                      onPressed:
                          settings.gain(AudioBus.voice) > 0 && !audio.paused
                          ? () => audio.previewVoice(word)
                          : null,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Music softens during spoken rewards. Haptics stay separate.',
                style: TextStyle(color: p.muted, fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
      );
    },
  );

  String _label(AudioBus bus) => switch (bus) {
    AudioBus.music => 'Music',
    AudioBus.effects => 'Effects',
    AudioBus.voice => 'Voice',
  };
}
