"""The parent flow's shared header background, from its 3x node export.

Figma clipped the export to the frame's 40pt device corners and matted the
cut-away corners onto its dark canvas. Each corner is filled from the pixels
just inside the curve, row by row, so a page drawn square — or scaled down
under the next with rounded corners of its own — shows no dark wedge.
"""
import json, os
import numpy as np
from PIL import Image

CAT = "/Users/anmkumar/Nano/GyroQR/GyroQR/Assets.xcassets"

def save(arr, name):
    d = os.path.join(CAT, f"{name}.imageset"); os.makedirs(d, exist_ok=True)
    Image.fromarray(arr).save(os.path.join(d, f"{name}.png"), optimize=True)
    json.dump({"images": [{"filename": f"{name}.png", "idiom": "universal", "scale": "3x"}],
               "info": {"author": "xcode", "version": 1}}, open(os.path.join(d, "Contents.json"), "w"), indent=2)

a = np.asarray(Image.open("shared/header_bg3x.png").convert("RGB")).copy()
H, W = a.shape[:2]
from scipy.ndimage import binary_dilation
dark0 = np.abs(a.astype(int) - 30).max(-1) < 6
# Everything within 4px of the canvas is contaminated by its antialiasing.
bad = binary_dilation(dark0, iterations=4)
bad[140:] = False                       # only the two top corners
for y in np.nonzero(bad.any(1))[0]:
    row = bad[y]
    good = np.nonzero(~row)[0]
    for x in np.nonzero(row)[0]:
        a[y, x] = a[y, good[np.argmin(np.abs(good - x))]]
dark = (np.abs(a.astype(int) - 30).max(-1) < 6).sum()
print("dark pixels left:", dark)
save(a, "parent_header_bg")
