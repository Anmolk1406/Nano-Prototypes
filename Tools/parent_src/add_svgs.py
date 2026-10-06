"""Copy the parent flow's plain icon SVGs into the asset catalog as vectors.

Only filter-free SVGs belong here — Xcode's SVG renderer ignores blur
filters, so anything with one is exported from Figma as a PNG instead.
"""
import json, os, shutil, sys
CAT = "/Users/anmkumar/Nano/GyroQR/GyroQR/Assets.xcassets"
def add(src, name):
    body = open(src).read()
    assert "<filter" not in body, f"{src} has a filter; export it as a PNG"
    d = os.path.join(CAT, f"{name}.imageset"); os.makedirs(d, exist_ok=True)
    shutil.copy(src, os.path.join(d, f"{name}.svg"))
    json.dump({"images": [{"filename": f"{name}.svg", "idiom": "universal"}],
               "info": {"author": "xcode", "version": 1},
               "properties": {"preserves-vector-representation": True}},
              open(os.path.join(d, "Contents.json"), "w"), indent=2)
    print("added", name)
for pair in sys.argv[1:]:
    src, name = pair.split("=")
    add(src, name)
