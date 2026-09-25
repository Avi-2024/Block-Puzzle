# Blockiva mobile production audit — 24 September 2026

Baseline: e52d747 (includes reviewed 85af494 and session/ad callback hardening).
Scope: portrait mobile, Android first. No web/desktop product work.

## A. Current state

Keep the pure 8x8 GameEngine, weighted piece catalog, three-slot batches,
GameSessionController, shared drag projector and validated saved-session schema.
Rules evaluate intersecting rows/columns together before clearing. Controller
rejects stale pieces and serializes persistence. Existing tests cover these
contracts; the default branch CI passed before this work.

## B. Production blockers found

- Previous native capture failed; audible Android SFX remains unaccepted.
- Game startup is a spinner; native Android scaffolding is generated in CI.
- No settings sheet or haptic preference; every valid preview change vibrates.
- Game over obscures the final move immediately.
- Progression controls are painted above loading/outcome UI by a parent Stack.
- Audio requests can queue stale sounds; no lifecycle suppression exists.
- No physical-device frame, memory, long-session or release acceptance evidence.

## C. UI work

Branded initialization-only splash, matching native launch mark, integrated HUD,
48 logical-pixel gameplay buttons and minimum piece touch targets, sound/haptics
settings, score count-up, scrollable result card and prominent Play Again.
Keep direct entry into the saved game; no artificial splash delay or extra home tap.
Keep original block artwork and palette. No third-party art or sounds introduced.

## D. Exact audio implementation

There are NO committed WAV/MP3 assets and no assets/audio directory.
- lib/core/audio/game_audio_service.dart: generates mono 22050 Hz PCM WAVs.
- lib/core/audio/sfx_source_io.dart: writes files via Directory.systemTemp.
- lib/core/audio/game_sound_player.dart: audioplayers, Android lowLatency mode,
  game/sonification context, no focus request, preloaded DeviceFileSource,
  stop/resume playback with ReleaseMode.stop.
- lib/core/audio/sfx_source.dart: conditional source adapter export.

Baseline filenames: pickup.wav, placement.wav, invalid.wav, clear.wav, combo.wav.
This pass adds button.wav, game_over.wav, high_score.wav using the same synthesizer.
Runtime location: ${Directory.systemTemp.path}/blockiva-sfx-<generated suffix>/.
The absolute directory cannot be known until the app runs on a device. Files are
removed on service disposal. No music exists, so there is no misleading music toggle.

Sound preference: settings.sound_enabled. Haptic preference: settings.haptics_enabled.
Native playback still needs cold start, mute/unmute, lock/unlock, interruptions,
Bluetooth, repeated games and rapid-event testing on a physical Android phone.

## E. Gameplay feel

Remove preview-cell haptics. Use pickup/place/clear/reward events. Keep board
geometry fixed during input (remove scale pulse). Let the last move settle for
460 ms before showing results while domain game over blocks further placements.
Retain deterministic clear effects and shared preview/commit coordinates.
Existing generous edge snapping and 92 logical-pixel finger lift require device
playtesting before further tuning. Do not alter scoring/generation for UI polish.

## F. Performance risks

Preview rebuilds the gameplay widget subtree; equality deduplicates same-cell
updates. Board has a repaint boundary. Clear effects are finite and event-driven.
Audio sources stay preloaded; coalesce overlapping requests rather than queueing
stale events. Pause cancels sounds without persisting mute, and discards active
drag state. This is code-level hardening, not measured latency/FPS evidence.

## G. Release gates

- Analyzer, full tests, seeded rule verification, Android APK compilation.
- Inspect mobile screenshots at 320x568, 360x640, 393x852 and 412x915.
- Physical touch: fast/slow/edge drag, interruption mid-drag, multi-touch, restart.
- Physical sound/haptics: first sound, all events, persistence, muted device,
  Bluetooth, 20 restarts and background/resume.
- 30-minute medium/low-end device session; profile 60/120 Hz frame timing/memory.
- Safe areas, large text, gesture/three-button navigation and display cutouts.
- Signed release APK/AAB with existing signing identity and release-mode smoke.
- Real ad IDs/consent, offline/ad failure paths and owner Play Console disclosures.

Do not label this production-ready until device and release gates are evidenced.
