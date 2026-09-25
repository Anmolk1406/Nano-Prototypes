#!/usr/bin/env python3
"""Cut the redesigned invite screen (Figma 980:15528) into its planes.

    python3 Tools/build_invite_layers.py

**Every plane here comes from a source that actually determines it.** That
sounds obvious and it is the whole point of this rewrite, because the first
version of this script did not: it solved all five planes with the two-ground
trick that worked on the account page, and on this screen that trick has no
signal.

The reason is the canvas. Figma renders a node onto the page's background, and
on this page that background is **pure white**. The two-ground solve is

    1 - α = (C1 - C2) / (G1 - G2)

with `G1` the canvas and `G2` what the plane sits on — and this screen's own
background runs from pale lilac at the top to *white* at the bottom under its
overlay. So `G1 - G2` goes to zero exactly where the sparkles are, α comes out
of a division by nothing, and every plane ends up carrying a rectangular slab
of background: the right sparkle's matte measured 0.43 mean alpha around its
whole border. Invisible at rest, because the slab *is* the background;
obvious the moment the card tilts and drags it along. On the account page the
canvas was blue against a purple page and the same code was fine.

So each plane is cut by the method its own material suits:

* **frame, star_l, star_r — from the original uploads.** `download_assets`
  returns the images the designer placed and those have real alpha. What they
  do not have is the node's transform, so the transforms come from the CSS:
  the left sparkle is rotated 75.57° and blurred 1pt inside an 86.8 × 90.8
  box, the right one is stretched to 120.6 × 230.2, flipped vertically and
  rotated −150.66°. Getting that wrong is what made the account page's ball
  wrong, so it is written out here term by term.
* **panel — from its own export against the white canvas.** It is a dark,
  opaque object on white, so `|C - white|` *is* its matte: saturated inside, a
  clean ramp at the rounded rim, nothing outside. No second ground needed.
* **qr — solved against the panel.** White ink on a dark panel is the one
  place on this screen where a solve has real signal.
* **bg — exported whole.** `980:15529` is the gradient, the ray pattern and
  the white overlay, and a node export carries none of its siblings, so the
  page is simply an export.

Outputs: `inv_bg`, `inv_frame`, `inv_panel`, `inv_qr`, `inv_star_l`,
`inv_star_r`, `inv_card_mask`, and the screen-local frames to paste into
`ScreenSpec`.
"""

import json
import os
import numpy as np
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "invite_src")
CATALOG = os.path.join(HERE, "..", "GyroQR", "Assets.xcassets")

S = 3
SCREEN_H = 812.0

# Every number below is from the node's CSS box, which is the rectangle Figma
# actually renders. The layer panel disagrees for anything with a transform —
# it reports the untransformed node — and both sparkles carry one.

# 980:15537 — the chrome frame. Its source's aspect matches the box's to four
# decimal places, so the `object-cover` fill is a straight resize.
FRAME = dict(box=(42.5, 196.907, 290.0, 409.186), src="raw_frame1.png")

# 980:15538 — the QR's recess.
PANEL = dict(box=(81.505, 238.761, 212.0, 244.0), export="panel3x.png")

# 980:15539 — the modules and the nano badge. The export is cropped to its
# content and so is about 4pt bigger than the group's box on each side.
QR = dict(box=(101.50, 274.23, 172.0, 173.0), export="qr3x.png", search=8)

# 980:15987 / 980:16004 — the two sparkles, with the transforms their CSS
# carries. `flip` is `-scale-y-100`; `rot` is the CSS angle, clockwise.
STAR_L = dict(name="inv_star_l", box=(-21.1, 458.32, 86.824, 90.752),
              src="raw_starL1.png", inner=(75.651, 70.189),
              rot=75.57, flip=False, blur=1.0)
STAR_R = dict(name="inv_star_r", box=(221.85, 219.05, 217.969, 259.807),
              src="raw_starR4.png", inner=(120.629, 230.232),
              rot=-150.66, flip=True, blur=0.0)


def load(path):
    return np.asarray(Image.open(os.path.join(SRC, path)).convert("RGB")).astype(np.float64) / 255


def px(v):
    return int(round(v * S))


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
    print(f"  {name:12s} {arr.shape[1]}x{arr.shape[0]}  {kb}KB")


def coverage_mask(rgba, floor=0.015, feather=1.0):
    """Where the card *is*, as a hard mask with a soft edge.

    Not the card's alpha — its **coverage**. The two differ where the chrome
    has its outer glow: the alpha there is a tenth or two, and masking the card
    by its own alpha would square that and dim the glow away. Hardening it
    instead gives a mask that is 1 over every part of the card, glow included,
    and 0 only where the card genuinely is not — which is the corners of its
    box, and the corners of its box are the whole problem.

    `GyroCardView` uses this to clip the sheen and the iridescence. Those are
    additive light bands and they were clipped to the card's *rectangle*: on a
    flat card the rectangle is the card, but this one is a moulded object with
    rounded corners inside its box, so the bands painted light onto nothing and
    left a pale rectangle sitting at the card's rest position while the card
    itself rotated away from it.
    """
    a = np.clip(rgba[..., 3] / floor, 0, 1)
    if feather:
        im = Image.fromarray((a * 255 + 0.5).astype(np.uint8))
        im = im.filter(ImageFilter.GaussianBlur(radius=feather * S / 2))
        a = np.asarray(im).astype(np.float64) / 255
    return np.dstack([np.ones_like(a), np.ones_like(a), np.ones_like(a), a])


def report(name, rgba, box):
    """Every plane gets the same check: how much background is it carrying?

    The border ring is the tell, and it is the number that would have caught
    the first version of this script. A plane whose matte is its own silhouette
    has almost nothing there. A plane carrying a slab has a ring mean in the
    tenths — and that slab is what slides into view under tilt.
    """
    a = rgba[..., 3]
    h, w = a.shape
    ring = np.zeros((h, w), bool)
    k = max(2, int(2 * S))
    ring[:k, :] = ring[-k:, :] = True
    ring[:, :k] = ring[:, -k:] = True
    print("  %-11s (%7.2f, %7.2f) %6.2f x %6.2f   ring alpha mean %.4f "
          "max %.3f   opaque %.2f"
          % (name, box[0], box[1], box[2], box[3],
             a[ring].mean(), a[ring].max(), (a > 0.99).mean()))


# ------------------------------------------------------------------ the planes

def from_source(spec):
    """A plane straight from the image the designer placed, at the node's size.

    Exact — the upload's own alpha, the node's own box — and the only thing it
    has to get right is the geometry.
    """
    w, h = px(spec["box"][2]), px(spec["box"][3])
    im = Image.open(os.path.join(SRC, spec["src"])).convert("RGBA")
    im = im.resize((w, h), Image.LANCZOS)
    return np.asarray(im).astype(np.float64) / 255


def from_source_transformed(spec, tight=False):
    """A sparkle: the source resized to its inner box, then flipped, rotated
    and blurred the way the CSS says, then centred in the node's box.

    Two sign conventions to keep straight. PIL rotates counter-clockwise and
    CSS clockwise, hence the negation. And the flip goes first, because
    Tailwind emits `transform: … rotate(a) scaleY(-1)` and CSS applies the
    list right to left.
    """
    im = Image.open(os.path.join(SRC, spec["src"])).convert("RGBA")
    im = im.resize((px(spec["inner"][0]), px(spec["inner"][1])), Image.LANCZOS)
    if spec["flip"]:
        im = im.transpose(Image.FLIP_TOP_BOTTOM)
    if spec["rot"]:
        im = im.rotate(-spec["rot"], resample=Image.BICUBIC, expand=True)
    if spec["blur"]:
        # CSS `blur(Npx)` is a Gaussian of sigma N/2.
        im = im.filter(ImageFilter.GaussianBlur(radius=spec["blur"] * S / 2))

    if tight:
        # Its own rendered bounds, so the sweep below is not comparing boxes
        # of different sizes with the content floating inside them.
        return np.asarray(im).astype(np.float64) / 255
    w, h = px(spec["box"][2]), px(spec["box"][3])
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    out.alpha_composite(im, ((w - im.width) // 2, (h - im.height) // 2))
    return np.asarray(out).astype(np.float64) / 255


def opaque_on_white(spec):
    """A dark, opaque plane cut from its own export against the white canvas.

    `C = F·α + 1·(1-α)`, and for an object whose colour is nowhere near white
    the distance from white *is* the matte: saturated inside, a one-pixel ramp
    at the rim, zero outside. Normalising by a low percentile of that distance
    rather than by its maximum is what keeps the panel's own bright highlight
    from thinning the whole matte.
    """
    C = load(spec["export"])
    d = np.abs(C - 1).max(axis=2)
    inner = np.percentile(d[d > 0.25], 35)
    alpha = np.clip(d / inner, 0, 1)
    a3 = alpha[..., None]
    colour = np.clip(np.where(a3 > 0.004, (C - (1 - a3)) / np.maximum(a3, 1e-4), 0), 0, 1)
    return np.dstack([colour, alpha])


def solve_qr(spec, screen, ground):
    """The modules, against the panel they are printed on.

    White ink on a dark ground is the one solve on this screen with real
    signal: `α = (C - G)/(1 - G)`, per channel, taking the least confident.
    The position is registered on the gaps — where the export has no ink the
    screen must already equal the panel.
    """
    export = load(spec["export"])
    h, w, _ = export.shape
    gaps = np.abs(export - 1).max(axis=2) < 0.02

    r = spec["search"] * S
    best = (1e9, 0, 0)
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            X, Y = px(spec["box"][0]) + dx, px(spec["box"][1]) + dy
            if X < 0 or Y < 0 or X + w > ground.shape[1] or Y + h > ground.shape[0]:
                continue
            d = np.abs(screen[Y:Y + h, X:X + w] - ground[Y:Y + h, X:X + w]).mean(axis=2)
            score = d[gaps].mean()
            if score < best[0]:
                best = (score, dx, dy)
    score, dx, dy = best
    X, Y = px(spec["box"][0]) + dx, px(spec["box"][1]) + dy

    C = screen[Y:Y + h, X:X + w]
    G = ground[Y:Y + h, X:X + w]
    # `α = (C - G)/(1 - G)` per channel, and then the **brightest** channel's
    # answer — not the dimmest.
    #
    # The dimmest is the natural choice and it is wrong here, because the group
    # is not all white modules: the nano badge in the middle is yellow, so its
    # blue channel is *darker* than the panel it sits on, that channel's answer
    # comes out negative, and taking the minimum punches the badge's interior
    # out into a hole. The panel is dark enough that any ink on it is brighter
    # in at least one channel, which is what makes the maximum the safe one.
    alpha = np.clip((C - G) / np.maximum(1 - G, 0.02), 0, 1).max(axis=2)
    alpha[alpha < 0.05] = 0
    a3 = alpha[..., None]
    colour = np.clip(np.where(a3 > 0.02, (C - G * (1 - a3)) / np.maximum(a3, 1e-4), 1), 0, 1)
    print("    gap-area fit %.2f/255" % (score * 255))
    return np.dstack([colour, alpha]), (X / S, Y / S, w / S, h / S)


def composite(ground, rgba, x, y):
    """`rgba` over a copy of `ground`, clipped — the left sparkle hangs off the
    screen's edge, so a plain slice is not enough."""
    out = ground.copy()
    H, W, _ = out.shape
    h, w, _ = rgba.shape
    X, Y = px(x), px(y)
    sx, sy = max(0, -X), max(0, -Y)
    dx, dy = max(0, X), max(0, Y)
    ww, hh = min(w - sx, W - dx), min(h - sy, H - dy)
    if ww <= 0 or hh <= 0:
        return out
    src = rgba[sy:sy + hh, sx:sx + ww]
    a = src[..., 3:4]
    out[dy:dy + hh, dx:dx + ww] = src[..., :3] * a + out[dy:dy + hh, dx:dx + ww] * (1 - a)
    return out


def fit_scale(spec, screen, ground, lo=0.30, hi=1.15, steps=18):
    """How big the sparkle actually renders, as well as where.

    Its silhouette comes from the upload and is exact; its *size* does not,
    because the CSS says the image fills a 120.6 × 230.2 box and it plainly
    does not — a square source stretched to that box gives a star twice the
    height the render shows. Rather than guess which of Figma's fill modes
    that is, the scale is swept and the render decides, which is the same
    thing the position search already does and needs no new idea.
    """
    def trial_at(k, reach, step):
        trial = dict(spec)
        trial["inner"] = (spec["inner"][0] * k, spec["inner"][1] * k)
        rgba = from_source_transformed(trial, tight=True)
        box = (spec["box"][0] + (spec["box"][2] - rgba.shape[1] / S) / 2,
               spec["box"][1] + (spec["box"][3] - rgba.shape[0] / S) / 2,
               rgba.shape[1] / S, rgba.shape[0] / S)
        placed, d = register(rgba, box, screen, ground, reach=reach,
                             quiet=True, step=step)
        return d, k, placed, rgba

    # Coarse, then one refinement around the winner — the full product of
    # scales and offsets at single-pixel steps is 12,000 composites and
    # minutes of wall clock for no better answer.
    coarse = min(trial_at(lo + (hi - lo) * i / (steps - 1), 14, 4)
                 for i in range(steps))
    span = (hi - lo) / (steps - 1)
    best = min(trial_at(coarse[1] + span * j / 2, 5, 1) for j in (-1, 0, 1))
    d, k, placed, rgba = min(best, coarse)
    print("    scale %.3f of the CSS box   placed (%.2f, %.2f)  %.2f x %.2f   fit %.2f/255"
          % (k, placed[0], placed[1], placed[2], placed[3], d * 255))
    return rgba, placed


def register(rgba, box, screen, ground, reach=8.0, quiet=False, step=1):
    """Where this plane actually lands, given that its matte is already right.

    The CSS box gets within a point or two and no further — Figma's own
    rounding, and for the sparkles the blur and the rotation both expand the
    rendered bounds. With an exact matte in hand the test is simply: composite
    the plane at a candidate offset and see how well the result matches the
    finished screen over the plane's own footprint. Solving the matte and the
    position together is what needed clever scoring; solving them one at a
    time does not.
    """
    h, w, _ = rgba.shape
    a = rgba[..., 3]
    seen = a > 0.08
    if seen.sum() < 200:
        return box
    H, W, _ = ground.shape
    r = int(reach * S)
    best = (1e9, 0, 0)
    for dy in range(-r, r + 1, step):
        for dx in range(-r, r + 1, step):
            X, Y = px(box[0]) + dx, px(box[1]) + dy
            sx, sy = max(0, -X), max(0, -Y)
            X, Y = max(0, X), max(0, Y)
            ww, hh = min(w - sx, W - X), min(h - sy, H - Y)
            if ww < w * 0.5 or hh < h * 0.5:
                continue
            src = rgba[sy:sy + hh, sx:sx + ww]
            m = src[..., 3:4]
            lay = src[..., :3] * m + ground[Y:Y + hh, X:X + ww] * (1 - m)
            sel = seen[sy:sy + hh, sx:sx + ww]
            d = np.abs(lay - screen[Y:Y + hh, X:X + ww]).mean(axis=2)[sel].mean()
            if d < best[0]:
                best = (d, dx, dy)
    d, dx, dy = best
    out = (box[0] + dx / S, box[1] + dy / S, box[2], box[3])
    if quiet:
        return out, d
    print("    placed (%+.2f, %+.2f) pt   fit %.2f/255" % (dx / S, dy / S, d * 255))
    return out


def main():
    screen = load("screen3x.png")
    bg = load("bg3x.png")
    # The background node is 803 tall against the screen's 812; the bottom
    # sheet covers the difference, but the asset is padded so nothing else has
    # to know that.
    bg = np.concatenate([bg, np.repeat(bg[-1:], px(SCREEN_H) - bg.shape[0], axis=0)], axis=0)

    print("planes")
    frame = from_source(FRAME)
    FRAME["box"] = register(frame, FRAME["box"], screen, bg)
    report("inv_frame", frame, FRAME["box"])

    after_frame = composite(bg, frame, FRAME["box"][0], FRAME["box"][1])
    panel = opaque_on_white(PANEL)
    PANEL["box"] = register(panel, PANEL["box"], screen, after_frame, reach=4)
    report("inv_panel", panel, PANEL["box"])

    ground = composite(after_frame, panel, PANEL["box"][0], PANEL["box"][1])
    qr, qr_box = solve_qr(QR, screen, ground)
    report("inv_qr", qr, qr_box)
    ground = composite(ground, qr, qr_box[0], qr_box[1])

    stars = []
    for spec in (STAR_L, STAR_R):
        rgba, spec["box"] = fit_scale(spec, screen, ground)
        report(spec["name"], rgba, spec["box"])
        ground = composite(ground, rgba, spec["box"][0], spec["box"][1])
        stars.append((spec, rgba))

    print("written")
    save(bg, "inv_bg")
    save(frame, "inv_frame")
    save(coverage_mask(frame), "inv_card_mask")
    save(panel, "inv_panel")
    save(qr, "inv_qr")
    for spec, rgba in stars:
        save(rgba, spec["name"])

    print("\nframes, screen-local")
    print("  frame       CGRect(x: %.2f, y: %.2f, width: %.2f, height: %.2f)" % FRAME["box"])
    print("  panel       CGRect(x: %.2f, y: %.2f, width: %.2f, height: %.2f)" % PANEL["box"])
    print("  qr          CGRect(x: %.2f, y: %.2f, width: %.2f, height: %.2f)" % qr_box)
    for spec, _ in stars:
        print("  %-11s CGRect(x: %.2f, y: %.2f, width: %.2f, height: %.2f)"
              % (spec["name"][4:], *spec["box"]))
    print("\n  card-local (the card being the frame's box)")
    for n, b in (("panel", PANEL["box"]), ("qr", qr_box)):
        print("  %-11s CGRect(x: %.2f, y: %.2f, width: %.2f, height: %.2f)"
              % (n, b[0] - FRAME["box"][0], b[1] - FRAME["box"][1], b[2], b[3]))


if __name__ == "__main__":
    main()
