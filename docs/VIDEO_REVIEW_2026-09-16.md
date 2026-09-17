# Blockiva recording review — 16 September 2026

Reviewed both user-supplied recordings through full-duration sampled timelines,
then half-second sequences around line-clear events. The second recording is
used as the user's gameplay reference; the video alone does not establish its
market ranking or revenue. No reference audio, artwork or branding is reused.

| Area | Blockiva recording (318s) | Reference recording (362s) | Decision |
| --- | --- | --- | --- |
| Audio | Sound icon enabled, but gameplay essentially silent. Decoded PCM is exactly zero in 0–75s and 110–318s. The few loud samples at 84–85s coincide with the test ad. | Frequent recorded feedback during moves and rewards. | P0: repair native playback and capture actual Android audio output. |
| Clear feedback | At 179–180s a yellow row briefly flashes, then disappears. Small reward text stays near score. | At 41–44s a multi-row clear uses a bright line outline, particles and prominent reward animation. | Add a short board-local clear burst and animated score feedback. Larger combo milestone choreography remains pending. |
| Preview | Dragged shape and preview are both close to fully saturated placed blocks. | Ghost silhouette and solid pieces have clearer separation. | Apply preview opacity to the entire tile, not only its gloss. |
| Pieces/grid | Rounded glossy cells and blue outlined empty cells; disconnected jelly-like faces. | Squarer bevels and quieter empty grid. | Pending component design pass; avoid repainting the whole screen with decorative overlays. |
| Layout | Large gaps above and below board on the tall recorded phone; smaller tray pieces. | Compact score/board relationship and calmer background. | Pending adaptive spacing pass after audio acceptance. |
| Progression | Combo label and score increases exist. | Milestone celebration and palette/theme changes throughout the run. | Pending event-driven milestone/combo design; preserve engine scoring. |

## Confirmed sound failure

The app combined `BytesSource` with `PlayerMode.lowLatency`. The pinned plugin's
[Android BytesSource implementation](https://github.com/bluefireteam/audioplayers/blob/audioplayers-v6.8.1/packages/audioplayers_android/android/src/main/kotlin/xyz/luan/audioplayers/source/BytesSource.kt)
explicitly rejects that combination. The app swallowed the resulting exception.
Existing WAV-header tests only validated synthesis, not native playback. Prior
emulator checks used `-noaudio`, so they could not prove audibility.

## This change

- Write original synthesized WAVs to temporary local files and preload them
  once with Android SoundPool. Keep decoded sources across replay commands.
- Configure game/sonification audio without taking persistent audio focus.
- Add pickup and invalid-drop cues alongside placement, clear and combo.
- Make mute cancel queued commands and stop active effects; dispose native
  players before deleting source files. Log playback failures instead of
  silently swallowing them.
- Add source compatibility, event routing, persisted mute, in-flight mute and
  disposal regressions. Retain existing rule and drag tests.
- Add an isolated QA entrypoint that invokes the production audio service,
  records actual emulator output, and checks five sounds plus mute/unmute.
- Replace opaque clear flash with a 420ms board-clipped burst; distinguish
  valid preview from committed blocks and animate the reward label.

## Acceptance still to verify

CI analyze/tests/build, captured Android output, and real gameplay video must
pass on the resulting commit. A passing WAV synthesis test is insufficient.
No claim of final visual parity, market performance, real-device latency or
60 FPS is made by this change.


## Market-reference implementation, 2026-09-17

Reviewed the supplied recordings plus official listings:
- https://play.google.com/store/apps/details?id=com.block.juggle
- https://play.google.com/store/apps/details?id=com.easybrain.block.puzzle.games

This is video/listing research, not a hands-on competitor playtest. Keep Blockiva's
8x8 rules and original assets; use the reference's readability and feedback hierarchy.

Implemented shared square beveled tiles for the board, tray and lifted piece;
quiet blue board cells without neon outlines; board and tray centered as a group
with a 16px gap; read-only row/column prediction highlighted before release.
Prediction tests compare a crossing clear against the engine and verify no score,
combo, move count or board mutation during hover.

Native sound code builds and its routing tests pass in the previous audio fix.
Audible Android output remains unverified: hosted emulator PulseAudio initialization
failed, and its first gameplay capture was obscured by a launcher ANR dialog.
Do not market those captures as accepted gameplay or claim device audio verified.
