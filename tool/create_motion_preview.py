"""Turn CI-captured Flutter frames into an inspectable motion preview."""
from pathlib import Path
from PIL import Image

root = Path('build/mobile-review')
paths = sorted((root / 'motion').glob('*.png'))
if not paths:
    raise SystemExit('Missing captured Flutter motion frames')
frames = [Image.open(path).convert('RGB') for path in paths]
frames[0].save(root / 'placement-preview.gif', save_all=True,
    append_images=frames[1:], duration=[40] * (len(frames) - 1) + [900], loop=0)
for frame in frames:
    frame.close()
