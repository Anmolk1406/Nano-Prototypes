#!/usr/bin/env python3
"""Render the skin-confirm rays as four planes for After Effects.

    python3 Tools/build_confirm_rays_layers.py

The rays are the four soft light shapes in the confirm screen's header wash,
Figma `Group 2147241960` in `Whatsapp chat template` (1036:18725): nested
funnels opening upward, stroked in near white. Their source is the vector
export `ae/confirm_rays/rays_design.svg`.

Each carries a *progressive* layer blur in the design — 15 or 25 at 35% of
its height, none by 75% — which neither SVG nor Lottie can express, so each
ray is a raster with the blur baked in. The blur is Figma's own: each vector
exported from Figma (`ae/confirm_rays/figma/`, see `figma_alpha`). A
cross-fade between a sharp and a blurred copy, which this used to be, leaves
a crisp line appearing partway up the stroke; Figma's blur tapers smoothly.
The approximation remains only for what the header frame crops off the
exports. One PNG per ray, cropped to what it covers,
at 2x of the 375 × 259 header, so they land on the 750 × 518 comp
`build_confirm_rays.jsx` makes. `layout.json` records where each goes.

The design's opacities (0.4 / 0.8 / 0.5 / 0.4) are raised by `BOOST`: the
rays sit over a light wash in the app and at the design's values they read
as barely there once moving.
"""

import json
import math
import os
import re

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "ae", "confirm_rays")
SVG = os.path.join(OUT, "rays_design.svg")

SCALE = 2          # comp pixels per design point
# The SVG viewport's origin in header points: the group's frame grown by the
# export's own inset (-9.64% / -4.95%).
ORIGIN = (-21.194, -41.854)
# Where every funnel narrows to: the bottom of the tall ray, the point the
# rays sway about.
PIVOT_SVG = (208.694, 245.239)
BOOST = 1.3
# Figma's per-vector exports (see `figma_alpha`), the backdrop the MCP renders
# them on, and how far in from a frame-cropped edge they take over.
FIGMA = os.path.join(OUT, "figma")
BACKDROP = 20.0
FEATHER = 16

# In paint order, bottom first — the SVG's own order.
RAYS = [
    # name, svg path id, stroke width, opacity, blur at the top, colours top→bottom
    ("RAY_A", "Vector 20715", 4.0, 0.4, 15, (255, 255, 255), (254, 252, 255)),
    ("RAY_B", "Vector 20718", 4.0, 0.8, 15, (246, 246, 246), (254, 252, 255)),
    ("RAY_C", "Vector 20716", 33.71, 0.5, 25, (255, 255, 255), (251, 251, 251)),
    ("RAY_D", "Vector 20717", 33.71, 0.4, 25, (255, 255, 255), (231, 231, 231)),
]


def parse_path(d):
    """Absolute M/L/H/C/Z → list of polylines (closed)."""
    toks = re.findall(r"[MLHVCZ]|-?\d*\.?\d+(?:e-?\d+)?", d)
    pts, cur, i, cmd = [], (0.0, 0.0), 0, None
    while i < len(toks):
        t = toks[i]
        if t.isalpha():
            cmd = t
            i += 1
            if cmd == "Z":
                continue
        if cmd == "M" or cmd == "L":
            cur = (float(toks[i]), float(toks[i + 1])); i += 2
            pts.append(cur)
        elif cmd == "H":
            cur = (float(toks[i]), cur[1]); i += 1
            pts.append(cur)
        elif cmd == "V":
            cur = (cur[0], float(toks[i])); i += 1
            pts.append(cur)
        elif cmd == "C":
            c1 = (float(toks[i]), float(toks[i + 1]))
            c2 = (float(toks[i + 2]), float(toks[i + 3]))
            p = (float(toks[i + 4]), float(toks[i + 5])); i += 6
            for s in np.linspace(0, 1, 24)[1:]:
                u = 1 - s
                pts.append((u**3 * cur[0] + 3 * u * u * s * c1[0] + 3 * u * s * s * c2[0] + s**3 * p[0],
                            u**3 * cur[1] + 3 * u * u * s * c1[1] + 3 * u * s * s * c2[1] + s**3 * p[1]))
            cur = p
        else:
            i += 1
    return pts


def to_comp(p):
    return ((p[0] + ORIGIN[0]) * SCALE, (p[1] + ORIGIN[1]) * SCALE)


def figma_alpha(pid, svg, approx, rgb, x0, y0):
    """The plane's alpha from Figma's own export of the vector, where it has one.

    `figma/vec_<n>.png` is the node exported at 2x through the Figma MCP,
    which renders onto opaque #141414, so alpha is recovered by unmixing
    against the stroke's own colour: a = (px − 20) / (c − 20). The export
    covers the SVG filter region clipped to the header frame, so it lands at
    the filter's origin, and what the frame cuts off — the tops of B, C and D
    and A's outer arms, all well into the blurred part — keeps the
    approximation, feathered into Figma's pixels over `FEATHER` so the seam
    doesn't show when the sway brings it on screen.
    """
    fn = os.path.join(FIGMA, "vec_" + pid.split()[-1] + ".png")
    if not os.path.exists(fn):
        return approx
    fid = re.search(r'<g id="%s"[^>]*filter="url\(#([^)]+)\)"' % re.escape(pid), svg).group(1)
    fx, fy = (float(v) for v in re.search(
        r'<filter id="%s" x="([-\d.e]+)" y="([-\d.e]+)"' % fid, svg).groups())
    ex, ey = max(0, round((fx + ORIGIN[0]) * SCALE)), max(0, round((fy + ORIGIN[1]) * SCALE))
    px = np.asarray(Image.open(fn).convert("RGB"), float)
    H, W = approx.shape
    fig = np.zeros((H, W))
    inside = np.zeros((H, W))
    # The export's box in this plane's pixels, cropped to the plane.
    ox, oy = ex - x0, ey - y0
    sx0, sy0 = max(0, -ox), max(0, -oy)
    dx0, dy0 = max(0, ox), max(0, oy)
    w = min(px.shape[1] - sx0, W - dx0)
    h = min(px.shape[0] - sy0, H - dy0)
    c = np.dstack(rgb)[dy0:dy0 + h, dx0:dx0 + w]
    src = px[sy0:sy0 + h, sx0:sx0 + w]
    a = ((src - BACKDROP) / np.maximum(1, c - BACKDROP)).mean(2)
    fig[dy0:dy0 + h, dx0:dx0 + w] = np.clip(a, 0, 1) * 255
    # Distance inward from the edges the frame cropped (not from the filter
    # region's own edges, where the render has already fallen to nothing).
    yy, xx = np.mgrid[0:h, 0:w]
    d = np.full((h, w), np.inf)
    if fy + ORIGIN[1] < 0:
        d = np.minimum(d, yy + sy0)
    if fx + ORIGIN[0] < 0:
        d = np.minimum(d, xx + sx0)
    if ex + px.shape[1] >= 375 * SCALE:
        d = np.minimum(d, px.shape[1] - 1 - (xx + sx0))
    inside[dy0:dy0 + h, dx0:dx0 + w] = np.clip(d / FEATHER, 0, 1)
    return fig * inside + approx * (1 - inside)


def main():
    svg = open(SVG).read()
    paths = dict(re.findall(r'<g id="([^"]+)"[^>]*>\s*<path d="([^"]+)"', svg))
    layout = {"comp": [375 * SCALE, 259 * SCALE], "pivot": list(to_comp(PIVOT_SVG)), "rays": []}
    for name, pid, width, opacity, blur, top, bottom in RAYS:
        poly = [to_comp(p) for p in parse_path(paths[pid])]
        xs, ys = [p[0] for p in poly], [p[1] for p in poly]
        # The vector's own bounds, which is what Figma's progressive blur
        # band is a fraction of.
        vy0, vy1 = min(ys), max(ys)
        sigma = blur * SCALE / 2
        pad = int(width * SCALE / 2 + sigma * 3 + 4)
        x0, y0 = int(math.floor(min(xs))) - pad, int(math.floor(vy0)) - pad
        x1, y1 = int(math.ceil(max(xs))) + pad, int(math.ceil(vy1)) + pad
        W, H = x1 - x0, y1 - y0

        # Coverage from the distance to the path: exact, anti-aliased, and
        # with no joins to show — a polyline drawn with a wide pen leaves a
        # tick at every vertex.
        gx, gy = np.meshgrid(np.arange(W) + x0 + 0.5, np.arange(H) + y0 + 0.5)
        dist = np.full((H, W), np.inf)
        ring = poly + [poly[0]]
        for (ax, ay), (bx, by) in zip(ring, ring[1:]):
            vx, vy = bx - ax, by - ay
            L2 = vx * vx + vy * vy or 1e-9
            u = np.clip(((gx - ax) * vx + (gy - ay) * vy) / L2, 0, 1)
            dist = np.minimum(dist, np.hypot(gx - (ax + u * vx), gy - (ay + u * vy)))
        cov = np.clip(width * SCALE / 2 - dist + 0.5, 0, 1)
        sharp = Image.fromarray((cov * 255).astype(np.uint8))
        soft = sharp.filter(ImageFilter.GaussianBlur(sigma))

        # The progressive band, in this plane's rows.
        rows = np.arange(H) + y0
        b0 = vy0 + (vy1 - vy0) * 0.3481
        b1 = vy0 + (vy1 - vy0) * 0.7453
        k = np.clip((rows - b0) / (b1 - b0), 0, 1)[:, None]          # 0 blurred → 1 sharp
        a = (np.asarray(soft, float) * (1 - k) + np.asarray(sharp, float) * k) * opacity

        # Stroke colour, top to bottom over the vector's height.
        t = np.clip((rows - vy0) / (vy1 - vy0), 0, 1)[:, None]
        rgb = [np.broadcast_to(top[c] + (bottom[c] - top[c]) * t, (H, W)) for c in range(3)]

        # Figma's own render replaces the approximation wherever there is one.
        a = figma_alpha(pid, svg, a, rgb, x0, y0)
        a = np.clip(a * BOOST, 0, 255)
        img = np.dstack(rgb + [a]).astype(np.uint8)
        fn = f"{name.lower()}.png"
        Image.fromarray(img).save(os.path.join(OUT, fn), optimize=True)
        layout["rays"].append({"name": name, "file": fn, "x": x0, "y": y0, "w": W, "h": H,
                               "opacity": round(min(1.0, opacity * BOOST), 3)})
        print(name, fn, (x0, y0, W, H))

    json.dump(layout, open(os.path.join(OUT, "layout.json"), "w"), indent=2)

    # A flat preview over the app's wash, for checking the planes.
    comp = layout["comp"]
    prev = Image.new("RGBA", tuple(comp), (0, 0, 0, 0))
    wash = np.zeros((comp[1], comp[0], 4), np.uint8)
    yy = np.arange(comp[1])[:, None]
    tt = np.clip((yy / SCALE + 20.3 - 307.256 * 0.08884) / (307.256 * (1 - 0.08884)), 0, 1)
    for c, v in enumerate((195, 202, 211)):
        wash[..., c] = np.broadcast_to(v + (255 - v) * tt, (comp[1], comp[0]))
    wash[..., 3] = 255
    prev = Image.fromarray(wash)
    for r in layout["rays"]:
        im = Image.open(os.path.join(OUT, r["file"]))
        prev.alpha_composite(im, (max(0, r["x"]), max(0, r["y"])),
                             (max(0, -r["x"]), max(0, -r["y"])))
    prev.save(os.path.join(OUT, "preview.png"))


if __name__ == "__main__":
    main()
