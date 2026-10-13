# Block colour study

The user supplied `base (3).apk` as a colour reference on 13 October 2026.
The study inspected the block sprite metadata and sampled numeric RGB values
from the centre face and four edges of the dark block set. The centre-face
sample is the most frequent opaque colour in the central third of each tile.

Only the colour values below are used in Magic Blocks. No reference textures,
sprites, animation files, fonts, sounds or game code are included. The rounded
bevel geometry, gradients and reward motion are implemented in our Flutter code.

## Ocean palette

Saved colour indices retain the established blue/green/gold/red/purple order.
Orange and cyan append to it, so upgrading an existing session preserves its
board, pieces and statistics. The sample's neutral disabled tile is excluded
from the playable colour pool.

| Index | Colour | Face | Top | Bottom | Left | Right |
| --- | --- | --- | --- | --- | --- | --- |
| 0 | Blue | `#3B5DE2` | `#8EB5FF` | `#21358C` | `#4466F2` | `#284CC4` |
| 1 | Green | `#30B43A` | `#83F19B` | `#0E711D` | `#42C73F` | `#0D882F` |
| 2 | Gold | `#E6AE32` | `#FAE577` | `#AF7216` | `#F8C83B` | `#CB951B` |
| 3 | Red | `#C73032` | `#EF8686` | `#851E25` | `#D94345` | `#AF2825` |
| 4 | Purple | `#8853D3` | `#D597F0` | `#5A2682` | `#A066D8` | `#7039A0` |
| 5 | Orange | `#E56F1F` | `#FFBE81` | `#9C4609` | `#FD8B37` | `#C25E17` |
| 6 | Cyan | `#29B0E0` | `#97E9FE` | `#066EA5` | `#3DC0ED` | `#1992CC` |

The APK also contains vivid and light colour sets. The deeper set is selected
for Ocean because it matches the user's preference for darker blocks. Useful
contrast combinations include blue/gold/purple, green/red/cyan, and
orange/blue/purple. These are design combinations, not a copied piece algorithm.

Midnight and Warm Sand retain their own established palette and add compatible
orange and cyan shades. Each theme uses the same original tile geometry.

## Reward motion

Rewards start 120 ms after placement so the line clear has a short head start.
The title grows from 64% to full size with a small overshoot over 240 ms, then
settles. A fine underline and bounded sparks reinforce a successful streak.
The bonus floats from the cleared cells independently of the title.

Nice lasts 820 ms, Combo 1040 ms, Amazing 1140 ms and higher streaks 1240 ms,
followed by their existing controller completion. Reduced motion uses static
lettering and removes travelling effects. This is a design change, not a
physical-device frame-rate measurement or a Play Store release certification.
