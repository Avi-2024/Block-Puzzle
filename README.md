# Blockiva: Block Puzzle

**Place. Clear. Combo.**

Blockiva is an original, offline-first 8×8 block puzzle built with Flutter. The product uses familiar block-puzzle ergonomics while keeping its own branding, visuals, code, difficulty model and monetization architecture.

## Current milestone

- direct app-open → active/new puzzle flow
- 8×8 high-contrast game board
- visible three-piece batches with fixed orientations
- deterministic finger-to-board drag projection
- visual piece, placement ghost and committed cells share one origin model
- 20+ weighted shapes with progressive difficulty gating
- row + column clearing with exact clear-line metadata
- score system + transient combo feedback
- large score / compact best-score HUD
- glossy seven-color block presentation
- line-clear flash, board pulse and haptic feedback
- offline synthesized placement / clear / combo sounds
- persistent sound mute control
- best-score persistence
- crash-safe active-session restore
- game-over detection
- one rewarded-revive hook per run
- game-over snapshot recovery
- custom game-over / continue overlay
- portrait-first Android game shell
- Google Mobile Ads Flutter SDK integrated for debug testing
- official Google rewarded **test ad** wired to revive
- UMP consent refresh + `canRequestAds()` gate
- privacy-options entry point when UMP requires it
- production release remains ad-disabled until real AdMob IDs are configured

## Stack

- Flutter / Dart
- `shared_preferences` for local stats, settings and active-session state
- `audioplayers` for low-latency playback of locally synthesized SFX
- `google_mobile_ads` for consent-gated test monetization and future production ads
- no backend
- no login
- no paid API for core gameplay

## Run

```bash
flutter pub get
flutter run
```

Recommended development SDK: Flutter 3.47.x or a compatible stable release.

## Quality checks

```bash
flutter analyze
flutter test
```

GitHub Actions additionally generates an Android scaffold, applies Blockiva branding and Google sample test-ad configuration, compiles a debug APK and uploads it as a workflow artifact.

## Architecture

See `docs/ARCHITECTURE.md`, `docs/MONETIZATION.md` and `docs/ROADMAP.md`.

## Product direction

The next product gates are Blockiva's production AdMob credentials, coins/daily retention systems, controlled interstitial policy, final icon/splash assets, privacy policy, release signing and Indus Appstore packaging. Core gameplay remains offline and backend-free.
