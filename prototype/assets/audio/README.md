# Magic Blocks audio

All runtime audio is bundled for offline use. No audio was taken from a reference APK.

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

Default mix: Effects 65%, Voice 85%, Bright female voice. Background music,
its player, its packaged asset and its settings control were removed at the
user's request. Old music preference fields are ignored; effects/voice levels
and mutes are retained. Older Warm selections migrate to Bright. No male
recordings are packaged. Mute is independent of each saved slider level.

Speech begins 160 ms after a clear, allowing the clear sound to lead. Ordinary
rewards do not interrupt an active word; a record has priority. A record is only
announced when crossing the persisted round's starting best (greater than zero).
The written reward and speech share the same reward classification.

The game owns one Android audio-focus session and uses USAGE_GAME. Backgrounding,
focus loss and disconnected headphones stop effects and speech. A temporary
interruption can resume the session; a permanent interruption or headphone
disconnect requires **Resume audio** in Sound & voice. No microphone, storage
or background-audio permission is needed.
