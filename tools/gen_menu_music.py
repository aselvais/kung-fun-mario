#!/usr/bin/env python3
"""Calm 8-bit ambient menu loop. Original, not from Mario or Kung-Fu Master."""
from __future__ import annotations

import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "music"
OUT.mkdir(parents=True, exist_ok=True)

SR = 22050
BPM = 76.0
BEAT = 60.0 / BPM

PITCH = {
    "C3": 130.81, "D3": 146.83, "E3": 164.81, "G3": 196.00, "A3": 220.00,
    "C4": 261.63, "D4": 293.66, "E4": 329.63, "G4": 392.00, "A4": 440.00,
    "C5": 523.25, "D5": 587.33, "E5": 659.25,
}


def pulse(n: int, hz: float, duty: float = 0.5) -> np.ndarray:
    t = np.arange(n) / SR
    return np.where(np.mod(t * hz, 1.0) < duty, 1.0, -1.0).astype(np.float64)


def tri(n: int, hz: float) -> np.ndarray:
    t = np.arange(n) / SR
    phase = np.mod(t * hz, 1.0)
    return 2.0 * np.abs(2.0 * phase - 1.0) - 1.0


def env(n: int, attack: float, release: float) -> np.ndarray:
    a = max(1, int(SR * attack))
    r = max(1, int(SR * release))
    e = np.ones(n, dtype=np.float64)
    a = min(a, n)
    r = min(r, n)
    e[:a] = np.linspace(0.0, 1.0, a)
    e[-r:] *= np.linspace(1.0, 0.0, r)
    return e


def place(buf: np.ndarray, start: int, wave: np.ndarray) -> None:
    end = min(len(buf), start + len(wave))
    buf[start:end] += wave[: end - start]


def note(buf, start_beat, length_beats, hz, vol, kind: str) -> None:
    n = int(SR * length_beats * BEAT)
    if n <= 8 or hz <= 0:
        return
    if kind == "pad":
        w = tri(n, hz) * env(n, 0.12, min(0.4, length_beats * BEAT * 0.5))
    else:
        w = pulse(n, hz, 0.5) * env(n, 0.02, min(0.25, length_beats * BEAT * 0.55))
    place(buf, int(start_beat * BEAT * SR), w * vol)


def main() -> None:
    bars = 16
    total_beats = bars * 4
    n = int(SR * total_beats * BEAT) + 1
    pad = np.zeros(n)
    lead = np.zeros(n)
    bass = np.zeros(n)

    # Soft pad chords (C pentatonic): two bars each
    pads = [
        (0, "C3", "G3", "E4"),
        (8, "A2", "E3", "C4"),
        (16, "G2", "D3", "B3") if False else (16, "G3", "D4", "G4"),
        (24, "C3", "G3", "C4"),
        (32, "E3", "A3", "E4"),
        (40, "G3", "D4", "G4"),
        (48, "A3", "E4", "A4"),
        (56, "C3", "G3", "E4"),
    ]
    # A2 not in table — skip the false branch. Use 8-beat pads:
    pad_seq = [
        (0, ["C3", "G3", "E4"]),
        (8, ["G3", "D4", "C4"]),
        (16, ["A3", "E4", "C5"]),
        (24, ["G3", "D4", "G4"]),
        (32, ["C3", "G3", "E4"]),
        (40, ["E3", "A3", "C4"]),
        (48, ["G3", "D4", "E4"]),
        (56, ["C3", "G3", "C4"]),
    ]
    for start, names in pad_seq:
        for nm in names:
            note(pad, start, 7.6, PITCH[nm], 0.07, "pad")

    # Sparse pentatonic lead
    melody = [
        (0.0, "E4", 2.0), (2.0, "G4", 2.0), (4.0, "A4", 3.0), (8.0, "G4", 2.0),
        (12.0, "E4", 4.0),
        (16.0, "D4", 2.0), (18.0, "C4", 2.0), (20.0, "E4", 4.0),
        (24.0, "G4", 2.0), (28.0, "C5", 4.0),
        (32.0, "A4", 2.0), (34.0, "G4", 2.0), (36.0, "E4", 4.0),
        (40.0, "D4", 2.0), (44.0, "C4", 4.0),
        (48.0, "E4", 2.0), (50.0, "G4", 2.0), (52.0, "E4", 2.0), (54.0, "D4", 2.0),
        (56.0, "C4", 6.0),
    ]
    for start, nm, dur in melody:
        note(lead, start, dur, PITCH[nm], 0.11, "lead")

    # Slow bass pulses on 1 of each bar
    for bar in range(bars):
        root = ["C3", "C3", "G3", "G3", "A3", "E3", "G3", "C3"][bar % 8]
        note(bass, bar * 4, 3.2, PITCH[root], 0.10, "pad")

    mix = pad + lead + bass
    fade = int(SR * 0.04)
    mix[:fade] *= np.linspace(0, 1, fade)
    mix[-fade:] *= np.linspace(1, 0, fade)
    peak = np.max(np.abs(mix)) or 1.0
    mix = np.clip(mix / peak * 0.75, -1.0, 1.0)

    path = OUT / "menu.wav"
    samples = (mix * 32767).astype(np.int16)
    with wave.open(str(path), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(samples.tobytes())
    print(f"wrote {path.relative_to(ROOT)}  {len(mix)/SR:.2f}s")


if __name__ == "__main__":
    main()
