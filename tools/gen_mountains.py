#!/usr/bin/env python3
"""NES-style mountain sprites for parallax backdrops."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SPRITES = ROOT / "assets" / "sprites"
SPRITES.mkdir(parents=True, exist_ok=True)

TRANS = (0, 0, 0, 0)
WHITE = (252, 252, 252, 255)
SNOW_D = (200, 216, 232, 255)
# Distant cool blues
FAR = (100, 148, 204, 255)
FAR_D = (68, 112, 172, 255)
FAR_SNOW = (236, 244, 252, 255)
FAR_SNOW_D = (188, 208, 228, 255)
# Mid teal-green
MID = (20, 152, 96, 255)
MID_D = (0, 104, 64, 255)
# Near, same family as the overworld hills
NEAR = (0, 168, 0, 255)
NEAR_D = (0, 104, 0, 255)
SKY_SPOT = (92, 148, 252, 255)


def new(w, h):
    return Image.new("RGBA", (w, h), TRANS)


def px(img, x, y, c):
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), c)


def lerp(a, b, t):
    return a + (b - a) * t


def ridge_line(width, peaks):
    """peaks: sorted (x, y) control points. y is from top of the image."""
    ridge = [peaks[0][1]] * width
    for i in range(len(peaks) - 1):
        x0, y0 = peaks[i]
        x1, y1 = peaks[i + 1]
        x0 = max(0, min(width - 1, int(x0)))
        x1 = max(0, min(width - 1, int(x1)))
        if x1 <= x0:
            ridge[x0] = int(y1)
            continue
        for x in range(x0, x1 + 1):
            t = (x - x0) / (x1 - x0)
            ridge[x] = int(round(lerp(y0, y1, t)))
    return ridge


def local_peaks(ridge):
    out = []
    n = len(ridge)
    for x in range(1, n - 1):
        if ridge[x] <= ridge[x - 1] and ridge[x] <= ridge[x + 1] and ridge[x] < ridge[max(0, x - 4)]:
            out.append(x)
    return out


def paint_mountain(img, ridge, fill, shade, snow=False, snow_fill=WHITE, snow_shade=SNOW_D, spots=None):
    w, h = img.size
    peaks = local_peaks(ridge)
    snow_depth = [0] * w
    if snow and peaks:
        # Only cap the highest peaks so foothills stay bare.
        tallest = sorted(peaks, key=lambda p: ridge[p])[: max(1, len(peaks) // 2 + 1)]
        for p in tallest:
            for x in range(max(0, p - 12), min(w, p + 13)):
                dist = abs(x - p)
                if ridge[x] <= ridge[p] + 10:
                    snow_depth[x] = max(snow_depth[x], 12 - dist + (1 if x % 3 == 0 else 0))
    for x in range(w):
        y0 = max(0, min(h - 1, ridge[x]))
        # Light from the left: descending-right slopes are in shadow.
        on_right = x > 0 and ridge[x] >= ridge[x - 1]
        body = shade if on_right else fill
        for y in range(y0, h):
            px(img, x, y, body)
        depth = snow_depth[x]
        if depth > 2:
            for i, y in enumerate(range(y0, min(h, y0 + depth))):
                px(img, x, y, snow_shade if on_right and i > 1 else snow_fill)
    for x in range(w):
        px(img, x, ridge[x], shade)
    if spots:
        for sx, sy, s in spots:
            for yy in range(s):
                for xx in range(s):
                    px(img, sx + xx, sy + yy, SKY_SPOT)
            for yy in range(1, s - 1):
                for xx in range(1, s - 1):
                    px(img, sx + xx, sy + yy, shade)


def mountain_from_peaks(w, h, peaks, fill, shade, snow=False, snow_fill=WHITE, snow_shade=SNOW_D, spots=None):
    img = new(w, h)
    # force feet at bottom corners so the silhouette plants
    pts = list(peaks)
    if pts[0][0] != 0:
        pts = [(0, h - 1)] + pts
    if pts[-1][0] != w - 1:
        pts = pts + [(w - 1, h - 1)]
    ridge = ridge_line(w, pts)
    paint_mountain(img, ridge, fill, shade, snow, snow_fill, snow_shade, spots)
    return img


# --- individual shapes -------------------------------------------------------

def m_cone(w=64, h=80, fill=NEAR, shade=NEAR_D, snow=False):
    return mountain_from_peaks(w, h, [(0, h - 1), (w * 0.5, 3), (w - 1, h - 1)], fill, shade, snow)


def m_spire(w=40, h=88, fill=NEAR, shade=NEAR_D, snow=True):
    return mountain_from_peaks(
        w, h,
        [(0, h - 1), (w * 0.42, 26), (w * 0.5, 2), (w * 0.58, 26), (w - 1, h - 1)],
        fill, shade, snow,
    )


def m_twin(w=96, h=72, fill=NEAR, shade=NEAR_D, snow=True):
    return mountain_from_peaks(
        w, h,
        [(0, h - 1), (w * 0.28, 8), (w * 0.40, 30), (w * 0.62, 4), (w * 0.78, 34), (w - 1, h - 1)],
        fill, shade, snow,
    )


def m_asymmetric(w=88, h=76, fill=NEAR, shade=NEAR_D, snow=True):
    return mountain_from_peaks(
        w, h,
        [(0, h - 1), (w * 0.22, 6), (w * 0.38, 28), (w * 0.55, 16), (w * 0.72, 36), (w - 1, h - 1)],
        fill, shade, snow,
    )


def m_broad(w=112, h=56, fill=NEAR, shade=NEAR_D, snow=False):
    return mountain_from_peaks(
        w, h,
        [(0, h - 1), (w * 0.18, 18), (w * 0.42, 8), (w * 0.68, 20), (w * 0.85, 14), (w - 1, h - 1)],
        fill, shade, snow,
    )


def m_jagged(w=80, h=84, fill=NEAR, shade=NEAR_D, snow=True):
    return mountain_from_peaks(
        w, h,
        [
            (0, h - 1),
            (w * 0.12, 40),
            (w * 0.22, 18),
            (w * 0.32, 34),
            (w * 0.48, 4),
            (w * 0.58, 28),
            (w * 0.70, 12),
            (w * 0.82, 38),
            (w - 1, h - 1),
        ],
        fill, shade, snow,
    )


def m_plateau(w=72, h=48, fill=NEAR, shade=NEAR_D, snow=False):
    return mountain_from_peaks(
        w, h,
        [(0, h - 1), (w * 0.22, 16), (w * 0.38, 10), (w * 0.62, 10), (w * 0.80, 18), (w - 1, h - 1)],
        fill, shade, snow,
    )


def m_small_snow(w=48, h=52, fill=NEAR, shade=NEAR_D):
    return mountain_from_peaks(
        w, h,
        [(0, h - 1), (w * 0.45, 4), (w * 0.7, 22), (w - 1, h - 1)],
        fill, shade, True,
    )


def m_hillish(w=80, h=48, fill=NEAR, shade=NEAR_D):
    img = mountain_from_peaks(
        w, h,
        [(0, h - 1), (w * 0.5, 6), (w - 1, h - 1)],
        fill, shade, False,
        spots=[(w // 2 - 10, h // 2, 6), (w // 2 + 8, h // 2 + 8, 5)],
    )
    return img


def stamp(dst, src, x, bottom):
    y = bottom - src.height
    dst.alpha_composite(src, (int(x), int(y)))


STRIP_W = 512
STRIP_H = 120


def build_far(width=STRIP_W, height=STRIP_H):
    img = new(width, height)
    # Same canvas height as the other layers; feet plant at the bottom.
    peaks = [
        (0, 88),
        (28, 56),
        (56, 80),
        (96, 10),
        (128, 66),
        (168, 32),
        (200, 84),
        (248, 8),
        (280, 58),
        (318, 26),
        (350, 76),
        (392, 14),
        (428, 62),
        (464, 36),
        (492, 80),
        (511, 88),
    ]
    ridge = ridge_line(width, peaks)
    paint_mountain(img, ridge, FAR, FAR_D, snow=True, snow_fill=FAR_SNOW, snow_shade=FAR_SNOW_D)
    return img


def build_mid(width=STRIP_W, height=STRIP_H):
    img = new(width, height)
    b = height
    stamp(img, m_broad(108, 64, MID, MID_D, snow=False), 4, b)
    stamp(img, m_spire(36, 110, MID, MID_D, True), 86, b)
    stamp(img, m_twin(100, 86, MID, MID_D, True), 118, b)
    stamp(img, m_plateau(68, 52, MID, MID_D, False), 210, b)
    stamp(img, m_jagged(84, 104, MID, MID_D, True), 268, b)
    stamp(img, m_small_snow(44, 60, MID, MID_D), 348, b)
    stamp(img, m_asymmetric(90, 90, MID, MID_D, True), 388, b)
    stamp(img, m_cone(56, 72, MID, MID_D, False), 470, b)
    return img


def build_near(width=STRIP_W, height=STRIP_H):
    img = new(width, height)
    b = height
    stamp(img, m_hillish(84, 50, NEAR, NEAR_D), 8, b)
    stamp(img, m_twin(110, 86, NEAR, NEAR_D, True), 70, b)
    stamp(img, m_cone(70, 64, NEAR, NEAR_D, False), 176, b)
    stamp(img, m_jagged(96, 100, NEAR, NEAR_D, True), 230, b)
    stamp(img, m_plateau(80, 52, NEAR, NEAR_D, False), 320, b)
    stamp(img, m_asymmetric(100, 90, NEAR, NEAR_D, True), 390, b)
    stamp(img, m_small_snow(52, 56, NEAR, NEAR_D), 470, b)
    return img


def save(img, path: Path):
    img.save(path)
    print("wrote", path, img.size)


def main():
    save(build_far(), SPRITES / "mountain_far.png")
    save(build_mid(), SPRITES / "mountain_mid.png")
    save(build_near(), SPRITES / "mountain_near.png")
    # Extra standalones (title / extra stamps)
    save(m_spire(40, 88, FAR, FAR_D, True), SPRITES / "mountain_spire.png")
    save(m_twin(96, 72, NEAR, NEAR_D, True), SPRITES / "mountain_twin.png")
    save(m_jagged(80, 84, MID, MID_D, True), SPRITES / "mountain_jagged.png")
    save(m_asymmetric(88, 76, NEAR, NEAR_D, True), SPRITES / "mountain_asymmetric.png")
    save(m_broad(112, 56, MID, MID_D, False), SPRITES / "mountain_broad.png")


if __name__ == "__main__":
    main()
