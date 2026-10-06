#!/usr/bin/env python3
"""Cut the account page's header (Figma 978:15074) into its animated layers.

    python3 Tools/build_account_layers.py

Third version, and the first that does not start from the finished render.
The first two took the render and patched out whatever had to move, and a
patch is an estimate: every one left a faint copy of what used to be there —
a ghost of the ball under the ball, of the status bar at the top — invisible
while everything sits at home and obvious the moment anything is in flight.

So each plane now comes from the source that *determines* it:

* **The backdrop is rebuilt from its recipe**, which the CSS gives exactly:

      header fill        linear #2188FF → #0A49B8, top to bottom
      978:15076          the starburst upload, colour-dodged onto it
      978:15077          #7D43EA in *color* blend mode, full bleed
      978:15078          radial #7D43EA@0 → #4C17B0@1, centre (188, 116.5),
                         radii 797 × 237, normal blend

  Nothing was ever in front of it, so nothing can ghost. It reproduces the
  render to ~1/255 wherever the render shows backdrop — the check that the
  recipe is read right. Two details it took to get there: the dodge and the
  color blend act on sRGB values directly, and the radial gradient
  interpolates colour *and* alpha together (straight, not premultiplied),
  which makes its middle 10/255 brighter than a fade to the end colour.
  Only the bottom strip, below the type, is the render: the skyline vectors
  of 978:15079 peek into it, and nothing that moves ever reaches it.
* **The ball and the star are their uploads**, at the CSS transform: the
  ball is 48.31pt rotated −13.02° in its 57.95 box, the star fills its box.
  Composited over the rebuilt backdrop they match the render to 2.6 and 1.3
  out of 255, which is antialiasing.
* **The bolt is its upload with the render's colour.** Figma draws it paler
  and cooler than the file, an image adjustment the CSS does not report. Its
  alpha is the upload's, so its edge is exact; its colour is the upload's
  mapped through a quadratic fitted against the render inside the ball.
* **The avatar is an ellipse**, so its matte is a circle.
* **The stickers are `pq_badge1…3`**, the same nodes as the profile card's.

And, for the rays animation, the backdrop in two planes (`Tools/ae/`):

    acct_rays_base     the backdrop with no starburst at all
    acct_rays          the starburst's contribution, as an RGBA plane that
                       reproduces the backdrop when laid over the base
    acct_rays_soft     the same with its outer edge feathered, for the copies
                       that fly outward and must never show a boundary
"""

import json
import os
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "account_src")
CATALOG = os.path.join(HERE, "..", "GyroQR", "Assets.xcassets")
AE_OUT = os.path.join(HERE, "ae", "account_rays")

S = 3
HEADER_W, HEADER_H = 375.0, 428.756

# The starburst's box, header-local. `978:15075` hangs at y −197.
RAYS_BOX = dict(x=-26.0, y=-197.17, w=428.637, h=767.612)
# Its vanishing point is the image's centre.
VP = (RAYS_BOX["x"] + RAYS_BOX["w"] / 2, RAYS_BOX["y"] + RAYS_BOX["h"] / 2)

# The planes' extent: the full width of the upload, and enough height that
# the rays plane still covers the header when scaled down to 0.88 about VP.
EXT = dict(x=-26.0, y=-24.0, w=428.0, h=486.0)
# Below this the backdrop is the render (the skyline art).
RENDER_FROM = 360.0

AVATAR = dict(x=114.33, y=113.67, d=146.33)
PROPS = [
    # name, upload, CSS box (header-local), drawn size inside it, rotation
    dict(name="acct_ball", file="raw_ball_r2.png",
         box=(287.51, 289.76 - 197, 57.954, 57.954), inner=(48.311, 48.311), rot=-13.02),
    dict(name="acct_star", file="raw_star_r1.png",
         box=(288.23, 460.91 - 197, 82.176, 82.176), inner=(82.176, 82.176), rot=0.0),
    dict(name="acct_bolt", file="raw_bolt_r1.png",
         box=(48.36, 460.79 - 197, 42.508, 41.969), inner=(42.508, 41.969), rot=0.0,
         grade=True),
]
STICKERS = [
    dict(name="pq_badge1", x=125.00, y=232.00, w=51.33, h=42.33),
    dict(name="pq_badge2", x=161.33, y=226.67, w=49.00, h=55.33),
    dict(name="pq_badge3", x=198.67, y=226.00, w=49.67, h=49.33),
]


def hexc(h):
    return np.array([(h >> 16) & 255, (h >> 8) & 255, h & 255]) / 255.0


def save(rgba, name, scale=S, folder=None):
    arr = np.clip(rgba * 255 + 0.5, 0, 255).astype(np.uint8)
    if folder:
        os.makedirs(folder, exist_ok=True)
        path = os.path.join(folder, f"{name}.png")
    else:
        d = os.path.join(CATALOG, f"{name}.imageset")
        os.makedirs(d, exist_ok=True)
        path = os.path.join(d, f"{name}.png")
        json.dump({"images": [{"filename": f"{name}.png", "idiom": "universal",
                               "scale": f"{scale}x"}],
                   "info": {"author": "xcode", "version": 1}},
                  open(os.path.join(d, "Contents.json"), "w"), indent=2)
    Image.fromarray(arr).save(path, optimize=True)
    print(f"  {name:16s} {arr.shape[1]}x{arr.shape[0]}  {os.path.getsize(path) // 1024}KB")


# ---------------------------------------------------------------- the backdrop

def grid(ext, scale=S):
    W, H = round(ext["w"] * scale), round(ext["h"] * scale)
    x = ext["x"] + (np.arange(W) + 0.5) / scale
    y = ext["y"] + (np.arange(H) + 0.5) / scale
    return np.meshgrid(x, y)


def starburst(ext, scale=S):
    """The upload, laid into `ext` at its CSS box. Zero outside it."""
    im = Image.open(os.path.join(SRC, "raw_rays1.png")).convert("RGB")
    W, H = round(ext["w"] * scale), round(ext["h"] * scale)
    # One affine resample straight into the output grid, so there is no
    # rounding between the box and the pixels.
    sx = im.size[0] / RAYS_BOX["w"]
    sy = im.size[1] / RAYS_BOX["h"]
    ox = (ext["x"] - RAYS_BOX["x"]) * sx
    oy = (ext["y"] - RAYS_BOX["y"]) * sy
    out = im.transform((W, H), Image.AFFINE,
                       (sx / scale, 0, ox, 0, sy / scale, oy),
                       resample=Image.BICUBIC)
    return np.asarray(out).astype(np.float64) / 255


def lum(c):
    return c[..., 0] * 0.3 + c[..., 1] * 0.59 + c[..., 2] * 0.11


def set_lum(c, l):
    c = c + (l - lum(c))[..., None]
    l = lum(c)[..., None]
    n = c.min(-1, keepdims=True)
    x = c.max(-1, keepdims=True)
    c = np.where(n < 0, l + (c - l) * l / np.maximum(l - n, 1e-6), c)
    c = np.where(x > 1, l + (c - l) * (1 - l) / np.maximum(x - l, 1e-6), c)
    return c


def backdrop(ext, rays=True, scale=S):
    X, Y = grid(ext, scale)
    t = np.clip(Y / HEADER_H, 0, 1)[..., None]
    c = hexc(0x2188FF) * (1 - t) + hexc(0x0A49B8) * t
    if rays:
        s = starburst(ext, scale)
        c = np.where(s >= 1, 1.0, np.minimum(1, c / np.maximum(1 - s, 1e-6)))
    c = set_lum(np.broadcast_to(hexc(0x7D43EA), c.shape), lum(c))
    # The vignette, in the box of 978:15078 (x 0.5, header y −197).
    r = np.hypot((X - 0.5 - 188) / 797.37, (Y + 197 - 313.5) / 237.0)
    a = np.clip(r, 0, 1)[..., None]
    col = hexc(0x7D43EA) * (1 - a) + hexc(0x4C17B0) * a
    return np.clip(c * (1 - a) + col * a, 0, 1)


def with_render_strip(img, ext, render):
    """Swap in the render below the type, with a 4pt blend."""
    X, Y = grid(ext)
    w = np.clip((Y - RENDER_FROM) / 4.0, 0, 1)
    inside = (X >= 0) & (X < HEADER_W) & (Y >= 0) & (Y < 429)
    out = img.copy()
    ys, xs = np.nonzero(inside)
    ry = np.clip(((Y[inside]) * S).astype(int), 0, render.shape[0] - 1)
    rx = np.clip(((X[inside]) * S).astype(int), 0, render.shape[1] - 1)
    ww = w[inside][:, None]
    out[ys, xs] = img[ys, xs] * (1 - ww) + render[ry, rx] * ww
    return out


def matte_over(F, B):
    """An RGBA plane P with P over B == F, as transparent as possible.

    The starburst only ever brightens, so every pixel is B moved toward
    something lighter: α is the least that gets the brightest-moving channel
    there, and the colour follows from it.
    """
    up = np.where(F > B, (F - B) / np.maximum(1 - B, 1e-4), 0)
    a = np.clip(up.max(-1), 0, 1)[..., None]
    C = np.clip((F - B * (1 - a)) / np.maximum(a, 1e-4), 0, 1)
    C = np.where(a > 1e-3, C, 1.0)
    return np.dstack([C, a[..., 0]])


# ------------------------------------------------------------------- the planes

def cover(im, w, h):
    iw, ih = im.size
    s = max(w / iw, h / ih)
    im = im.resize((max(1, round(iw * s)), max(1, round(ih * s))), Image.LANCZOS)
    l, t = (im.size[0] - w) // 2, (im.size[1] - h) // 2
    return im.crop((l, t, l + w, t + h))


def prop_plane(p):
    """The upload at its CSS transform, on a canvas the size of the CSS box."""
    x, y, w, h = p["box"]
    im = Image.open(os.path.join(SRC, p["file"])).convert("RGBA")
    im = cover(im, round(p["inner"][0] * S), round(p["inner"][1] * S))
    if p["rot"]:
        im = im.rotate(-p["rot"], resample=Image.BICUBIC, expand=True)
    W, H = round(w * S), round(h * S)
    canvas = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    canvas.alpha_composite(im, ((W - im.size[0]) // 2, (H - im.size[1]) // 2))
    return np.asarray(canvas).astype(np.float64) / 255


def paste(dst, plane, x, y):
    X0, Y0 = int(round(x * S)), int(round(y * S))
    h, w = plane.shape[:2]
    H, W = dst.shape[:2]
    xs, ys, xe, ye = max(0, X0), max(0, Y0), min(W, X0 + w), min(H, Y0 + h)
    s = plane[ys - Y0:ye - Y0, xs - X0:xe - X0]
    a = s[..., 3:]
    dst[ys:ye, xs:xe] = s[..., :3] * a + dst[ys:ye, xs:xe] * (1 - a)


def grade(plane, p, bg, render):
    """Map the upload's colour onto the render's, through a quadratic in RGB."""
    x, y = p["box"][:2]
    X0, Y0 = int(round(x * S)), int(round(y * S))
    h, w = plane.shape[:2]
    a = plane[..., 3]
    core = a > 0.985
    src = plane[..., :3][core]
    dst = render[Y0:Y0 + h, X0:X0 + w][core]

    def feats(c):
        r, g, b = c[:, 0], c[:, 1], c[:, 2]
        return np.stack([r, g, b, r * r, g * g, b * b, r * g, g * b, b * r,
                         np.ones_like(r)], 1)

    M, *_ = np.linalg.lstsq(feats(src), dst, rcond=None)
    flat = plane[..., :3].reshape(-1, 3)
    out = np.clip(feats(flat) @ M, 0, 1).reshape(plane[..., :3].shape)
    err = np.abs(np.clip(feats(src) @ M, 0, 1) - dst).mean() * 255
    print(f"    colour grade fitted on {core.sum()} px, residual {err:.2f}/255")
    return np.dstack([out, a])


def avatar_plane():
    rgb = np.asarray(Image.open(os.path.join(SRC, "avatar3x.png")).convert("RGB")
                     ).astype(np.float64) / 255
    n = rgb.shape[0]
    Y, X = np.mgrid[0:n, 0:n]
    d = np.hypot(X - (n - 1) / 2, Y - (n - 1) / 2)
    return np.dstack([rgb, np.clip(n / 2 - d + 0.5, 0, 1)])


def sticker_plane(st):
    im = Image.open(os.path.join(CATALOG, f"{st['name']}.imageset/{st['name']}.png")
                    ).convert("RGBA")
    im = im.resize((round(st["w"] * S), round(st["h"] * S)), Image.LANCZOS)
    return np.asarray(im).astype(np.float64) / 255


# ---------------------------------------------------------------- verification

def report(name, a, b, box, pad=4):
    x, y, w, h = box
    sl = (slice(max(0, int((y - pad) * S)), int((y + h + pad) * S)),
          slice(max(0, int((x - pad) * S)), min(a.shape[1], int((x + w + pad) * S))))
    d = np.abs(a[sl] - b[sl]).mean(-1) * 255
    print(f"    {name:12s} mean {d.mean():5.2f}  p95 {np.percentile(d, 95):5.2f}  (/255)")


def main():
    header_ext = dict(x=0, y=0, w=375, h=429)
    render = np.asarray(Image.open(os.path.join(SRC, "header3x.png")).convert("RGB")
                        ).astype(np.float64) / 255

    print("the backdrop")
    bg = with_render_strip(backdrop(header_ext), header_ext, render)

    # Where the render shows only backdrop, the rebuild must equal it.
    X, Y = grid(header_ext)
    clear = np.ones(X.shape, bool)
    for p in PROPS:
        x, y, w, h = p["box"]
        clear &= ~((X > x - 3) & (X < x + w + 3) & (Y > y - 3) & (Y < y + h + 3))
    clear &= ~((X > 90) & (X < 285) & (Y > 95) & (Y < 360))      # avatar, stickers, type
    clear &= ~(Y < 104)                                            # status bar, buttons
    d = np.abs(bg - render).mean(-1)[clear] * 255
    print(f"    rebuild vs render, clear backdrop: mean {d.mean():.2f}  p95 "
          f"{np.percentile(d, 95):.2f}  p99 {np.percentile(d, 99):.2f}  (/255)")

    print("written")
    save(bg, "acct_bg")
    # Frame 0 of the rays animation: the header before any ray has arrived.
    # The Lottie view shows it while the archive loads, so there is no flash.
    save(with_render_strip(backdrop(header_ext, rays=False), header_ext, render),
         "acct_bg_base")
    save(avatar_plane(), "acct_avatar")
    planes = {}
    for p in PROPS:
        plane = prop_plane(p)
        if p.get("grade"):
            plane = grade(plane, p, bg, render)
        planes[p["name"]] = plane
        save(plane, p["name"])

    print("recomposited against the design")
    comp = bg.copy()
    for p in PROPS:
        paste(comp, planes[p["name"]], *p["box"][:2])
        report(p["name"][5:], comp, render, p["box"])
    paste(comp, avatar_plane(), AVATAR["x"], AVATAR["y"])
    report("avatar", comp, render, (AVATAR["x"] + 8, AVATAR["y"] + 8,
                                   AVATAR["d"] - 16, AVATAR["d"] - 16), pad=0)
    for st in STICKERS:
        paste(comp, sticker_plane(st), st["x"], st["y"])
    report("stickers", comp, render, (125, 226, 123, 56), pad=0)

    print("the rays, for After Effects")
    F = backdrop(EXT)
    B = backdrop(EXT, rays=False)
    # The render strip belongs in both, so the rays plane is clear over it.
    F = with_render_strip(F, EXT, render)
    B = with_render_strip(B, EXT, render)
    rays = matte_over(F, B)
    back = rays[..., :3] * rays[..., 3:] + B * (1 - rays[..., 3:])
    d = np.abs(back - F).mean(-1) * 255
    print(f"    rays over base vs backdrop: mean {d.mean():.2f}  max {d.max():.2f}  (/255)")
    save(np.dstack([B, np.ones(B.shape[:2])]), "acct_rays_base", folder=AE_OUT)
    save(rays, "acct_rays", folder=AE_OUT)

    # The soft copy: feathered to nothing by 200pt from the vanishing point,
    # which is inside the upload's nearest edge (214pt away, left and right),
    # so a copy at any scale shows rays thinning out and never an edge.
    soft_ext = dict(x=VP[0] - 206, y=VP[1] - 206, w=412, h=412)
    Fs, Bs = backdrop(soft_ext, scale=2), backdrop(soft_ext, rays=False, scale=2)
    soft = matte_over(Fs, Bs)
    Xs, Ys = grid(soft_ext, scale=2)
    r = np.hypot(Xs - VP[0], Ys - VP[1])
    t = np.clip((200 - r) / 70, 0, 1)
    soft[..., 3] *= t * t * (3 - 2 * t)
    save(soft, "acct_rays_soft", folder=AE_OUT)

    json.dump(dict(size=[375, 429], vp=[round(VP[0], 3), round(VP[1], 3)],
                   rays=dict(file="acct_rays.png", x=EXT["x"], y=EXT["y"],
                             w=EXT["w"], h=EXT["h"], scale=S),
                   soft=dict(file="acct_rays_soft.png", x=soft_ext["x"],
                             y=soft_ext["y"], w=412, h=412, scale=2),
                   base=dict(file="acct_rays_base.png", x=EXT["x"], y=EXT["y"],
                             w=EXT["w"], h=EXT["h"], scale=S)),
              open(os.path.join(AE_OUT, "layout.json"), "w"), indent=1)

    print("\nAccountSpec frames")
    for p in PROPS:
        x, y, w, h = p["box"]
        print(f"  {p['name'][5:]:6s} CGRect(x: {x:.2f}, y: {y:.2f}, width: {w:.2f}, height: {h:.2f})")


if __name__ == "__main__":
    main()
