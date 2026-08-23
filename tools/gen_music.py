#!/usr/bin/env python3
"""Original 8-bit overworld loop: bright platformer bounce + martial pentatonic drive.
Not based on Nintendo or Irem melodies."""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "music"
OUT.mkdir(parents=True, exist_ok=True)

SR = 22050
BPM = 142.0
BEAT = 60.0 / BPM
SIXTEENTH = BEAT / 4.0

# C major pentatonic core (martial) with a few diatonic neighbors (bounce)
PITCH = {
    "C2": 65.41, "D2": 73.42, "E2": 82.41, "G2": 98.00, "A2": 110.00, "B2": 123.47,
    "C3": 130.81, "D3": 146.83, "E3": 164.81, "F3": 174.61, "G3": 196.00, "A3": 220.00, "B3": 246.94,
    "C4": 261.63, "D4": 293.66, "E4": 329.63, "F4": 349.23, "G4": 392.00, "A4": 440.00, "B4": 493.88,
    "C5": 523.25, "D5": 587.33, "E5": 659.25, "G5": 783.99, "A5": 880.00,
}


def pulse(n: int, hz: float, duty: float = 0.25) -> np.ndarray:
    t = np.arange(n) / SR
    phase = np.mod(t * hz, 1.0)
    return np.where(phase < duty, 1.0, -1.0).astype(np.float64)


def tri(n: int, hz: float) -> np.ndarray:
    t = np.arange(n) / SR
    phase = np.mod(t * hz, 1.0)
    return (2.0 * np.abs(2.0 * phase - 1.0) - 1.0)


def noise(n: int) -> np.ndarray:
    return np.random.default_rng(1984 + n).uniform(-1.0, 1.0, n)


def env(n: int, attack: float = 0.008, release: float = 0.08) -> np.ndarray:
    a = max(1, int(SR * attack))
    r = max(1, int(SR * release))
    e = np.ones(n, dtype=np.float64)
    a = min(a, n)
    r = min(r, n)
    e[:a] = np.linspace(0.0, 1.0, a)
    if r < n:
        e[-r:] = np.linspace(1.0, 0.0, r)
    else:
        e *= np.linspace(1.0, 0.0, n)
    return e


def place(buf: np.ndarray, start: int, wave: np.ndarray) -> None:
    end = min(len(buf), start + len(wave))
    buf[start:end] += wave[: end - start]


def note(buf: np.ndarray, start_beat: float, length_beats: float, hz: float, vol: float, kind: str) -> None:
    n = int(SR * length_beats * BEAT)
    if n <= 4 or hz <= 0:
        return
    if kind == "lead":
        w = pulse(n, hz, 0.125) * env(n, 0.004, min(0.12, length_beats * BEAT * 0.45))
    elif kind == "harmony":
        w = pulse(n, hz, 0.25) * env(n, 0.006, min(0.14, length_beats * BEAT * 0.5))
    else:
        w = tri(n, hz) * env(n, 0.003, min(0.1, length_beats * BEAT * 0.4))
    place(buf, int(start_beat * BEAT * SR), w * vol)


def drum_kick(n: int) -> np.ndarray:
    t = np.arange(n) / SR
    hz = np.linspace(110, 38, n)
    tone = np.sin(2 * np.pi * np.cumsum(hz) / SR)
    return (tone * 0.7 + noise(n) * 0.15) * np.exp(-t * 18)


def drum_snare(n: int) -> np.ndarray:
    t = np.arange(n) / SR
    return (noise(n) * 0.85 + pulse(n, 180, 0.5) * 0.1) * np.exp(-t * 22)


def drum_hat(n: int) -> np.ndarray:
    t = np.arange(n) / SR
    return noise(n) * np.exp(-t * 55) * 0.35


def parse_phrase(spec: str) -> list[tuple[str, float]]:
    """Tokens like 'E4:2' (eighth=2 sixteenths). '.' is rest of 1 sixteenth. Default length 2."""
    out = []
    for tok in spec.split():
        if tok == ".":
            out.append(("-", 1.0))
            continue
        if ":" in tok:
            name, ln = tok.split(":")
            out.append((name, float(ln)))
        else:
            out.append((tok, 2.0))
    return out


def lay_phrase(buf, start_16: float, spec: str, vol: float, kind: str, transpose_ratio: float = 1.0) -> None:
    t = start_16
    for name, ln in parse_phrase(spec):
        beats = ln * 0.25  # 16th = 0.25 beat
        if name != "-":
            hz = PITCH[name] * transpose_ratio
            note(buf, t * 0.25, beats, hz, vol, kind)
        t += ln


def main() -> None:
    bars = 16
    total_beats = bars * 4
    n = int(SR * total_beats * BEAT) + 1
    lead = np.zeros(n)
    harm = np.zeros(n)
    bass = np.zeros(n)
    drums = np.zeros(n)

    # --- Melody: 4-bar A (bouncy climb) + 4-bar B (martial repeat) x2 ---
    # Lengths in sixteenths. 16 sixteenths = 1 bar.
    A1 = "E4:2 G4:2 A4:4 G4:2 E4:2 D4:4"
    A2 = "C4:2 E4:2 G4:4 E4:2 D4:2 C4:4"
    A3 = "E4:2 G4:2 C5:4 A4:2 G4:2 E4:4"
    A4 = "G4:2 E4:2 D4:4 C4:4 ."
    B1 = "G4:2 G4:2 A4:2 C5:2 D5:4 C5:2 A4:2"
    B2 = "G4:4 E4:2 G4:2 A4:4 G4:4"
    B3 = "E4:2 D4:2 C4:2 E4:2 G4:4 E4:4"
    B4 = "D4:2 E4:2 G4:4 C4:8"

    C1 = "G4:2 A4:2 C5:4 D5:2 C5:2 A4:4"
    C2 = "G4:2 E4:2 G4:4 A4:2 G4:2 E4:4"
    C3 = "C5:2 A4:2 G4:4 E4:2 D4:2 C4:4"
    C4 = "E4:2 G4:2 A4:4 G4:2 E4:2 C4:4"

    phrases = [A1, A2, A3, A4, B1, B2, B3, B4, C1, C2, C3, C4, A1, A2, A3, A4]
    for i, ph in enumerate(phrases):
        lay_phrase(lead, i * 16, ph, 0.22, "lead")
        # Harmony a fifth below, delayed a sixteenth — kung-fu call-and-response
        lay_phrase(harm, i * 16 + 1, ph, 0.09, "harmony", 2 / 3)

    # --- Bass ostinato: martial 8ths with a walking fill every 4th bar ---
    ostinato = ["C3", "G2", "C3", "E3"]  # 8ths
    walk = ["C3", "E3", "F3", "G3", "A3", "G3", "E3", "D3"]
    for bar in range(bars):
        start = bar * 4
        if (bar % 4) == 3:
            for i, nm in enumerate(walk):
                note(bass, start + i * 0.5, 0.48, PITCH[nm], 0.20, "bass")
        else:
            for i in range(8):
                nm = ostinato[i % 4]
                # Bar 8 and 12 drop to G for lift-back
                if bar in (7, 11) and i >= 4:
                    nm = "G2" if i % 2 == 0 else "B2"
                note(bass, start + i * 0.5, 0.46, PITCH[nm], 0.22, "bass")

    # --- Drums: kung-fu drive (8th hats) + platformer backbeat ---
    rng_hat = 0
    for beat in range(total_beats):
        # kick on 1 and 3
        if beat % 2 == 0:
            place(drums, int(beat * BEAT * SR), drum_kick(int(SR * 0.12)))
        # snare on 2 and 4
        if beat % 4 == 2:
            place(drums, int(beat * BEAT * SR), drum_snare(int(SR * 0.10)))
        # 8th hats
        for sub in (0.0, 0.5):
            rng_hat += 1
            place(drums, int((beat + sub) * BEAT * SR), drum_hat(int(SR * 0.04)))
        # extra fill snare on last bar
        if beat >= total_beats - 4 and beat % 1 == 0:
            place(drums, int((beat + 0.5) * BEAT * SR), drum_hat(int(SR * 0.05)) * 1.4)

    mix = lead + harm + bass + drums * 0.55
    # Light master: soft clip + fade edges so the loop doesn't click
    fade = int(SR * 0.01)
    mix[:fade] *= np.linspace(0, 1, fade)
    mix[-fade:] *= np.linspace(1, 0, fade)
    peak = np.max(np.abs(mix)) or 1.0
    mix = np.clip(mix / peak * 0.82, -1.0, 1.0)

    path = OUT / "overworld.wav"
    samples = (mix * 32767).astype(np.int16)
    with wave.open(str(path), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(samples.tobytes())
    print(f"wrote {path.relative_to(ROOT)}  {len(mix)/SR:.2f}s  peak={peak:.2f}")


if __name__ == "__main__":
    main()
