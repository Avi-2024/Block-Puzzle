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
        for name in expected | {prefix + 'music/ocean-steps.ogg'}:
            if not apk.read(name).startswith(b'OggS'):
                raise ValueError(f'Invalid bundled audio: {name}')
        for effect in ('pickup', 'place', 'invalid', 'clear', 'combo', 'record'):
            name = prefix + 'effects/' + effect + '.wav'
            if not apk.read(name).startswith(b'RIFF'):
                raise ValueError(f'Invalid bundled effect: {name}')
    print(f'{Path(path).name}: six female voice clips, music and six effects verified')


if __name__ == '__main__':
    check(sys.argv[1])
