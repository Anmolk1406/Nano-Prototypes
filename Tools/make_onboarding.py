#!/usr/bin/env python3
"""Rebuild the onboarding flow's assets from the designer's exports.

Two jobs, both of which have a trap in them:

1. **Splash clip.** The export is VP9-in-WebM. iOS has no VP9 decoder at all, so
   `AVPlayer` shows nothing and reports no error worth reading — the screen is
   just black. Transcode to H.264. The source is `yuv420p` with no alpha, so an
   opaque mp4 loses nothing. The clip's last frame is also saved as a still,
   because the email step's backdrop is exactly that frame.

2. **Interest icons.** Figma's per-node export of these came back with the
   tile's plate and a slice of its blue border baked in, because each one is a
   rectangle whose *fill* is a scaled crop of a shared reference sheet. Cutting
   the icons out of that sheet directly gives clean transparency; the sheet is a
   5 x 2 grid of icon-over-caption cells, so take the first occupied row band in
   each cell and the caption is left behind.

Usage:  python3 Tools/make_onboarding.py [--src DIR]

`--src` defaults to the designer's drop folder. Only the splash step needs it;
the icon step reads the reference sheets already committed under
`Tools/onboarding_src/`.
"""

import argparse
import json
import os
import shutil
import subprocess
import sys

try:
    from PIL import Image
except ImportError:
    sys.exit("Pillow required:  python3 -m pip install pillow")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CAT = os.path.join(ROOT, "GyroQR", "Assets.xcassets")
RES = os.path.join(ROOT, "GyroQR", "Onboarding", "Res")
SRC_DEFAULT = os.path.expanduser(
    "~/Desktop/Project - September/Nano/App Assets renders")
SHEETS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "onboarding_src")

# Cells on the reference sheet, left to right, top row then bottom.
#   1 Gaming  2 Art & Drawing  3 Sports  4 Music  5 Anime & Cartoons
#   6 Fashion & Sneakers  7 Science  8 Building & LEGO  9 Coding  10 Animals
ICONS = {
    "art":     ("sheet_a.png", 2),
    "gaming":  ("sheet_a.png", 1),
    "sports":  ("sheet_a.png", 3),
    "fashion": ("sheet_a.png", 6),
    "lego":    ("sheet_a.png", 8),
    "pets":    ("sheet_a.png", 10),
    "science": ("sheet_a.png", 7),
    # The anime cell on sheet A is a television; sheet B carries the character.
    "anime":   ("sheet_b.png", 5),
}


def imageset(name, src_path, vector=False, template=False):
    d = os.path.join(CAT, f"{name}.imageset")
    os.makedirs(d, exist_ok=True)
    ext = os.path.splitext(src_path)[1]
    if os.path.abspath(src_path) != os.path.abspath(os.path.join(d, name + ext)):
        shutil.copy(src_path, os.path.join(d, name + ext))
    entry = {"images": [{"idiom": "universal", "filename": name + ext}],
             "info": {"author": "xcode", "version": 1}}
    props = {}
    if vector:
        props["preserves-vector-representation"] = True
    if template:
        props["template-rendering-intent"] = "template"
    if props:
        entry["properties"] = props
    with open(os.path.join(d, "Contents.json"), "w") as f:
        json.dump(entry, f, indent=2)


def build_splash(src_dir):
    webm = os.path.join(src_dir, "Splash Setup - Burst 2.webm")
    if not os.path.exists(webm):
        print(f"  skip splash: {webm} not found")
        return
    os.makedirs(RES, exist_ok=True)
    mp4 = os.path.join(RES, "splash_burst.mp4")
    subprocess.run(
        ["ffmpeg", "-y", "-loglevel", "error", "-i", webm,
         "-c:v", "libx264", "-profile:v", "high", "-pix_fmt", "yuv420p",
         "-crf", "20", "-preset", "slow", "-an", "-movflags", "+faststart", mp4],
        check=True)
    print(f"  splash_burst.mp4  {os.path.getsize(mp4) // 1024} KB")

    # The still the email step sits on.
    tmp = os.path.join(RES, "_last.png")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-sseof", "-0.05",
                    "-i", mp4, "-frames:v", "1", tmp], check=True)
    hold = os.path.join(RES, "_splash_hold.jpg")
    Image.open(tmp).convert("RGB").save(hold, quality=92)
    imageset("splash_hold", hold)
    os.remove(tmp)
    os.remove(hold)
    print("  splash_hold      (email-step backdrop)")


def cut_icon(sheet_path, cell):
    """Return cell `cell` of the reference sheet, icon only."""
    im = Image.open(sheet_path).convert("RGBA")
    W, H = im.size
    cw, ch = W / 5, H / 2
    col, row = (cell - 1) % 5, (cell - 1) // 5
    c = im.crop((int(col * cw), int(row * ch), int((col + 1) * cw), int((row + 1) * ch)))

    # Occupied row bands: the icon is the first one, the caption the second.
    a = c.split()[3].point(lambda v: 255 if v > 25 else 0)
    px = a.load()
    bands, start = [], None
    for y in range(a.height + 1):
        on = y < a.height and any(px[x, y] for x in range(a.width))
        if on and start is None:
            start = y
        elif not on and start is not None:
            bands.append((start, y))
            start = None
    if not bands:
        raise SystemExit(f"{sheet_path} cell {cell}: nothing opaque found")
    y0, y1 = bands[0]
    band = c.crop((0, y0, c.width, y1))
    return band.crop(band.split()[3].point(lambda v: 255 if v > 25 else 0).getbbox())


def build_icons():
    for name, (sheet, cell) in ICONS.items():
        path = os.path.join(SHEETS, sheet)
        if not os.path.exists(path):
            print(f"  skip int_{name}: {sheet} not in Tools/onboarding_src/")
            continue
        out = cut_icon(path, cell)
        d = os.path.join(CAT, f"int_{name}.imageset")
        os.makedirs(d, exist_ok=True)
        dest = os.path.join(d, f"int_{name}.png")
        out.save(dest)
        imageset(f"int_{name}", dest)
        print("  int_%-8s %s" % (name, out.size))


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", default=SRC_DEFAULT, help="designer's export folder")
    args = ap.parse_args()

    print("splash:")
    build_splash(args.src)
    print("interest icons:")
    build_icons()
