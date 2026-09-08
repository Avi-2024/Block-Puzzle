# Product Roadmap

## M1 — Core loop
- [x] 8×8 board
- [x] three-piece batch
- [x] placement validation
- [x] row/column clear
- [x] score/combo
- [x] game over
- [x] best score persistence
- [x] rewarded-revive architecture
- [x] unit tests + CI

## M2 — Feel and retention
- [x] deterministic finger-to-board drag projection
- [x] visual piece / ghost / committed-cell alignment
- [x] game-first navy board + HUD redesign
- [x] large score + compact best-score hierarchy
- [x] remove permanent combo card; transient combo feedback
- [x] glossy 7-color block treatment
- [x] floating three-piece tray
- [x] exact row/column clear flash metadata
- [x] score/combo pop animation
- [x] placement / clear / revive haptics
- [x] offline synthesized sound manager + persistent mute control
- [x] game-style restart confirmation
- [x] direct app-open → active/new puzzle flow
- [x] portrait-first system chrome
- [x] crash-safe active session resume
- [x] seventh-color persistence migration coverage
- [x] polished game-over / rewarded-revive overlay

## M3 — Difficulty and progression
- [x] 20+ fixed-orientation shape catalog
- [x] weighted easy/medium/hard shape gating by run progress
- [x] natural three-piece batches without forced playable-piece assistance
- [x] offline coin economy + one-time run rewards
- [x] run reward/game-count idempotency across rewarded revive
- [x] daily claim reward with local-day streak logic
- [x] achievement catalog + one-time coin rewards
- [x] unlockable/selectable themes backed by earned coins
- [x] compact rewards HUD + progression bottom sheet
- [ ] deterministic daily challenge seed/mode
- [ ] daily challenge completion reward

## M4 — Monetization
- [x] Google Mobile Ads Flutter SDK test integration
- [x] Google sample rewarded ad wired to debug revive flow
- [x] UMP consent refresh + canRequestAds gate
- [x] privacy-options entry point when required by UMP
- [x] ad loading remains non-blocking; core game stays offline-playable
- [ ] production AdMob App ID + rewarded unit ID
- [ ] production rewarded revive
- [ ] rewarded reroll / double coins
- [ ] controlled interstitial frequency cap
- [ ] production Privacy & Messaging configuration in AdMob account
- [ ] retention + ad funnel analytics

## M5 — Store readiness
- [ ] final icon
- [ ] splash assets
- [ ] screenshots
- [ ] privacy policy URL
- [ ] release signing
- [ ] release AAB/APK smoke test
- [ ] Indus Appstore listing package
