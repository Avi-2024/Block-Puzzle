# Blockiva 1.0.0 — Indus Release Checklist

## Release identity

- App: Blockiva: Block Puzzle
- Package: `com.blockiva.blockiva`
- Version: `1.0.0+4`
- Primary upload for first Indus release: signed `app-release.apk`
- Optional secondary artifact: signed `app-release.aab`

## Account gates

- [ ] Indus developer account email verified
- [ ] Indus developer profile/KYC requirements completed if requested by the console
- [ ] Google AdMob account active
- [ ] Blockiva Android app created/approved in AdMob
- [ ] Production rewarded ad unit created

## GitHub release secrets

Configure these in Repository → Settings → Secrets and variables → Actions:

- `BLOCKIVA_KEYSTORE_BASE64`
- `BLOCKIVA_KEYSTORE_PASSWORD`
- `BLOCKIVA_KEY_ALIAS`
- `BLOCKIVA_KEY_PASSWORD`
- `ADMOB_ANDROID_APP_ID`
- `ADMOB_ANDROID_REWARDED_ID`

The signing values are in the private `blockiva-release-signing-kit.zip`. Never commit them to the public repository.

## Build

Run GitHub Actions → **Indus Release** → Run workflow.

The workflow must pass:

- [ ] Flutter analyze
- [ ] Unit/widget tests
- [ ] Production AdMob App ID validation
- [ ] Production rewarded unit ID validation
- [ ] Release signing
- [ ] Signed APK build
- [ ] Signed AAB build
- [ ] SHA-256 generation

Download artifact: `blockiva-indus-release`.

## Store listing

Use `store/indus/LISTING.md` for approved copy and declarations.

- [ ] App name entered
- [ ] Games → Puzzle category selected
- [ ] Short description entered
- [ ] Long description entered
- [ ] Ads declaration set correctly
- [ ] Data-safety/privacy declarations completed
- [ ] Privacy policy URL entered
- [ ] Support URL entered

## Creative assets

- [ ] 512×512 Blockiva icon uploaded
- [ ] 1024×500 feature graphic uploaded
- [ ] At least two current gameplay screenshots uploaded
- [ ] Screenshots visually match the submitted build

## Functional smoke test before submit

Install the exact signed APK that will be uploaded and verify:

- [ ] App opens directly to Blockiva gameplay
- [ ] 8×8 board renders correctly
- [ ] All three tray pieces drag accurately
- [ ] Placement preview matches committed cells
- [ ] Rows and columns clear correctly
- [ ] Score and best score update
- [ ] Sound toggle works
- [ ] Restart confirmation works
- [ ] Progress/session survives app restart
- [ ] Game-over state appears correctly
- [ ] Rewarded revive appears when a production ad is available
- [ ] Completing/closing a rewarded ad follows correct reward behavior
- [ ] App remains playable when offline (ad-funded actions may be unavailable)

## Submission

- [ ] Upload the signed release APK
- [ ] Review permissions and automated security scan results
- [ ] Check every store preview field
- [ ] Submit for Indus review
- [ ] Do not call the app live until Indus marks the release Published/Live

## Update safety

Keep the same Blockiva signing keystore permanently. Future versions of `com.blockiva.blockiva` must use the same signing identity unless the store provides an approved key-migration process.
