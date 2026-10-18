# Magic Blocks — original block puzzle prototype

Fresh Flutter implementation of the approved gameplay, combo animation,
result screen, first-play guidance and three-theme design. This folder is independent from the existing Blockiva app.
No code, images or sounds were taken from the uploaded Block Blast APK.

## Run

Use Flutter 3.47.2 (the same version as this repository's CI).

```sh
cd prototype
flutter pub get
flutter create --platforms=android --org com.blockiva --project-name puzzle_prototype .
python3 tool/brand_android.py
flutter run
```

The compatibility preview has its own package, `com.blockiva.tilora_preview`,
and installs as **Magic Blocks** alongside the earlier `com.blockiva.puzzle_prototype`
app. Existing progress in that older app is retained there; it is not migrated
into the separate preview. The Android namespace remains `com.blockiva.puzzle_prototype`.
The working title is **Magic Blocks: Combo Puzzle**. Settings includes a deterministic animation review
that preserves the current game; Back to game restores it.

## Included

Version 0.2.7 keeps only the approved female voice, migrates older voice preferences
and preserves native preference methods during Android release shrinking.

Version 0.2.6 adds the approved original Ocean Steps music loop, six synthesized
block/clear effects and six spoken rewards in the Bright female voice. Open
Settings → Sound & voice for independent saved Music / Effects / Voice sliders,
channel mute and individual female word previews. Voice is one channel,
record callouts only occur when crossing the round's previous best, and music
ducks during speech. Audio pauses on background/focus loss; headset disconnect
requires an explicit Resume audio. See [audio provenance](assets/audio/README.md).
The existing haptics setting stays independent. Audio preferences use a separate
versioned key; saved game state and score rules retain their format.

Version 0.2.5 adds the user-requested block colour study: seven Ocean face colours
and explicit highlight/side/shadow values sampled from the supplied APK's dark
block palette. Only numeric colour values are used. All tile geometry, shaders,
and effects are our own Flutter code; no reference sprite, font, sound or game
code is bundled. Orange and cyan append to the existing saved colour indices.
Midnight and Warm Sand include matching additional colours within their own
palettes. Board/tray/tutorial/splash tiles share a crisper bevel renderer.
Combo and Amazing now enter faster, use a thinner outline, a sparkling underline
and a separate travelling bonus; six-plus chains have a Magic Streak reward.
See [docs/block-colour-study.md](docs/block-colour-study.md) for palette values.

Version 0.2.4 applies the approved darker Ocean block colors and deeper blue
background to the existing UI, with a subtle board edge for definition.
Board geometry, tray positions and saved theme IDs retain their existing behavior.

Version 0.2.3 adds the approved Magic Blocks identity: a tile-and-sparkle
mark, animated branded launch screen using the gameplay tile renderer and Ocean
palette, and matching Android launcher/native splash. The launcher artwork lives
in `assets/brand/launcher_icon.webp` and is copied by `tool/brand_android.py`.
Version 0.2.2 refines the existing gameplay layout: a bounded gap below the
score, a lighter board frame, and larger tray pieces sized to their actual
shape. Long shapes still fit their slot. Board hit coordinates and scoring
are unchanged; tutorial and theme-preview frames retain their existing style.

- Original 8×8 Classic game, three-piece batches, row/column clears and combos.
- Drag with a placement shadow; tap a piece then a board cell also works.
- Nice, Combo ×2, Amazing and Unstoppable effects, board sweeps, particles,
  points and best-score feedback; effects finish instead of running continuously.
- Saved session/best score, haptic preference, system/user reduced motion,
  background interruption handling, reset confirmation and game-over replay.
- Ocean, Midnight and Warm Sand, with a live preview and saved selection.
- Real round statistics, new-record detection, native text sharing and copying.
- An interactive drag → clear → combo introduction, remembered after completion
  or skip; How to play can be replayed without changing saved progress.
- Separate pure-Dart rules and Flutter presentation; regression coverage for
  intersecting clears, scoring, storage, touch placement and four screen sizes.

`Fresh Puzzle Prototype` CI checks the code, captures real Flutter screenshots,
builds a universal release-mode APK (ARM32, ARM64 and x86-64) with test signing
and records a separate review APK on Android. Every advertised ABI must contain
both `libflutter.so` and `libapp.so`. The exact downloadable APK is also installed
and launched normally on Android API 29 and 35, including first run, cold restart,
preference restoration and background resume.
The manual `Verify Existing Magic Blocks APK` workflow can check a retained playable APK
on Android 10 by its build run ID, without rebuilding it. Its optional legacy run
ID also reproduces the earlier missing-engine crash before testing the replacement.

CI test-signing keys may differ between builds. If Android reports a signature
conflict with an older preview, do not uninstall it without backing up progress:
uninstalling deletes that app's saved data. A stable release signing key is not
configured by this prototype.

The compatibility APK and recording both select the legacy Flutter renderer
in the manifest. Startup tests use ordinary launcher intents without runtime
renderer overrides. The recording is a visual review, not a device performance benchmark. The
manual `Puzzle Android Recording` workflow can reuse a capture APK by passing
its build run ID while that artifact is retained.

This is a review prototype, not a store release. Physical-device audio listening, brand/name clearance,
production signing, monetization and physical-device performance testing remain
release work. It makes no FPS, retention or market-performance claim.

See [TILORA_FEATURES.md](TILORA_FEATURES.md) for persistence and migration details.

