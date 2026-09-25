#!/usr/bin/env python3
"""Build the interest-category imagesets from the Figma asset sheet.

Source: `Category assets` (848:53680) in the Motion Canvas file — ten
categories, each drawn twice: an `_a` chrome/iridescent set and a `_b` playful
3D set. Both ship; `OnboardingTuning.categoryArt` picks between them at runtime.

Two traps this handles.

1. Not every source render has an alpha channel. Figma hands back whichever
   bytes were uploaded, and six of these twenty were flattened onto the sheet's
   near-black background. Keying those by luminance alone eats the icon's own
   dark detail — the shadow under a lamp, the black buttons on a gamepad — so
   the background is removed with a flood fill seeded from the border instead.
   Only near-black that is *connected to the edge* goes; an enclosed dark
   region survives.

2. The sheet's rectangles crop their fills, so a node's box on the canvas says
   nothing about the icon's real proportions. Everything is trimmed to its own
   alpha bounding box here and sized in Swift instead.

Run from the project root:  python3 Tools/make_categories.py
"""

from collections import deque
from pathlib import Path
import json
import sys

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "Tools" / "category_src"
OUT = ROOT / "GyroQR" / "Assets.xcassets"

SLUGS = ["gaming", "tech", "reading", "arts", "building",
         "beauty", "sneakers", "room", "sports", "plush"]

# Longest edge of the emitted PNG. The tiles draw these at roughly 46pt, so 200
# covers @3x with room to spare for the bigger `_a` renders.
TARGET = 200
# A pixel is background only below this on max(R,G,B). The sheet's plate is
# ~#1a1a1c, and the darkest ink inside these icons sits well above it.
BG_CUTOFF = 46
# Sources whose halves have to be brought together — see `pair_up`.
RECOMPOSE = {"sports_a"}
# Feather, in pixels, across the keyed edge — without it the flood fill leaves
# a hard black fringe that reads as a sticker outline on a light tile.
FEATHER = 2


def key_background(im: Image.Image) -> Image.Image:
    """Clear border-connected near-black, leaving enclosed dark areas alone."""
    w, h = im.size
    px = im.load()
    bg = bytearray(w * h)          # 1 = background
    seen = bytearray(w * h)
    q = deque()

    def consider(x, y):
        i = y * w + x
        if seen[i]:
            return
        seen[i] = 1
        r, g, b, _ = px[x, y]
        if max(r, g, b) < BG_CUTOFF:
            bg[i] = 1
            q.append((x, y))

    for x in range(w):
        consider(x, 0)
        consider(x, h - 1)
    for y in range(h):
        consider(0, y)
        consider(w - 1, y)

    while q:
        x, y = q.popleft()
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < w and 0 <= ny < h:
                consider(nx, ny)

    # Distance-to-background ramp gives the feather. One dilation pass per step
    # is enough at this size and avoids pulling in scipy.
    alpha = [0 if bg[i] else 255 for i in range(w * h)]
    edge = [i for i in range(w * h) if not bg[i] and (
        (i % w > 0 and bg[i - 1]) or (i % w < w - 1 and bg[i + 1])
        or (i >= w and bg[i - w]) or (i < w * (h - 1) and bg[i + w]))]
    for step in range(FEATHER):
        level = int(255 * (step + 1) / (FEATHER + 1))
        nxt = []
        for i in edge:
            alpha[i] = min(alpha[i], level)
            x, y = i % w, i // w
            for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if 0 <= nx < w and 0 <= ny < h:
                    j = ny * w + nx
                    if not bg[j] and alpha[j] == 255:
                        nxt.append(j)
        edge = nxt

    out = im.copy()
    out.putalpha(Image.frombytes("L", (w, h), bytes(bytearray(alpha))))
    return out


def pair_up(im: Image.Image) -> Image.Image:
    """Rearrange a two-object render into something tile-shaped.

    `sports_a` is a ball and a boot at opposite ends of a 2:1 canvas. Trimmed,
    that is a 2.5 aspect — far wider than anything else here, so sizing it by
    area leaves a sliver. The sheet dodges this by cropping the two objects into
    separate rectangles and placing them itself; this does the same, stacking
    them on a diagonal (boot low and leading, ball high and trailing) to land
    near the 1.3 aspect the sheet's own box uses.

    The split is found from the art, not taken at the midpoint — the gap here
    sits at 39% and halving the image cuts straight through the boot.
    """
    alpha = im.split()[3].load()
    w, h = im.size
    filled = [any(alpha[x, y] > 12 for y in range(0, h, 3)) for x in range(w)]

    # Widest empty column run that is not at either end.
    best, run = None, None
    for x in range(w + 1):
        if x < w and not filled[x]:
            run = run or x
        elif run is not None:
            if run > 0 and x < w and (best is None or x - run > best[1] - best[0]):
                best = (run, x)
            run = None
    if best is None:
        return im

    cut = (best[0] + best[1]) // 2
    first = im.crop((0, 0, cut, h))
    second = im.crop((cut, 0, w, h))
    first = first.crop(first.getbbox())
    second = second.crop(second.getbbox())

    # The wider object leads at the bottom; the other rides above and behind.
    low, high = (second, first) if second.width >= first.width else (first, second)
    overlap_x = int(min(low.width, high.width) * 0.32)
    overlap_y = int(max(low.height, high.height) * 0.65)

    out_w = low.width + high.width - overlap_x
    out_h = max(high.height, overlap_y + low.height)
    out = Image.new("RGBA", (out_w, out_h), (0, 0, 0, 0))
    out.alpha_composite(high, (out_w - high.width, 0))
    out.alpha_composite(low, (0, out_h - low.height))
    return out


def build(path: Path, name: str) -> tuple:
    im = Image.open(path).convert("RGBA")
    keyed = False
    if min(im.getdata(3)) == 255:            # flattened onto the sheet
        im = key_background(im)
        keyed = True

    box = im.getbbox()
    if box is None:
        sys.exit(f"{name}: nothing left after keying")
    im = im.crop(box)

    if name in RECOMPOSE:
        im = pair_up(im)

    scale = TARGET / max(im.size)
    if scale < 1:
        im = im.resize((max(1, round(im.width * scale)),
                        max(1, round(im.height * scale))), Image.LANCZOS)

    folder = OUT / f"cat_{name}.imageset"
    folder.mkdir(parents=True, exist_ok=True)
    im.save(folder / f"cat_{name}.png")
    (folder / "Contents.json").write_text(json.dumps({
        "images": [{"idiom": "universal", "filename": f"cat_{name}.png"}],
        "info": {"author": "xcode", "version": 1},
    }, indent=2) + "\n")
    return im.size, keyed


def main():
    print(f"{'asset':<18}{'size':<12}{'aspect':<9}source")
    for slug in SLUGS:
        for variant in ("a", "b"):
            name = f"{slug}_{variant}"
            src = SRC / f"{name}.png"
            if not src.exists():
                sys.exit(f"missing source {src}")
            (w, h), keyed = build(src, name)
            print(f"cat_{name:<14}{w}x{h:<8}{w / h:<9.3f}"
                  f"{'keyed' if keyed else 'alpha'}")


if __name__ == "__main__":
    main()
