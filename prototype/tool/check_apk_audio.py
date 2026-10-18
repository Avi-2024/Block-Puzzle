"""Check the shipped assets in the real APK, including the female-only requirement."""
from pathlib import Path
import sys
import zipfile


def check(path):
    prefix = 'assets/flutter_assets/assets/audio/'
    expected = {prefix + 'voice/bright/' + word + '.ogg' for word in
                ('good', 'great', 'combo', 'amazing', 'incredible', 'new-best')}
    with zipfile.ZipFile(path) as apk:
        actual = {name for name in apk.namelist() if name.startswith(prefix + 'voice/')}
        if actual != expected:
            raise ValueError(f'Female voice assets differ: missing {expected - actual}, extra {actual - expected}')
        if any(name.startswith(prefix + 'music/') for name in apk.namelist()):
            raise ValueError('Background music must not be packaged')
        for name in expected:
            if not apk.read(name).startswith(b'OggS'):
                raise ValueError(f'Invalid bundled audio: {name}')
        for effect in ('pickup', 'place', 'invalid', 'clear', 'combo', 'record'):
            name = prefix + 'effects/' + effect + '.wav'
            if not apk.read(name).startswith(b'RIFF'):
                raise ValueError(f'Invalid bundled effect: {name}')
    print(f'{Path(path).name}: six female voice clips and six effects verified; no background music')


if __name__ == '__main__':
    check(sys.argv[1])
