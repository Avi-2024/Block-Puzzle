# Blockiva production audit and premium pass

Reviewed baseline: `6c40c1e` (main), newer than brief build `85af494`.

## Current state

The project is Flutter, with a pure Dart domain engine, injected repositories,
controller-managed sessions, and a separate presentation layer. The 8×8 engine
already supports weighted shape unlocks, simultaneous clears, combo scoring,
game-over detection, session restore, daily challenges and progression. Drag
feedback and the placement ghost share `BoardDragProjector`. Sound and haptics
have persisted preferences and lifecycle gating. Existing tests cover domain,
projection, persistence, feedback, and mobile layouts. Launch goes directly to
an active/restored game; there is no home screen to redesign.

## Problems and changes

The score was compressed between two equally wide retention controls. The
central score now receives half the HUD width and uses 48px type, while best
score is explicitly labeled. The small generic launch icon is replaced with an
original painted interlocking mark also used in the header. Native launch art
uses the same arrangement and palette. No image loading or artificial launch
delay is introduced.

The stage now uses deeper navy tones and quieter empty cells. The board frame
has more deliberate padding and corners. Tray slots have subtle wells and an
active pickup state, keeping the existing drag lifecycle and finger offset.
A short rules hint appears before the first move. The play surface is capped
at 480 logical pixels on wide devices so touch targets do not sprawl. Settings
have sound/haptic icons and visible active switch colors. Existing clear,
combo, milestone, score, outcome and session flows remain in place.

Changed components: `AppTheme`, `BlockivaSplash`, new `BlockivaMark`,
`UnifiedGameScreen`, `PieceTray`, `ProgressionActions`, native splash generator,
and mobile layout regression checks.

## Audio: exact implementation and paths

There are **no bundled WAV/MP3 assets** and no `assets/audio/` directory.
`lib/core/audio/game_audio_service.dart` synthesizes 22,050Hz mono 16-bit WAVs.
The eight event names are `pickup`, `placement`, `invalid`, `clear`, `combo`,
`button`, `game_over`, and `high_score`.

On native platforms `lib/core/audio/sfx_source_io.dart` writes actual files at:

`<Directory.systemTemp>/blockiva-sfx-<generated suffix>/<event name>.wav`

Thus filenames are `pickup.wav`, `placement.wav`, `invalid.wav`, `clear.wav`,
`combo.wav`, `button.wav`, `game_over.wav`, and `high_score.wav`. The absolute
path is assigned at runtime and differs by installation/session. Files remain
until service disposal. `lib/core/audio/game_sound_player.dart` prepares native
players, uses Android low-latency mode and resumes preloaded sources after stop.
The service coalesces playback requests and cancels stale commands on mute or
suspension. Web uses `sfx_source_memory.dart`.

No audio replacement was needed for this visual pass. Code inspection and mock
playback tests do not prove audible output on Android. The existing
`tool/audio_smoke.dart` and `tool/check_android_audio.py` are native verification
helpers, not evidence of a test executed in this pass.

## Game feel and performance

Preserve immediate pickup, shared ghost/drop coordinates, completion preview,
420ms clear feedback and animated scores. Further finger-lift or clear timing
changes require device playtesting. Invalid placement remains subtle. Existing
clear and score effects supply reward feedback without a new gameplay delay.

Preview changes rebuild the game screen, including 64 board cells. This is
bounded but should be profiled on a medium Android device. Existing repaint
boundaries isolate the board and effects. Audio initialization prepares eight
native players serially, and the splash waits for feedback readiness; measure
cold-start latency before deciding whether parallel preparation is safe.
`ProgressionBootstrap` applies a whole-screen hue filter for nonclassic themes;
check GPU cost and text contrast. No measured FPS claim is made.

## Release gates

- Flutter analysis, full test suite, seeded rule verifier and mobile captures.
- Actual touch validation: fast/slow drags, edges, cancellations, rapid moves.
- Real Android cold start and audible first sound, restart, mute, background,
  lock/unlock, Bluetooth, repeated games and disposal.
- Portrait/safe-area checks on small, tall and wide screens; large text checks.
- Long sessions and low/medium-device frame timings, memory and startup profile.
- Signed APK/AAB validation with project release credentials; current repository
  generates Android scaffolding in CI rather than checking it in.
- Consent/ad-disabled behavior, production ad identifiers and privacy policy URL.
- Store screenshots, accessibility review and a closed player test measuring
  first-session comprehension, replay rate and daily-challenge participation.

Polish alone cannot establish that the game will trend. Player retention and
store conversion need measured testing. Do not label this production-ready until
these gates have recorded results. No paid services or public store release are
part of this pass.
