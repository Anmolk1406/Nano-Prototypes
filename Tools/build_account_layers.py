#!/usr/bin/env python3
"""Cut the account page's header (Figma 978:15074) into its animated layers.

    python3 Tools/build_account_layers.py

The header is the only part of this page that moves, so it is the only part
that gets taken apart. Everything below it — the widgets, the settings lists —
is one flat export, which is the right trade for a page whose body never
animates.

Same method as `build_account_layers`'s sibling, `build_profile_layers.py`, and
for the same reason: a layer that is going to move has to be cut to its own
alpha, or it carries a slab of backdrop with it and draws a box around itself
the moment it leaves home.

* **The backdrop is an export.** `978:15076` is the starburst image clipped to
  the header. What it does not carry is the two gradient rects stacked over it
  (`978:15077`, `978:15078`), which are what turn the source's blue into the
  page's purple — those are fitted per-pixel from the finished render, so the
  rays behind the avatar are the real rays and nothing is inpainted.
* **The avatar is an ellipse**, so its matte is a circle. Nothing is measured.
* **The three props keep their own alpha.** Their node exports come back matted
  (Figma renders a node onto whatever is behind it), but `download_assets` also
  returns the original uploads, and those have real alpha. Export RGB + raw
  alpha is the prop.
* **The three interest stickers are already in the catalogue.** They are the
  same nodes as the profile card's badges — `pq_badge1…3` — and template
  matching puts them here to within 1.7/255, so they are reused rather than
  cut again.

Outputs:

    acct_bg        the purple backdrop, whole
    acct_avatar    the profile photo in its disc
    acct_ball      the fuzzy googly ball
    acct_star      the iridescent sparkle
    acct_bolt      the lightning baseball
    acct_body      everything below the header, flat
"""

import json
import os
import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter, binary_dilation

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "account_src")
CATALOG = os.path.join(HERE, "..", "GyroQR", "Assets.xcassets")

S = 3
HEADER_W, HEADER_H = 375.0, 429.0

# Card-local geometry. Positions are summed through the parent frames; the
# header's art all lives in `Frame 2147242732` (978:15075) at y = -197, which
# is why every number below is its Figma y minus 197.
AVATAR = dict(x=114.33, y=113.67, d=146.33)      # 978:15212, measured — see below
# Positions from the node's *CSS box* rather than from the layer panel. For a
# node with a transform the two disagree, and only the CSS is the rendered
# rectangle: the panel puts the ball's top at 300.64 and the CSS at 289.76,
# because the panel reports the unrotated node and the CSS the box its −13.02°
# rotation actually occupies. An independent template match agrees with the
# CSS to a tenth of a point.
PROPS = [
    dict(name="acct_ball", file="ball3x.png",
         x=287.5078, y=289.7578 - 197, w=57.9538, h=57.9538),      # 978:15095
    dict(name="acct_star", file="star3x.png",
         x=288.2344, y=460.9141 - 197, w=82.1760, h=82.1760),      # 978:15093
    dict(name="acct_bolt", file="fluff3x.png",
         x=48.3633,  y=460.7891 - 197, w=42.5076, h=41.9686),      # 978:15083
]
# `pq_badge1…3`, re-placed here. Template-matched against the header render at
# 1.11 / 1.66 / 1.44 out of 255 — the same group as the profile card's, moved
# by (+11.33, +30).
STICKERS = [
    dict(name="pq_badge1", x=125.00, y=232.00, w=51.33, h=42.33),
    dict(name="pq_badge2", x=161.33, y=226.67, w=49.00, h=55.33),
    dict(name="pq_badge3", x=198.67, y=226.00, w=49.67, h=49.33),
]
NAME_BOX = dict(x=50.5, y=300.76, w=274.0, h=32.0)
MAIL_BOX = dict(x=112.5, y=336.76, w=150.0, h=20.0)
HEADER_BAR = dict(x=16.0, y=45.0, w=343.0, h=56.0)
STATUS_BAR = dict(x=0.0, y=0.0, w=375.0, h=45.0)


def load(path, size=None):
    im = Image.open(os.path.join(SRC, path)).convert("RGB")
    if size and im.size != size:
        im = im.resize(size, Image.LANCZOS)
    return np.asarray(im).astype(np.float64) / 255


def save(rgba, name):
    d = os.path.join(CATALOG, f"{name}.imageset")
    os.makedirs(d, exist_ok=True)
    arr = np.clip(rgba * 255 + 0.5, 0, 255).astype(np.uint8)
    Image.fromarray(arr).save(os.path.join(d, f"{name}.png"), optimize=True)
    json.dump({"images": [{"filename": f"{name}.png", "idiom": "universal",
                           "scale": f"{S}x"}],
               "info": {"author": "xcode", "version": 1}},
              open(os.path.join(d, "Contents.json"), "w"), indent=2)
    kb = os.path.getsize(os.path.join(d, f"{name}.png")) // 1024
    print(f"  {name:14s} {arr.shape[1]}x{arr.shape[0]}  {kb}KB")


# ---------------------------------------------------------------- the backdrop

def support_of(export, pad=2):
    """Where a node export differs from the canvas it was matted onto.

    Not the alpha — the *support*, which is all the backdrop patch needs to
    know. It comes from the export alone, before anything else is solved.
    """
    canvas = canvas_from_margin(export)
    m = np.abs(export - canvas).max(axis=2) > 0.02
    return binary_dilation(m, iterations=pad)


def backdrop(bg, flat, supports):
    """Recover the header's purple everywhere, including behind everything.

    `bg` is the starburst as Figma renders it alone; `flat` is the finished
    header. Between them sit two full-bleed gradient rects, and what they do to
    a pixel depends only on where that pixel is — so the map between the two is
    smooth in x and y even though it is not smooth in colour. Fitted locally as
    a per-channel affine and then evaluated *inside* the holes, which is how
    the rays come back behind the avatar without being drawn.
    """
    H, W, _ = bg.shape
    Y, X = np.mgrid[0:H, 0:W]
    x, y = X / S, Y / S

    def rect(b, pad=0):
        return ((x > b["x"] - pad) & (x < b["x"] + b["w"] + pad) &
                (y > b["y"] - pad) & (y < b["y"] + b["h"] + pad))

    def place(mask, box):
        out = np.zeros((H, W), bool)
        X, Y = int(round(box[0] * S)), int(round(box[1] * S))
        mh, mw = mask.shape
        out[Y:Y + mh, X:X + mw] = mask
        return out

    hole = np.hypot(x - (AVATAR["x"] + AVATAR["d"] / 2),
                    y - (AVATAR["y"] + AVATAR["d"] / 2)) < AVATAR["d"] / 2 + 4
    # The props and the stickers are holed by their *silhouettes*, not their
    # boxes. This matters more than it sounds: the prop solve below needs the
    # backdrop to be right in the clear margin inside each prop's box, because
    # that margin is where it reads off "these two renders agree, so alpha is
    # zero here". Holing the whole box puts that margin into the fit's
    # extrapolated region, where it came out 15/255 adrift — and a 15/255
    # error there makes the solve think the transparent corners are opaque.
    for sup, box in supports:
        hole |= place(sup, box)
    hole |= rect(NAME_BOX, 3) | rect(MAIL_BOX, 3)
    hole |= rect(HEADER_BAR, 3) | rect(STATUS_BAR, 2)

    # What has to come out from behind something. The avatar and its stickers
    # scale up from small, so they uncover ground inside their own footprint;
    # the props travel in, so they uncover their homes; and the type and the
    # two icon buttons are drawn natively so they can join the stagger, which
    # means the backdrop has to be clean where they sit. The status bar goes
    # too, and for a different reason: the device draws its own, and leaving
    # the design's in gives the page two clocks.
    vacated = hole & ~(y > 372)
    # The bottom of the header is the dark ribbon art the body covers anyway.
    hole |= y > 372

    known = ~hole

    def fields(sigmas=(12, 28, 64, 150, 360)):
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

    A, B = fields()
    fit = np.clip(bg * A + B, 0, 1)
    err = np.abs(fit - flat)[known]
    print("  affine fit alone: mean %.2f  p95 %.2f  (/255, on %d%% of the header)"
          % (err.mean() * 255, np.percentile(err, 95) * 255,
             round(100 * known.mean())))

    # The fit's rays come out stronger than the rendered ones — the gradient
    # rects flatten them more than a per-channel affine can express, and where
    # the source clips to white there is nothing left to fit. So the fit is not
    # used as the backdrop. It is used only to *patch*, and its level is
    # corrected first.
    #
    # The correction is the fit's own error, measured where both images are
    # known and carried into the holes by a normalised blur. That error is
    # smooth — it is a level and a contrast, not structure — so carrying it in
    # this way removes it while leaving the rays the fit got right.
    k = known.astype(np.float64)
    resid = (flat - fit) * k[..., None]
    sig = 40.0
    weight = gaussian_filter(k, sig)
    lift = np.dstack([gaussian_filter(resid[..., c], sig) /
                      np.maximum(weight, 1e-6) for c in range(3)])
    patch = np.clip(fit + lift, 0, 1)
    err = np.abs(patch - flat)[known]
    print("  after the level correction: mean %.2f  p95 %.2f  (/255)"
          % (err.mean() * 255, np.percentile(err, 95) * 255))

    # And the base is the *render*, with only the vacated regions patched.
    # Everything the animation does not move — the rays, the type, the status
    # bar — stays pixel-exact, and the fit is only trusted where something has
    # to come out from behind.
    soft = gaussian_filter(vacated.astype(np.float64), 2.5 * S)[..., None]
    out = flat * (1 - soft) + patch * soft
    return np.clip(out, 0, 1)


# ------------------------------------------------------------------- the planes

def cut_avatar():
    """The disc. Its matte is a circle, because the node is an ellipse."""
    rgb = load("avatar3x.png")
    n = rgb.shape[0]
    Y, X = np.mgrid[0:n, 0:n]
    d = np.hypot(X - (n - 1) / 2, Y - (n - 1) / 2)
    alpha = np.clip(n / 2 - d + 0.5, 0, 1)
    return np.dstack([rgb, alpha])


def canvas_from_margin(export):
    """The page colour behind a node export, read off its own border ring.

    Figma renders a node **without its siblings**, matted onto the page
    canvas — the prop exports here come back on the file's blue, not on the
    header's purple, which is what makes the solve below possible. The canvas
    is a gentle gradient rather than one flat blue, so a plane fitted through
    the border pixels is worth the four lines over sampling one corner.
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


def cut_prop(p, flat, plate):
    """Solve the prop's alpha and colour from two renders over two grounds.

    A single composite is one equation in two unknowns, which is why no amount
    of thresholding one image can say where an object ends. Two composites over
    *different* grounds is two equations:

        C1 = F·α + G1·(1-α)
        C2 = F·α + G2·(1-α)     ⟹     1-α = (C1-C2)/(G1-G2)

    and both are to hand: `C1` is the node's own export over the page canvas,
    `C2` is the finished header over the backdrop `reconstruct` recovered.

    This replaced taking α from the original upload, which is the obvious
    shortcut and is wrong: the uploads are the *untransformed* source, and the
    CSS shows this node group applies transforms the metadata does not mention
    — the ball is rotated −13.02° and drawn at 48.3pt inside its 58pt box.
    Its upload's silhouette therefore does not match its export's, and no
    amount of care about placement fixes a matte that is the wrong shape.
    Solving from the two renders needs to know none of that.

    The position is searched at the same time, by the score that made the
    profile card's badges work: at the right offset the three channels' answers
    for `1-α` agree, because they are three readings of one number.
    """
    export = load(p["file"])
    h, w, _ = export.shape
    canvas = canvas_from_margin(export)

    # A short refinement only — the CSS box is right, and a wide search on a
    # 40pt prop finds spurious minima in the rays behind it.
    best = (1e9, 0, 0)
    for dy in range(-2 * S, 2 * S + 1):
        for dx in range(-2 * S, 2 * S + 1):
            X = int(round(p["x"] * S)) + dx
            Y = int(round(p["y"] * S)) + dy
            if X < 0 or Y < 0 or X + w > flat.shape[1] or Y + h > flat.shape[0]:
                continue
            d = canvas - plate[Y:Y + h, X:X + w]
            usable = np.abs(d) > 0.03
            inv = np.where(usable, (export - flat[Y:Y + h, X:X + w]) /
                           np.where(usable, d, 1), np.nan)
            score = np.nanmedian(np.nanmax(inv, axis=2) - np.nanmin(inv, axis=2))
            if score < best[0]:
                best = (score, dx, dy)
    score, dx, dy = best
    X = int(round(p["x"] * S)) + dx
    Y = int(round(p["y"] * S)) + dy

    C2 = flat[Y:Y + h, X:X + w]
    G2 = plate[Y:Y + h, X:X + w]
    d = canvas - G2
    weight = np.abs(d)
    weight = weight / np.maximum(weight.sum(axis=2, keepdims=True), 1e-6)
    inv = np.clip(np.where(np.abs(d) > 1e-4, (export - C2) /
                           np.where(np.abs(d) > 1e-4, d, 1), 1.0), 0, 1)
    alpha = np.clip(1.0 - (inv * weight).sum(axis=2), 0, 1)
    alpha[alpha < 0.015] = 0
    a3 = alpha[..., None]
    colour = np.clip(np.where(a3 > 0.004, (C2 - G2 * (1 - a3)) /
                              np.maximum(a3, 1e-4), 0.0), 0, 1)
    p["x"], p["y"] = X / S, Y / S
    print("    %-10s at (%.2f, %.2f)  moved (%+.2f, %+.2f)  channel spread %.3f  coverage %.2f"
          % (p["name"], p["x"], p["y"], dx / S, dy / S, score, (alpha > 0.01).mean()))
    return np.dstack([colour, alpha])


def main():
    flat = load("header3x.png")
    bg = load("bg3x.png", size=(flat.shape[1], flat.shape[0]))

    # Every plane's silhouette, before anything is solved: the props from
    # their own exports, the stickers from the alpha they already have.
    supports = [(support_of(load(p["file"])), (p["x"], p["y"])) for p in PROPS]
    for st in STICKERS:
        a = np.asarray(Image.open(os.path.join(
            CATALOG, f"{st['name']}.imageset/{st['name']}.png")).convert("RGBA"))
        a = np.asarray(Image.fromarray(a).resize(
            (int(round(st["w"] * S)), int(round(st["h"] * S))), Image.LANCZOS))
        supports.append((binary_dilation(a[..., 3] > 6, iterations=2),
                         (st["x"], st["y"])))

    print("the backdrop")
    plate = backdrop(bg, flat, supports)

    print("written")
    save(plate, "acct_bg")
    save(cut_avatar(), "acct_avatar")
    print("  the props")
    for p in PROPS:
        save(cut_prop(p, flat, plate), p["name"])
    # The body goes in as it comes out of Figma. The page header does not:
    # its export is 8pt of shadow bleed around two *transparent* rings, matted
    # onto the purple, so it would arrive as a purple slab. The two buttons are
    # a white ring and a glyph — cheaper and sharper drawn natively, and they
    # are chrome rather than part of the animation.
    body = Image.open(os.path.join(SRC, "body3x.png")).convert("RGBA")
    save(np.asarray(body).astype(np.float64) / 255, "acct_body")

    print("\nAccountSpec frames")
    print("  avatar   CGRect(x: %.2f, y: %.2f, width: %.2f, height: %.2f)"
          % (AVATAR["x"], AVATAR["y"], AVATAR["d"], AVATAR["d"]))
    for p in PROPS:
        print("  %-8s CGRect(x: %.2f, y: %.2f, width: %.2f, height: %.2f)"
              % (p["name"][5:], p["x"], p["y"], p["w"], p["h"]))
    for s in STICKERS:
        print("  %-8s CGRect(x: %.2f, y: %.2f, width: %.2f, height: %.2f)"
              % (s["name"][3:], s["x"], s["y"], s["w"], s["h"]))


if __name__ == "__main__":
    main()
