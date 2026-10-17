"""Rebuild original game effects; Python standard library only, no source samples."""
from pathlib import Path
import math
import struct
import wave

RATE = 24000
OUT = Path(__file__).resolve().parents[1] / 'assets/audio/effects'


def tone(duration, start, end=None, gain=.22):
    count = round(duration * RATE)
    phase = 0.0
    result = []
    for i in range(count):
        t = i / max(1, count - 1)
        frequency = start + ((end or start) - start) * t
        phase += 2 * math.pi * frequency / RATE
        envelope = min(1, t / .035) * (1 - t) ** 2
        result.append(gain * envelope * (math.sin(phase) + .15 * math.sin(2 * phase)))
    return result


def chord(notes, spacing=.035, gain=.13, duration=.30):
    result = [0.0] * round((duration + spacing * (len(notes) - 1)) * RATE)
    for index, note in enumerate(notes):
        offset = round(index * spacing * RATE)
        for i, value in enumerate(tone(duration, note, gain=gain)):
            if offset + i < len(result):
                result[offset + i] += value
    return result


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    clips = {
        'pickup': tone(.065, 390, 530, .18),
        'place': tone(.11, 145, 69, .38),
        'invalid': tone(.095, 210, 150, .14),
        'clear': chord([523.25, 659.25, 783.99]),
        'combo': chord([659.25, 783.99, 1046.5], .04, .13, .34),
        'record': chord([783.99, 987.77, 1174.66, 1567.98], .075, .12, .40),
    }
    for name, samples in clips.items():
        assert max(map(abs, samples)) < .6, name
        with wave.open(str(OUT / f'{name}.wav'), 'wb') as audio:
            audio.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
            audio.writeframes(b''.join(struct.pack('<h', round(v * 32767)) for v in samples))
        print(f'{name}: {len(samples) / RATE:.3f}s')


if __name__ == '__main__':
    main()
