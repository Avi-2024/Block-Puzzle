# Blockiva Architecture

## Design goals

1. Core game rules must not depend on Flutter widgets or ad SDKs.
2. A failed/closed ad must never mutate game state.
3. Game-over and revive behavior must be deterministic and testable.
4. Local-only V1 must remain usable without network access.
5. Future modes should reuse the engine instead of duplicating it.
6. The piece shown under the user's finger, board ghost and committed cells must share one coordinate model.
7. Difficulty should come from visible board/tray decisions, not hidden rescue logic.

## Layers

### Domain
`lib/features/game/domain/` owns board state, placement rules, scoring, line clearing, snapshots, piece catalog, and weighted piece generation. The board stores palette indexes rather than `Color`, keeping rendering concerns outside the engine. `MoveResult` exposes exact cleared row/column indexes so presentation can animate the actual clear event without leaking widget concerns into the engine.

### Application
`GameSessionController` coordinates a run: three-piece batch lifecycle, best score, game over, crash-safe session persistence, and rewarded revive. Dependencies are injected through interfaces.

### Presentation
Flutter widgets render current state and translate gestures into domain actions. `BoardDragProjector` converts the global finger position into one snapped board origin. The draggable feedback and placement preview use the same finger-lift geometry, and final placement commits the already-validated preview origin. Presentation never directly mutates board cells.

### Infrastructure
`lib/core/` contains ad, local-storage, theme and audio adapters. `GameAudioService` synthesizes short offline WAV effects and persists the user's mute preference; no remote audio API or paid asset service is required. Ad network code is intentionally absent from the domain layer.

## Three-piece difficulty model

1. A run always exposes a batch of three fixed-orientation pieces.
2. All three slots come from a weighted catalog; the board is not inspected to secretly force a playable piece.
3. Small/forgiving shapes have higher early-run weight.
4. Medium and large shapes unlock progressively using `movesPlayed` thresholds.
5. After all three pieces are consumed, the next visible batch is generated.
6. If none of the remaining visible pieces can be placed, the run legitimately reaches game over.
7. Difficulty tuning should change catalog weights/unlock thresholds, not inject invisible rescue pieces.

## Rewarded revive transaction

1. Detect no legal move among remaining tray pieces.
2. Freeze a deep `GameSnapshot`.
3. Present revive only if the ad service reports readiness.
4. Wait for the rewarded callback.
5. If reward is not granted, state remains untouched.
6. Restore the frozen snapshot.
7. Apply deterministic board relief while preserving score.
8. Reset combo and resume the same run.
9. Limit revive to one per run initially.

## Persistence contract

Active session state stores the 8×8 palette-index board, visible tray, score/combo counters, game-over state and revive usage. The current schema accepts palette indexes `0..6`, preserving older six-color saves while supporting the seventh Blockiva color. Malformed or unsupported state fails closed to a fresh run rather than crashing gameplay.
