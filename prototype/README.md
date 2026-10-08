# Tilora — original block puzzle prototype

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
and installs as **Tilora Preview** alongside the earlier `com.blockiva.puzzle_prototype`
app. Existing progress in that older app is retained there; it is not migrated
into the separate preview. The Android namespace remains `com.blockiva.puzzle_prototype`.
The working title is Tilora. Settings includes a deterministic animation review
that preserves the current game; Back to game restores it.

## Included

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

CI test-signing keys may differ between builds. If Android reports a signature
conflict with an older preview, do not uninstall it without backing up progress:
uninstalling deletes that app's saved data. A stable release signing key is not
configured by this prototype.

The compatibility APK and recording both select the legacy Flutter renderer
in the manifest. Startup tests use ordinary launcher intents without runtime
renderer overrides. The recording is a visual review, not a device performance benchmark. The
manual `Puzzle Android Recording` workflow can reuse a capture APK by passing
its build run ID while that artifact is retained.

This is a review prototype, not a store release. Sound design, brand/name clearance,
production signing, monetization and physical-device performance testing remain
release work. It makes no FPS, retention or market-performance claim.

See [TILORA_FEATURES.md](TILORA_FEATURES.md) for persistence and migration details.
