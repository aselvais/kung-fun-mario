#!/usr/bin/env python3
"""NES-style ninja + green Yamo (Bruce Lee C64, 1984) enemy sprites."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SPRITES = ROOT / "assets" / "sprites"

TRANS = (0, 0, 0, 0)
BLACK = (0, 0, 0, 255)
WHITE = (252, 252, 252, 255)
# Ninja — charcoal gi (C64 ninja), light trim so he reads on green hills
N_GI = (40, 40, 64, 255)
N_HI = (112, 112, 148, 255)
N_SKIN = (220, 196, 164, 255)
# Yamo — bright green sumo
Y_SKIN = (88, 232, 56, 255)
Y_DARK = (32, 148, 24, 255)
Y_DEEP = (16, 88, 16, 255)
MAW = (196, 36, 20, 255)
MAW_D = (120, 16, 8, 255)
MAW_L = (228, 92, 40, 255)


def new(w, h):
    return Image.new("RGBA", (w, h), TRANS)


def px(img, x, y, c):
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), c)


def rect(img, x, y, w, h, c):
    for yy in range(y, y + h):
        for xx in range(x, x + w):
            px(img, xx, yy, c)


def hline(img, x, y, w, c):
    rect(img, x, y, w, 1, c)


def vline(img, x, y, h, c):
    rect(img, x, y, 1, h, c)


def outline(img):
    w, h = img.size
    src = img.copy()
    sp = src.load()
    pix = img.load()
    for y in range(h):
        for x in range(w):
            if sp[x, y][3] != 0:
                continue
            for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and sp[nx, ny][3] != 0:
                    pix[x, y] = BLACK
                    break


def save(img, name):
    outline(img)
    path = SPRITES / name
    img.save(path)
    print("wrote", path.name, img.size)


def draw_ninja(frame="walk1"):
    """24x24, facing right. Black ninja, white eyes, flying-kick pose."""
    img = new(24, 24)
    if frame == "kick":
        # crouched torso, flying side-kick
        rect(img, 4, 4, 9, 6, N_GI)  # hood/head
        rect(img, 5, 5, 7, 5, N_HI)
        px(img, 9, 7, WHITE)
        px(img, 11, 7, WHITE)
        px(img, 9, 8, BLACK)
        px(img, 11, 8, BLACK)
        rect(img, 5, 10, 8, 7, N_GI)  # torso
        vline(img, 4, 11, 6, BLACK)
        hline(img, 6, 16, 6, N_HI)  # sash
        # guard arm
        rect(img, 2, 11, 3, 3, N_GI)
        rect(img, 1, 12, 2, 2, N_SKIN)
        # planted thigh
        rect(img, 6, 17, 5, 3, N_GI)
        rect(img, 6, 20, 4, 3, N_GI)
        rect(img, 6, 22, 4, 2, N_SKIN)
        # kicking leg stretched right
        rect(img, 11, 14, 10, 4, N_GI)
        hline(img, 11, 14, 10, N_HI)
        rect(img, 20, 13, 4, 5, N_SKIN)  # foot
        px(img, 23, 15, BLACK)
        return img
    # walk / idle
    bob = 0 if frame == "walk1" else 1
    rect(img, 8, 1 + bob, 8, 7, N_GI)  # hood
    rect(img, 9, 2 + bob, 6, 6, N_HI)
    px(img, 11, 4 + bob, WHITE)
    px(img, 13, 4 + bob, WHITE)
    px(img, 11, 5 + bob, BLACK)
    px(img, 13, 5 + bob, BLACK)
    rect(img, 7, 8 + bob, 10, 8, N_GI)  # gi
    vline(img, 7, 9 + bob, 7, BLACK)
    vline(img, 16, 9 + bob, 7, N_HI)
    hline(img, 7, 15 + bob, 10, N_HI)
    # arms
    if frame == "walk2":
        rect(img, 5, 10, 2, 6, N_GI)
        rect(img, 17, 10, 2, 6, N_GI)
        rect(img, 5, 15, 2, 2, N_SKIN)
        rect(img, 17, 15, 2, 2, N_SKIN)
    else:
        rect(img, 5, 11, 2, 5, N_GI)
        rect(img, 17, 11, 2, 5, N_GI)
        rect(img, 5, 15, 2, 2, N_SKIN)
        rect(img, 17, 15, 2, 2, N_SKIN)
    # legs
    if frame == "walk2":
        rect(img, 7, 16, 4, 6, N_GI)
        rect(img, 13, 16, 4, 5, N_GI)
        rect(img, 7, 22, 4, 2, N_SKIN)
        rect(img, 14, 21, 4, 2, N_SKIN)
    else:
        rect(img, 8, 16, 4, 6, N_GI)
        rect(img, 12, 16, 4, 6, N_GI)
        rect(img, 8, 22, 4, 2, N_SKIN)
        rect(img, 12, 22, 4, 2, N_SKIN)
    return img


def draw_sumo(frame="walk1"):
    """32x32, facing right. Green Yamo: bulky, mawashi, punch."""
    img = new(32, 32)
    punch = frame == "punch"
    waddle = 1 if frame == "walk2" else 0
    # bald green head
    hx = 9
    hy = 1
    rect(img, hx + 1, hy, 12, 9, Y_SKIN)
    rect(img, hx, hy + 1, 14, 7, Y_SKIN)
    hline(img, hx + 2, hy, 10, Y_DARK)  # scalp shade
    # brow + eyes
    hline(img, hx + 3, hy + 3, 3, Y_DEEP)
    hline(img, hx + 8, hy + 3, 3, Y_DEEP)
    px(img, hx + 4, hy + 4, WHITE)
    px(img, hx + 5, hy + 4, BLACK)
    px(img, hx + 9, hy + 4, WHITE)
    px(img, hx + 8, hy + 4, BLACK)
    # frown
    hline(img, hx + 5, hy + 6, 4, Y_DEEP)
    # thick neck
    rect(img, hx + 3, hy + 8, 8, 3, Y_SKIN)
    # huge torso / belly
    rect(img, 6, 11, 20, 12, Y_SKIN)
    rect(img, 7, 10, 18, 2, Y_SKIN)
    vline(img, 6, 12, 10, Y_DARK)
    vline(img, 25, 12, 10, Y_DEEP)
    # navel
    px(img, 16, 18, Y_DEEP)
    # mawashi
    rect(img, 6, 21, 20, 5, MAW)
    hline(img, 6, 21, 20, MAW_L)
    hline(img, 6, 25, 20, MAW_D)
    rect(img, 14, 20, 5, 7, MAW_D)  # front knot
    # rear arm
    if punch:
        rect(img, 4, 13, 4, 5, Y_SKIN)
        rect(img, 3, 14, 3, 4, Y_DARK)
        # punching arm + giant fist
        rect(img, 24, 12, 5, 5, Y_SKIN)
        rect(img, 27, 10, 5, 7, Y_SKIN)
        rect(img, 28, 11, 4, 5, Y_DARK)
        px(img, 31, 13, Y_DEEP)
    else:
        rect(img, 4, 13 + waddle, 4, 6, Y_SKIN)
        rect(img, 3, 17 + waddle, 3, 3, Y_DARK)
        rect(img, 24, 13 - waddle, 4, 6, Y_SKIN)
        rect(img, 26, 17 - waddle, 3, 3, Y_DARK)
    # legs / feet
    if frame == "walk2":
        rect(img, 8, 26, 7, 4, Y_SKIN)
        rect(img, 17, 26, 7, 5, Y_SKIN)
        rect(img, 7, 30, 8, 2, Y_DEEP)
        rect(img, 18, 30, 7, 2, Y_DEEP)
    elif punch:
        rect(img, 8, 26, 7, 5, Y_SKIN)
        rect(img, 17, 26, 7, 5, Y_SKIN)
        rect(img, 7, 30, 8, 2, Y_DEEP)
        rect(img, 17, 30, 8, 2, Y_DEEP)
    else:
        rect(img, 8, 26, 7, 5, Y_SKIN)
        rect(img, 17, 26, 7, 4, Y_SKIN)
        rect(img, 7, 30, 8, 2, Y_DEEP)
        rect(img, 17, 30, 8, 2, Y_DEEP)
    return img


def main():
    save(draw_ninja("walk1"), "ninja_walk1.png")
    save(draw_ninja("walk2"), "ninja_walk2.png")
    save(draw_ninja("kick"), "ninja_kick.png")
    save(draw_sumo("walk1"), "sumo_walk1.png")
    save(draw_sumo("walk2"), "sumo_walk2.png")
    save(draw_sumo("punch"), "sumo_punch.png")


if __name__ == "__main__":
    main()
