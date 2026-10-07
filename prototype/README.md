# Original Block Puzzle prototype

Fresh Flutter implementation of the approved blue gameplay screen and combo
animation direction. This folder is independent from the existing Blockiva app.
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

The Android preview has its own package, `com.blockiva.puzzle_prototype`.
The app title is temporary. Settings includes a deterministic animation review
that preserves the current game; Back to game restores it.

## Included

- Original 8×8 Classic game, three-piece batches, row/column clears and combos.
- Drag with a placement shadow; tap a piece then a board cell also works.
- Nice, Combo ×2, Amazing and Unstoppable effects, board sweeps, particles,
  points and best-score feedback; effects finish instead of running continuously.
- Saved session/best score, haptic preference, system/user reduced motion,
  background interruption handling, reset confirmation and game-over replay.
- Separate pure-Dart rules and Flutter presentation; regression coverage for
  intersecting clears, scoring, storage, touch placement and four screen sizes.

`Fresh Puzzle Prototype` CI checks the code, captures real Flutter screenshots,
builds a playable debug APK and records a separate review APK on Android.

This is a review prototype, not a store release. Sound design, final brand/icon,
production signing, monetization and physical-device performance testing are
outside this first build. It makes no FPS, retention or market-performance claim.
