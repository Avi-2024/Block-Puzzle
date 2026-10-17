#!/usr/bin/env python3
"""Original 88 BPM puzzle underscore. No samples, imported songs or models.

Python 3 + NumPy + SciPy. Deterministic synthesis and a circular room/delay.
Writes a seamless 16-bar, stereo, 48 kHz PCM loop and reproducible mix metrics.
"""
from pathlib import Path
import json
import math
import numpy as np
from scipy import signal
from scipy.io import wavfile

SR = 48000
BPM = 88
BEAT = 60.0 / BPM
BARS = 16
N = round(BARS * 4 * BEAT * SR)
ROOT = Path(__file__).resolve().parent
OUT = ROOT / 'deliverables'
OUT.mkdir(exist_ok=True)
RNG = np.random.default_rng(881610)
TAU = 2 * np.pi
BUS_NAMES = ('marimba', 'warm_pluck', 'bells', 'bass', 'percussion')
buses = {name: np.zeros((N, 2), dtype=np.float64) for name in BUS_NAMES}
events = []


def hz(note):
    return 440.0 * 2 ** ((note - 69) / 12)


def time_axis(duration):
    return np.arange(round(duration * SR), dtype=np.float64) / SR


def taper(y, attack=.003, release=.025):
    y = y.copy()
    a = min(round(attack * SR), len(y) // 2)
    r = min(round(release * SR), len(y) // 2)
    if a:
        y[:a] *= np.sin(np.linspace(0, np.pi / 2, a)) ** 2
    if r:
        y[-r:] *= np.cos(np.linspace(0, np.pi / 2, r)) ** 2
    return y


def marimba(note, length, velocity):
    f = hz(note)
    t = time_axis(max(1.5, length + .8))
    # Soft modal wooden bar, restrained upper modes and mallet transient.
    decay = .42 * (440 / f) ** .23
    modes = ((1, 1, decay), (3.98, .18, .105), (9.95, .018, .044))
    y = np.zeros_like(t)
    for ratio, gain, d in modes:
        if f * ratio < 7000:
            y += gain * np.sin(TAU * f * ratio * t) * np.exp(-t / d)
    # A quiet octave supports phone speakers without making the hit sharp.
    y += .045 * np.sin(TAU * f * 2 * t) * np.exp(-t / .16)
    return taper(y * velocity, .0035, .06)


def warm_pluck(note, length, velocity):
    f = hz(note)
    t = time_axis(length + 1.45)
    y = np.zeros_like(t)
    # Decaying additive triangle-like timbre, with a barely detuned voice.
    for harmonic, amp in ((1, 1), (2, .19), (3, .105), (4, .035), (5, .014)):
        decay = (.68 + length * .16) / (harmonic ** .55)
        ph = TAU * f * harmonic * t
        y += amp * (np.sin(ph) * .76 + np.sin(ph * 1.0015) * .24) * np.exp(-t / decay)
    return taper(y * velocity, .012, .08)


def bell(note, length, velocity):
    f = hz(note)
    t = time_axis(3.0)
    y = (np.sin(TAU * f * t) * np.exp(-t / .63)
         + .115 * np.sin(TAU * f * 2.006 * t) * np.exp(-t / .32)
         + .018 * np.sin(TAU * f * 3.98 * t) * np.exp(-t / .13))
    return taper(y * velocity, .008, .12)


def bass(note, length, velocity):
    f = hz(note)
    t = time_axis(length + .65)
    y = (np.sin(TAU * f * t) + .19 * np.sin(TAU * f * 2 * t)
         + .038 * np.sin(TAU * f * 3 * t))
    env = np.exp(-t / .9) * (1 - np.exp(-t / .015))
    return taper(y * env * velocity, .007, .08)


def percussion(kind, velocity):
    if kind == 'shaker':
        t = time_axis(.12)
        noise = RNG.standard_normal(len(t))
        sos = signal.butter(2, (3300, 7700), btype='bandpass', fs=SR, output='sos')
        y = signal.sosfilt(sos, noise) * np.exp(-t / .025)
        return taper(y * velocity, .007, .02)
    if kind == 'wood':
        t = time_axis(.18)
        y = (.55 * np.sin(TAU * 730 * t) * np.exp(-t / .022)
             + .25 * np.sin(TAU * 1120 * t) * np.exp(-t / .016)
             + .08 * RNG.standard_normal(len(t)) * np.exp(-t / .008))
        return taper(y * velocity, .0014, .02)
    t = time_axis(.28)
    # Tiny warm felt thump rather than a dance kick.
    phase = TAU * (67 * t + 32 * .018 * (1 - np.exp(-t / .018)))
    return taper(np.sin(phase) * np.exp(-t / .065) * velocity, .008, .04)


def put(bus_name, y, beat, pan=0):
    start = round(beat * BEAT * SR) % N
    # Equal-power pan. Slight stereo width, solid mono centre.
    angle = (pan + 1) * np.pi / 4
    frame = y[:, None] * np.array([math.cos(angle), math.sin(angle)])[None, :]
    stop = start + len(frame)
    if stop <= N:
        buses[bus_name][start:stop] += frame
    else:
        first = N - start
        buses[bus_name][start:] += frame[:first]
        buses[bus_name][:len(frame) - first] += frame[first:]


def note(bus_name, midi, beat, length, velocity, pan=0, humanize=True):
    synth = {'marimba': marimba, 'warm_pluck': warm_pluck,
             'bells': bell, 'bass': bass}[bus_name]
    timing = RNG.uniform(-.008, .008) / BEAT if humanize else 0
    vel = velocity * RNG.uniform(.95, 1.04)
    put(bus_name, synth(midi, length * BEAT, vel), beat + timing, pan)
    events.append({'instrument': bus_name, 'midi': midi, 'beat': round(beat + timing, 5),
                   'length_beats': length, 'velocity': round(vel, 5), 'pan': pan})


# D-major home. Two-bar harmonies make the loop gentle and easy to follow.
# Chord tuples: bass MIDI, warm pluck voicing MIDI, short label.
D = (38, (62, 66, 69, 76), 'Dadd9')
BM = (35, (59, 62, 66, 69), 'Bm7')
G = (31, (55, 62, 66, 69), 'Gmaj9')
A = (33, (57, 64, 66, 71), 'A6sus2')
FM = (30, (54, 61, 64, 69), 'F#m7')
chords = (D, D, BM, BM, G, G, A, A, D, FM, BM, A, G, G, A, A)

# Original, sparse call-and-answer motif. Rests are deliberate SFX space.
# Beat within bar, MIDI note, nominal gate in beats.
melody = (
    ((.50, 74, .65), (1.25, 78, .65), (2.50, 81, .75), (3.25, 78, .65)),
    ((.50, 76, .85), (1.50, 74, 1.30)),
    ((.50, 71, .80), (1.50, 74, .70), (2.75, 78, .85)),
    ((.25, 76, .70), (1.25, 74, .80), (2.50, 71, 1.00)),
    ((.50, 74, .75), (1.50, 78, .70), (2.75, 81, .90)),
    ((.50, 83, .80), (1.50, 81, .70), (2.75, 78, 1.00)),
    ((.50, 76, .75), (1.50, 78, .75), (2.75, 81, .85)),
    ((.25, 78, .70), (1.50, 76, .80), (3.00, 73, .75)),
    ((.50, 74, .65), (1.25, 78, .65), (2.50, 81, .65), (3.25, 83, .65)),
    ((.50, 81, .85), (1.50, 76, .75), (2.75, 78, .95)),
    ((.50, 78, .75), (1.50, 74, .70), (2.75, 71, .95)),
    ((.50, 76, .75), (1.50, 83, .70), (2.75, 81, .95)),
    ((.50, 74, .75), (1.50, 78, .70), (2.75, 81, .90)),
    ((.25, 83, .70), (1.25, 81, .70), (2.50, 78, .75), (3.25, 76, .70)),
    ((.50, 76, .75), (1.50, 78, .70), (2.75, 81, .90)),
    ((.25, 78, .70), (1.50, 76, .80), (3.00, 73, .75)),
)

for bar in range(BARS):
    base = bar * 4
    root, voicing, _ = chords[bar]
    # Plucks are lower and quieter than the wooden lead.
    for offset, index, level in ((0, 0, .082), (1, 2, .053), (1.75, 1, .048),
                                  (2.50, 3, .045), (3.50, 2, .042)):
        if bar % 4 == 3 and offset == 3.5:
            continue
        note('warm_pluck', voicing[index], base + offset, .65, level,
             (-.23, .20, -.12, .27)[index])
    # A gentle low chord bloom adds warmth without a pad wash.
    for index in (1, 2):
        note('warm_pluck', voicing[index] - 12, base + .025 * index,
             1.5, .033, (-.27 if index == 1 else .25))
    note('bass', root, base, 1.8, .135, 0, False)
    note('bass', root + (12 if bar % 4 == 2 else 7), base + 2.5, .9, .071, 0)
    for index, (offset, midi, gate) in enumerate(melody[bar]):
        accent = .178 if index == 0 else .157
        note('marimba', midi, base + offset, gate, accent, -.06 + (midi - 74) * .013)
    # Bells appear only as small phrase punctuation, not every beat.
    if bar in (1, 5, 9, 13):
        bnote = {1: 86, 5: 90, 9: 88, 13: 86}[bar]
        note('bells', bnote, base + 3.0, 1.0, .035, .32)
    if bar in (3, 7, 11, 15):
        note('bells', 81 if bar in (3, 11) else 88, base + 3.5, 1, .027, -.32)
    # Light, regular groove: felt thump, wooden taps, low-volume shakers.
    for offset, vel in ((0, .080), (2, .043)):
        put('percussion', percussion('felt', vel), base + offset, 0)
    for offset, vel in ((1, .027), (3, .024)):
        put('percussion', percussion('wood', vel), base + offset + .008, -.15)
    for i in range(8):
        if bar % 4 == 3 and i == 7:
            continue
        beat = base + i * .5 + (.022 if i % 2 else 0)
        put('percussion', percussion('shaker', .011 if i % 2 else .007),
            beat, .28 if i % 2 else -.28)


def circular_filter(x, cutoff, btype, order=2):
    """Warm up filter with one previous loop so no artificial start transient."""
    sos = signal.butter(order, cutoff, btype=btype, fs=SR, output='sos')
    _, state = signal.sosfilt(sos, x, axis=0, zi=np.zeros((len(sos), 2, x.shape[1])))
    return signal.sosfilt(sos, x, axis=0, zi=state)[0]


# Darken the backing, leaving upper-mid space for game notifications.
buses['warm_pluck'] = circular_filter(buses['warm_pluck'], 2800, 'lowpass')
buses['marimba'] = circular_filter(buses['marimba'], 5200, 'lowpass')
buses['bass'] = circular_filter(buses['bass'], 900, 'lowpass')
dry = sum(buses.values())
send = (buses['marimba'] * .22 + buses['warm_pluck'] * .19
        + buses['bells'] * .30 + buses['percussion'] * .08)

# Deterministic small room. Circular convolution folds tails into loop start.
ir_len = round(SR * 1.65)
rt = np.arange(ir_len) / SR
irs = []
for channel in range(2):
    noise = RNG.standard_normal(ir_len)
    sos = signal.butter(2, (280, 3900), btype='bandpass', fs=SR, output='sos')
    room = signal.sosfilt(sos, noise)
    envelope = np.exp(-rt / .235) * (1 - np.exp(-rt / .027))
    room *= envelope
    room[:round(.016 * SR)] = 0
    room = taper(room, .001, .10)
    room /= max(np.sqrt(np.sum(room * room)), 1e-12)
    room *= .46
    for delay, gain in ((.027, .21), (.049, .15), (.081, .10), (.123, .06)):
        room[round((delay + channel * .0023) * SR)] += gain
    irs.append(room)

wet = np.zeros_like(dry)
for channel in range(2):
    src = .86 * send[:, channel] + .14 * send[:, 1 - channel]
    conv = signal.fftconvolve(src, irs[channel])
    wet[:, channel] = conv[:N]
    wet[:len(conv) - N, channel] += conv[N:]

# Very soft eighth-note cross delay links the melody, including across the join.
delay_send = circular_filter(buses['marimba'], 2200, 'lowpass')
delay = (np.roll(delay_send[:, ::-1], round(BEAT * .5 * SR), axis=0) * .065
         + np.roll(delay_send, round(BEAT * 1.0 * SR), axis=0) * .027)
mix = circular_filter(dry + wet + delay, 35, 'highpass')
mix = circular_filter(mix, 11000, 'lowpass')

# Preserve transient dynamics; target a restrained -23 dBFS stereo RMS master.
gain = 10 ** (-23 / 20) / np.sqrt(np.mean(mix * mix))
gain = min(gain, 10 ** (-4 / 20) / np.max(np.abs(mix)))
mix *= gain
assert np.all(np.isfinite(mix)) and np.max(np.abs(mix)) < .9
pcm = np.rint(np.clip(mix, -1, 1) * 32767).astype(np.int16)
wav_path = OUT / 'puzzle-ocean-loop-88bpm.wav'
wavfile.write(wav_path, SR, pcm)

# Short join probe contains 3 seconds before/after the wrap for verification.
join = np.concatenate((pcm[-SR * 3:], pcm[:SR * 3]))
wavfile.write(ROOT / 'loop-boundary-check.wav', SR, join)
metrics = {
    'title': 'Ocean Steps', 'bpm': BPM, 'time_signature': '4/4',
    'key': 'D major', 'bars': BARS, 'sample_rate': SR,
    'samples_per_channel': N, 'duration_seconds': N / SR,
    'peak_dbfs': float(20 * np.log10(np.max(np.abs(mix)))),
    'rms_dbfs': float(20 * np.log10(np.sqrt(np.mean(mix * mix)))),
    'loop_boundary_max_step': float(np.max(np.abs(mix[0] - mix[-1]))),
    'adjacent_step_99th_percentile': float(np.quantile(np.abs(np.diff(mix, axis=0)), .99)),
    'stereo_correlation': float(np.corrcoef(mix.T)[0, 1]),
    'clipped_samples': int(np.sum(np.abs(pcm.astype(np.int32)) >= 32767)),
    'chords': [chord[2] for chord in chords], 'note_events': len(events),
    'source': 'Original score and procedural synthesis; no third-party samples.',
}
(ROOT / 'mix-metrics.json').write_text(json.dumps(metrics, indent=2) + '\n')
(ROOT / 'score-events.json').write_text(json.dumps(events, indent=2) + '\n')
print(json.dumps(metrics, indent=2))
print('Wrote', wav_path)
