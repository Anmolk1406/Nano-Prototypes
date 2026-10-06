#!/usr/bin/env python3
"""Pack the After Effects export into `GyroQR/skin_confirm_rays.lottie`.

    python3 Tools/pack_confirm_rays.py

Takes `Tools/ae/confirm_rays/confirm_rays.json` — written by
`Tools/ae/export_confirm_rays.jsx` from the CONFIRM_RAYS comp — and the four
ray planes it references, and zips them as a dotLottie archive:

    manifest.json
    animations/confirm_rays.json
    images/ray_<n>.webp

Lossless WebP, like the account rays, and the same Lottie-safety audit
(`pack_account_rays.audit`) before anything is written.
"""

import io
import json
import os
import sys
import zipfile

from PIL import Image

from pack_account_rays import audit

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "ae", "confirm_rays")
OUT = os.path.join(HERE, "..", "GyroQR", "skin_confirm_rays.lottie")


def main():
    anim = json.load(open(os.path.join(SRC, "confirm_rays.json")))
    report = json.load(open(os.path.join(SRC, "export_report.json")))
    for note in report.get("notes", []):
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
        name = os.path.splitext(a["p"])[0] + ".webp"
        images[name] = buf.getvalue()
        a["p"], a["u"], a["e"] = name, "/images/", 0
        print(f"  {name:14s} {im.size[0]}x{im.size[1]}  {len(buf.getvalue()) // 1024}KB")

    manifest = {"version": "1", "generator": "GyroQR/Tools/pack_confirm_rays.py",
                "author": "GyroQR", "animations": [{"id": "confirm_rays"}]}
    with zipfile.ZipFile(OUT, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("manifest.json", json.dumps(manifest))
        z.writestr("animations/confirm_rays.json", json.dumps(anim, separators=(",", ":")))
        for name, data in images.items():
            z.writestr("images/" + name, data, compress_type=zipfile.ZIP_STORED)
    print(f"  {len(anim['layers'])} layers, {anim['op']} frames at {anim['fr']}fps")
    print(f"wrote {os.path.relpath(OUT)}  {os.path.getsize(OUT) // 1024}KB")


if __name__ == "__main__":
    main()
