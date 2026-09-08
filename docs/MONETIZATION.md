# Monetization Rules

Blockiva is earning-focused, but retention comes before ad density.

## Rewarded placements

- **Revive**: one per run after game over.
- **Extra piece / reroll**: later, only when explicitly requested by the player.
- **Double coins**: later, after eligible rewards or run completion.

A reward is granted only after the mobile-ads SDK reports that the user earned the reward. Closing, failing to load, or failing to show an ad never mutates the game state.

## Current development integration

Debug Android builds use Google's official sample AdMob App ID and rewarded test unit. They are test ads only and generate no revenue.

Startup remains game-first:

1. The puzzle launches normally.
2. UMP requests current consent information in the background.
3. Any required consent form is shown.
4. `canRequestAds()` is checked.
5. Google Mobile Ads initializes only for the test monetization path.
6. One rewarded ad is preloaded.
7. When the run reaches game over and a rewarded ad is ready, `Watch Ad & Continue` can revive the frozen run.
8. The consumed ad is disposed and the next one is preloaded.

If UMP requires a privacy-options entry point, the debug app exposes one so the user can revisit privacy choices.

## Production safety

- Production/live AdMob IDs are not committed to source.
- Release builds remain ad-disabled until Blockiva's real AdMob App ID and ad-unit IDs are configured.
- Never use production ad units for repetitive development or automated testing.
- Core gameplay must never depend on ad availability or network connectivity.
- Ad load/show failures must always leave restart and normal play available.

## Planned interstitial policy

Interstitials are not enabled yet. When enabled, they will appear only at natural breaks, be frequency-capped, and never interrupt an active drag, clear animation, revive flow, or appear immediately after a rewarded ad.

## Offline behavior

The game engine, score, best score, settings and current run remain playable offline. If ads cannot load, ad-funded rewards remain unavailable and normal restart/play stays available.
