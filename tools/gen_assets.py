#!/usr/bin/env python3
"""Generate NES-style original pixel art for a Super Mario Bros 1-1 tribute."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
TILES = ROOT / "assets" / "tiles"
SPRITES = ROOT / "assets" / "sprites"
TILES.mkdir(parents=True, exist_ok=True)
SPRITES.mkdir(parents=True, exist_ok=True)

T = 16

# NES-inspired overworld palette (original tribute, not ripped)
SKY = (92, 148, 252, 255)
TRANS = (0, 0, 0, 0)
BLACK = (0, 0, 0, 255)
WHITE = (252, 252, 252, 255)
RED = (181, 49, 32, 255)
RED2 = (228, 92, 16, 255)
SKIN = (252, 188, 176, 255)
HAIR = (172, 124, 0, 255)
BLUE = (0, 88, 248, 255)
BLUE2 = (0, 56, 176, 255)
BROWN = (172, 80, 0, 255)
BROWN2 = (136, 64, 0, 255)
DIRT = (228, 92, 16, 255)
DIRT2 = (160, 64, 16, 255)
DIRT3 = (96, 40, 8, 255)
GRASS = (0, 168, 0, 255)
GRASS2 = (0, 120, 0, 255)
PIPE = (0, 168, 0, 255)
PIPE_D = (0, 104, 0, 255)
PIPE_L = (184, 248, 24, 255)
PIPE_H = (252, 252, 252, 255)
BRICK = (200, 76, 12, 255)
BRICK_D = (136, 20, 0, 255)
BRICK_L = (252, 160, 68, 255)
Q_GOLD = (252, 188, 0, 255)
Q_DARK = (172, 124, 0, 255)
Q_WHITE = (252, 252, 252, 255)
HARD = (200, 76, 12, 255)
HARD_D = (136, 20, 0, 255)
HARD_L = (252, 188, 176, 255)
GOOMBA = (200, 76, 12, 255)
GOOMBA_D = (136, 20, 0, 255)
GOOMBA_F = (252, 188, 176, 255)
MUSH_RED = (228, 0, 88, 255)
MUSH_SPOT = (252, 252, 252, 255)
MUSH_STEM = (252, 216, 168, 255)
COIN = (252, 188, 0, 255)
COIN_D = (200, 76, 12, 255)
CLOUD = (252, 252, 252, 255)
CLOUD_L = (184, 248, 216, 255)
HILL = (0, 168, 0, 255)
HILL_D = (0, 104, 0, 255)
CASTLE = (0, 0, 0, 255)
CASTLE_B = (200, 76, 12, 255)
FLAG_G = (0, 168, 0, 255)
KOOPA = (0, 168, 0, 255)
KOOPA_D = (0, 104, 0, 255)
KOOPA_Y = (252, 188, 0, 255)
KOOPA_S = (252, 188, 176, 255)


def new(w, h, color=TRANS):
    img = Image.new("RGBA", (w, h), color)
    return img


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


def save(img, path: Path):
    img.save(path)
    print("wrote", path.relative_to(ROOT))


def tile_ground_top():
    img = new(T, T)
    rect(img, 0, 0, T, T, DIRT)
    hline(img, 0, 0, T, GRASS)
    hline(img, 0, 1, T, GRASS2)
    # speckles
    for x, y in [(2, 5), (7, 8), (12, 6), (4, 12), (10, 13), (14, 9), (1, 10)]:
        px(img, x, y, DIRT2)
    # grass tufts
    for x in (1, 5, 9, 13):
        px(img, x, 2, GRASS)
    return img


def tile_ground_fill():
    img = new(T, T, DIRT)
    for x, y in [(3, 2), (8, 4), (13, 1), (1, 7), (6, 9), (11, 11), (4, 13), (14, 8), (9, 14)]:
        px(img, x, y, DIRT2)
    for x, y in [(5, 5), (12, 12), (2, 14)]:
        px(img, x, y, DIRT3)
    return img


def tile_brick():
    img = new(T, T, BRICK)
    hline(img, 0, 0, T, BRICK_L)
    hline(img, 0, 7, T, BLACK)
    hline(img, 0, 8, T, BRICK_L)
    hline(img, 0, 15, T, BLACK)
    vline(img, 0, 0, T, BLACK)
    vline(img, 7, 0, 8, BLACK)
    vline(img, 15, 0, T, BLACK)
    vline(img, 3, 8, 8, BLACK)
    vline(img, 11, 8, 8, BLACK)
    return img


def tile_question(used=False):
    img = new(T, T, Q_DARK if used else Q_GOLD)
    # border
    hline(img, 1, 0, 14, BLACK)
    hline(img, 1, 15, 14, BLACK)
    vline(img, 0, 1, 14, BLACK)
    vline(img, 15, 1, 14, BLACK)
    px(img, 1, 1, WHITE)
    px(img, 14, 1, BLACK)
    px(img, 1, 14, BLACK)
    inner = Q_DARK if used else Q_GOLD
    if not used:
        # ?
        for x, y in [
            (6, 3), (7, 3), (8, 3), (9, 3),
            (5, 4), (10, 4),
            (10, 5),
            (9, 6), (8, 7), (7, 8),
            (7, 9),
            (7, 11), (7, 12),
        ]:
            px(img, x, y, BLACK)
            px(img, x + 1, y + 1, Q_DARK)
        px(img, 7, 3, WHITE)
        px(img, 8, 3, WHITE)
    else:
        rect(img, 2, 2, 12, 12, (136, 88, 0, 255))
        hline(img, 2, 2, 12, Q_DARK)
    # rivets
    for x, y in [(2, 2), (13, 2), (2, 13), (13, 13)]:
        px(img, x, y, WHITE if not used else Q_DARK)
    return img


def tile_hard():
    img = new(T, T, HARD)
    hline(img, 0, 0, T, HARD_L)
    vline(img, 0, 0, T, HARD_L)
    hline(img, 0, 15, T, HARD_D)
    vline(img, 15, 0, T, HARD_D)
    # inner bevel
    rect(img, 3, 3, 10, 10, HARD_D)
    rect(img, 4, 4, 8, 8, HARD)
    return img


def tile_pipe(kind):
    """kind: top_l, top_r, body_l, body_r"""
    img = new(T, T, PIPE)
    if kind.startswith("top"):
        rect(img, 0, 0, T, T, PIPE)
        hline(img, 0, 0, T, BLACK)
        hline(img, 0, 1, T, PIPE_L)
        hline(img, 0, 4, T, BLACK)
        if kind.endswith("l"):
            vline(img, 0, 0, T, BLACK)
            vline(img, 1, 1, 3, PIPE_L)
            rect(img, 2, 5, 14, 11, PIPE)
            vline(img, 2, 5, 11, PIPE_L)
        else:
            vline(img, 15, 0, T, BLACK)
            rect(img, 0, 5, 14, 11, PIPE)
            vline(img, 13, 5, 11, PIPE_D)
            vline(img, 14, 5, 11, BLACK)
    else:
        if kind.endswith("l"):
            vline(img, 2, 0, T, BLACK)
            vline(img, 3, 0, T, PIPE_L)
            rect(img, 4, 0, 12, T, PIPE)
        else:
            rect(img, 0, 0, 12, T, PIPE)
            vline(img, 12, 0, T, PIPE_D)
            vline(img, 13, 0, T, BLACK)
            rect(img, 14, 0, 2, T, TRANS)
    return img


GI = (252, 252, 252, 255)
GI_D = (188, 188, 188, 255)
PANTS = (196, 20, 20, 255)
PANTS_D = (140, 8, 8, 255)
HAIR_K = (16, 16, 16, 255)
BELT = (40, 40, 40, 255)


def draw_player_small(frame="idle"):
    return draw_thomas(24, frame)


def draw_thomas(h: int, frame: str = "idle"):
    """Original NES-style tribute of Kung-Fu Master (1984) Thomas:
    black hair, sleeveless white keikogi, red pants, side view facing right.
    Canvas is 24 wide so punches/kicks have reach; torso stays left-of-center.
    """
    img = new(24, h)
    # Anchor the body so feet sit on the bottom row.
    by = h - 24  # 0 for small (24 tall), 8 for big (32 tall)
    # --- hair ---
    rect(img, 8, by + 1, 8, 6, HAIR_K)
    rect(img, 7, by + 2, 10, 5, HAIR_K)
    rect(img, 6, by + 3, 3, 5, HAIR_K)  # back of head
    # --- face ---
    rect(img, 9, by + 4, 7, 6, SKIN)
    px(img, 14, by + 6, BLACK)  # eye
    px(img, 13, by + 6, WHITE)
    hline(img, 12, by + 8, 4, SKIN)
    # --- gi (sleeveless white keikogi) ---
    rect(img, 7, by + 10, 10, 8, GI)
    hline(img, 8, by + 10, 8, GI_D)
    # V-neck
    px(img, 11, by + 10, SKIN)
    px(img, 12, by + 10, SKIN)
    px(img, 11, by + 11, SKIN)
    vline(img, 7, by + 11, 7, GI_D)
    vline(img, 16, by + 11, 7, BLACK)
    # belt
    hline(img, 7, by + 17, 10, BELT)
    # --- pants ---
    rect(img, 7, by + 18, 10, 4, PANTS)
    # --- arms / legs by pose, all facing right ---
    if frame == "punch":
        # rear arm cocked
        rect(img, 5, by + 12, 3, 3, SKIN)
        # punching arm extended
        rect(img, 16, by + 12, 7, 3, SKIN)
        rect(img, 21, by + 11, 3, 4, SKIN)  # fist
        px(img, 23, by + 12, BLACK)
        # stance
        rect(img, 7, by + 18, 4, 5, PANTS)
        rect(img, 12, by + 18, 5, 5, PANTS)
        rect(img, 6, by + 22, 4, 2, SKIN)
        rect(img, 13, by + 22, 4, 2, SKIN)
    elif frame == "kick":
        # guard hands
        rect(img, 5, by + 12, 3, 4, SKIN)
        rect(img, 16, by + 11, 3, 3, SKIN)
        # planted leg
        rect(img, 8, by + 18, 4, 5, PANTS)
        rect(img, 8, by + 22, 4, 2, SKIN)
        # kicking leg outstretched
        rect(img, 12, by + 16, 10, 3, PANTS)
        rect(img, 20, by + 15, 4, 4, SKIN)  # foot
        hline(img, 12, by + 16, 10, PANTS_D)
    elif frame == "jump":
        rect(img, 4, by + 11, 3, 4, SKIN)
        rect(img, 17, by + 11, 3, 4, SKIN)
        rect(img, 6, by + 18, 4, 3, PANTS)
        rect(img, 13, by + 19, 4, 3, PANTS)
        rect(img, 5, by + 20, 4, 2, SKIN)
        rect(img, 14, by + 21, 4, 2, SKIN)
    elif frame == "walk2":
        rect(img, 5, by + 12, 2, 5, SKIN)
        rect(img, 17, by + 12, 2, 5, SKIN)
        rect(img, 5, by + 18, 4, 4, PANTS)
        rect(img, 13, by + 18, 4, 4, PANTS)
        rect(img, 4, by + 22, 4, 2, SKIN)
        rect(img, 14, by + 22, 4, 2, SKIN)
    else:
        # idle / walk1
        vline(img, 5, by + 12, 6, SKIN)
        vline(img, 6, by + 12, 6, SKIN)
        vline(img, 17, by + 12, 6, SKIN)
        vline(img, 18, by + 12, 6, SKIN)
        rect(img, 7, by + 18, 4, 5, PANTS)
        rect(img, 12, by + 18, 5, 5, PANTS)
        vline(img, 7, by + 18, 5, PANTS_D)
        rect(img, 7, by + 22, 4, 2, SKIN)
        rect(img, 13, by + 22, 4, 2, SKIN)
    return img


def draw_player_big(frame="idle"):
    return draw_thomas(32, frame)


def draw_goomba(frame=1, flat=False):
    img = new(T, T)
    if flat:
        rect(img, 1, 12, 14, 3, GOOMBA)
        hline(img, 1, 12, 14, GOOMBA_D)
        rect(img, 2, 14, 3, 2, BLACK)
        rect(img, 11, 14, 3, 2, BLACK)
        return img
    # body
    rect(img, 2, 4, 12, 9, GOOMBA)
    rect(img, 3, 3, 10, 1, GOOMBA)
    rect(img, 4, 2, 8, 1, GOOMBA)
    # frown / brows
    hline(img, 4, 5, 3, BLACK)
    hline(img, 9, 5, 3, BLACK)
    px(img, 5, 6, WHITE)
    px(img, 6, 6, BLACK)
    px(img, 10, 6, WHITE)
    px(img, 9, 6, BLACK)
    # teeth
    hline(img, 6, 9, 4, GOOMBA_F)
    px(img, 7, 9, BLACK)
    px(img, 8, 9, BLACK)
    # feet
    if frame == 1:
        rect(img, 1, 13, 5, 3, BLACK)
        rect(img, 10, 13, 5, 3, BLACK)
    else:
        rect(img, 2, 13, 5, 3, BLACK)
        rect(img, 9, 13, 5, 3, BLACK)
    return img


def draw_koopa(frame=1, shell=False):
    img = new(T, 24)
    if shell:
        rect(img, 3, 10, 10, 10, KOOPA)
        rect(img, 4, 9, 8, 1, KOOPA)
        rect(img, 4, 11, 8, 8, KOOPA_D)
        rect(img, 5, 12, 6, 6, KOOPA)
        px(img, 6, 13, KOOPA_Y)
        px(img, 9, 16, KOOPA_Y)
        return img
    # shell
    rect(img, 3, 8, 11, 10, KOOPA)
    rect(img, 4, 7, 9, 1, KOOPA)
    rect(img, 5, 9, 7, 7, KOOPA_D)
    px(img, 6, 10, KOOPA_Y)
    # head
    rect(img, 10, 3, 5, 6, KOOPA_Y)
    px(img, 13, 5, BLACK)
    px(img, 14, 4, KOOPA_S)
    # feet
    if frame == 1:
        rect(img, 3, 18, 4, 4, KOOPA_Y)
        rect(img, 10, 18, 4, 4, KOOPA_Y)
    else:
        rect(img, 2, 18, 4, 4, KOOPA_Y)
        rect(img, 11, 18, 4, 4, KOOPA_Y)
    return img


def draw_coin(frame=0):
    img = new(T, T)
    # 4-frame spin: full, mid, thin, mid
    if frame % 4 == 0:
        rect(img, 5, 2, 6, 12, COIN)
        vline(img, 4, 3, 10, COIN_D)
        vline(img, 11, 3, 10, WHITE)
        vline(img, 7, 4, 8, COIN_D)
    elif frame % 4 == 1:
        rect(img, 6, 2, 4, 12, COIN)
        vline(img, 7, 3, 10, COIN_D)
    elif frame % 4 == 2:
        vline(img, 7, 2, 12, COIN)
        vline(img, 8, 2, 12, COIN_D)
    else:
        rect(img, 6, 2, 4, 12, COIN)
        vline(img, 8, 3, 10, WHITE)
    return img


def draw_mushroom():
    img = new(T, T)
    # cap
    rect(img, 1, 3, 14, 6, MUSH_RED)
    rect(img, 2, 2, 12, 1, MUSH_RED)
    rect(img, 4, 1, 8, 1, MUSH_RED)
    # spots
    rect(img, 3, 3, 3, 3, MUSH_SPOT)
    rect(img, 10, 3, 3, 3, MUSH_SPOT)
    rect(img, 7, 5, 2, 2, MUSH_SPOT)
    # stem
    rect(img, 5, 9, 6, 6, MUSH_STEM)
    hline(img, 5, 9, 6, BLACK)
    px(img, 6, 11, BLACK)
    px(img, 9, 11, BLACK)
    rect(img, 4, 14, 3, 2, BROWN)
    rect(img, 9, 14, 3, 2, BROWN)
    return img


def draw_star():
    img = new(T, T)
    star = [
        "....XXXX....",
        "...XXXXXX...",
        "XXXXXXXXXXXX",
        ".XXXXXXXXXX.",
        "..XXXXXXXX..",
        "..XXX..XXX..",
        ".XXX....XXX.",
        "XX........XX",
    ]
    ox, oy = 2, 4
    for y, row in enumerate(star):
        for x, ch in enumerate(row):
            if ch == "X":
                px(img, ox + x, oy + y, Q_GOLD if y < 4 else Q_DARK)
    px(img, 5, 6, BLACK)
    px(img, 10, 6, BLACK)
    return img


def draw_cloud(size=1):
    w = 32 + (size - 1) * 16
    img = new(w, 24)
    # puffy ovals
    blobs = [(4, 8, 20, 12), (12, 4, 20, 14)]
    if size >= 2:
        blobs.append((24, 6, 20, 12))
    if size >= 3:
        blobs.append((40, 5, 22, 13))
    for x, y, bw, bh in blobs:
        rect(img, x, y, bw, bh, CLOUD)
        hline(img, x + 2, y - 1, bw - 4, CLOUD)
        hline(img, x + 1, y + bh, bw - 2, CLOUD_L)
    return img


def draw_bush(size=1):
    img = draw_cloud(size)
    # recolor white->green
    pix = img.load()
    for y in range(img.height):
        for x in range(img.width):
            if pix[x, y] == CLOUD:
                pix[x, y] = HILL
            elif pix[x, y] == CLOUD_L:
                pix[x, y] = HILL_D
    return img


def draw_hill(large=False):
    w, h = (80, 48) if large else (48, 32)
    img = new(w, h)
    # triangle-ish
    peak = w // 2
    for y in range(h):
        t = y / max(h - 1, 1)
        half = int((w // 2) * t) + 2
        x0 = peak - half
        x1 = peak + half
        for x in range(x0, x1):
            px(img, x, y, HILL if (x - x0) > 3 else HILL_D)
    # spots
    spots = [(peak - 8, h // 2), (peak + 6, h // 2 + 6)]
    if large:
        spots.append((peak, h // 2 + 10))
    for sx, sy in spots:
        rect(img, sx, sy, 6, 6, SKY)
        rect(img, sx + 1, sy + 1, 4, 4, HILL_D)
    return img


def draw_castle():
    img = new(80, 80, TRANS)
    # body
    rect(img, 8, 32, 64, 48, CASTLE_B)
    # battlements
    for i in range(5):
        rect(img, 8 + i * 13, 24, 10, 10, CASTLE_B)
    # door
    rect(img, 32, 52, 16, 28, BLACK)
    # windows
    rect(img, 16, 40, 8, 10, BLACK)
    rect(img, 56, 40, 8, 10, BLACK)
    # tower
    rect(img, 32, 8, 16, 24, CASTLE_B)
    rect(img, 30, 4, 20, 8, CASTLE_B)
    rect(img, 36, 0, 8, 6, CASTLE_B)
    return img


def draw_flag():
    img = new(24, 16)
    # triangle flag
    for y in range(14):
        w = 18 - y // 2
        hline(img, 0, y + 1, max(w, 4), WHITE if y < 2 else (228, 0, 88, 255))
    return img


def draw_pole():
    img = new(4, 160, FLAG_G)
    vline(img, 0, 0, 160, BLACK)
    vline(img, 3, 0, 160, PIPE_D)
    rect(img, 0, 0, 4, 4, WHITE)
    return img


def draw_particle_bump():
    img = new(8, 8)
    rect(img, 2, 2, 4, 4, BRICK)
    return img


def main():
    save(tile_ground_top(), TILES / "ground_top.png")
    save(tile_ground_fill(), TILES / "ground_fill.png")
    save(tile_brick(), TILES / "brick.png")
    save(tile_question(False), TILES / "question.png")
    save(tile_question(True), TILES / "question_used.png")
    save(tile_hard(), TILES / "hard.png")
    save(tile_pipe("top_l"), TILES / "pipe_top_l.png")
    save(tile_pipe("top_r"), TILES / "pipe_top_r.png")
    save(tile_pipe("body_l"), TILES / "pipe_body_l.png")
    save(tile_pipe("body_r"), TILES / "pipe_body_r.png")

    for name, frame in [
        ("idle", "idle"),
        ("walk1", "idle"),
        ("walk2", "walk2"),
        ("jump", "jump"),
        ("punch", "punch"),
        ("kick", "kick"),
    ]:
        save(draw_player_small(frame), SPRITES / f"player_small_{name}.png")
        save(draw_player_big(frame), SPRITES / f"player_big_{name}.png")

    save(draw_goomba(1), SPRITES / "goomba1.png")
    save(draw_goomba(2), SPRITES / "goomba2.png")
    save(draw_goomba(flat=True), SPRITES / "goomba_flat.png")
    save(draw_koopa(1), SPRITES / "koopa1.png")
    save(draw_koopa(2), SPRITES / "koopa2.png")
    save(draw_koopa(shell=True), SPRITES / "koopa_shell.png")
    for i in range(4):
        save(draw_coin(i), SPRITES / f"coin{i}.png")
    save(draw_mushroom(), SPRITES / "mushroom.png")
    save(draw_star(), SPRITES / "star.png")
    save(draw_cloud(1), SPRITES / "cloud1.png")
    save(draw_cloud(2), SPRITES / "cloud2.png")
    save(draw_cloud(3), SPRITES / "cloud3.png")
    save(draw_bush(1), SPRITES / "bush1.png")
    save(draw_bush(2), SPRITES / "bush2.png")
    save(draw_bush(3), SPRITES / "bush3.png")
    save(draw_hill(False), SPRITES / "hill_small.png")
    save(draw_hill(True), SPRITES / "hill_large.png")
    save(draw_castle(), SPRITES / "castle.png")
    save(draw_flag(), SPRITES / "flag.png")
    save(draw_pole(), SPRITES / "pole.png")
    save(draw_particle_bump(), SPRITES / "brick_bit.png")

    # sky color reference swatch (not used in-game)
    print("done")


if __name__ == "__main__":
    main()
