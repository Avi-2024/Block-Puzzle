# Blockiva reference redesign

The rejected PR #3 is reverted and closed. This replacement starts at main
6c40c1e. Reference: Hungry Studio official Google Play screenshots at
https://play.google.com/store/apps/details?id=com.block.juggle

Original implementation uses reference-inspired colours, not claimed official
Block Blast tokens: stage #3546BC / #2D4FC6 / #253FA7, board #192957,
empty cell #283D79, white score. Pieces: #416DFF, #19CAE8, #35D34B,
#FFD12E, #FF872F, #F34848, #AD57EE.

Full-width 58px score; unobstructed floating pieces; secondary progression
controls below the tray. Sharper 18% facets and 160ms placement pop;
340ms line dissolve; 560ms clear/combo payoff; reduced-motion settings honored.
These are our own tuning values. No game rules, scoring, save data, shape
selection, or audio assets are replaced. Required privacy control moves to the
free central area of the lower toolbar so it does not crowd restart.

Visual and animation review must use actual Flutter captures. No claim of
production sound reliability: the previous emulator recording backend failed.

## Gameplay screen refinement

Gameplay is reviewed independently before extending its design to other screens.
Compact score and personal-best row, larger usable board on short phones,
12px board corners, subtle depth, and 14px secondary-control corners replace
the oversized centered score and circular footer. Stage is now #344DB2 /
#2C47AD / #243C96. Actual Flutter capture and four-size layout checks required.
