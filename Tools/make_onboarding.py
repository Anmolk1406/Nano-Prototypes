#!/usr/bin/env python3
"""Rebuild the onboarding flow's assets from the designer's exports.

Two jobs, both of which have a trap in them:

1. **Splash clip.** The source is the After Effects render `Splash / Nano 2x
   1Oct.mp4` (H.264, 750 x 1624, 60 fps, 1.93s, ~16.6 Mbps, 3.9 MB). The
   designer's deliverable is a VP9 WebM, but iOS has no VP9 decoder: `AVPlayer`
   shows a silent black screen. So the bundle gets HEVC instead, tagged `hvc1`
   (the tag AVFoundation needs), at CRF 22 = 498 KB, VMAF 97.4 against a 99.1
   lossless ceiling. That matches the WebM (VP9 CRF 32, 417 KB, VMAF 97.5).
   The previous 2.8s cut (`Nano Splash new.mp4`) scored the same at these
   settings: HEVC ~560 KB / 97.0, WebM ~450 KB / 97.2. There is no alpha, so an opaque mp4 loses nothing. The clip's last frame is also saved as a still,
   because the email step's backdrop is exactly that frame.

2. **Interest icons.** Figma's per-node export of these came back with the
   tile's plate and a slice of its blue border baked in, because each one is a
   rectangle whose *fill* is a scaled crop of a shared reference sheet. Cutting
   the icons out of that sheet directly gives clean transparency; the sheet is a
   5 x 2 grid of icon-over-caption cells, so take the first occupied row band in
   each cell and the caption is left behind.

Usage:  python3 Tools/make_onboarding.py [--splash FILE]

`--splash` defaults to the AE render in the designer's drop folder. The icon
step reads the reference sheets already committed under
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
SPLASH_DEFAULT = os.path.expanduser(
    "~/Desktop/Project - September/Nano/Splash / Nano 2x 1Oct.mp4")
INTRO_DEFAULT = os.path.expanduser(
    "~/Desktop/Project - September/Nano/Nano Wallet / Skins Intro/Nano Wallet / Skins Intro.mov")
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


def build_splash(src):
    if not os.path.exists(src):
        print(f"  skip splash: {src} not found")
        return
    os.makedirs(RES, exist_ok=True)
    mp4 = os.path.join(RES, "splash_burst.mp4")
    subprocess.run(
        ["ffmpeg", "-y", "-loglevel", "error", "-i", src,
         "-c:v", "libx265", "-crf", "22", "-preset", "slow", "-tag:v", "hvc1",
         "-x265-params", "log-level=error", "-pix_fmt", "yuv420p",
         "-an", "-movflags", "+faststart", mp4],
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


def build_intro(src):
    """The skins intro, with its alpha: HEVC-with-alpha (hvc1), which iOS
    plays transparent on a bare AVPlayerLayer. ffmpeg cannot decode the alpha
    layer back, so check it with AVFoundation, not ffprobe."""
    if not os.path.exists(src):
        print(f"  skip intro: {src} not found")
        return
    out = os.path.join(RES, "skins_intro.mov")
    subprocess.run(
        ["ffmpeg", "-y", "-loglevel", "error", "-i", src, "-map", "0:v",
         "-c:v", "hevc_videotoolbox", "-allow_sw", "1", "-alpha_quality", "0.75",
         "-b:v", "2500k", "-tag:v", "hvc1", "-pix_fmt", "bgra",
         "-color_primaries", "bt709", "-color_trc", "bt709", "-colorspace", "bt709",
         "-an", "-write_tmcd", "0", "-movflags", "+faststart", out],
        check=True)
    print(f"  skins_intro.mov  {os.path.getsize(out) // 1024} KB")


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
    ap.add_argument("--splash", default=SPLASH_DEFAULT, help="splash clip to bundle")
    ap.add_argument("--intro", default=INTRO_DEFAULT, help="skins intro (with alpha) to bundle")
    args = ap.parse_args()

    print("splash:")
    build_splash(args.splash)
    print("skins intro:")
    build_intro(args.intro)
    print("interest icons:")
    build_icons()
