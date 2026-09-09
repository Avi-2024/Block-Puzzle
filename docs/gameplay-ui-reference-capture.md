# BLOCKIVA Gameplay UI Reference Capture

Captured before the next widget-level UI polish pass.

## Primary user reference

- Source upload: `WhatsApp Video 2026-09-08 at 10.09.01 PM.mp4`
- Current extracted visual sheets used for review:
  - `blockiva_video_contact.jpg`
  - `blockiva_drag_sequence.jpg`

## Observed reference states

- Header: back/sound action on the left, compact BLOCKIVA title/logo in the center area, restart action on the right.
- Score area: three compact cards for Score, Best, and Combo.
- Board: centered 8x8 grid with light cells, rounded container, and visible placed blocks.
- Tray: three-piece bottom tray with white rounded container and empty placeholders.
- Drag/preview: lifted piece must stay visible above the finger; valid previews should feel stable near edges.
- Invalid preview: red/pink cells communicate blocked placement.
- Restart overlay: centered confirmation card over dimmed gameplay.

## Current repo implementation anchors

- App root shell: `lib/app/blockiva_app.dart`
- Gameplay screen: `lib/features/game/presentation/unified_game_screen.dart`
- Canvas atmosphere shell: `lib/features/game/presentation/game_canvas_v2_shell.dart`
- Drag projection: `lib/features/game/presentation/board_drag_projector.dart`
- Theme tokens: `lib/core/theme/app_theme.dart`
- CI workflow: `.github/workflows/flutter_ci.yml`

## Implementation guardrails

- Keep the game original; do not copy competitor assets, names, icons, or exact layouts.
- Use the user video as the baseline for current UX issues.
- Make small presentation-layer changes first.
- Do not touch engine, scoring, persistence, ads, or daily-challenge logic unless required by a verified bug.
- Every meaningful code change should pass Flutter analyze, tests, Android scaffold, debug APK build, and artifact upload.

## Next polish target

Widget-level presentation polish in `unified_game_screen.dart`:

- `_HudButton`
- `_ScoreDisplay`
- `_Board`
- `_BoardCell`
- `_PieceTray`
- `_PieceView`

Goal: premium casual puzzle feel with stronger readability, depth, board focus, and mobile touch clarity without gameplay-rule changes.
