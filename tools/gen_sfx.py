#!/usr/bin/env python3
"""Original 8-bit style SFX (not ripped from any commercial game)."""
from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "sfx"
OUT.mkdir(parents=True, exist_ok=True)

SR = 22050


def clamp(v: float) -> int:
    return max(-32767, min(32767, int(v * 32767)))


def write_wav(name: str, samples: list[float]) -> None:
    path = OUT / f"{name}.wav"
    with wave.open(str(path), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", clamp(s)) for s in samples))
    print("wrote", path.relative_to(ROOT), f"({len(samples) / SR:.3f}s)")


def env(i: int, n: int, attack: float = 0.01, release: float = 0.2) -> float:
    t = i / max(n - 1, 1)
    a = min(1.0, t / max(attack, 1e-4))
    r = 1.0
    if t > 1.0 - release:
        r = max(0.0, (1.0 - t) / max(release, 1e-4))
    return a * r


def square(t: float, hz: float, duty: float = 0.5) -> float:
    return 1.0 if math.fmod(t * hz, 1.0) < duty else -1.0


def tri(t: float, hz: float) -> float:
    x = math.fmod(t * hz, 1.0)
    return 4.0 * x - 1.0 if x < 0.5 else 3.0 - 4.0 * x


def noise() -> float:
    return random.uniform(-1.0, 1.0)


def tone_sweep(dur: float, f0: float, f1: float, vol: float = 0.22, wave="square", duty=0.5) -> list[float]:
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        u = i / max(n - 1, 1)
        hz = f0 + (f1 - f0) * u
        osc = square(t, hz, duty) if wave == "square" else tri(t, hz)
        out.append(osc * vol * env(i, n, 0.02, 0.35))
    return out


def noise_burst(dur: float, vol: float = 0.28, decay: float = 0.7) -> list[float]:
    n = int(SR * dur)
    out = []
    for i in range(n):
        u = i / max(n - 1, 1)
        out.append(noise() * vol * ((1.0 - u) ** decay))
    return out


def mix(*parts: list[float]) -> list[float]:
    n = max(len(p) for p in parts)
    out = [0.0] * n
    for p in parts:
        for i, s in enumerate(p):
            out[i] += s
    peak = max(1e-6, max(abs(s) for s in out))
    if peak > 0.95:
        out = [s * 0.95 / peak for s in out]
    return out


def notes(pairs: list[tuple[float, float, float]], wave="square") -> list[float]:
    """(freq, dur, vol) sequence."""
    out: list[float] = []
    for hz, dur, vol in pairs:
        out.extend(tone_sweep(dur, hz, hz, vol, wave=wave, duty=0.25))
    return out


def main() -> None:
    random.seed(1984)

    write_wav("jump", tone_sweep(0.14, 280, 620, 0.20, duty=0.25))
    write_wav("double_jump", tone_sweep(0.16, 360, 820, 0.18, duty=0.25))
    write_wav(
        "punch",
        mix(
            noise_burst(0.08, 0.22, 1.4),
            tone_sweep(0.07, 180, 90, 0.16, duty=0.5),
        ),
    )
    write_wav(
        "kick",
        mix(
            noise_burst(0.11, 0.26, 1.1),
            tone_sweep(0.10, 140, 70, 0.20, duty=0.5),
        ),
    )
    write_wav(
        "coin",
        mix(
            tone_sweep(0.08, 980, 980, 0.18, wave="tri"),
            [0.0] * int(SR * 0.04) + tone_sweep(0.14, 1320, 1320, 0.20, wave="tri"),
        ),
    )
    write_wav("bump", tone_sweep(0.08, 120, 90, 0.22, duty=0.5))
    write_wav(
        "break",
        mix(
            noise_burst(0.16, 0.30, 0.8),
            tone_sweep(0.10, 200, 80, 0.12),
        ),
    )
    write_wav(
        "stomp",
        mix(
            noise_burst(0.09, 0.24, 1.2),
            tone_sweep(0.09, 220, 110, 0.18),
        ),
    )
    write_wav(
        "hit",
        mix(
            noise_burst(0.07, 0.28, 1.5),
            tone_sweep(0.06, 340, 160, 0.16, duty=0.25),
        ),
    )
    write_wav(
        "powerup",
        notes([(392, 0.07, 0.16), (494, 0.07, 0.16), (587, 0.07, 0.16), (784, 0.12, 0.18)]),
    )
    write_wav(
        "grow",
        notes([(262, 0.08, 0.16), (330, 0.08, 0.16), (392, 0.08, 0.16), (523, 0.16, 0.18)]),
    )
    write_wav(
        "star",
        notes([(523, 0.06, 0.14), (659, 0.06, 0.14), (784, 0.06, 0.14), (1046, 0.12, 0.16)]),
    )
    write_wav(
        "oneup",
        notes([(523, 0.08, 0.16), (659, 0.08, 0.16), (784, 0.08, 0.16), (1046, 0.08, 0.16), (1318, 0.16, 0.18)]),
    )
    write_wav("die", tone_sweep(0.55, 420, 80, 0.20, wave="square", duty=0.5))
    write_wav(
        "flag",
        notes([(392, 0.10, 0.16), (523, 0.10, 0.16), (659, 0.14, 0.18)]),
    )
    write_wav(
        "win",
        notes(
            [
                (392, 0.10, 0.16),
                (494, 0.10, 0.16),
                (587, 0.10, 0.16),
                (784, 0.22, 0.20),
            ]
        ),
    )
    print("done")


if __name__ == "__main__":
    main()
