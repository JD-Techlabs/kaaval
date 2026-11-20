"""Synthesises every sound in the game into assets/audio as 16-bit mono WAV.

Everything is generated from maths here (no samples from third parties), so
the output is the project's own work. Re-run with:  python tools/gen_audio.py
"""
import math, os, random, struct, wave

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio")
RATE = 22050
random.seed(7)


def save(name, samples):
    os.makedirs(ROOT, exist_ok=True)
    peak = max(1e-6, max(abs(s) for s in samples))
    scale = min(1.0, 0.9 / peak) * 32767
    with wave.open(os.path.join(ROOT, name + ".wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(s * scale)) for s in samples))


def env(i, n, attack=0.01, release=0.3):
    t, total = i / RATE, n / RATE
    a = min(1.0, t / attack) if attack > 0 else 1.0
    r = min(1.0, (total - t) / release) if release > 0 else 1.0
    return a * r


def tone(freq, dur, vol=1.0, attack=0.005, release=None, harm=((1, 1.0),), slide=0.0):
    n = int(dur * RATE); release = dur * 0.8 if release is None else release
    out, phase = [], 0.0
    for i in range(n):
        f = freq * (1.0 + slide * i / n)
        phase += 2 * math.pi * f / RATE
        s = sum(a * math.sin(phase * h) for h, a in harm)
        out.append(s * vol * env(i, n, attack, release))
    return out


def noise(dur, vol=1.0, lowpass=0.3, release=None):
    n = int(dur * RATE); release = dur * 0.9 if release is None else release
    out, prev = [], 0.0
    for i in range(n):
        prev += lowpass * (random.uniform(-1, 1) - prev)
        out.append(prev * vol * env(i, n, 0.002, release))
    return out


def mix(*tracks):
    n = max(len(t) for t in tracks)
    return [sum(t[i] for t in tracks if i < len(t)) for i in range(n)]


def seq(parts, gap=0.0):
    out = []
    for p in parts:
        out += p + [0.0] * int(gap * RATE)
    return out


def at(track, offset):
    return [0.0] * int(offset * RATE) + track


BELL = ((1, 1.0), (2, 0.4), (3, 0.2), (4.2, 0.1))
save("hit", mix(noise(0.07, 0.9, 0.6), tone(180, 0.07, 0.6, slide=-0.5)))
save("ember", tone(1320, 0.12, 0.8, harm=BELL))
save("hurt", mix(tone(140, 0.22, 1.0, slide=-0.5, harm=((1, 1), (2, 0.5))), noise(0.15, 0.5, 0.2)))
save("levelup", seq([tone(f, 0.11, 0.8, harm=BELL) for f in (523, 659, 784)] + [tone(1047, 0.4, 0.9, harm=BELL)]))
save("click", tone(660, 0.05, 0.7, harm=BELL))
save("chest", mix(seq([tone(f, 0.09, 0.8, harm=BELL) for f in (392, 523, 659, 784, 1047)]), at(noise(0.4, 0.25, 0.8), 0.1)))
save("potion", seq([tone(f, 0.08, 0.8, harm=BELL) for f in (587, 784)] + [tone(1175, 0.3, 0.85, harm=BELL)]))
save("purchase", seq([tone(784, 0.1, 0.8, harm=BELL), tone(1175, 0.35, 0.9, harm=BELL)]))
save("boss", mix(tone(55, 1.6, 1.0, attack=0.05, harm=((1, 1), (2, 0.6), (3, 0.4), (5, 0.2))),
                 at(tone(82, 1.2, 0.7, attack=0.05, harm=((1, 1), (2, 0.5), (3, 0.3))), 0.4),
                 noise(1.6, 0.3, 0.05)))
save("explode", mix(noise(0.35, 1.0, 0.25), tone(90, 0.3, 0.8, slide=-0.6)))
save("drum", mix(tone(70, 0.45, 1.0, slide=-0.4), noise(0.08, 0.5, 0.5)))
save("whoosh", noise(0.18, 0.7, 0.12, release=0.15))
save("defeat", seq([tone(f, 0.32, 0.8, harm=((1, 1), (2, 0.3))) for f in (392, 330, 262, 196)]))


def pad(freqs, dur, vol):
    n = int(dur * RATE)
    out = [0.0] * n
    for f in freqs:
        for detune in (0.997, 1.003):
            ph = random.uniform(0, 6.28)
            for i in range(n):
                t = i / RATE
                out[i] += math.sin(ph + 2 * math.pi * f * detune * t) * vol * math.sin(math.pi * t / dur) ** 2
    return out


def loop(chords, chord_dur, vol):
    """Chords overlap by half so the result loops seamlessly."""
    step = chord_dur / 2
    n = int(len(chords) * step * RATE)
    out = [0.0] * n
    for k, chord in enumerate(chords):
        p = pad(chord, chord_dur, vol)
        start = int(k * step * RATE)
        for i, s in enumerate(p):
            out[(start + i) % n] += s
    return out


A2, C3, D3, E3, G3, A3, B3, C4, D4, E4, G4 = 110, 130.8, 146.8, 164.8, 196, 220, 246.9, 261.6, 293.7, 329.6, 392
night = loop([(A2, E3, A3, C4), (A2, D3, A3, D4), (C3, G3, C4, E4), (A2, E3, B3, E4)], 6.0, 0.2)
crickets = [0.0] * len(night)
for k in range(0, len(night), int(RATE * 1.5)):
    for j in range(5):
        chirp = tone(4200, 0.03, 0.03, harm=((1, 1),))
        for i, s in enumerate(chirp):
            idx = (k + j * int(RATE * 0.06) + i) % len(night)
            crickets[idx] += s
save("music_night", mix(night, crickets))
save("music_dawn", loop([(C3, G3, C4, E4), (D3, A3, D4, G4), (G3, B3, D4, G4), (C3, G3, E4, G4)], 5.0, 0.2))
print("audio written")
