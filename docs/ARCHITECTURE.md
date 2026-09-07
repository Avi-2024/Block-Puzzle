# Blockiva Architecture

## Design goals

1. Core game rules must not depend on Flutter widgets or ad SDKs.
2. A failed/closed ad must never mutate game state.
3. Game-over and revive behavior must be deterministic and testable.
4. Local-only V1 must remain usable without network access.
5. Future modes should reuse the engine instead of duplicating it.

## Layers

### Domain
`lib/features/game/domain/` owns board state, placement rules, scoring, line clearing, snapshots, piece catalog, and piece generation. The board stores palette indexes rather than `Color`, keeping rendering concerns outside the engine.

### Application
`GameSessionController` coordinates a run: tray lifecycle, best score, game over, persistence, and rewarded revive. Dependencies are injected through interfaces.

### Presentation
Flutter widgets render current state and translate drag/drop gestures into domain actions. Presentation never directly mutates board cells.

### Infrastructure
`lib/core/` contains ad and local-storage adapters. Ad network code is intentionally absent from the domain layer.

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

## Fairness guard

When a fresh tray is generated, Blockiva first identifies shapes that are currently placeable. If at least one exists, one slot is guaranteed to come from that set before the tray is shuffled. This prevents an avoidable instant game-over caused only by unlucky RNG.
