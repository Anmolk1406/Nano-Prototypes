"""Copy the parent flow's bitmap assets into the asset catalog, unchanged."""
import json, os, shutil, sys
CAT = "/Users/anmkumar/Nano/GyroQR/GyroQR/Assets.xcassets"
for pair in sys.argv[1:]:
    src, name = pair.split("=")
    scale = "3x"
    if ":" in name: name, scale = name.split(":")
    d = os.path.join(CAT, f"{name}.imageset"); os.makedirs(d, exist_ok=True)
    shutil.copy(src, os.path.join(d, f"{name}.png"))
    json.dump({"images": [{"filename": f"{name}.png", "idiom": "universal", "scale": scale}],
               "info": {"author": "xcode", "version": 1}}, open(os.path.join(d, "Contents.json"), "w"), indent=2)
    print("added", name, scale, os.path.getsize(src) // 1024, "KB")
