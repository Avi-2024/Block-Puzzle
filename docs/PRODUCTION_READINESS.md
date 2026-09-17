# Blockiva production readiness — 17 September 2026

## Decision

Not approved for public production yet. Build success is not sound, visual or
frame-rate acceptance. Do not upload the debug review APK as a store release.

## Evidence and market benchmark

The supplied real gameplay recordings and official listings were reviewed:
- Block Blast: https://play.google.com/store/apps/details?id=com.block.juggle
- Blockudoku: https://play.google.com/store/apps/details?id=com.easybrain.block.puzzle.games

Use readable pieces, a quiet board, clear landing previews and event-driven
rewards as the benchmark. Blockiva retains original art and its 8x8 rules;
Blockudoku's 9x9/subgrid rules are not being copied. No hands-on competitor
playtest, retention comparison or market-ranking claim has been made.

85af494 passed analyzer, 52 tests, 2,048 seeded boards / 3,014,656 placement
checks and debug APK compilation. Its native capture was rejected: Android's
Quickstep ANR dialog blocked input and host audio verification failed.
The sound implementation was patched, but audible native playback is still open.

## Production hardening in this pass

- Serialize immutable session snapshots and stats writes; an old move cannot
  complete after and overwrite a restart. Failed writes remain observable via
  lastPersistenceError and do not poison the queue.
- Deduplicate initialization and rewarded revive requests; invalidate late ad
  callbacks after restart/dispose; do not notify disposed controllers.
- Test delayed storage, storage failure recovery, duplicate revive and stale
  ad callbacks using controllable futures.
- Reject screenshots with crash/ANR dialogs or without the app in foreground.
  Stop only the known broken emulator launcher, never suppress app ANRs.
- Reject sample/malformed AdMob IDs in the signed release workflow and verify
  APK/AAB signatures after building. Signing credentials stay in CI secrets.
- Add tool/performance_profile.dart to log bounded 120-frame samples from the
  actual app on a physical Android device; no performance claim until measured.

## Acceptance before launch

| Area | Required evidence | Current status |
| --- | --- | --- |
| Gameplay | Legal placement, crossing clears, drag cancellation, stale-piece protection | Automated coverage exists |
| Session | Rapid moves, background/resume, restart during ad, kill/relaunch restore | Race tests added; device exercise open |
| Visuals | Small/tall phone, active board, clear/combo, game over; no overlapping HUD/overflow | Latest native capture rejected |
| Sound | Pickup/place/invalid/clear/combo, mute/unmute, interruption/resume audible on phone | Open |
| Performance | Physical phone, profile build, sustained drag/clears, p95 build and raster within refresh budget | Unmeasured |
| Stability | 30-minute session, offline mode, ad unavailable/failure, no crashes/ANRs | Open |
| Difficulty | Board-aware generation and fairness/play-length simulations | Not implemented; tuning decision needed |
| Release | Original signing/upload key, release-mode smoke, real ad configuration, increasing versionCode | Workflow exists; credentials/configuration not verified |
| Store | Developer account/access, public privacy URL, data safety, content rating, target audience, listing assets | Owner/account completion required |

## Physical-device performance procedure

Use a connected Android phone, not an emulator:

```sh
flutter run --profile -t tool/performance_profile.dart
```

Play for 10 minutes including rapid drags, board-edge drops and multi-line clears.
Inspect BLOCKIVA_FRAME_SAMPLE logs and Flutter DevTools timeline. Record device,
Android version, refresh rate, build hash, thermal conditions, build/raster p95,
over-budget counts and visible hitches. Target both build and raster p95 below
16.7ms at 60Hz / 8.3ms at 120Hz; idle time is not a representative test.
The counter is a diagnostic, not an end-to-end input-latency measurement.
Reference: https://docs.flutter.dev/perf/ui-performance

## Release and account handoff

Existing .github/workflows/release_indus.yml builds signed APK and AAB. Required
repository secrets: BLOCKIVA_KEYSTORE_BASE64, BLOCKIVA_KEYSTORE_PASSWORD,
BLOCKIVA_KEY_ALIAS, BLOCKIVA_KEY_PASSWORD, ADMOB_ANDROID_APP_ID,
ADMOB_ANDROID_REWARDED_ID. Reuse the existing app signing identity. Never send
private keys or passwords in chat. The existing workflow does not publish stores.

For Google Play: internal testing first, then any required closed testing and
production-access review; finally a staged production rollout after acceptance.
For applicable new personal accounts, Google requires at least 12 testers opted
in continuously for 14 days before applying for production access:
https://support.google.com/googleplay/android-developer/answer/14151465
Confirm account type/creation date in Play Console rather than assume it applies.

Unresolved owner inputs: target store(s), developer-account access/status, existing
application ID/signing identity, production ad setup and public privacy/support URL.
A staged rollout needs crash/ANR and user-feedback monitoring plus a halt/recovery
plan; no live publish was performed in this pass.
