"""Exercise only the isolated Android capture APK; never shares to a recipient."""
from pathlib import Path
import re
import subprocess
import time
import xml.etree.ElementTree as ET

out = Path('build/native-preview')


def adb(*args):
    return subprocess.check_output(['adb', *args], timeout=25)


def nodes():
    adb('shell', 'uiautomator', 'dump', '/sdcard/tilora-feature.xml')
    return list(ET.fromstring(adb('exec-out', 'cat', '/sdcard/tilora-feature.xml')).iter('node'))


def tap(label):
    for attempt in range(3):
        for node in nodes():
            lines = (node.get('text', '') + '\n' + node.get('content-desc', '')).splitlines()
            if label in lines:
                bounds = [int(v) for v in re.findall(r'\d+', node.get('bounds', ''))]
                if len(bounds) == 4 and bounds[3] > bounds[1]:
                    adb('shell', 'input', 'tap', str((bounds[0] + bounds[2]) // 2), str((bounds[1] + bounds[3]) // 2))
                    time.sleep(1)
                    return
        if attempt < 2:
            adb('shell', 'input', 'swipe', '540', '1700', '540', '900', '350')
            time.sleep(.6)
    raise AssertionError(f'Could not find Android control: {label}')


def capture(name, expected):
    current = nodes()
    labels = '\n'.join(n.get('text', '') + '\n' + n.get('content-desc', '') for n in current)
    if expected not in labels:
        raise AssertionError(f'{name}: missing {expected!r}')
    (out / f'{name}.png').write_bytes(adb('exec-out', 'screencap', '-p'))
    (out / f'{name}.xml').write_bytes(adb('exec-out', 'cat', '/sdcard/tilora-feature.xml'))


# Taller portrait capture provides readable, full feature previews.
adb('shell', 'wm', 'size', '1080x2280')
time.sleep(1)
tap('Settings')
tap('Themes')
capture('tilora-themes-android', 'Make it your space.')
tap('Warm Sand')
tap('Use Warm Sand')
capture('tilora-sand-game-android', 'TILORA')
tap('Settings')
tap('How to play')
capture('tilora-guide-android', 'Find the perfect fit.')
tap('Close guide')
tap('Settings')
tap('Preview result screen')
capture('tilora-result-android', 'Beautifully played.')
tap('Share score')
tap('Copy score')
capture('tilora-score-copied-android', 'Score copied')
tap('Share score text')
# Inspect the system chooser without selecting a receiving app or contact.
chooser = nodes()
if not any(n.get('package') in ('android', 'com.android.intentresolver') for n in chooser):
    raise AssertionError('The Android sharing sheet did not open')
(out / 'tilora-share-sheet-android.png').write_bytes(adb('exec-out', 'screencap', '-p'))
adb('shell', 'input', 'keyevent', '4')
time.sleep(.7)
with (out / 'verification.txt').open('a') as report:
    report.write('Tilora: theme applied, tutorial replayed, result opened, actual score copied, Android share sheet opened without sending.\n')
