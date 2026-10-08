"""Launch the exact downloadable APK, exercise first run and saved preferences."""
from pathlib import Path
import json
import re
import subprocess
import time
import xml.etree.ElementTree as ET
from check_apk_abis import check

PACKAGE = 'com.blockiva.tilora_preview'
ACTIVITY = 'com.blockiva.puzzle_prototype.MainActivity'
OLD_PACKAGE = 'com.blockiva.puzzle_prototype'
out = Path('build/startup-review')
out.mkdir(parents=True, exist_ok=True)
apk = Path('build/playable/build/review/block-puzzle-prototype.apk')
prior = Path('build/prior/build/review/block-puzzle-prototype.apk')


def adb(*args, timeout=30):
    return subprocess.check_output(['adb', *args], timeout=timeout, stderr=subprocess.STDOUT)


def nodes():
    adb('shell', 'uiautomator', 'dump', '/sdcard/tilora-startup.xml')
    return list(ET.fromstring(adb('exec-out', 'cat', '/sdcard/tilora-startup.xml')).iter('node'))


def labels(current):
    return '\n'.join(n.get('text', '') + '\n' + n.get('content-desc', '') for n in current)


def wait_for(text):
    for attempt in range(8):
        current = nodes()
        if text in labels(current) and any(n.get('package') == PACKAGE for n in current):
            return current
        time.sleep(1)
    raise AssertionError(f'App did not show {text!r} after an ordinary launcher start')


def tap(text):
    for node in wait_for(text):
        if text in (node.get('text', '') + '\n' + node.get('content-desc', '')).splitlines():
            bounds = list(map(int, re.findall(r'\d+', node.get('bounds', ''))))
            if len(bounds) == 4 and bounds[3] > bounds[1]:
                adb('shell', 'input', 'tap', str((bounds[0] + bounds[2]) // 2), str((bounds[1] + bounds[3]) // 2))
                time.sleep(.8)
                return
    raise AssertionError(f'Control not found: {text}')


def capture(name):
    (out / f'{name}.png').write_bytes(adb('exec-out', 'screencap', '-p'))
    (out / f'{name}.xml').write_bytes(adb('exec-out', 'cat', '/sdcard/tilora-startup.xml'))


def launch():
    # No renderer, route, or demo-entrypoint Intent extras.
    adb('shell', 'am', 'start', '-W', '-a', 'android.intent.action.MAIN',
        '-c', 'android.intent.category.LAUNCHER', '-n', f'{PACKAGE}/{ACTIVITY}')


try:
    adb('shell', 'wm', 'size', '1080x2280')
    adb('shell', 'wm', 'density', '420')
    adb('shell', 'am', 'force-stop', 'com.android.launcher3')
    if prior.exists():
        try:
            check(prior)
        except ValueError as error:
            (out / 'prior-abi-defect.txt').write_text(str(error))
        else:
            raise AssertionError('The old APK unexpectedly passed ABI validation')
        adb('install', '-r', str(prior), timeout=60)
        adb('logcat', '-c')
        adb('shell', 'am', 'start', '-W', '-n', f'{OLD_PACKAGE}/.MainActivity')
        time.sleep(4)
        old_log = adb('logcat', '-d').decode(errors='replace')
        (out / 'prior-crash-logcat.txt').write_text(old_log)
        if 'libflutter.so' not in old_log or not any(term in old_log for term in ('UnsatisfiedLinkError', 'MissingLibraryException', 'couldn\'t find')):
            raise AssertionError('Did not reproduce the old APK missing-engine startup failure')
        adb('shell', 'am', 'force-stop', OLD_PACKAGE)
        # Keep the old package installed: verify the replacement coexists safely.

    metadata = check(apk)
    adb('install', '-r', str(apk), timeout=90)
    adb('logcat', '-c')
    launch()
    wait_for('Find the perfect fit.')
    capture('first-launch')
    tap('Skip intro')
    wait_for('Find your next move')
    capture('playable-board')
    tap('Settings')
    tap('Themes')
    tap('Midnight')
    tap('Use Midnight')
    wait_for('Find your next move')
    adb('shell', 'am', 'force-stop', PACKAGE)
    launch()
    current = wait_for('Find your next move')
    if 'Skip intro' in labels(current):
        raise AssertionError('Introduction completion was not restored')
    capture('cold-relaunch')
    tap('Settings')
    wait_for('Midnight')
    capture('persisted-theme')
    tap('Keep playing')
    adb('shell', 'input', 'keyevent', '3')
    time.sleep(1)
    launch()
    wait_for('Find your next move')
    adb('shell', 'pidof', PACKAGE)
    logs = adb('logcat', '-d').decode(errors='replace')
    if any(marker in logs for marker in ('FATAL EXCEPTION', '[ERROR:flutter/runtime', 'Fatal signal')):
        raise AssertionError('Release startup smoke test recorded a runtime failure')
    metadata['checks'] = ['fresh launcher start', 'first-play guide', 'skip to playable board', 'theme apply', 'cold relaunch', 'preference restore', 'background resume']
    metadata['android_api'] = adb('shell', 'getprop', 'ro.build.version.sdk').decode().strip()
    (out / 'verification.json').write_text(json.dumps(metadata, indent=2))
finally:
    (out / 'release-logcat.txt').write_bytes(adb('logcat', '-d'))
    (out / 'last-screen.png').write_bytes(adb('exec-out', 'screencap', '-p'))
