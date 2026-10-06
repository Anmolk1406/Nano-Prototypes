#!/usr/bin/env python3
"""Pack the After Effects export into `GyroQR/Account/acct_rays.lottie`.

    python3 Tools/pack_account_rays.py

Takes `Tools/ae/account_rays/acct_rays.json` — written by
`Tools/ae/export_lottie.jsx` from the ACCT_RAYS comp — and the planes it
references, and zips them as a dotLottie archive, the same shape as the
onboarding's `mail_otp_intro.lottie`:

    manifest.json
    animations/acct_rays.json
    images/<plane>.webp

The planes go in as *lossless* WebP. The animation's last frame is meant to
be the design's backdrop to within 1/255, and a lossy encode would spend that
margin on the rays' fine gradients.

Before writing, it checks the JSON for what Lottie cannot play — expressions,
effects, blend modes, merge paths — so a hand edit in AE that sneaks one back
in fails here and not on the device.
"""

import io
import json
import os
import sys
import zipfile
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "ae", "account_rays")
OUT = os.path.join(HERE, "..", "GyroQR", "Account", "acct_rays.lottie")


def audit(anim):
    problems = []

    def walk(node, where):
        if isinstance(node, dict):
            if "x" in node and isinstance(node["x"], str):
                problems.append(f"expression at {where}")
            if node.get("ty") == "mm":
                problems.append(f"merge paths at {where}")
            for k, v in node.items():
                walk(v, f"{where}.{k}")
        elif isinstance(node, list):
            for i, v in enumerate(node):
                walk(v, f"{where}[{i}]")

    for L in anim["layers"]:
        if L.get("ef"):
            problems.append(f"effects on {L['nm']}")
        if L.get("bm", 0):
            problems.append(f"blend mode on {L['nm']}")
        walk(L, L["nm"])
    return problems


def gradient_stops(png, start, end, tol=1.0 / 255):
    """Read a linear gradient's colours off its solo render.

    ExtendScript cannot read gradient colours, so the exporter renders the
    layer alone and hands over the gradient's start and end in comp pixels.
    Sampled densely along that line and then thinned to the fewest stops that
    reproduce every sample to `tol` — AE's midpoints and any extra stops come
    out as extra Lottie stops, not as an approximation.
    """
    import numpy as np
    im = np.asarray(Image.open(os.path.join(SRC, png)).convert("RGB")).astype(float) / 255
    H, W = im.shape[:2]
    n = 257
    ts = np.linspace(0, 1, n)
    xs = np.clip(start[0] + (end[0] - start[0]) * ts, 0, W - 1)
    ys = np.clip(start[1] + (end[1] - start[1]) * ts, 0, H - 1)
    # A 5px average across the line, to lose the render's dither.
    cols = []
    for x, y in zip(xs, ys):
        x0, x1 = int(max(0, x - 2)), int(min(W, x + 3))
        cols.append(im[int(round(y)), x0:x1].mean(0))
    cols = np.array(cols)

    keep, last = [0], 0
    for j in range(2, n):
        seg = cols[last:j + 1]
        u = (ts[last:j + 1] - ts[last]) / (ts[j] - ts[last])
        lin = cols[last] + (cols[j] - cols[last]) * u[:, None]
        if np.abs(lin - seg).max() > tol:
            keep.append(j - 1)
            last = j - 1
    keep.append(n - 1)
    flat = []
    for k in keep:
        flat += [round(float(ts[k]), 4)] + [round(float(c), 4) for c in cols[k]]
    return len(keep), flat


def main():
    anim = json.load(open(os.path.join(SRC, "acct_rays.json")))
    report = json.load(open(os.path.join(SRC, "export_report.json")))
    for note in report.get("notes", []):
        print("  exporter:", note)

    # Fill in sampled gradients.
    requests = {g["file"]: g for g in report.get("gradients", [])}

    def fill(node):
        if isinstance(node, dict):
            if node.get("ty") == "gf" and "_sample" in node:
                g = requests[node.pop("_sample")["file"]]
                count, flat = gradient_stops(g["file"], g["start"], g["end"])
                node["g"] = {"p": count, "k": {"a": 0, "k": flat}}
                print(f"  gradient '{node['nm']}' on {g['layer']}: {count} stops, "
                      f"top {flat[1:4]}  bottom {flat[-3:]}")
            for v in node.values():
                fill(v)
        elif isinstance(node, list):
            for v in node:
                fill(v)
    fill(anim["layers"])
    problems = audit(anim)
    if problems:
        print("not Lottie-safe:\n  " + "\n  ".join(problems))
        sys.exit(1)

    images = {}
    for a in anim["assets"]:
        if "p" not in a:
            continue
        im = Image.open(os.path.join(SRC, a["p"])).convert("RGBA")
        buf = io.BytesIO()
        im.save(buf, "WEBP", lossless=True, quality=100, method=6)
        name = os.path.splitext(a["p"])[0] + ".webp"
        images[name] = buf.getvalue()
        a["p"], a["u"], a["e"] = name, "/images/", 0
        print(f"  {name:22s} {im.size[0]}x{im.size[1]}  {len(buf.getvalue()) // 1024}KB")

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    manifest = {"version": "1", "generator": "GyroQR/Tools/pack_account_rays.py",
                "author": "GyroQR", "animations": [{"id": "acct_rays"}]}
    with zipfile.ZipFile(OUT, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("manifest.json", json.dumps(manifest))
        z.writestr("animations/acct_rays.json", json.dumps(anim, separators=(",", ":")))
        for name, data in images.items():
            z.writestr("images/" + name, data, compress_type=zipfile.ZIP_STORED)

    keys = 0
    def count(node):
        nonlocal keys
        if isinstance(node, dict):
            if node.get("a") == 1:
                keys += len(node["k"])
            for v in node.values():
                count(v)
        elif isinstance(node, list):
            for v in node:
                count(v)
    count(anim["layers"])
    print(f"  {len(anim['layers'])} layers, {anim['op']} frames at {anim['fr']}fps, "
          f"{keys} keyframes after simplification")
    print(f"wrote {os.path.relpath(OUT)}  {os.path.getsize(OUT) // 1024}KB")


if __name__ == "__main__":
    main()
