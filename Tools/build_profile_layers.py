#!/usr/bin/env python3
"""Cut the profile QR card (Figma 940:63003) into its parallax planes.

    python3 Tools/build_profile_layers.py

Every plane here is a *real asset*, not a reconstruction of one. That is the
whole point of this rewrite.

The first version of this script had one flat render of the card and had to
invent everything that was hidden behind something: it punched holes where the
portrait and the QR sat and filled them by diffusion and a radial ray model.
Two things went wrong with that, and both showed up the moment the card tilted.
The synthesised fill never quite matched its surroundings, so the seam slid
into view as a pale crescent; and the mattes it produced were bounding boxes
with soft blobs in them, so each plane carried a slab of backdrop that slid
across the plate underneath — a drop-shadow-shaped edge with nothing casting it.

What this version does instead:

* **The backdrop is exported on its own.** `940:63004` is the starburst image,
  and Figma renders it clipped to the card with everything above it absent. So
  the rays under the portrait and between the QR's modules are the *real* rays.
  Nothing is invented. What the export does not have is the two gradient rects
  (`940:63005`, `940:63006`) stacked over it, which are what turn the source's
  blue into the card's purple — those are fitted, see `reconstruct`.
* **Every foreground plane is its own export**, cut to its own alpha:
  the portrait disc, and each of the three interest badges separately. Their
  alpha is *solved*, not guessed — see `unmatte`.
* **The QR is a matte of its own ink**, derived against the recovered backdrop.

Outputs, into the asset catalogue:

    pq_plate      the purple starburst, whole, with bleed
    pq_portrait   the avatar disc and its ring
    pq_badge1..3  the three interest stickers
    pq_qr         the QR's modules as a white matte

and it prints the card-local frames to paste into `CardSpec.profile`.
"""

import json
import os
import numpy as np
from PIL import Image
from scipy.ndimage import (gaussian_filter, binary_dilation, label,
                           distance_transform_edt)

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "profile_src")
CATALOG = os.path.join(HERE, "..", "GyroQR", "Assets.xcassets")

# The card, in its own points. Figma 940:63003.
CARD_W, CARD_H = 351.0, 656.0
S = 3          # the flat render and the backdrop export are both 3x
PS = 4         # the portrait export is 4x

# Card-local geometry, straight off `get_metadata` (positions are summed
# through the parent frames; the numbers below are already absolute in the
# card's own space).
#
# The portrait is `Ellipse 24643` (940:63104) at (105.5, 84), 140 x 140, with a
# 2pt white stroke *outside* it — which is why its export is 144pt square and
# why the plane's frame is the ellipse inset by 2 on every side.
DISC = dict(cx=105.5 + 70, cy=84 + 70, r=72.0)

# `Group 2147227459` (940:63586). Three sticker frames, each its own node. They
# are separate planes here because they are separate assets; grouping them was
# what put a single rectangle around all three.
BADGES = [
    dict(name="pq_badge1", node="940:63587", file="badge1_3x.png",
         x=119.1640625,      y=201.18359375, w=39.9173469543457,  h=38.41102981567383),
    dict(name="pq_badge2", node="940:63590", file="badge2_3x.png",
         x=155.98828125,     y=197.8359375,  w=36.97753143310547, h=49.163055419921875),
    dict(name="pq_badge3", node="940:63593", file="badge3_3x.png",
         x=192.8087615966797, y=196.99995613098145, w=39.024070739746094, h=43.953269958496094),
]

QR = dict(x=35.5, y=288.0, w=280.0, h=280.0)
NAME_BOX = dict(x=38.5, y=248.0, w=274.0, h=32.0)
CAPTION_BOX = dict(x=47.0, y=576.0, w=257.0, h=44.0)
CLOSE = dict(cx=303.0, cy=46.0, r=20.0)

# How far the plate is extended past the card's edge, in points. The plate sits
# below the surface and drifts with the tilt, so it has to be bigger than the
# card or the drift exposes its edge. Bleed rather than `scale`: a scale is
# anchored at the card's centre, and on a 656pt card that displaces everything
# near the top by several points.
BLEED = 8.0


# --------------------------------------------------------------------------- io

def load(path, scale=None):
    im = Image.open(path).convert("RGB")
    if scale and im.size != scale:
        im = im.resize(scale, Image.LANCZOS)
    return np.asarray(im).astype(np.float64) / 255


def save(rgba, name, scale):
    """Write an imageset. `scale` is the asset's own multiple of a point."""
    d = os.path.join(CATALOG, f"{name}.imageset")
    os.makedirs(d, exist_ok=True)
    img = Image.fromarray(np.clip(rgba * 255 + 0.5, 0, 255).astype(np.uint8),
                          "RGBA" if rgba.shape[2] == 4 else "RGB")
    img.save(os.path.join(d, f"{name}.png"), optimize=True)
    json.dump({"images": [{"filename": f"{name}.png", "idiom": "universal",
                           "scale": f"{scale}x"}],
               "info": {"author": "xcode", "version": 1}},
              open(os.path.join(d, "Contents.json"), "w"), indent=2)
    kb = os.path.getsize(os.path.join(d, f"{name}.png")) // 1024
    print(f"  {name:14s} {img.width}x{img.height}  {kb}KB")


# ------------------------------------------------------------------- the plate

def reconstruct(bg, flat):
    """Recover the card's backdrop everywhere, including behind everything.

    `bg` is the starburst as Figma renders it on its own; `flat` is the
    finished card. Between them sit two full-bleed gradient rects, and what
    they do to a pixel depends only on where that pixel is — so the map from
    one to the other is smooth in x and y even though it is not smooth in
    colour. Fit it locally and it can be evaluated *inside* the holes, which is
    how the rays come back under the portrait without being drawn.

    The fit is a per-channel affine `flat = a·bg + b` with `a` and `b` estimated
    from a Gaussian neighbourhood of known pixels. Two passes: the first masks
    the boxes that hold ink, the second masks only the ink itself, which hands
    most of the QR's area back to the fit — the gaps between the modules are
    backdrop, and there are a lot of them.

    Where a neighbourhood holds too few known pixels to fit — deep inside the
    portrait disc — the estimate falls back to a wider one, and then wider
    again. Push-pull, but on the coefficients rather than on the colour, so
    what gets smoothed is the gradient's shape and never the rays themselves.
    """
    H, W, _ = bg.shape
    Y, X = np.mgrid[0:H, 0:W]
    x, y = X / S, Y / S

    def rect(b, pad=0):
        return ((x > b["x"] - pad) & (x < b["x"] + b["w"] + pad) &
                (y > b["y"] - pad) & (y < b["y"] + b["h"] + pad))

    # Opaque: nothing of the backdrop survives here at all.
    solid = np.hypot(x - DISC["cx"], y - DISC["cy"]) < DISC["r"] + 2
    for b in BADGES:
        solid |= rect(b, pad=3)
    solid |= np.hypot(x - CLOSE["cx"], y - CLOSE["cy"]) < CLOSE["r"] + 3
    # Ink: mostly backdrop, with marks on it.
    inkbox = rect(QR, 4) | rect(NAME_BOX, 4) | rect(CAPTION_BOX, 4)
    # The card's own rounded edge and its white border, which are not backdrop.
    edge = (x < 9) | (x > CARD_W - 9) | (y < 9) | (y > CARD_H - 9)

    def fields(known, sigmas=(12, 28, 64, 150, 360)):
        k = known.astype(np.float64)
        A = np.full(bg.shape, np.nan)
        B = np.full(bg.shape, np.nan)
        for sig in sigmas:
            N = gaussian_filter(k, sig)
            for c in range(3):
                u, v = bg[..., c], flat[..., c]
                Su = gaussian_filter(u * k, sig)
                Sv = gaussian_filter(v * k, sig)
                Suu = gaussian_filter(u * u * k, sig)
                Suv = gaussian_filter(u * v * k, sig)
                den = Suu * N - Su * Su
                good = (N > 0.06) & (np.abs(den) > 4e-6)
                a = np.clip(np.where(good, (Suv * N - Su * Sv) /
                                     np.where(good, den, 1), np.nan), 0.0, 3.0)
                b = np.where(good, (Sv - a * Su) / np.where(N > 0, N, 1), np.nan)
                take = np.isnan(A[..., c]) & good
                A[..., c][take] = a[take]
                B[..., c][take] = b[take]
        return np.nan_to_num(A, nan=1.0), np.nan_to_num(B, nan=0.0)

    A, B = fields(~(solid | inkbox | edge))
    # Anything inside an ink box that the first fit cannot explain *is* ink.
    ink = inkbox & (np.abs(np.clip(bg * A + B, 0, 1) - flat).max(axis=2) > 0.10)
    known = ~(solid | ink | edge)
    A, B = fields(known)
    plate = np.clip(bg * A + B, 0, 1)

    err = np.abs(plate - flat)[known]
    print("  backdrop fit: mean %.2f  p95 %.2f  p99 %.2f  (/255, on %d%% of the card)"
          % (err.mean() * 255, np.percentile(err, 95) * 255,
             np.percentile(err, 99) * 255, round(100 * known.mean())))
    return plate, ink


def with_bleed(plate, inset=10.0, radius=32.0):
    """Push the backdrop out past the card, from inside the card's own shape.

    Two things have to go. The export carries the card's 4pt white border and
    the antialiasing of its 32pt rounded corners, neither of which is backdrop;
    and the plate has to reach further than the card, because it sits below the
    surface and drifts.

    Growing it from a *rectangle* inset by a few points does not work — at the
    corners, a few points in from the edge is still outside the rounded shape,
    so the fill spreads the white border inwards and the card's corners come
    out cream. So the safe region is the rounded rectangle itself, inset, and
    everything outside it takes the value of the nearest pixel inside. Then the
    whole thing is padded by `BLEED`.
    """
    H, W, _ = plate.shape
    Y, X = np.mgrid[0:H, 0:W]
    x, y = X / S, Y / S
    r = radius - inset
    # Distance to the inset rounded rectangle, the usual clamped-corner form.
    dx = np.maximum(np.maximum(inset + r - x, x - (CARD_W - inset - r)), 0)
    dy = np.maximum(np.maximum(inset + r - y, y - (CARD_H - inset - r)), 0)
    inside = np.hypot(dx, dy) <= r
    _, (iy, ix) = distance_transform_edt(~inside, return_indices=True)
    out = plate[iy, ix]
    b = int(round(BLEED * S))
    return np.pad(out, ((b, b), (b, b), (0, 0)), mode="edge")


# -------------------------------------------------------------- the foreground

def resample(rgba, frm, to):
    if frm == to:
        return rgba
    h, w, _ = rgba.shape
    im = Image.fromarray(np.clip(rgba * 255 + 0.5, 0, 255).astype(np.uint8), "RGBA")
    im = im.resize((round(w / frm * to), round(h / frm * to)), Image.LANCZOS)
    return np.asarray(im).astype(np.float64) / 255


def composite(ground, rgba, x, y):
    """`rgba` over a copy of `ground`, at card-point (x, y)."""
    h, w, _ = rgba.shape
    out = ground.copy()
    X, Y = int(round(x * S)), int(round(y * S))
    a = rgba[..., 3:4]
    out[Y:Y + h, X:X + w] = rgba[..., :3] * a + out[Y:Y + h, X:X + w] * (1 - a)
    return out


def unmatte(over_canvas, over_plate, canvas_bg, plate_bg):
    """Solve a plane's alpha and colour from the same pixels over two grounds.

    A composite gives one equation and two unknowns, so a single render can
    never say what is object and what is ground — which is why the old script
    had to draw the silhouette by hand and always got a slab of backdrop with
    it. Two renders over *different* grounds give two equations:

        C1 = F·α + G1·(1-α)
        C2 = F·α + G2·(1-α)   ⟹   1-α = (C1-C2)/(G1-G2)

    Figma hands us both for free: the node's own export is the plane over the
    page canvas, and the card's flat render is the same plane over the
    backdrop. Both grounds are known — the canvas from the export's own margin,
    the backdrop from `reconstruct` — so α falls straight out, per channel,
    and the channels are averaged in proportion to how far apart the two
    grounds are in each (a channel where they nearly agree says nothing).
    """
    d = canvas_bg - plate_bg
    num = over_canvas - over_plate
    w = np.abs(d)
    weight = w / np.maximum(w.sum(axis=2, keepdims=True), 1e-6)
    inv = np.clip(np.where(w > 1e-4, num / np.where(w > 1e-4, d, 1), 1.0), 0, 1)
    alpha = np.clip(1.0 - (inv * weight).sum(axis=2), 0, 1)
    a3 = alpha[..., None]
    colour = np.where(a3 > 0.004, (over_plate - plate_bg * (1 - a3)) /
                      np.maximum(a3, 1e-4), 0.0)
    return np.clip(colour, 0, 1), alpha


def canvas_from_margin(export):
    """The page colour behind an export, read off its own border ring.

    The canvas is a gentle gradient rather than one flat blue, so a single
    sampled colour leaves a bias that turns into a haze in the alpha. Fitting a
    plane through the border pixels costs nothing and removes it.
    """
    H, W, _ = export.shape
    Y, X = np.mgrid[0:H, 0:W]
    ring = np.zeros((H, W), bool)
    ring[:2, :] = ring[-2:, :] = True
    ring[:, :2] = ring[:, -2:] = True
    M = np.stack([X[ring], Y[ring], np.ones(ring.sum())], 1)
    out = np.empty_like(export)
    for c in range(3):
        sol, *_ = np.linalg.lstsq(M, export[ring, c], rcond=None)
        out[..., c] = sol[0] * X + sol[1] * Y + sol[2]
    return out


def register(export, flat, ground, box, search=30):
    """Find where a node's export sits in the card, to the pixel.

    Figma pads an export by whatever effect the node carries and does not say
    by how much — the badges come back about 6pt larger than their frames on
    every side, and 5pt lower than centred, because each sticker drops a
    shadow. So the nominal position is a starting guess and the rest is
    measured.

    The score is what makes this reliable: at the right offset the per-channel
    estimates of `1-α` from `unmatte` agree with each other, because they are
    three readings of one number. At a wrong offset they are three readings of
    three different pixels and they scatter. Matching the two renders on
    brightness instead does not work — most of what is being compared is
    ground, and ground is *supposed* to differ.
    """
    eh, ew, _ = export.shape
    canvas = canvas_from_margin(export)
    x0 = int(round((box["x"] + box["w"] / 2) * S - ew / 2))
    y0 = int(round((box["y"] + box["h"] / 2) * S - eh / 2))
    best, bestd = None, 1e9
    for dy in range(-search, search + 1):
        for dx in range(-search, search + 1):
            X, Y = x0 + dx, y0 + dy
            if X < 0 or Y < 0 or X + ew > flat.shape[1] or Y + eh > flat.shape[0]:
                continue
            d = canvas - ground[Y:Y + eh, X:X + ew]
            usable = np.abs(d) > 0.03
            inv = np.where(usable, (export - flat[Y:Y + eh, X:X + ew]) /
                           np.where(usable, d, 1), np.nan)
            score = np.nanmedian(np.nanmax(inv, axis=2) - np.nanmin(inv, axis=2))
            if score < bestd:
                bestd, best = score, (X, Y)
    return best, bestd


def cut_badge(spec, flat, ground):
    export = load(os.path.join(SRC, spec["file"]))
    (X, Y), score = register(export, flat, ground, spec)
    eh, ew, _ = export.shape
    colour, alpha = unmatte(export, flat[Y:Y + eh, X:X + ew],
                            canvas_from_margin(export), ground[Y:Y + eh, X:X + ew])
    alpha = only_the_sticker(alpha)
    # Trim to the ink, so the plane's frame is its own silhouette and not the
    # export's padding.
    ys, xs = np.where(alpha > 0.01)
    x1, x2, y1, y2 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    rgba = np.dstack([colour, alpha])[y1:y2, x1:x2]
    frame = ((X + x1) / S, (Y + y1) / S, (x2 - x1) / S, (y2 - y1) / S)
    print("    %s  at (%.2f, %.2f)  channel spread %.3f  coverage %.2f" %
          (spec["name"], frame[0], frame[1], score, (alpha > 0.01).mean()))
    return rgba, frame


def only_the_sticker(alpha, reach=7.0, floor=0.012):
    """Keep the sticker and the shadow it casts; drop everything else.

    `unmatte` is exact where the two grounds are far apart and noisy in the
    last percent or two where they nearly agree, so the solved alpha comes back
    with a faint haze over the whole export — ray structure from the plate, and
    ghosts of the neighbouring badges, which are above this one in the card and
    so are part of its `C2` but not of its ground.

    None of that can be real: a sticker and its drop shadow both live within
    the shadow's own reach of the sticker, and the noise does not. So the
    support is the solid body, grown by `reach` points, and the haze outside is
    simply not part of this plane.
    """
    core = alpha > 0.45
    lab, n = label(core)
    if n > 1:                     # the body, not a speck of a neighbour
        sizes = np.bincount(lab.ravel())
        sizes[0] = 0
        core = lab == sizes.argmax()
    support = binary_dilation(core, iterations=int(round(reach * S)))
    out = np.where(support, alpha, 0.0)
    out[out < floor] = 0
    return out


def cut_portrait():
    """The disc. Its alpha is a circle, because the node is an ellipse.

    Nothing is measured here and nothing needs to be: the ellipse is 140pt
    across with a 2pt stroke outside it, so the plane is a 144pt disc and its
    matte is that circle, antialiased. Every earlier attempt to *find* this
    shape in the pixels came back with the pale halo attached, because the halo
    is part of the artwork and there is no threshold that separates a soft ring
    from the soft backdrop behind it.
    """
    rgb = load(os.path.join(SRC, "portrait4x.png"))
    H, W, _ = rgb.shape
    r = DISC["r"] * PS
    Y, X = np.mgrid[0:H, 0:W]
    d = np.hypot(X - (W - 1) / 2, Y - (H - 1) / 2)
    alpha = np.clip(r - d + 0.5, 0, 1)           # one pixel of feather
    return np.dstack([rgb, alpha])


def cut_qr(flat, plate):
    """The modules, as a white matte over the recovered backdrop.

    On this card the QR has no panel — the modules are ink printed straight on
    the starburst, and the rays show between them. So the plane is the ink and
    nothing else: white at whatever coverage each pixel has.
    """
    x1, y1 = int(QR["x"] * S), int(QR["y"] * S)
    x2, y2 = int((QR["x"] + QR["w"]) * S), int((QR["y"] + QR["h"]) * S)
    f, p = flat[y1:y2, x1:x2], plate[y1:y2, x1:x2]
    # flat = 1·α + p·(1-α)  ⟹  α = (flat - p) / (1 - p), per channel.
    a = np.clip((f - p) / np.maximum(1 - p, 1e-3), 0, 1).min(axis=2)
    a[a < 0.06] = 0
    colour = np.ones(f.shape)
    ys, xs = np.where(a > 0.01)
    bx1, bx2, by1, by2 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    rgba = np.dstack([colour, a])[by1:by2, bx1:bx2]
    frame = (QR["x"] + bx1 / S, QR["y"] + by1 / S, (bx2 - bx1) / S, (by2 - by1) / S)
    print("    pq_qr  coverage %.2f" % (a > 0.01).mean())
    return rgba, frame


# ------------------------------------------------------------------------ main

def main():
    flat = load(os.path.join(HERE, "profile_flat3x.png"))
    bg = load(os.path.join(SRC, "bg3x.png"), scale=(flat.shape[1], flat.shape[0]))
    print("the backdrop")
    plate, _ = reconstruct(bg, flat)

    print("the planes")
    portrait = cut_portrait()
    # The badges hang off the bottom of the disc, so what is *behind* them in
    # the card render is the portrait, not the plate. Solving them against the
    # plate alone put the disc's own pixels into their alpha and gave three
    # translucent rectangles.
    ground = composite(plate, resample(portrait, PS, S),
                       DISC["cx"] - DISC["r"], DISC["cy"] - DISC["r"])
    badges = [cut_badge(b, flat, ground) for b in BADGES]
    qr, qr_frame = cut_qr(flat, plate)

    print("written")
    save(with_bleed(plate), "pq_plate", S)
    # 3x on the way out, like every other plane: an asset catalogue has slots
    # for 1x, 2x and 3x and nothing else, and a 4x imageset builds with an
    # "unassigned child" warning and no matching slot at runtime. The cut is
    # done at 4x anyway — the disc's edge is a circle and it is worth
    # antialiasing it against the finer grid before coming back down.
    save(resample(portrait, PS, S), "pq_portrait", S)
    for spec, (rgba, _) in zip(BADGES, badges):
        save(rgba, spec["name"], S)
    save(qr, "pq_qr", S)

    print("\nCardSpec.profile frames")
    print("  plate     CGRect(x: %.0f, y: %.0f, width: %.0f, height: %.0f)"
          % (-BLEED, -BLEED, CARD_W + 2 * BLEED, CARD_H + 2 * BLEED))
    print("  portrait  CGRect(x: %.1f, y: %.1f, width: %.0f, height: %.0f)"
          % (DISC["cx"] - DISC["r"], DISC["cy"] - DISC["r"],
             DISC["r"] * 2, DISC["r"] * 2))
    for spec, (_, f) in zip(BADGES, badges):
        print("  %-9s CGRect(x: %.2f, y: %.2f, width: %.2f, height: %.2f)"
              % (spec["name"][3:], *f))
    print("  qr        CGRect(x: %.2f, y: %.2f, width: %.2f, height: %.2f)" % qr_frame)


if __name__ == "__main__":
    main()
