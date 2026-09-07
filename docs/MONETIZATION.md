# Monetization Rules

Blockiva is earning-focused, but retention comes before ad density.

## Planned rewarded placements

- **Revive**: one per run after game over.
- **Extra piece / reroll**: later, only when explicitly requested by the player.
- **Double coins**: after eligible rewards or run completion.

Rewarded ads must grant value only after the SDK reward callback fires.

## Planned interstitial policy

Interstitials are not part of the first playable milestone. When enabled, they should appear only at natural breaks and be frequency-capped. Never interrupt an active drag, combo animation, or immediately after a rewarded ad.

## Development safety

- Debug builds can use `DebugRewardAdService` to exercise flows without ad traffic.
- Release builds currently use `NoOpAdService`.
- Real AdMob IDs must never be used for automated/manual repetitive testing.
- Real ad SDK integration will be isolated behind `AdService`.

## Offline behavior

The game engine, score, best score and core session remain playable offline. If ads cannot load, ad-funded rewards simply remain unavailable; normal restart/play is always available.
