import os, json
import numpy as np
from PIL import Image
_R = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(_R, 'Tools', 'source_layers')
DST = os.path.join(_R, 'GyroQR', 'Assets.xcassets')

def resize_rgba(im, size):
    """Resize in PREMULTIPLIED space. Resizing straight RGBA pulls the black of
    fully-transparent pixels into edge pixels, which a later blur then smears
    into a dark halo."""
    a=np.asarray(im.convert('RGBA')).astype(np.float64)/255
    al=a[...,3:4]
    pm=np.concatenate([a[...,:3]*al, al],-1)
    small=np.asarray(Image.fromarray((pm*255).round().astype(np.uint8),'RGBA')
                     .resize(size, Image.LANCZOS)).astype(np.float64)/255
    out_a=np.clip(small[...,3:4],0,1)
    rgb=np.where(out_a>1e-4, small[...,:3]/np.maximum(out_a,1e-4), 0.0)
    out=np.concatenate([np.clip(rgb,0,1), out_a],-1)
    return Image.fromarray((out*255).round().astype(np.uint8),'RGBA')

SPEC = {
 'plate':          (351.0, 450.0),
 'blob':           (351.0, 450.0),
 'qr_panel':       (196.577, 196.577),
 'name':           (280.0, 42.0),
 'mascot_baseball':(38.446, 37.959),
 'mascot_fuzzy':   (35.049, 35.049),
 'mascot_grin':    (72.369, 72.369),
 'screen_backdrop':(375.0, 812.0),
 'avatar':         (112.4956, 112.4956),
}
HEADROOM = {'mascot_baseball':2.0,'mascot_fuzzy':2.0,'mascot_grin':2.0}

for name,(w,h) in SPEC.items():
    src=Image.open(f'{SRC}/{name}.png').convert('RGBA')
    d=f'{DST}/{name}.imageset'; os.makedirs(d, exist_ok=True)
    imgs=[]; hr=HEADROOM.get(name,1.0)
    for s in (1,2,3):
        size=(max(1,int(round(w*s*hr))), max(1,int(round(h*s*hr))))
        fn=f'{name}@{s}x.png' if s>1 else f'{name}.png'
        resize_rgba(src, size).save(f'{d}/{fn}')
        imgs.append({"idiom":"universal","filename":fn,"scale":f"{s}x"})
    json.dump({"images":imgs,"info":{"author":"xcode","version":1}},
              open(f'{d}/Contents.json','w'), indent=2)
print('assets regenerated (premultiplied)')

# sanity: edge darkening check on the baseball
a=np.asarray(Image.open(f'{DST}/mascot_baseball.imageset/mascot_baseball@3x.png')).astype(float)
semi=(a[...,3]>20)&(a[...,3]<200)
print('semi-transparent edge pixels: %d  mean RGB %.0f (higher = no black bleed)'
      % (semi.sum(), a[...,:3][semi].mean()))


# ---- wallet skins (skin-select scene) ----
# One universal slot per skin, at native pixel size. 22 skins x 3 scale slots
# would be ~90MB of catalog; the scene always sets an explicit frame, so a
# single high-resolution file behaves like a 3x asset at any size it is drawn.
import glob as _glob
_skins = sorted(_glob.glob(f'{SRC}/skin_*.png'))
for src in _skins:
    name = os.path.splitext(os.path.basename(src))[0]
    d = f'{DST}/{name}.imageset'; os.makedirs(d, exist_ok=True)
    Image.open(src).convert('RGBA').save(f'{d}/{name}.png', optimize=True)
    json.dump({"images": [{"idiom": "universal", "filename": f"{name}.png"}],
               "info": {"author": "xcode", "version": 1}},
              open(f'{d}/Contents.json', 'w'), indent=2)
print(f'wallet skins: {len(_skins)}')
