# Blockiva: Block Puzzle

**Place. Clear. Combo.**

Blockiva is an original, offline-first 8×8 block puzzle built with Flutter. The project is designed as a real product rather than a throwaway clone: game rules are isolated from UI, local progression is persistence-ready, rewarded revive is abstracted behind an ad service, and automated tests protect the core board logic.

## Current milestone

- playable 8×8 board
- three-piece tray
- drag/drop placement
- full-piece placement preview
- row + column clearing
- score and combo system
- best-score persistence
- fair tray generation guard
- game-over detection
- one rewarded-revive hook per run
- game-over snapshot recovery
- debug-only fake reward service for safe testing
- production release defaults to no live ads until AdMob is configured

## Stack

- Flutter / Dart
- `shared_preferences` using the async API for local stats
- no backend
- no login
- no paid API for core gameplay

## Run

```bash
flutter pub get
flutter run
```

Recommended development SDK: Flutter 3.47.x or newer compatible stable release.

## Quality checks

```bash
flutter analyze
flutter test
```

GitHub Actions runs both checks on pushes and pull requests.

## Architecture

See `docs/ARCHITECTURE.md` and `docs/MONETIZATION.md`.

## Product direction

Next milestones focus on tactile polish, haptics/audio, daily challenge, coins/themes, analytics events, production AdMob rewarded revive, controlled interstitials, and Indus Appstore release packaging.
