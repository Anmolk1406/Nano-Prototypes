# GyroQR

A SwiftUI test app for exploring **gyroscopic effects on the QR share card** from
[Anmol | Motion Canvas → `1 Child details`](https://www.figma.com/design/Or9RuyCtjXRPrnbUJFx7As/Anmol-%7C-Motion-Canvas?node-id=779-22071)
(Figma node `779:22089`).

The full screen is built — close button, avatar, card, caption, OR divider,
invite link, Share button, home bar — laid out at the design's native 375 × 812
and scaled to the device. The card is the live piece; everything else is chrome.

The card is not a flat screenshot. It is decomposed into parallax planes at
different **elevations above the card surface**, so tilting the phone moves them
against each other and the QR panel reads as floating above its container.

At rest the render matches the Figma export to a **1.41 % mean pixel error**.
In motion it is calibrated against a reference clip — see
[Matching the reference](#matching-the-reference).

---

## What responds to the gyro

| Effect | What it does |
|---|---|
| **3D tilt** | The whole card rotates on X and Y with perspective. |
| **In-plane roll** | A couple of degrees of Z rotation. Small, but a surprising amount of the liveliness. |
| **Elevation parallax** | A layer `h` points above the surface shifts by `h · tan(θ)` before the rotation. That single relationship is the whole depth model. |
| **Contact shadows** | The floating planes cast a shadow *onto* the card. The light is fixed in card space, so the shadow stays near the layer's un-parallaxed position while the layer itself drifts — this is the strongest elevation cue. |
| **Depth scaling** | Nearer planes grow slightly as the card turns toward them. |
| **Element wobble** | Mascots counter-rotate a few degrees, so they read as loose objects rather than stickers. |
| **Blur from roll** | Figma bakes a layer blur into the mascots. Held constant at this size it just reads as a smudge, so it is driven by \|tilt.x\| instead: sharp square-on, defocused as the card rolls either way. Toggle it off for the static Figma blur. |
| **Specular sheen** | A white band sweeps across the face; strongest while moving. |
| **Iridescence** | A narrow rainbow band slides opposite the sheen. Fades to zero when flat, so a resting card stays true to the design. |
| **Rim light** | The 4pt border highlight tracks the lit edge. |
| **Dynamic card shadow** | The card's own shadow slides opposite the tilt to keep it grounded. |
| **Idle recentre** | Hold the phone still and the card returns to flat, adopting that pose as level. |

## Parallax planes

Back to front, from `CardSpec.swift`. **Elevation** is height above the card
surface in points. Negative sits behind it, positive floats above.

| Layer | Elevation | Clipped | Shadow | Notes |
|---|---:|:--:|:--:|---|
| `plate` | −8 pt | ✓ | | Full card art with the moving pieces removed. Oversized 1.10× so its counter-drift never exposes an edge. |
| `blob` | −3 pt | ✓ | | The magenta wash in the top-right corner. |
| `grin` | +7 pt | ✓ | | Purple grinning ball, right edge. Figma opacity 30 %. |
| `fuzzy` | +9 pt | ✓ | | Purple fuzzy ball. Bleeds off the left edge by design, so it stays clipped. |
| `baseball` | +11 pt | ✓ | | Baseball with the lightning bolt, top-left. |
| `name` | +13 pt | | | "Kiaan Khalid", an alpha matte so the original Noontree Bold shapes survive. |
| `qr` | **+20 pt** | | **✓** | The hero. Drawn outside the card's clip so it may overhang. |
| `avatar` | **+20 pt** | | ✓ | The profile picture, on the QR's plane so the two move as one. Its card-local frame sits above the card's top edge, so it overhangs. |
| `caption` | 0 pt | | | Printed on the card surface — shares its plane exactly, no parallax against it, no shadow. |

Change the elevations in `CardSpec.swift` and rebuild, or scale them all live
with the **Elevation ×** slider.

## Scenes

The app hosts two prototypes; switch with the **Scene** picker at the top of the
controls sheet (the slider button, top right).

| Scene | What it is |
|---|---|
| **QR card** | The share screen — Figma `779:22071`. Gyro tilt, elevation parallax, the floating QR. |
| **Skin select** | The wallet-skin picker — Figma `794:30694`. Swipe up to cycle 22 skins, drag down to confirm. |

## Skin select

Both gestures live on one axis. Drag **up** throws the front card **back into
the stack** and brings the next one forward, cycling all 22 skins endlessly —
the design's own flow drops the swiped card off the bottom instead, which cannot
cycle. Drag **down** pulls the card into a white pocket to confirm.

**Entry.** The stack deals itself out of a single collapsed pile: cards start
stacked flat, scaled down and low, then fan into their slots back-to-front with
a ~45ms stagger while the header settles in. Around 515ms end to end
(`Response` + `Stagger` in the controls). It reads as a deck being squared off,
and deliberately avoids moving along either gesture axis so it never looks like
a hint.

**The cycle is one continuous quantity.** `advance` runs 0→1 and drives
everything at once: the thrown card rides up, shrinks and fades toward the
back-slot transform, every other card creeps one slot forward on a *fractional*
slot, and the background arc sweeps. At `advance == 1` the layout is identical
to the committed layout at 0, so the index swap happens inside a transaction
with animations disabled and nothing moves at the seam.

**The thrown card never fades, and it goes behind on release.** It rides up with
the finger — on top, since you are lifting it clear of the stack — and the
instant you let go it drops to the very back and arcs down into the parked slot,
getting progressively occluded on the way. Leaving it on top until the index
committed is what made it shrink *over* the stack and blink out at the very end.

That depth switch has to be `zIndex` on a **stable** `ForEach`. Re-sorting the
array mid-flight churns view identity and snaps the running animation straight
to its end state — the card vanishes in a single frame instead of settling. The
symptom looks exactly like "no animation", which is a slow thing to diagnose;
the tell is that slowing the spring to 1.4s changes nothing.

It ends up hidden because the card in front is larger and opaque, not
because it was faded out. That required changing the stack geometry: the rise
stops at the last visible slot, so cards parked deeper keep shrinking but hold
that height and sit entirely inside the card in front. With the old geometry a
parked card's top edge peeked above its neighbour, which is why a fade was
needed at all.

**The card drops behind the sheet.** During the pull the pocket outranks the
card in z; the moment it settles, they swap. That is what lets the card vanish
completely and then be presented on top.

**Background transition.** Crossfade by default — both skins are mounted and
`advance` drives the mix, so it tracks the throw and lands fully opaque exactly
as the index commits. **Arc** is the alternative: the incoming skin masked by a
circle centred below the screen, so only its top arc crosses the view as a dome
rising from the bottom. It looked good but did not run smoothly; each field is
now rasterised with `.drawingGroup()` so the full-screen blur happens once per
skin rather than every frame. `Arc depth` sets the curvature, and the edge is a
stroked circle in `.plusLighter` — **Rim**, **Glow** or **Bloom**.

**Idle hints** (off by default). Plays a fraction of each real transition rather
than a generic wiggle: the card lifts and the background reveals ~16% of the
next skin, then it dips ~13% into the pull with a light tick. Cancels on first
touch, resumes after a confirm is reset.

The pull, in order: the pocket rises from below, the card shrinks and descends
*behind* it, the rest of the stack recedes, and past the threshold the sheet
settles while the card — hidden at that moment — springs back up **on top** of
the sheet at hero size. Then `Confirm?` and the Continue button arrive.

**Gesture travel.** Both spans are long on purpose — a throw needs 215pt and a
pull 330pt, committing at 78% of either. The first pass used 105/165, which was
twitchy enough that the card was gone before the hand had finished moving: the
haptic ramp and the pocket rise both live inside the pull, so a short span skips
straight past them. Travel scales the *finger* distance, not the card's — the
card still moves exactly as far, it just takes a deliberate gesture to get it
there. `Drag travel` under **Gesture** scales both spans live (0.5–2.0) and the
row beneath it prints the resulting point distances.

`PocketShape` is the Figma vector `793:28368` traced as a SwiftUI `Path`: a
rectangle whose top edge carries a centred notch, the mouth of the wallet. Its
control points are the exported SVG's, with the shadow inset removed and x
normalised by the 385.342pt design width so it scales cleanly.

### Haptics

| Trigger | Feel |
|---|---|
| Throwing the card up | Detents along the travel, then a light impact on commit. |
| Pulling the card down | A pulse train that **grows** with the pull. |
| Card settles in the pocket | Rigid impact, then a softer one 85ms later — the card bedding in. |

The pull ramp is a train of discrete impacts, not one continuous Core Haptics
event. The first attempt was continuous and could not be felt on device; a pulse
train is audible on every device, and it makes the gap between taps a thing you
can actually tune. Strength ramps from `Start strength` to `End strength` across
the pull, and the generator steps light → medium → heavy along with it — a heavy
tap at 0.4 feels different from a light tap at 0.4, and that change of character
is what sells "getting closer".

The throw used to be silent until it committed, which left most of a 215pt
gesture with nothing to feel. It now fires `Throw detents` evenly-spaced ticks
across the travel, each a little firmer than the last.

Knobs under **Haptics** in the controls sheet:

| Knob | Default | What it does |
|---|---:|---|
| Pulse gap | 0.060s | Seconds between taps. Constant across the pull. |
| Start strength | 0.18 | Impact strength at the top of the pull. |
| End strength | 1.00 | Impact strength at the settle threshold. |
| Ramp curve | 1.40 | >1 holds it light for longer, then bites late. |
| Throw detents | 5 | Ticks fired across an upward throw. |

The timer is added to the run loop in `.common` mode — in `.default` it stops
dead the moment the drag starts tracking, which is a silent way to ship no
haptics at all.

### Verifying it

The Simulator has no touch input, so the scene ships a scripted replay:

```bash
xcrun simctl launch <udid> com.noon.gyroqr -skinDemo
```

It drives two swipes and a slow pull through the *same* `handleDrag`/`endDrag`
entry points the real gesture uses, so the haptics fire too. Add `-hapticLog` to
print the pulse train — gap, progress, generator band and strength per tap —
which is how the ramp is checked without a device to feel it on.

### Assets

The 22 skins come from Figma `794:30710`. Each node carries both a hi-res and a
low-res source and the frame-level fetch is capped at 20 images, so a naive pull
returns duplicates and misses six skins entirely — they were reconciled by
matching every candidate against crops of the frame render. Two hi-res sources
had been flattened onto solid backdrops; `Tools/build_skins.py` grafts the matte
from their low-res twins, which kept alpha and share framing.

Each skin's full-bleed background is derived at runtime from its own card art —
blown up past the frame and blurred. The design has a real material texture per
skin, but only a handful exist in the file, and 22 of them would add tens of
megabytes for something that is out of focus anyway.

## The screen

`ShareScreen.swift` lays the design out at its native 375 × 812 and scales it to
fill the device, so every frame in `ScreenSpec.swift` is the Figma value
verbatim. On an iPhone 17 Pro that scale is 1.076 and the design's 812pt height
lands within 4pt of the 874pt screen, so nothing is cropped meaningfully.

| Piece | Figma node | Notes |
|---|---|---|
| Backdrop | `779:22072` + decoration | The flat screen export with the card rect refilled — see below. |
| Close button | `779:22685` | M-IconButton H40, vector `cross` icon. |
| Avatar | `779:22688` | Cropped from the flat render, circular alpha baked in. Drawn as a card layer on the QR's plane. |
| Card | `779:22089` | The live gyro card. |
| Caption | `779:22701` | Native text, drawn as a card layer at elevation 0. |
| OR divider | `779:22705` | B12/Bold, `#989FB3`. |
| Invite link | `779:22709` | Capsule, `#D6E9FF` border, vector `copy` icon. |
| Share button | `M-NeutralButton` H52 | `#101628`, 12pt radius, vector `upload` icon. |

**The sheet has no fill of its own.** `779:22703` carries only a radius and a
shadow — the screen background shows through behind the OR row and the invite
field. Only the invite field, the action bar and the home bar are white. Backing
the whole container in white (the obvious reading) flattens that whole band.

Two knock-on effects, both handled in `Tools/build_screen.py`: the card's baked
drop shadow has to be cleared 15pt below the card or it stacks with the live
one and dirties the now-transparent band; and the OR row has to be cleared from
the backdrop because the live copy lands on it, and at the device's 1.076 scale
the two rasterisations do not align sub-pixel, so it prints bold. The invite
field needs neither — it is opaque and covers itself exactly.

**The caption and the avatar belong to the card, not the screen.** In Figma both
are siblings of the card, but they sit visually on it — left as siblings they
stay bolt upright while the card turns underneath, which reads as broken. Both
are drawn as card layers instead, at the elevations their appearance implies:
the caption at **0**, printed flat on the surface, and the avatar at **+20**,
the QR panel's plane, so the two float together. The avatar's card-local frame
puts it above the card's top edge, so it is a `floats` layer and overhangs the
clip the way the design shows.

**Anything that moves has to come out of the backdrop.** The backdrop is the
flat screen export, so every element the card carries is baked into it — and a
baked copy shows as a static ghost the moment the live one moves. That means the
card *and* the avatar: the avatar sits ~226pt above the card's centre, so the 3D
rotation swings it a long way, and its baked head was clearly visible behind the
live one until it was cut out too.

**The backdrop has the card cut out of it.** The card tilts, and a tilted card
is smaller than its flat footprint — so a backdrop with the card baked in shows
a ghost of it around the edges. `Tools/build_screen.py` refills the card's rect
(plus 6pt) with the same push-pull solver used for the card's own layers. The
pad is kept tight on purpose: cutting the full width instead takes the lavender
side strips with it and leaves them a flat interpolated white.

**Icons are real vector assets.** The three SVGs are checked in as asset-catalog
imagesets with `preserves-vector-representation`, rendered as templates. No
SF Symbol substitutes.

**Type is the system font.** The design uses Noontree, which is not on the
device. `ScreenSpec.TypeScale` matches its size, weight, line height and
tracking; the letterforms differ. The one exception is the name on the card,
which is lifted as an alpha matte and so keeps the real Noontree Bold shapes.

## Running it

```bash
open GyroQR.xcodeproj
```

Build and run on a **device** for real gyro. Portrait only.

In the **Simulator** there is no gyro, so the app falls back to `Demo` — a slow
automatic orbit — and you can switch input at any time:

- **Gyro** — `CMMotionManager` device motion, relative to a captured reference
  attitude. Hit **Recenter** to treat however you are holding the phone as flat.
  Hold the phone still and the card **eases itself back to level**: after
  `Idle delay` seconds without meaningful movement (1.5 s by default), the pose
  currently being held creeps into the baseline, walking the tilt back to zero
  over about the same again. Moving freezes the baseline where it is, so the new
  resting pose becomes the new level. Gyro only — drag already springs back on
  release and demo is meant to keep moving.
- **Drag** — drag anywhere to pose the card by hand. Useful on device too, for
  holding a pose while judging the effect.
- **Demo** — automatic orbit on two incommensurate frequencies.

Tap the slider button at the top right for tilt amount, perspective, parallax travel, smoothing,
sheen, iridescence, shadow, card scale, axis inversion, and a **Show layer
bounds** overlay that draws each plane's frame and depth.

## Source files

| File | Role |
|---|---|
| `ShareScreen.swift` | The full screen: chrome, layout, scaling. |
| `ScreenSpec.swift` | Screen geometry, colours and type scale, 1:1 from Figma. |
| `CardSpec.swift` | Card geometry, 1:1 — every position, blur, opacity, rotation — plus each plane's elevation. |
| `MotionEngine.swift` | Normalises gyro / drag / demo into one smoothed tilt, driven by `CADisplayLink`. Holds `MotionOutput` separately — see below. |
| `GyroCardView.swift` | The card: planes, light, shadow, debug overlay. |
| `Tuning.swift` | Every tunable parameter. |
| `ControlsPanel.swift` | The panel. |

## Matching the reference

The motion was fitted to a reference clip rather than eyeballed. Both the clip
and this app's own output were segmented the same way (card silhouette and QR
panel isolated per frame, min-area rectangles fitted), so the numbers are
directly comparable.

| Measured | Reference clip | GyroQR |
|---|---:|---:|
| Card foreshortening amplitude | 0.130 | 0.127 |
| QR travel vs card, horizontal | ±17.4 pt | ±17.9 pt |
| QR travel vs card, vertical | ±21.5 pt | ±23.8 pt |
| Card in-plane roll | ±2.1° | ±2.2° |
| QR size swing | ±3.3 % | ±3.3 % |

Two caveats on that table. The card's soft drop shadow inflates its silhouette
and has to be excluded, or the fitted centre drifts with tilt and swamps the
parallax signal. And each sample catches different points of the demo cycle, so
the amplitudes move by 10–20 % run to run — the fit is good to about that, not
better.

One thing deliberately **not** matched: in the reference the QR panel is ~85 % of
the card width, so it nearly touches the edge and the shift is dramatic against
the border. The Figma design here insets the QR to ~56 %, leaving a 77pt margin,
so the same travel reads more subtly. Closing that gap is a design change, not a
motion one.

## Three things worth knowing

**Never let a control observe the tilt.** `tilt` changes every display frame.
Anything observing it rebuilds at 120 Hz, and a `Slider` or `Picker` rebuilt
that often never gets to finish a gesture — the controls sheet renders fine and
is simply dead to touch. The per-frame value therefore lives in its own
`MotionOutput` object, separate from `MotionEngine`'s settings, so the card and
the readout observe the fast one while the controls observe only the slow one.
Measured with a body-eval counter: **60/sec before, 0/sec after.**

**Size the light bands off the card diagonal, not the card.** The sheen and
iridescence are gradients pushed across the face by up to 300pt. Sized as a
plain multiple of the card they run out of material on hard tilts and their own
straight edge slides into view. They are squares of
`diagonal + 2 × maxTravel + 80` = 1251pt, which still covers the card at the
worst case of ±1 on both axes with 100pt to spare. The gradient stops are
retightened to match, so the band keeps its on-card width over the longer
diagonal.


**Figma CSS coordinates are padding-box relative.** `get_design_context` reports
node offsets measured from *inside* the card's 4pt white border, while the card
image itself starts at the outer edge. Every position in `CardSpec.swift` is
therefore its Figma offset **plus (4, 4)**. Missing this leaves ghost copies of
each element baked into the background plate.

**Figma blur is a radius, not a sigma.** SwiftUI's `.blur(radius:)` is
sigma-like and far stronger at the same number — Figma's `4.254` on the baseball
renders as a formless blob. Even at a corrected scale a *constant* blur destroys
a 38pt mascot, so the blur is driven by the roll instead (**Blur from roll**):
the assets are sharp at rest and defocus as you tilt. This is a deliberate
departure from the Figma render, and it is why the at-rest fidelity is 1.73 %
rather than 1.41 % — the mascots are now crisper than the design.

**The name matte had to be cleaned, twice.** Lifting the text off the background
as an alpha matte measures "darker than the surrounding inpaint", which also
catches the baseball overlapping the text box and the star rays behind it. Left
in, those reappear as a dark ghost floating above the card. `build_layers.py`
now cuts everything left of 75pt, floors off the weak background leak, and crops
to the glyphs' actual ink bounds.

## Regenerating the layer assets

`Tools/` holds the pipeline that turned the flat Figma export into separable
planes. You only need this if the design changes.

```bash
python3 -m venv .venv && .venv/bin/pip install numpy pillow
.venv/bin/python Tools/make_assets.py    # source_layers/ -> Assets.xcassets at 1x/2x/3x
```

`make_assets.py` runs as-is; `Tools/source_layers/` is checked in. The split
steps only matter if the Figma design itself changes:

```bash
.venv/bin/python Tools/build_screen.py    # screen backdrop + avatar (input checked in)
# for the card, first export node 779:22089 from Figma at 3x to Tools/card_flat3x.png
.venv/bin/python Tools/build_layers.py    # re-splits the card into planes
```

- `build_layers.py` punches the moving elements out of the flat card export and
  refills the holes with `fill.py`, a push-pull pyramid solver. The fill only has
  to be boundary-continuous, because the element is redrawn on top and covers
  nearly all of it — only a few points of edge are ever revealed.
- `make_assets.py` resizes in **premultiplied** space. Resizing straight RGBA
  pulls the black of fully-transparent pixels into edge pixels, which the blur
  then smears into a dark halo.
- `Tools/figma_reference_3x.png` is the untouched Figma card export, for
  regression-checking fidelity.
