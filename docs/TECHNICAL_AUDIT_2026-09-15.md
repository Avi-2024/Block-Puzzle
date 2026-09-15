# Blockiva technical audit — 15 September 2026

Baseline: `439b963139368eb6313c9367031827df81488de2` on `main`.
The baseline GitHub Flutter CI run 34511324053 passed. That proves the listed
build gates passed; it does not prove visual quality or device performance.

## Scope and architecture

Inspected the repository tree, domain engine/catalog/generators, session
controller and serialization, gameplay widgets and drag projector, application
wiring, progression/daily features, storage, audio/ads adapters, tests and
Android/screenshot workflows. No repository AGENTS.md was present.

Flutter 3.47.2 in CI; Dart >=3.10; Material widgets; local SharedPreferences;
synthesized WAV via audioplayers; Google Mobile Ads rewarded integration.
Android scaffolding is generated during CI rather than committed.

Reusable foundations: independent 8x8 engine, mathematically defined catalog,
deep snapshots, exact row/column clear events, seeded daily batch generation,
three-piece lifecycle, once-per-run settlement and one-revive policy.

Loop: initialize/restore -> present three pieces -> drag projection -> validate
placement -> stamp cells -> discover all complete rows/columns before clearing
-> score/combo -> consume slot -> refill only when all slots are empty ->
check whether ANY remaining piece fits -> persist -> game over/revive/restart.
No gravity is applied.

## Prioritized findings

| Priority | Finding and evidence | Treatment |
| --- | --- | --- |
| P0 | `placePiece` called engine.place before checking tray membership; used/foreign/stale pieces could mutate board and score. | Validate live object ownership before any mutation; regression tests. |
| P0 | Per-slot Draggable limits permitted simultaneous drags while the screen shared one preview. | One active piece across tray; callbacks validate ownership; two-pointer test. |
| P0 | Flutter calls drag-end even on PointerCancel; a system-cancelled gesture could commit the last valid preview. | Track the owning pointer and clear preview before the drag-end callback; cancellation regression test. |
| P0 | Tray fixed at 116 high, pieces used 25px cells: a v5 needs 125px and an h5 can exceed narrow slot width. | Uniform responsive cell size constrained by actual tray shapes and both axes; test 292/332/402px trays. |
| P0 | Feedback size was read while building before board layout, falling back to 38px on the first drag. | Read board measurement when feedback is built; test first-drag geometry. |
| P0 | Smart generator requirements are not implemented: current generator only weights by moves played and does not inspect board, congestion, score or session duration. | Pending configurable board-aware generator plus difficulty/fairness simulations. Preserve separate deterministic daily sequence. |
| P0 | 60 FPS, pause/resume and long-session behavior lack measured Android evidence. | Pending real-device profile; do not infer FPS from unit tests. |
| P1 | Daily route still wrapped in GameCanvasV2Shell, which paints over the gameplay child, despite endless rollback. | Remove daily wrapper; use actual gameplay widgets. |
| P1 | Invalid drag returns instantly; no animated return. Preview opacity applies only to tile gloss, leaving preview fill too close to a committed tile. | Pending presentation work after input correctness. |
| P1 | Every preview cell change rebuilds the game screen; no frame timings or visual regressions recorded. | Extract tray/view for focused verification; full render/profile still required. |
| P1 | Scoring constants are inline; no Combo Fever; game-over lacks run-best combo/new-best celebration. | Pending centralized score policy and designed feedback. |
| P1 | Async revive is not guarded against overlapping requests/disposal; saves fire without serialized ordering. | Pending lifecycle and storage-race tests before release. |
| P2 | Daily uses deterministic batches and local calendar dates, but no defined global-day policy. | Decide/document day boundary before global launch. |
| P2 | Themes hue-filter the entire screen instead of consuming individual theme palettes. Home screen, session-duration stats and independent audio/haptic controls are incomplete. | Pending real component-level theme application and retention UX. |
| P3 | Rewarded adapter exists; interstitial frequency caps, remove-ads purchase and analytics architecture are incomplete. | Defer until P0/P1 acceptance. |

## Quality benchmark

The official [Block Blast Play listing](https://play.google.com/store/apps/details?id=com.block.juggle)
was consulted for its advertised drag/place, row/column clear, combo and offline
loop. This is a genre benchmark, not a measured side-by-side device test.
Acceptance for our presentation: readable board and tray, matching drag/preview
geometry, uncluttered score/actions, event-driven feedback, no decorative layer
obscuring gameplay, and predictable small-screen layout. Original Blockiva
branding/assets remain required. The old mockup and videos are not present in
this checkout; claims of a visual match require newly captured app evidence.

## Verification record

- Standalone Dart oracle: 2,048 seeded boards and 3,014,656 placement checks
  passed, including legal-move detection, simultaneous clears, rejected moves
  and preservation of untouched cells (no gravity).
- Run `dart run tool/verify_game_rules.dart` to repeat that check. This is rule
  correctness coverage, not generator fairness or an FPS benchmark.
- Commit `cd2400c` passed [Flutter CI run 34988544352](https://github.com/Avi-2024/Block-Puzzle/actions/runs/34988544352):
  analyzer clean, 44 tests, the seeded rule oracle, and debug APK build. This
  includes pointer-cancellation protection and responsive normal-piece sizing.
- [Android capture run 34988544446](https://github.com/Avi-2024/Block-Puzzle/actions/runs/34988544446)
  passed on an API 35 emulator. Inspected startup and mid-game 1080x1920 PNGs
  and a 720x1280 small-screen PNG. Two drag placements appeared on the board
  and score advanced from 0 to 30; HUD, board and remaining tray piece fit
  both captured sizes without the former ghost overlay. Captured logcat had
  no FATAL EXCEPTION, E/flutter, RenderFlex overflow or Unhandled Exception.
- Visual issues remain: diagonal seams appear on glossy blocks in emulator
  captures; their cause has not been established. System bars and tray/board
  styling also need the planned component-level design pass. These captures
  validate a basic interaction flow, not final visual acceptance or device FPS.
- Downloaded APK artifact ZIP matched GitHub SHA256
  `e2d901b7d7e37b4800a1f5cd8691b48d811d50191045b6bfea8a2e10bed3de00`
  and passed ZIP integrity validation before extracting the installable APK.
- Local Flutter bootstrap was blocked by automatic approval review when the SDK
  attempted cloud metadata access. Local Flutter processes were stopped; existing
  GitHub Actions runners perform Flutter validation instead.
- Release APK/AAB remains gated on real Android QA and release validation.
