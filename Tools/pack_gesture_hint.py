#!/usr/bin/env python3
"""Pack the gesture-hint exports into the app's two dotLotties.

    python3 Tools/pack_gesture_hint.py

Takes `Tools/ae/gesture_hint/gesture_{down,up}.json` — written by
`Tools/ae/export_gesture_hint.jsx` from the GESTURE_DOWN / GESTURE_UP comps —
and the planes they reference, and writes

    GyroQR/hint_hand_pull_down.lottie
    GyroQR/hint_hand_swipe_up.lottie

each a dotLottie archive (manifest, one animation, lossless WebP images),
after the same Lottie-safety audit the rays get.
"""

import io
import json
import os
import sys
import zipfile

from PIL import Image

from pack_account_rays import audit

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "ae", "gesture_hint")
APP = os.path.join(HERE, "..", "GyroQR")

JOBS = [("gesture_down.json", "report_down.json", "hint_hand_pull_down"),
        ("gesture_up.json", "report_up.json", "hint_hand_swipe_up")]


def pack(src, report, name):
    anim = json.load(open(os.path.join(SRC, src)))
    rep = json.load(open(os.path.join(SRC, report)))
    for note in rep.get("notes", []):
        print("  exporter:", note)
    problems = audit(anim)
    if problems:
        print("not Lottie-safe:\n  " + "\n  ".join(problems))
        sys.exit(1)
    images = {}
    for a in anim["assets"]:
        im = Image.open(os.path.join(SRC, a["p"])).convert("RGBA")
        buf = io.BytesIO()
        im.save(buf, "WEBP", lossless=True, quality=100, method=6)
        webp = os.path.splitext(a["p"])[0] + ".webp"
        images[webp] = buf.getvalue()
        a["p"], a["u"], a["e"] = webp, "/images/", 0
    out = os.path.join(APP, name + ".lottie")
    manifest = {"version": "1", "generator": "GyroQR/Tools/pack_gesture_hint.py",
                "author": "GyroQR", "animations": [{"id": name}]}
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("manifest.json", json.dumps(manifest))
        z.writestr(f"animations/{name}.json", json.dumps(anim, separators=(",", ":")))
        for n, data in images.items():
            z.writestr("images/" + n, data, compress_type=zipfile.ZIP_STORED)
    print(f"wrote {os.path.relpath(out)}  {len(anim['layers'])} layers, "
          f"{anim['op']} frames at {anim['fr']}fps, {os.path.getsize(out) // 1024}KB")


if __name__ == "__main__":
    for job in JOBS:
        pack(*job)
