# Magic Blocks audio

All runtime audio is bundled for offline use. No audio was taken from a reference APK.

- `music/ocean-steps.ogg`: original procedural composition, 88 BPM, D major,
  16 bars / 43.636 seconds. Marimba, plucked synth, bells and light percussion.
  Source: `tool/compose_puzzle_loop.py`; measured mix in `music/mix-metrics.json`.
  Loop the complete file, without adding a fade at each repeat.
- `effects/*.wav`: original synthesized pickup, placement, invalid placement,
  clear, combo and record cues. Regenerate with `python3 tool/compose_game_effects.py`.
  Mono PCM16, 24 kHz, no borrowed samples.
- `voice/bright/*.ogg`: newly generated English stock synthetic female voice.
  Bright uses Kokoro `af_heart`. The six approved phrases are:
  Good, Great, Combo, Amazing, Incredible, New best.
  This is a stock AI voice, not an exclusive human actor recording or a clone of
  the reference game's speaker. `voice/manifest.json` records generation settings,
  original WAV hashes, durations and peaks.

Voice generation used Kokoro v1.0 (Apache-2.0 model) with kokoro-onnx 0.6.1
(MIT wrapper). Only generated audio is shipped; model weights and inference
software are not bundled in the APK.

Model: https://huggingface.co/hexgrad/Kokoro-82M
Wrapper: https://github.com/thewh1teagle/kokoro-onnx
Model SHA-256: `beb0d1848dee9a49da392cc3df26958d46cfa35d321edf434f52949153f0df3a`
Voices SHA-256: `bca610b8308e8d99f32e6fe4197e7ec01679264efed0cac9140fe9c29f1fbf7d`

Default mix: Music 30%, Effects 65%, Voice 85%, Bright female voice. No male recordings are packaged. Older Warm preferences
migrate to Bright while retaining volumes and mute settings. Mute is independent
of each saved slider level. Speech ducks music by 6 dB (80 ms down / 200 ms up).
Speech begins 160 ms after a clear, allowing the clear sound to lead. Ordinary
rewards do not interrupt an active word; a record has priority. A record is only
announced when crossing the persisted round's starting best (greater than zero).

The game owns one Android audio-focus session and uses USAGE_GAME. Backgrounding,
focus loss and disconnected headphones stop effects and speech. Music pauses
without losing its loop position. A temporary interruption can resume music;
a permanent interruption or headphone disconnect requires **Resume audio** in
Sound & voice. No microphone, storage or background-audio permission is needed.
