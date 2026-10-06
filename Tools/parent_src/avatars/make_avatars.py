"""Give the gender cards' hexagon avatars real alpha.

The node exports (1015:44867 boy, 1015:44879 girl) come back matted onto
their card's fill, and selecting a card swaps that fill, so each avatar is cut
to the hexagon it lives in: the design's own path (Polygon 19, with its
stroke), rasterised at 3× with 4× supersampling.
"""
import re, json, os
import numpy as np
from PIL import Image, ImageDraw

def path_points(d, steps=24):
    toks = re.findall(r"[MCLHVZmclhvz]|-?[\d.]+(?:e-?\d+)?", d)
    pts, i, cur, cmd = [], 0, (0.0, 0.0), None
    def num():
        nonlocal i; v = float(toks[i]); i += 1; return v
    while i < len(toks):
        if re.match(r"[A-Za-z]", toks[i]): cmd = toks[i]; i += 1
        if cmd == "M" or cmd == "L": cur = (num(), num()); pts.append(cur)
        elif cmd == "H": cur = (num(), cur[1]); pts.append(cur)
        elif cmd == "V": cur = (cur[0], num()); pts.append(cur)
        elif cmd == "C":
            p1 = (num(), num()); p2 = (num(), num()); p3 = (num(), num()); p0 = cur
            for k in range(1, steps + 1):
                t = k / steps; a = (1 - t) ** 3; b = 3 * (1 - t) ** 2 * t; c = 3 * (1 - t) * t * t; e = t ** 3
                pts.append((a*p0[0]+b*p1[0]+c*p2[0]+e*p3[0], a*p0[1]+b*p1[1]+c*p2[1]+e*p3[1]))
            cur = p3
        elif cmd in "Zz": pass
    return pts

def cut(export, svg, out, name, catalog):
    im = np.asarray(Image.open(export).convert("RGB")).astype(float)
    H, W = im.shape[:2]
    d = re.search(r' d="([^"]+)"', open(svg).read()).group(1)
    sw = float(re.search(r'stroke-width="([\d.]+)"', open(svg).read()).group(1))
    # The export's box is the group's plus the stroke's outer half.
    ss = 4; S = W / float(re.search(r'width="([\d.]+)"', open(svg).read()).group(1))
    mask = Image.new("L", (W * ss, H * ss), 0)
    dr = ImageDraw.Draw(mask)
    pts = [(x * S * ss, y * S * ss) for x, y in path_points(d)]
    dr.polygon(pts, fill=255)
    dr.line(pts + [pts[0]], fill=255, width=max(1, int(sw * S * ss)))
    a = np.asarray(mask.resize((W, H), Image.LANCZOS)).astype(float) / 255
    rgba = np.dstack([im / 255, a])
    d_ = os.path.join(catalog, f"{name}.imageset"); os.makedirs(d_, exist_ok=True)
    Image.fromarray((np.clip(rgba, 0, 1) * 255 + 0.5).astype(np.uint8)).save(os.path.join(d_, f"{name}.png"))
    json.dump({"images": [{"filename": f"{name}.png", "idiom": "universal", "scale": "3x"}],
               "info": {"author": "xcode", "version": 1}}, open(os.path.join(d_, "Contents.json"), "w"), indent=2)
    print(name, W, H, "coverage %.2f" % a.mean())

CAT = "/Users/anmkumar/Nano/GyroQR/GyroQR/Assets.xcassets"
cut("boy3x.png", "poly_a.svg", None, "parent_avatar_boy", CAT)
cut("girl3x.png", "g_poly_a.svg", None, "parent_avatar_girl", CAT)
