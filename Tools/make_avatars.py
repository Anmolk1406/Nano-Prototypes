#!/usr/bin/env python3
"""Build the avatar imagesets from the `Avatars` section (905:61038).

Fifteen circular avatars, 3 rows x 5 columns, each a 419.8pt frame holding a
coloured Background circle and a character Image.

Sliced out of **one** export of the whole section rather than fetched per
avatar. The section's `rawImages` are capped at 20 and arrive unlabelled — the
trap that cost real time on the category assets — and there are more than 20
source images under this node, so that route both truncates and scrambles.
One composed render of the section has neither problem: the coloured circle is
already behind its character, and the grid is regular.

The export is **not** the section's stated bounds. It comes back 8610 x 5250
where 2790 x 1670 at 3x would be 8370 x 5010 — 40pt of margin per side, dark
like the section itself, so there is no transparent edge to measure from.
Rather than guess the offset, the grid is found by projection: count non-dark
pixels down each column and across each row, and the five column humps and
three row humps are the circles. That agrees with the design to a quarter of a
pixel (detected column step 1574.25 against 524.802 x 3 = 1574.41) and survives
a re-export at any padding or scale.

Run from the project root:  python3 Tools/make_avatars.py
"""

from pathlib import Path
import json
import sys

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "Tools" / "avatar_src" / "section.png"
OUT = ROOT / "GyroQR" / "Assets.xcassets"

COLS, ROWS = 5, 3
# Frame size in the design, and the scale the section was exported at.
FRAME_PT = 419.8021545410156
SCALE = 3
# 280pt hero at @3x. Anything larger is carried for nothing — these are only
# ever drawn at 280 on the avatar screen and far smaller in the row.
TARGET = 840


def grid(im):
    """Circle centres, found by projection rather than from the export's bounds."""
    w, h = im.size
    px = im.convert("RGB").load()

    def nondark(p, tol=18):
        return not all(abs(p[i] - 20) <= tol for i in range(3))

    def humps(counts, step):
        thresh = max(counts) * 0.18
        out, start = [], None
        for i, v in enumerate(counts):
            if v > thresh and start is None:
                start = i
            elif v <= thresh and start is not None:
                out.append((start * step, (i - 1) * step))
                start = None
        if start is not None:
            out.append((start * step, (len(counts) - 1) * step))
        return [(a + b) // 2 for a, b in out if b - a > 300]

    xs = humps([sum(1 for y in range(0, h, 7) if nondark(px[x, y]))
                for x in range(0, w, 3)], 3)
    ys = humps([sum(1 for x in range(0, w, 7) if nondark(px[x, y]))
                for y in range(0, h, 3)], 3)
    if len(xs) != COLS or len(ys) != ROWS:
        sys.exit(f"found {len(xs)} columns and {len(ys)} rows, expected {COLS}x{ROWS}")
    return xs, ys


def main():
    if not SRC.exists():
        sys.exit(f"missing {SRC} — re-export node 905:61038 at scale {SCALE}")
    im = Image.open(SRC).convert("RGBA")
    xs, ys = grid(im)
    d = round(FRAME_PT * SCALE)
    print(f"columns {xs}\nrows {ys}\ntile {d}px -> {TARGET}px")

    # One circular mask for all fifteen. The corners are the section's dark
    # fill, not part of any avatar, and cutting them here means the asset is
    # the avatar rather than an avatar in a dark box — the view clips to a
    # circle anyway, but a stray unclipped use would show the box.
    mask = Image.new("L", (TARGET, TARGET), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, TARGET - 1, TARGET - 1), fill=255)

    n = 0
    total = 0
    for r, cy in enumerate(ys):
        for c, cx in enumerate(xs):
            n += 1
            tile = im.crop((cx - d // 2, cy - d // 2, cx - d // 2 + d, cy - d // 2 + d))
            tile = tile.resize((TARGET, TARGET), Image.LANCZOS)
            tile.putalpha(mask)

            folder = OUT / f"onb_av_{n}.imageset"
            folder.mkdir(parents=True, exist_ok=True)
            for old in list(folder.glob("*.png")) + list(folder.glob("*.jpg")):
                old.unlink()
            path = folder / f"onb_av_{n}.png"
            tile.save(path, "PNG", optimize=True)
            (folder / "Contents.json").write_text(json.dumps({
                "images": [{"idiom": "universal", "filename": path.name}],
                "info": {"author": "xcode", "version": 1},
            }, indent=2) + "\n")
            size = path.stat().st_size
            total += size
            print(f"  onb_av_{n:<2d} r{r+1}c{c+1}  {size/1024:6.0f} KB")
    print(f"total {total/1024/1024:.1f} MB")


if __name__ == "__main__":
    main()
