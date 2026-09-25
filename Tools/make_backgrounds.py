#!/usr/bin/env python3
"""Build the per-skin background imagesets.

Source: `Card skins & bg` (849:58131) — one authored 973 × 1616 backdrop per
skin, exported at 1.5× so the displayed region lands at native @3x. Each
backdrop is the rounded-rectangle *behind* the card in its group, exported on
its own; exporting the group instead would bake the card in.

Eighteen of the twenty-two nodes are named for their skin (`03-silver 2`,
`10-yellow-plush 2`). The other four are `exec-<uuid>`, and those were matched
by rendering each group — the card sitting on the backdrop identifies it — then
confirming by elimination against the four missing numbers: 11 lego, 13 green
croc leather, 15 green glass, 20 blue croc.

PNG is the wrong container here. These are photographic textures and the
twenty-two come to 106MB as PNG, which is most of a minute added to every clean
build for a prototype. They are fully opaque, so JPEG costs nothing but a few
bytes of chroma and lands around 8MB for the set.

Run from the project root:  python3 Tools/make_backgrounds.py
"""

from pathlib import Path
import json
import sys

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "Tools" / "bg_src"
OUT = ROOT / "GyroQR" / "Assets.xcassets"

COUNT = 22
# The stage is 375 × 812 and these fill by height, so the visible strip is
# 812 × 0.602 = 489pt wide. At @3x that is 1467 × 2436 — the source is already
# within a few pixels, so nothing is resampled.
MAX_HEIGHT = 2436
QUALITY = 88


def build(n: int) -> tuple:
    src = SRC / f"bg_{n:02d}.png"
    if not src.exists():
        sys.exit(f"missing source {src}")
    im = Image.open(src).convert("RGB")

    if im.height > MAX_HEIGHT:
        scale = MAX_HEIGHT / im.height
        im = im.resize((round(im.width * scale), MAX_HEIGHT), Image.LANCZOS)

    folder = OUT / f"bg_{n:02d}.imageset"
    folder.mkdir(parents=True, exist_ok=True)
    # Any stale PNG from an earlier run would win over the JPEG in the catalog.
    for old in folder.glob("*.png"):
        old.unlink()
    path = folder / f"bg_{n:02d}.jpg"
    im.save(path, "JPEG", quality=QUALITY, optimize=True, progressive=True)
    (folder / "Contents.json").write_text(json.dumps({
        "images": [{"idiom": "universal", "filename": path.name}],
        "info": {"author": "xcode", "version": 1},
    }, indent=2) + "\n")
    return im.size, path.stat().st_size


def main():
    total = 0
    for n in range(1, COUNT + 1):
        (w, h), size = build(n)
        total += size
        print(f"bg_{n:02d}  {w}x{h}  {size / 1024:6.0f} KB")
    print(f"total {total / 1024 / 1024:.1f} MB")


if __name__ == "__main__":
    main()
