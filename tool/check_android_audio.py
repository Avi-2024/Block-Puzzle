"""Verify real guest audio reached QEMU's WAV backend during Android QA.

The emulator WAV backend omits idle time, so its samples cannot be aligned to
logcat timestamps. Mute cancellation and suppression are covered separately
by game_audio_playback_test.dart.
"""
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

expected = [
    'pickup', 'placement', 'invalid', 'clear', 'combo', 'button',
    'game_over', 'high_score',
]
markers = re.findall(r'BLOCKIVA_AUDIO_(?:EVENT (\w+)|(MUTED|UNMUTED|DONE))', log)
actual = [name or state.lower() for name, state in markers]
if actual != expected + ['muted', 'unmuted', 'done']:
    raise SystemExit(f'Audio smoke did not complete in order: {actual}')

with wave.open(str(root / 'emulator-output.wav')) as wav:
    if wav.getsampwidth() != 2 or wav.getnchannels() not in (1, 2):
        raise SystemExit('Unexpected native emulator PCM format')
    rate, channels = wav.getframerate(), wav.getnchannels()
    samples = array.array('h', wav.readframes(wav.getnframes()))
if sys.byteorder != 'little':
    samples.byteswap()
if not samples:
    raise SystemExit('Emulator produced no native PCM')

peak = max(abs(v) for v in samples) / 32768
rms = math.sqrt(sum(v * v for v in samples) / len(samples)) / 32768
window = max(1, rate // 20 * channels)
levels = [max(abs(v) for v in samples[i:i + window]) / 32768
          for i in range(0, len(samples), window)]
bursts = sum(level > .001 and all(previous <= .001 for previous in levels[max(0, i - 4):i])
             for i, level in enumerate(levels))
results = {
    'events_completed': expected,
    'mute_commands_completed': True,
    'native_wav_seconds': round(len(samples) / channels / rate, 2),
    'peak': round(peak, 5),
    'rms': round(rms, 5),
    'audible_bursts': bursts,
}
if peak < .01 or rms < .0005 or bursts < 9:
    raise SystemExit(f'Native emulator output missing or too weak: {results}')
(root / 'audio-verification.json').write_text(json.dumps(results, indent=2))
print(json.dumps(results, indent=2))
