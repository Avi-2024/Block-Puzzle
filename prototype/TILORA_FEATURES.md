# Tilora prototype — approved feature pass

## 0.2.1 startup compatibility correction

The earlier ARM64-only build included plugin libraries in ARM32 and x86-64 folders
without the corresponding Flutter engine and app libraries. These extra ABI folders
could allow installation on a processor for which the app could not run. The replacement
build includes complete runtimes for all three ABIs and fails CI if any are missing.

The replacement installs separately as **Tilora Preview** so users do not need to
uninstall an older preview signed by another CI runner. Earlier app data stays in the
earlier package. Renderer selection is now part of the manifest, and the actual
downloadable release APK receives normal-launch smoke tests on Android API 29 and 35.
Device-specific failures still require the affected phone model and crash logs.

All work is isolated to `prototype/` on `codex/fresh-puzzle-prototype`. The root application and main branch are unchanged.

- Original Tilora wordmark and five-tile T icon; no extracted third-party APK code or assets.
- Ocean, Midnight and Warm Sand palettes, including game board, pieces, UI, result screen and system bars. Theme drafts only persist when applied.
- Round-complete screen with actual score, personal best, largest clear streak and number of rows/columns cleared. Native text sharing and clipboard fallback require a user tap.
- Three interactive practice steps: drag, row clear, consecutive-clear combo. Tap-to-place is available too. Completion/skip is remembered, and How to play reopens practice without modifying a saved round.
- New per-round statistics use backward-compatible session fields. Older sessions cannot reconstruct earlier cleared lines or their best-ever combo; counts start from the available data.
- Reduced-motion preference and system accessibility setting are respected. Existing touch, animation-preview and progress persistence behavior is retained.

## Verification

Verified on 2026-10-08 in [CI run 37760856527](https://github.com/Avi-2024/Block-Puzzle/actions/runs/37760856527): analyzer clean, 26 tests passed, ARM64 playable APK built, and Android emulator checks passed for four consecutive clears, theme application, tutorial replay, results, clipboard confirmation and the native sharing sheet. No receiving app or recipient was selected.

CI formats, analyzes and tests the original Flutter code, captures real widget screenshots at small and standard sizes, builds the ARM64 APK and runs the animation-review APK on Android. The deterministic preview app is a separate entry point; the playable APK does not auto-play or replace saved games with review data.

This is a test-signed prototype APK, not a Play Store release. Store signing, final package identity, trademark/name clearance, device testing and store privacy declarations remain release work.
