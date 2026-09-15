"""Normalise the wallet-skin card art for the skin-select scene.

INPUT  Tools/skin_src/skin_NN.png          - card art from Figma node 794:30710
       Tools/skin_src/skin_NN_alpha.png    - optional alpha donor, see below
OUTPUT Tools/source_layers/skin_NN.png     - trimmed, premultiplied-safe card
"""
import numpy as np, os, glob
from PIL import Image, ImageFilter

TOOLS = os.path.dirname(os.path.abspath(__file__))
os.chdir(TOOLS)
OUT = 'source_layers'; os.makedirs(OUT, exist_ok=True)

# Target width of the trimmed card art, in pixels. The scene draws the hero card
# at 316pt, so 3x that plus headroom for the settle-bounce overshoot.
TARGET_W = 1100

for src in sorted(glob.glob('skin_src/skin_[0-9][0-9].png')):
    name = os.path.basename(src)
    im = Image.open(src).convert('RGBA')
    a = np.asarray(im).astype(np.float64) / 255

    # A few hi-res sources were exported flattened onto a solid backdrop. The
    # low-res variant of the same art kept its alpha, and both share framing, so
    # take RGB from the sharp one and the matte from the small one.
    donor = src.replace('.png', '_alpha.png')
    if os.path.exists(donor):
        d = Image.open(donor).convert('RGBA')
        assert abs(d.width/d.height - im.width/im.height) < 0.01, name
        al = np.asarray(d.resize(im.size, Image.LANCZOS)).astype(np.float64)[..., 3] / 255
        a[..., 3] = np.clip(al, 0, 1)

    ys, xs = np.nonzero(a[..., 3] > 0.02)
    a = a[ys.min():ys.max()+1, xs.min():xs.max()+1]

    # Resize in premultiplied space so the soft shadow edge cannot pull the
    # transparent black background into the card's outline.
    pm = np.concatenate([a[..., :3] * a[..., 3:4], a[..., 3:4]], -1)
    h = max(1, int(round(TARGET_W * pm.shape[0] / pm.shape[1])))
    pm = np.asarray(Image.fromarray((np.clip(pm, 0, 1)*255).astype(np.uint8))
                    .resize((TARGET_W, h), Image.LANCZOS)).astype(np.float64)/255
    al = np.maximum(pm[..., 3:4], 1e-6)
    out = np.concatenate([np.clip(pm[..., :3]/al, 0, 1), pm[..., 3:4]], -1)
    Image.fromarray((out*255).astype(np.uint8)).save(f'{OUT}/{name}')
    print('%-14s %-12s -> %dx%d  alpha%s' % (name, str(im.size), TARGET_W, h,
                                             ' (grafted)' if os.path.exists(donor) else ''))
