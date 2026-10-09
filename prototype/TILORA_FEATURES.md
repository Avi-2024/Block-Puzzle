# Tilora prototype — approved feature pass

## 0.2.1 startup compatibility correction

## 0.2.2 gameplay polish

The approved existing UI now keeps the board closer to the score, uses a lighter
board frame, and sizes tray pieces to their real shape so small pieces remain
legible. Responsive layout and touch-placement tests pass at 320, 360, 393 and
412 logical-pixel widths. The universal APK is verified on Android API 29 and
35; the separate visual-recording runner hit an emulator raster-thread native
crash and does not affect the playable APK checks.

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

The 0.2.1 compatibility build in [CI run 37809406932](https://github.com/Avi-2024/Block-Puzzle/actions/runs/37809406932) passed analysis, all 26 tests, complete ARM32/ARM64/x86-64 runtime checks and the separate Android animation preview. The exact downloadable APK passed ordinary launcher startup, first-play guide, skip to board, theme application, cold relaunch, preference restoration and background resume on the Android 15 emulator. The earlier APK's missing-`libflutter.so` startup crash was reproduced on Android 10.

Replacement APK SHA-256: `452616ae6046e392dc8603ae93be03ff6ec896dadffe1ecd9f6e733c3676f4b8`.

The same downloadable APK also passed every startup check on Android 10 in
[verification run 37811896879](https://github.com/Avi-2024/Block-Puzzle/actions/runs/37811896879).
That run first reproduced the old APK's missing-engine crash, then installed and
launched the replacement while keeping the older package installed. Android
10 and 15 checks used x86-64 emulators; ARM32/ARM64 binaries passed packaging
validation, but the affected physical phone has not yet been tested.

CI formats, analyzes and tests the original Flutter code, captures real widget screenshots at small and standard sizes, builds the universal APK and runs the animation-review APK on Android. The deterministic preview app is a separate entry point; the playable APK does not auto-play or replace saved games with review data.

This is a test-signed prototype APK, not a Play Store release. Store signing, final package identity, trademark/name clearance, device testing and store privacy declarations remain release work.
