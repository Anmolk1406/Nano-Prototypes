"""Split the full-screen Figma export (node 779:22071) into the pieces the app
draws live.

INPUT  Tools/screen_flat3x.png  -- the screen exported from Figma at 3x.
OUTPUT Tools/source_layers/screen_backdrop.png, avatar.png
"""
import numpy as np, sys, os
from PIL import Image, ImageDraw, ImageFilter
TOOLS = os.path.dirname(os.path.abspath(__file__))
os.chdir(TOOLS); sys.path.insert(0, TOOLS)
from fill import pushpull

S = 3
SCREEN_W, SCREEN_H = 375, 812
CARD = (12.0, 139.0, 351.0, 450.0)          # Figma node 779:22089
AVATAR = (131.25, 81.52490234375, 112.49560546875, 112.49560546875)   # 779:22688
OUT = 'source_layers'; os.makedirs(OUT, exist_ok=True)

flat = Image.open('screen_flat3x.png').convert('RGB')
assert flat.size == (SCREEN_W*S, SCREEN_H*S), flat.size
rgb = np.asarray(flat).astype(np.float64)/255
H, W = rgb.shape[:2]

# The card is drawn live and it tilts, so the baked copy underneath has to go or
# it shows through at the edges. The fill only has to be continuous with the
# border it meets — the card covers all but ~30pt of it at any tilt.
# Keep the pad tight to the card. Cutting the full width instead would take the
# lavender side strips with it and leave them a flat interpolated white.
PAD = 6.0
# The card's baked drop shadow reaches ~19pt below it. The live card draws its
# own, so the baked one has to go or the two stack and darken the transparent
# top of the sheet. 608pt stops short of the OR row at 610.
BOTTOM_PAD = 15.0
x0 = max(0, int(round((CARD[0]-PAD)*S)))
y0 = max(0, int(round((CARD[1]-PAD)*S)))
x1 = min(W, int(round((CARD[0]+CARD[2]+PAD)*S)))
y1 = min(H, int(round((CARD[1]+CARD[3]+BOTTOM_PAD)*S)))
known = np.ones((H, W)); known[y0:y1, x0:x1] = 0.0

# The avatar rides the card now, and it sits far above the card's centre, so
# the 3D rotation swings it a long way. Its baked copy has to come out too or
# it shows as a second, static head. Only the part above the card's hole is new.
AV_PAD = 10.0
known[max(0, int(round((AVATAR[1]-AV_PAD)*S))):min(H, int(round((AVATAR[1]+AVATAR[3]+AV_PAD)*S))),
      max(0, int(round((AVATAR[0]-AV_PAD)*S))):min(W, int(round((AVATAR[0]+AVATAR[2]+AV_PAD)*S)))] = 0.0

filled = pushpull(rgb, known)
kf = np.asarray(Image.fromarray((known*255).astype(np.uint8))
                .filter(ImageFilter.GaussianBlur(6))).astype(np.float64)/255 * known
backdrop = rgb*kf[...,None] + filled*(1-kf[...,None])
Image.fromarray((np.clip(backdrop,0,1)*255).astype(np.uint8)).save(f'{OUT}/screen_backdrop.png')
print('backdrop  %dx%d px  (card rect %.0f,%.0f..%.0f,%.0f + avatar refilled)'
      % (W, H, CARD[0]-PAD, CARD[1]-PAD, CARD[0]+CARD[2]+PAD, CARD[1]+CARD[3]+BOTTOM_PAD))

# The OR row is drawn live on top of the baked one. The invite field is opaque
# so it covers itself, but this row is thin text and hairlines — at the device's
# 1.076 scale the two rasterisations do not align sub-pixel and it prints bold.
# It is a thin band on a smooth gradient, so refilling it is clean. The 2pt gap
# to the card's hole above keeps the two from merging into one tall cavity,
# which is what makes the fill drift.
OR_ROW = (20.0, 610.0, 335.0, 18.0)          # 779:22705
known2 = np.ones((H, W)); p2 = 4.0
known2[max(0,int(round((OR_ROW[1]-p2)*S))):min(H,int(round((OR_ROW[1]+OR_ROW[3]+p2)*S))),
       max(0,int(round((OR_ROW[0]-p2)*S))):min(W,int(round((OR_ROW[0]+OR_ROW[2]+p2)*S)))] = 0.0
src = np.asarray(Image.open(f'{OUT}/screen_backdrop.png').convert('RGB')).astype(np.float64)/255
filled2 = pushpull(src, known2)
kf2 = np.asarray(Image.fromarray((known2*255).astype(np.uint8))
                 .filter(ImageFilter.GaussianBlur(4))).astype(np.float64)/255 * known2
out2 = src*kf2[...,None] + filled2*(1-kf2[...,None])
Image.fromarray((np.clip(out2,0,1)*255).astype(np.uint8)).save(f'{OUT}/screen_backdrop.png')
print('backdrop  OR row refilled (%.0f..%.0f pt)' % (OR_ROW[1]-p2, OR_ROW[1]+OR_ROW[3]+p2))

# Avatar: crop the circle straight out of the flat render so it keeps its ring
# and lighting; the app clips it to a Circle, so the corners do not matter.
ax0, ay0 = int(round(AVATAR[0]*S)), int(round(AVATAR[1]*S))
ax1, ay1 = int(round((AVATAR[0]+AVATAR[2])*S)), int(round((AVATAR[1]+AVATAR[3])*S))
av = flat.crop((ax0, ay0, ax1, ay1)).convert('RGBA')
m = Image.new('L', av.size, 0)
ImageDraw.Draw(m).ellipse([0, 0, av.width-1, av.height-1], fill=255)
av.putalpha(m)
av.save(f'{OUT}/avatar.png')
print('avatar    %dx%d px  (%.2f pt)' % (av.width, av.height, AVATAR[2]))
