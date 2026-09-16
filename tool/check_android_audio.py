"""Verify native emulator output, including a silent mute window."""
import array
import json
import math
from pathlib import Path
import re
import sys
import wave

root = Path(sys.argv[1])
log = (root / 'audio-smoke-logcat.txt').read_text()
if 'Blockiva audio error:' in log or 'BLOCKIVA_AUDIO_FAILED' in log:
    raise SystemExit('Production audio service reported a playback error')
start = float((root / 'audio-recording-start.txt').read_text())
with wave.open(str(root / 'audio-smoke.wav')) as wav:
    assert wav.getsampwidth() == 2 and wav.getnchannels() == 1
    rate = wav.getframerate()
    samples = array.array('h', wav.readframes(wav.getnframes()))
if sys.byteorder != 'little':
    samples.byteswap()

def level(begin, end):
    values = samples[max(0, int(begin * rate)):max(0, int(end * rate))]
    if not values:
        raise SystemExit(f'Missing audio interval {begin}..{end}')
    peak = max(abs(v) for v in values) / 32768
    rms = math.sqrt(sum(v*v for v in values) / len(values)) / 32768
    return {'peak': round(peak, 5), 'rms': round(rms, 5)}

results = {}
for line in log.splitlines():
    marker = re.search(r'BLOCKIVA_AUDIO_(EVENT (\w+)|MUTED|UNMUTED)', line)
    if not marker:
        continue
    t = float(line.split()[0]) - start
    name = marker[2] or marker[1].lower()
    # Native start is asynchronous; allow a broad audible window. Skip the
    # first 0.4s of mute so the preceding effect's native buffer can drain.
    stats = level(t + .4, t + 1.6) if name == 'muted' else level(t - .35, t + 1.6)
    results[name] = stats
for name in ['pickup', 'placement', 'invalid', 'clear', 'combo', 'unmuted']:
    if name not in results or results[name]['peak'] < .01:
        raise SystemExit(f'Missing/silent native sound {name}: {results}')
if results.get('muted', {}).get('peak', 1) > .003:
    raise SystemExit(f'Mute leaked audio: {results}')
(root / 'audio-verification.json').write_text(json.dumps(results, indent=2))
print(json.dumps(results, indent=2))
