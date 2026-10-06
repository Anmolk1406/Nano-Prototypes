#!/usr/bin/env python3
"""Rasterise the gesture-hint parts for After Effects.

    python3 Tools/build_gesture_hint_layers.py

The skin picker's two gesture hints, Figma `gesture animate - down`
(1060:19705) and `gesture animate - up` (1060:19706): a finger trail, a touch
dot, three chevrons and the chrome hand. The two frames are the same parts —
"up" is "down" mirrored top to bottom, with the hand kept upright — so one
set of planes serves both comps.

The Figma exports render onto opaque #141414, so the parts are drawn here
from the design's own numbers instead, with real alpha:

    trail   Rectangle 1891598610 — 24 × 113.61, bottom corners 30 (so 12),
            white, radial: 80% alpha to 22.3% of the radius then clear at
            100%, centred (12, 110.85) with radii 33.47 × 87.00; rect at 80%.
    dot     Ellipse 24672 — 18, white, linear alpha 0 at y 13.17 → 1 at 1.50.
    chev    Group 2147241970 — the three chevron paths at 90%.
    hand    image 1583515876 — the supplied 1000px PNG (figma/hand_down.png),
            resized to 3x of its 86.28pt so it stays sharp on a 3x screen
            when the 2x comp is scaled up.

At 2x (the comp's scale) apart from the hand. `layout.json` records sizes
and the points `build_gesture_hint.jsx` needs.
"""

import json
import os
import re

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "ae", "gesture_hint")
FIG = os.path.join(OUT, "figma")
S = 2          # comp pixels per point
SS = 8         # supersampling for the hand-drawn shapes


def trail():
    w, h = 24.0, 113.6129
    W, H = int(round(w * S)), int(round(h * S))
    ys, xs = np.mgrid[0:H, 0:W]
    x = (xs + 0.5) / S
    y = (ys + 0.5) / S
    t = np.sqrt(((110.85 - y) / 86.998) ** 2 + ((x - 12) / 33.471) ** 2)
    a = np.where(t <= 0.22323, 0.8, 0.8 * np.clip((1 - t) / (1 - 0.22323), 0, 1)) * 0.8
    # Bottom corners: radius 30 clamps to half the width.
    r = w / 2
    cy = h - r
    inside = np.ones_like(a)
    low = y > cy
    d = np.hypot(x - r, y - cy)
    inside[low] = np.clip(r - d[low] + 0.5 / S, 0, 1)
    a = a * inside
    img = np.zeros((H, W, 4), np.uint8)
    img[..., :3] = 255
    img[..., 3] = np.clip(a * 255, 0, 255).astype(np.uint8)
    return Image.fromarray(img)


def dot():
    n = 18
    N = n * S * SS
    ys, xs = np.mgrid[0:N, 0:N]
    x = (xs + 0.5) / (S * SS)
    y = (ys + 0.5) / (S * SS)
    cov = (np.hypot(x - 9, y - 9) <= 9).astype(float)
    g = np.clip((13.1731 - y) / (13.1731 - 1.49609), 0, 1)
    a = cov * g
    img = np.zeros((N, N, 4), np.float32)
    img[..., :3] = 255
    img[..., 3] = a * 255
    im = Image.fromarray(img.astype(np.uint8))
    # Premultiplied downsample, so the clear edge doesn't darken.
    return im.resize((n * S, n * S), Image.LANCZOS)


def chevrons():
    svg = open(os.path.join(FIG, "chev_down.svg")).read()
    w, h = 6.464, 15.7677
    W, H = int(np.ceil(w * S)) + 2, int(np.ceil(h * S)) + 2
    big = Image.new("L", (W * SS, H * SS), 0)
    d = ImageDraw.Draw(big)
    for path in re.findall(r'<path d="([^"]+)"', svg):
        # Absolute M / L / H / V / Z — all these three use.
        toks = re.findall(r"[MLHVZ]|-?\d*\.?\d+(?:e-?\d+)?", path)
        pts, cx, cy, i, cmd = [], 0.0, 0.0, 0, None
        while i < len(toks):
            if toks[i].isalpha():
                cmd = toks[i]; i += 1
                continue
            if cmd in "ML":
                cx, cy = float(toks[i]), float(toks[i + 1]); i += 2
            elif cmd == "H":
                cx = float(toks[i]); i += 1
            elif cmd == "V":
                cy = float(toks[i]); i += 1
            pts.append(((cx * S + 1) * SS, (cy * S + 1) * SS))
        d.polygon(pts, fill=255)
    a = np.asarray(big.resize((W, H), Image.LANCZOS), float) * 0.9
    img = np.zeros((H, W, 4), np.uint8)
    img[..., :3] = 255
    img[..., 3] = a.astype(np.uint8)
    return Image.fromarray(img)


def hand():
    im = Image.open(os.path.join(FIG, "hand_down.png")).convert("RGBA")
    side = int(round(86.277 * 3))
    # Premultiply for the resize, so the transparent black doesn't halo.
    a = np.asarray(im, float) / 255
    pm = np.dstack([a[..., :3] * a[..., 3:], a[..., 3:]])
    pm = Image.fromarray((pm * 255).astype(np.uint8)).resize((side, side), Image.LANCZOS)
    b = np.asarray(pm, float) / 255
    rgb = np.where(b[..., 3:] > 0, b[..., :3] / np.maximum(b[..., 3:], 1e-6), 0)
    return Image.fromarray((np.dstack([np.clip(rgb, 0, 1), b[..., 3:]]) * 255).astype(np.uint8)), side


def main():
    os.makedirs(OUT, exist_ok=True)
    parts = {"trail": trail(), "dot": dot(), "chev": chevrons()}
    for k, im in parts.items():
        im.save(os.path.join(OUT, f"{k}.png"), optimize=True)
    h, side = hand()
    h.save(os.path.join(OUT, "hand.png"), optimize=True)

    # Where the fingertip is on the hand image. In the design the hand sits
    # in a 117.857 box turned −30° about its centre, and the fingertip is on
    # the dot's centre — (38.93, 101.61) against a box centre of
    # (58.93, 121.67) in `down`. Un-turning that offset lands it in the
    # image; `up` gives the same point to within a point.
    k = 86.277 / 1000
    off = np.array([29.928 + 9 - 58.928, 92.613 + 9 - (62.74 + 58.928)])
    c, s = np.cos(np.radians(30)), np.sin(np.radians(30))
    un = np.array([off[0] * c - off[1] * s, off[0] * s + off[1] * c])   # rotate +30°
    tip_src = 500 + un / k
    layout = {
        "scale": S,
        "trail": list(parts["trail"].size),
        "dot": list(parts["dot"].size),
        "chev": list(parts["chev"].size),
        "hand": [side, side],
        # The hand's fingertip in hand.png's own pixels, and the plane's
        # scale to its design size at 2x.
        "handTip": [round(float(tip_src[0]) * side / 1000, 2), round(float(tip_src[1]) * side / 1000, 2)],
        "handScale": round(86.277 * S / side * 100, 3),
    }
    json.dump(layout, open(os.path.join(OUT, "layout.json"), "w"), indent=2)
    print(json.dumps(layout))


if __name__ == "__main__":
    main()
