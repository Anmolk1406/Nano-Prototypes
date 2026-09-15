"""Split the flat Figma card export into separable parallax planes.

INPUT  Tools/card_flat3x.png -- the `779:22089` node exported from Figma at 3x.
       It is NOT checked in; re-export it when the design changes.
OUTPUT Tools/source_layers/*.png -- feed these to make_assets.py.
"""
import numpy as np, sys, os
from PIL import Image, ImageDraw, ImageFilter
TOOLS = os.path.dirname(os.path.abspath(__file__))
os.chdir(TOOLS)
sys.path.insert(0, TOOLS)
from fill import pushpull

S=3; CW,CH=351,450; W,H=CW*S,CH*S
OX,OY=36,39
OUT='source_layers'; os.makedirs(OUT,exist_ok=True)

if os.path.exists('figma_reference_3x.png'):
    flat=Image.open('figma_reference_3x.png').convert('RGBA')   # already card-cropped
else:
    flat=Image.open('card_flat3x.png').convert('RGBA').crop((OX,OY,OX+W,OY+H))
    flat.save('figma_reference_3x.png')
img=np.asarray(flat).astype(np.float64)/255
rgb=img[...,:3].copy()
def np2pil(a): return Image.fromarray((np.clip(a,0,1)*255).astype(np.uint8))
def blurL(a,r):
    return np.asarray(Image.fromarray((np.clip(a,0,1)*255).astype(np.uint8))
                      .filter(ImageFilter.GaussianBlur(r))).astype(np.float64)/255
def rect_px(x,y,w,h,pad=0):
    return (int(round((x-pad)*S)),int(round((y-pad)*S)),
            int(round((x+w+pad)*S)),int(round((y+h+pad)*S)))

# ---- blob mask (top-right magenta wash) ----
r,g,b=rgb[...,0],rgb[...,1],rgb[...,2]
mag=np.clip((r-g)+(b-g),0,None)
yy,xx=np.mgrid[0:H,0:W].astype(np.float64); u=xx/W; v=yy/H
win=np.clip((u-0.55)/0.18,0,1)*np.clip((0.34-v)/0.14,0,1)
blob_a=blurL(np.clip((mag*win-0.06)/0.55,0,1),6)

# ---- holes ----
holes=np.zeros((H,W))
def add_rect(x,y,w,h,pad=0):
    x0,y0,x1,y1=rect_px(x,y,w,h,pad)
    x0=max(0,x0);y0=max(0,y0);x1=min(W,x1);y1=min(H,y1)
    holes[y0:y1,x0:x1]=1.0; return (x0,y0,x1,y1)
# Figma's CSS positions are relative to the card's PADDING box, i.e. inside the
# 4pt border. Everything below is shifted by that border to land in card coords.
B = 4.0
R_BASEBALL=add_rect(26.27+B, 57.26+B, 38.446,37.959, pad=12)
R_FUZZY   =add_rect(-21.78+B,270.38+B, 49.551,49.551, pad=7)
R_GRIN    =add_rect(301.77+B,266.91+B, 72.369,72.369, pad=15)
R_QR      =add_rect(73.21+B, 121.0+B,  196.577,196.577, pad=3)
R_NAME    =add_rect(34.5+B,  78.0+B,   274.0,32.0,   pad=5)
holes=np.maximum(holes,(blob_a>0.02).astype(np.float64))
print('hole coverage %.3f'%holes.mean())

known=1.0-holes
filled=pushpull(rgb,known)
kf=blurL(known,4)*known
plate=rgb*kf[...,None]+filled*(1-kf[...,None])
np2pil(plate).save(f'{OUT}/plate.png')

# ---- blob layer ----
np2pil(np.concatenate([rgb,blob_a[...,None]],-1)).save(f'{OUT}/blob.png')

# ---- QR panel ----
x0,y0,x1,y1=rect_px(73.21+B,121.0+B,196.577,196.577,0)
qr=flat.crop((x0,y0,x1,y1)).convert('RGBA')
m=Image.new('L',qr.size,0)
ImageDraw.Draw(m).rounded_rectangle([0,0,qr.width-1,qr.height-1],radius=int(round(16.8495*S)),fill=255)
qr.putalpha(m); qr.save(f'{OUT}/qr_panel.png')

# ---- name text matte ----
# Lift the glyphs off the background as an alpha matte, so the original
# Noontree Bold shapes survive instead of being re-set in a substitute font.
#
# Two things have to be kept OUT of this matte or they reappear as a dark ghost
# floating above the card:
#   * the baseball, whose lower half overlaps the text box on the left;
#   * the star rays behind the text, which are darker than the smooth inpaint
#     the matte measures against and so leak in as weak alpha.
nx0,ny0,nx1,ny1=R_NAME
sub=rgb[ny0:ny1,nx0:nx1]; bg=filled[ny0:ny1,nx0:nx1]
TXT=np.array([0x1d/255,0x25/255,0x39/255])
alpha=np.max(np.clip((bg-sub)/np.maximum(bg-TXT,1e-3),0,1),axis=-1)

TEXT_LEFT_PT = 75.0                      # clear of the baseball + its blur
cut = int(round(TEXT_LEFT_PT*S)) - nx0
if cut > 0: alpha[:, :cut] = 0
alpha = np.clip((alpha-0.22)/0.78, 0, 1)  # floor off the faint background leak

ys,xs = np.nonzero(alpha > 0.25)
pad = int(round(4*S))
ix0,ix1 = max(0,xs.min()-pad), min(alpha.shape[1], xs.max()+pad+1)
iy0,iy1 = max(0,ys.min()-pad), min(alpha.shape[0], ys.max()+pad+1)
alpha = alpha[iy0:iy1, ix0:ix1]
name=np.zeros((*alpha.shape,4)); name[...,:3]=TXT; name[...,3]=alpha
np2pil(name).save(f'{OUT}/name.png')
NAME_ORIGIN = ((nx0+ix0)/S, (ny0+iy0)/S)
NAME_SIZE   = (alpha.shape[1]/S, alpha.shape[0]/S)

# The mascots come straight from Figma (nodes 22207/22208/22209) and are
# already correct in source_layers/ -- nothing to do here.
print('plate qr-center', (plate[658,514]*255).round(), ' boundary', (plate[658,205]*255).round())
print('QR panel origin pt = (%.3f, %.3f)'%(x0/S,y0/S))
print('NAME layer  origin pt = (%.3f, %.3f)  size = (%.3f, %.3f)'%(*NAME_ORIGIN,*NAME_SIZE))
print('done'); print('RECTS', dict(baseball=R_BASEBALL,fuzzy=R_FUZZY,grin=R_GRIN,qr=R_QR,name=R_NAME))
