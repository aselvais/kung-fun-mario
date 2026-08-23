#!/usr/bin/env python3
"""NES-style 4-point shuriken (ninja star)."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SPRITES = ROOT / "assets" / "sprites"
TRANS = (0, 0, 0, 0)
BLACK = (0, 0, 0, 255)
STEEL = (220, 220, 228, 255)
MID = (160, 160, 176, 255)
DARK = (88, 88, 104, 255)


def px(img, x, y, c):
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), c)


def main():
    img = Image.new("RGBA", (16, 16), TRANS)
    cx, cy = 7.5, 7.5
    # 4-point throwing star: N/E/S/W blades + small diagonals.
    blades = []
    # vertical blade
    for y in range(0, 16):
        for x in range(6, 10):
            blades.append((x, y))
    # horizontal blade
    for x in range(0, 16):
        for y in range(6, 10):
            blades.append((x, y))
    # taper the tips
    skip = {
        (6, 0), (9, 0), (6, 15), (9, 15),
        (0, 6), (0, 9), (15, 6), (15, 9),
        (6, 1), (9, 1), (6, 14), (9, 14),
        (1, 6), (1, 9), (14, 6), (14, 9),
    }
    filled = [(x, y) for x, y in blades if (x, y) not in skip]
    # diagonal notches
    extra = [
        (5, 5), (10, 5), (5, 10), (10, 10),
        (4, 5), (11, 5), (4, 10), (11, 10),
        (5, 4), (10, 4), (5, 11), (10, 11),
    ]
    filled.extend(extra)
    body = set(filled)
    for x, y in list(body):
        # outline: neighbor empty -> black, else steel/mid
        edge = False
        for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            if (x + dx, y + dy) not in body:
                edge = True
                break
        if edge:
            px(img, x, y, BLACK)
        else:
            # inner highlight toward top-left
            col = STEEL if x + y < 16 else MID
            if 6 <= x <= 9 and 6 <= y <= 9:
                col = DARK if (x, y) in ((7, 7), (8, 8), (7, 8), (8, 7)) else STEEL
            px(img, x, y, col)
    # center hole
    px(img, 7, 7, BLACK)
    px(img, 8, 7, BLACK)
    px(img, 7, 8, BLACK)
    px(img, 8, 8, BLACK)
    path = SPRITES / "shuriken.png"
    img.save(path)
    print("wrote", path, img.size)


if __name__ == "__main__":
    main()
