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

### Invite — Figma 980:15528

| Layer | Elevation | Notes |
|---|---:|---|
| `frame` | 0 pt | The chrome bezel and the plate it is moulded from. The card's whole shape, glow included, so the card itself has no corner, no border and nothing behind. |
| `panel` | −3 pt | The QR's recess. **Negative** — it drifts *against* the tilt, which is what sells the frame as having depth rather than being printed on. |
| `qr` | +7 pt | The modules and the nano badge: ink on the panel, and the only thing above the surface. |
| `name` | +3 pt | "Kiaan Khalid", native, filled with the design's black → #4C17A0 ramp. |

The range is 10pt where the card this replaced spanned 28. That is the
redesign, not a retune: the old invite card was a flat panel with a QR
floating over it and mascots bleeding off its edges, and this one is a single
moulded object with the QR recessed into it.

### Profile — Figma 940:63003

| Layer | Elevation | Notes |
|---|---:|---|
| `plate` | −8 pt | The starburst, whole, with 8pt of baked bleed. |
| `portrait` | +20 pt | The avatar disc. |
| `badge1…3` | +20 pt | The three interest stickers, at the portrait's elevation so they stay attached to it. |
| `qr` | +20 pt | A white matte of the modules. |
| `name` / `caption` | +13 / 0 pt | Native Noontree. |

Change the elevations in `CardSpec.swift` and rebuild, or scale them all live
with the **Elevation ×** slider.

## Scenes

The app hosts several prototypes; switch with the **Scene** picker at the top of
the controls sheet (the slider button, top right). `-scene "Top up"` opens one
straight from the command line.

| Scene | What it is |
|---|---|
| **Kid's onboarding** | The six-step flow — Figma `845:48674`. |
| **QR card** | Two share screens — Figma `980:15528` and `940:62757`. Gyro tilt, elevation parallax. Pick between them under **Controls ▸ Card**. |
| **Skin select** | The wallet-skin picker — Figma `794:30694`. Swipe up to cycle 22 skins, drag down to confirm. |
| **Top up** | Request top up — Figma `935:62729`. Wallet → amount → the confirmation animation in the card skin's own colours → back to the wallet with the money in. |
| **Account** | The account page — Figma `978:15007`. One header load-in: the avatar pops, the stickers arrive on it, the three props travel in. |

## Skin select

Both gestures live on one axis. Drag **up** throws the front card **back into
the stack** and brings the next one forward, cycling all 22 skins endlessly —
the design's own flow drops the swiped card off the bottom instead, which cannot
cycle. Drag **down** pulls the card into a white pocket to confirm.

**Entry.** The stack deals itself out of a single collapsed pile: cards start
stacked flat, scaled down and low, then fan into their slots back-to-front while
the header settles in. 0.55s response on a 120ms stagger, so about 0.91s end to
end (`Response` + `Stagger` under **Entry & hints**). It reads as a deck being
squared off, and deliberately avoids moving along either gesture axis so it
never looks like a hint.

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

**The commit transition is a fixed duration, not a gesture mapping.** This is
the one thing about the cycle that had to be rebuilt. `advance` originally drove
the card's lift, the stack's creep and the background together, straight off the
drag — which reads beautifully at hand speed and falls apart at flick speed: the
finger covers 150pt in under 100ms, the value hits 1 inside the swipe, and the
transition is over before the thumb leaves the glass. Nothing is visible but the
card landing.

So the two are now separate quantities. `advance` still tracks the finger,
because lifting a card is direct manipulation and has to follow the hand.
`reveal` drives the stack hand-off and the background, and the drag scrubs it
*scaled* to `cyclePreview` (0.12) — enough that the background is visibly
*about* to change while the finger is down, not enough for a flick to consume
it. The commit then carries it to 1 over `cycleDuration` (0.55s). **Controls ▸
Gesture ▸ Cycle transition** has both, and `-skinFlick` reproduces the original
failure case — one frame of drag to the threshold, then release.

Two details in there are the difference between smooth and not.

**The preview scales rather than clamps.** Clamping at 0.12 meant the arc
tracked the finger for the first eighth of the throw and then stopped dead for
the rest of it. A hard stall in the middle of a gesture is exactly what reads as
a stutter, and it is not obvious from the code that a `min` is doing it.

**The commit uses `easeOut`, not `easeInOut`.** The finger was already moving
the arc when it lifted, and `easeInOut` restarts from zero velocity — a visible
hitch right at the seam. `easeOut` leaves at full speed and decelerates into
place, which continues the gesture instead of interrupting it.

**Touch is dead while the transition runs.** `handleDrag` assigns `advance` and
`reveal` directly — deliberately, so they track the hand — which means a gesture
accepted mid-transition snaps both out of their running curves and the card and
the background jump. The gesture is *masked* rather than guarded inside the
handlers: one allowed to begin and then ignored is still live when the
transition ends, and its first honoured frame arrives with a large accumulated
translation, which is the same jump a moment later.
`testGestureIsLockedOutDuringTheCycleTransition` covers it, and its second half
checks the lock lifts again — a drag that does nothing mid-transition has to
work once the transition is over, or the screen is bricked.

**The card commits on one spring, with no hold.** This was three staggered
curves: `advance` easing to 1 so the card would top out clear of the stack, then
`tuck` springing after a delay so the depth change happened while it was clear.
On an overshot throw `advance` is *already* 1 when the finger lifts, which makes
that easing a no-op and leaves the delay as the only thing happening — the card
sat still at the top for ~90ms. Meanwhile the under-threshold fall-back was a
single spring with no hold, and that was the motion that read well. The commit
now uses the same shape, and the hold turns out not to be missed: on an overshot
throw the card is already 49pt clear at release, and on a marginal one it
overlaps by 6pt for a frame or two, on an edge.

**The header fades while a card is overhead.** Any throw that clears the stack
has to reach the title: the card rests at 348.9, the card behind it tops out at
338, so clearing takes 201pt of lift, which puts the card's top edge at 148 —
inside the title block at 112…192. There is no lift that both clears the pile
and stays below the type. The type gets out of the way instead, on
`advance * (1 - tuck)` so it comes back as the card beds in rather than snapping
back at the commit. Invisible at 156pt of lift because the transition was over
instantly; obvious the moment it took 0.55s.

**Background transition.** Crossfade by default — both skins are mounted and
`advance` drives the mix, so it tracks the throw and lands fully opaque exactly
as the index commits. **Arc** is the alternative: the incoming skin masked by a
circle centred below the screen, so only its top arc crosses the view as a dome
rising from the bottom. It looked good but did not run smoothly; each field is
now rasterised with `.drawingGroup()` so the full-screen blur happens once per
skin rather than every frame. `Arc depth` sets the curvature, and the edge is a
stroked circle in `.plusLighter` — **Rim**, **Glow** or **Bloom**.

**The hint follows the gesture.** It used to name the two directions and then
get out of the way the moment one started, which left the part that actually
needs coaching — how far is far enough — unsaid. It now runs
idle → "Keep going" → "Release to change", and the same for the pull. The armed
line is the one that matters, and it lands on the same frame as the `armed()`
tick, so the phone and the screen say it together.

Its position is fussier than it looks. 579 is the design's spot and it is only
safe when nothing is crossing it. A pull sends three things through it at once:
the chosen card descends from 385 to 588, the sheet rises to 470, and the drop
outline owns 560 down — so the hint was rendering *behind* the card for most of
the gesture. Riding just above the sheet does not help, because the card is
above the sheet. It moves to 300 for the pull instead, and sits above the card
stack in z, because the departing cards sweep up through 300 as well and there
is no band between the subtitle and the card region that stays clear for a whole
gesture. `OnTexture` keeps it legible over whatever is fading past behind it.

**Continue appears only once a card is chosen.** It used to arm gradually
through the pull, which put a half-lit disabled button on screen for the whole
gesture — something to look at that could not be pressed.

**Idle hints** (off by default). Plays a fraction of each real transition rather
than a generic wiggle: the card lifts and the background reveals ~16% of the
next skin, then it dips ~13% into the pull with a light tick. Cancels on first
touch, resumes after a confirm is reset.

The pull, in order: the pocket rises from below, the card shrinks and descends
*behind* it, the rest of the stack recedes, and past the threshold the sheet
settles while the card — hidden at that moment — springs back up **on top** of
the sheet at hero size. Then `Confirm?` and the Continue button arrive.

**Gesture travel.** A throw needs 150pt, a pull 330pt, committing at 78% of
either, and the two scale **separately** — they are not the same kind of
gesture, so one shared multiplier meant tuning either one moved both. The first pass used 105/165, which was twitchy enough that the card was
gone before the hand had finished moving: the haptic ramp and the pocket rise
both live inside the pull, so a short span skips straight past them. Both then
went long together (215/330), and the throw turned out to be the wrong one to
stretch — it is the gesture you repeat a dozen times hunting for a skin, so it
wants to be quick, while the pull is the one that commits and earns its length.
Travel scales the *finger* distance, not the card's — the card still moves
exactly as far, it just takes a deliberate gesture to get it there. `Drag
travel` under **Gesture** scales both spans live (0.5–2.0) and the row beneath
it prints the resulting point distances.

**The deck is not asset order.** `SkinSelectSpec.displayOrder` is a
permutation, because `skin_01…22` opened on two black cards: 01 and 02 measure
saturation 0.007 and 0.027 at brightness 0.187 and 0.110, so the first two slots
of the resting stack were both near-black leather and the opening frame said
nothing about what was in the deck. The order comes from a measured pass over
all 22 — mean saturation and brightness-weighted mean hue — under two rules: the
first four are strongly coloured and far apart in hue, since at `visibleDepth` 3
those are the only ones the resting stack shows, and the six near-neutrals
(01, 02, 03, 09, 14, 17) sit three apart at positions 6, 9, 12, 15, 18 and 21 so
no two are ever adjacent, including across the wrap from 22 back to 1. The
backdrop lookup goes through the same order, or it stops belonging to the card
in front of it.

**The entry waits a beat.** `entryDelay`, 0.35s by default, before the deal-in
starts — the stack used to be mid-flight on the first frame the screen was
visible, competing with whatever transition brought the user there. Everything
timed off the entry waits with it (the scripted drivers, the held-pull args),
or they start scrubbing a stack that has not been dealt. Controls ▸ Entry, and
`-entryDelay 0` for captures.

**Either axis cycles.** `cycleAxis` is up or sideways; the confirm pull stays
downward in both, since it is the gesture that commits and it has the pocket to
aim at. Sideways reuses the whole state machine — the card rides the finger,
then arcs back and beds into the parked slot — turned ninety degrees, and adds a
46pt rise and a 13° tilt, because a purely horizontal slide reads as a filmstrip
rather than as a card coming off a pile. Two things do change: the throw's
direction now has a sign, and the header dim is skipped, since only an upward
throw is ever in the title's way.

**The drag locks to one axis.** `axisLock` is decided on the first frame past
the deadband — the sign of the vertical translation on the upward axis, whichever
axis the finger has gone further on sideways — and held for the rest of the
gesture. So a pull that drifts left stays a pull, a throw that sags stays a
throw, and the release resolves on the axis the drag committed to rather than by
re-reading the translation, which a diagonal could otherwise satisfy twice over.
`throwDir` is latched with it, so a finger that doubles back does not fling the
card across the screen mid-throw. `-cycleAxis Side` and `-skinDiag` for captures.

Without the lock the two gestures ran *simultaneously* on the sideways axis, and
the visible result was two cards moving on two axes at once. `advance` carried
the front card out on x, while `pull` — derived from `drag.height` rather than
from state, so that the abort spring can animate it back — stayed non-zero and
both dropped that same card on y and mounted `draggedCopy` in front of the
sheet. One diagonal swipe, two cards. The gate lives on the way out of `pull`
for that reason: it cannot move to the assignment without breaking the retract.

Testing it took two passes and the first one was worthless. A diagonal drag plus
an assertion on Continue passes either way, because the *release* was already
resolving correctly — the bug was entirely mid-drag, which the button cannot
see, and XCUITest cannot query anything mid-drag either since
`press(forDuration:thenDragTo:)` returns after the gesture. So the app latches
the condition itself: `crossTalk` records whether `pull` was ever non-zero while
the lock was on the throw, which is the same expression `draggedCopy` mounts on.
`-skinProbe` exposes it as an accessibility label. Removing the gate now fails
the test, which is the only evidence that it tests anything.

**Stack size and the throw's reach.** The card is 290pt wide, the design's
248.7 at 1.17×; the settled hero is left at the design's own 315.66, so
confirming is now a smaller step up than it was. The throw lifts 250pt, not
156. The old figure left the card's bottom edge still overlapping the pile at
the moment of release, and since a released card drops to the back of the
z-order immediately, that overlap *was* the visible flicker — the card appeared
to change depth in mid-air. The card rests at 348.9…539.2 and the one behind it
tops out at 338, so clearing the stack takes at least 201pt of lift.

`tuck` used to be held back 90ms so the card would top out clear of the stack
before changing depth, and that hold is gone. On an overshot throw `advance` is
already 1 when the finger lifts, so its easing is a no-op and the hold is the
only thing left happening — the card sat still at the top for ~90ms. The commit
now runs the same single spring as the under-threshold fall-back, which is the
motion that reads well. The hold is not missed: an overshot card is already
49pt clear at release, and a marginal one overlaps by 6pt for a frame or two.

**The stack leaves upward, once the card is chosen.** It used to be opacity
alone, and three overlapping cards dissolving in place reads as a rendering
fault rather than a departure. The exit mirrors the deal-in's vocabulary —
offset, scale, fade — pointed the other way: up and out, so the deck looks like
it is being lifted off the card you chose.

**It runs on its own clock, not on the drag.** Mapped to the pull it fired while
the finger was still moving, which put the deck's departure in the middle of the
gesture that chooses a card — and a pull released short of the threshold dragged
the deck half out and then put it back. `exitDrive` is set by `settle()`
instead, so the deck stays untouched for the whole gesture and leaves as one
beat afterwards. Back-to-front, 50ms apart: slots 2 and 3 are only invisible
because slot 1 covers them, so lifting slot 1 first would *uncover* them.

They ride *above* the pocket: the existing depth flip that presents the chosen
card on the sheet carries the departing deck with it, and that is what makes the
exit visible at all. Under the pocket it would happen entirely behind white.

`exitLift` went 320 → **112**, and the fade came off the same curve as the
travel. 320 took the deck off the top edge, on the reasoning that the settled
sheet covers everything from 242 down so a short lift only parks it on the white
page. It does leave — and on the way it crosses the whole upper half of the
screen and sweeps over the title. 112 keeps the topmost card's edge below the
subtitle at 222, and the fade is what stops it being parked rather than the
distance.

The fade runs on `exitFade` (0.12s ease-out) against `exitResponse` (0.28s
spring) for the movement, so each card is gone before it has covered much
ground. Both came down from 0.17/0.34, and the stagger from 0.05 to 0.028: the
hero's bounce starts 0.12s after the commit and runs half a second, while the
old figures had the last card leaving at 0.15 + 0.17 = 0.32s, so the deck was
still clearing through the card it had uncovered. It is gone by 0.20s now. That needs **two** `.animation(_:value:)` modifiers on the same trigger
at different points in the chain — the spring lower down claims the transaction
for the offset and the scale, the ease-out above it gets the opacity. Writing a
steeper curve as a function of `exitDrive` does nothing at all, which is worth
knowing: the driver is a 0 → 1 step, SwiftUI interpolates only between the two
endpoints it is given, and every shaping function has the same endpoints. The
scoping was checked by temporarily setting the fade to 1.2s — the deck finished
its travel and then lingered, which it could not do if one animation governed
both.

Hoisting only the chosen card into its own layer — keeping the deck under the
pocket — was the tidier idea and it does not work. The stack's own copy of the
card then has to hide, its opacity change rides the settle spring, and for a
third of a second there are two of the same card at slightly different points on
two curves.

**A new sheet, from `Subtract` (915:61054).** 376 wide against the old 385.342,
a 42.26pt notch against 51, and — the part everything else had to absorb — a top
edge that is **not flat**: it sits 8.26pt lower at the far left and right than
at the notch's shoulders, so the sheet crowns. Every y is now measured from that
crest, and the authored path is shifted up by its own 2.741 so nothing is drawn
above the frame.

That one change broke two things silently, both the same way. `contact` and
`insideDepth` were keyed to the notch *floor*, which on a flat-edged shape is
where a descending card first meets the mouth; on a crowned one the first thing
it meets is the crest, so both stayed at zero through the entire crossing and
only woke up once the card was already inside — exactly backwards. And the
shader's profile returned a constant outside the notch, which is true of a
straight edge and not of this one, so `mouthY` now ramps from the rim up to the
crest across each flank.

**The pocket mouth lights up as you pull** — Siri's screen border, on the
wallet's notch. Three layers over `PocketEdge` (the top edge of `PocketShape`
on its own, so the blur is not spent on the sides and bottom that sit off
screen): an additive outer bloom, an additive mid body, and a thin filament
drawn *normally*. The filament is not optional. Additive layers cancel out
against the white sheet, so without it the glow is only ever a halo above the
mouth with no line on it — and over the brighter skins' background fields
`plusLighter` clips straight to white and the whole thing disappears. Thickness
and opacity ramp on the square of the pull, so the first third is a filament and
the thickening arrives late; the light goes out on commit, because it is the
anticipation of the drop and has no business burning under a settled card. Both
were tuned down once: a 54pt stroke under a 33pt blur had stopped being an
outline and become coloured fog over the bottom third of the screen.

**Only the stretch the card is touching is lit.** The glow used to stroke the
whole top edge, so a 211pt card lit the full width of the sheet and the runs
either side of the notch glowed against nothing. Two masks now, answering
different questions, and both applied to each layer's *mask* rather than over
the finished stack — a `.mask` wrapped around the three layers would group them,
and a grouped `plusLighter` blends against its own group instead of the page.

`MouthWindow.gradient` is the horizontal one: *which* stretch of the mouth
belongs to this card — its own width, clipped to the notch (67.57…308.43 at the
design width). That needs no special case at either end of the gesture, since
early on the card is wider than the mouth and the notch bounds it, and as the
card shrinks into the pocket the light closes in around it.

`MouthWindow.reached` is the vertical one: *how much of that stretch has been
touched yet*. It keeps the profile at or above the card's leading edge, so
because the shape crowns, the two first meet at the outer crown where the mouth
is highest and the light spreads inward along the shoulders to the floor as the
card descends. Without it the whole mouth lit at once the instant contact began
anywhere along it. The crossing is narrow — the leading edge goes from the crest
to past the floor between 36% and 44% of the pull — so that stretch carries all
of the character.

**Full strength for almost all of the contact ramp.** The layer opacities are
constants rather than proportional to intensity, times a short onset fade over
the first quarter of the engagement — `mouthFadeIn`, about 25pt of card travel.
Both extremes were wrong: fading across the whole pull read as the pocket
warming up on its own rather than as the card lighting it, and arriving at full
in a single frame read as a switch being thrown. Thickness still grows with
engagement, per the original brief, but from 45% rather than from nothing — a
hairline at full brightness is not what "lit on contact" should look like.

The fade also runs backwards, so an aborted pull takes the light down with the
sheet instead of cutting it.

**It only lights on contact, and the contact ends.** Ramping on the pull had the
mouth burning while the card was still 200pt above it, which reads as the pocket
lighting up on its own rather than as the card lighting it. `contact` rises as
the card's bottom edge arrives — over two notch depths, so nothing until they
meet at 43% of the pull and full by 61% — and **falls again as its top edge
leaves**, so the light is out by the time the card is through. It used to only
rise, which left the mouth burning at the end of the pull with the card sitting
a clear 18pt below it, touching nothing.

The departure is measured against the middle of the notch, not its floor.
Against the floor the whole fade has to happen inside the last 5% of the gesture
— the top edge only clears the floor at 74% and the gesture arms at 78% — which
reads as a switch being thrown. The midline is crossed at 69% and gives the fade
a fifth of the gesture. `leaveSpan` derives the distance rather than fixing it,
because the renders are 143.6 to 162.8 tall at the seated width: a fixed offset
would leave the tall ones glowing and snap the short ones off early.

**The shadow and the glow are separate quantities.** They shared one driver, and
they cannot: the card is genuinely *inside* the pocket at the end of the pull, so
the lip still shades it long after the mouth's edge has stopped glowing. The
cast runs on `insideDepth`, which only rises, and it falls **outside** the
shape: `PocketShape` is the caster, blurred and lifted so the cast reaches up
past its own edge, then clipped to `PocketCap` — the region *above* the mouth.
It was clipped the other way round at first, which darkened the sheet's own face
and the part of the card already inside it. That is the opposite of what puts
the card behind the shape: a shadow on the near side of an edge reads as dirt,
not as depth. Its opacity also went 0.42 → 0.62,
because at the lower figure it measured a real cast — 216 against 255 on the
white sheet, over 25pt — and still read as nothing on the card, which is the
surface it exists for. 15% of darkening on a bright plush card is not depth.

**Windowed to the card.** `MouthWindow` is the card's own width clipped to the
notch, and both the glow and the sheet's cast shadow mask through it — they have
to agree, being two effects of the same card being in the same place. Lighting
or shading the full 385pt perimeter for a 235pt card gives the pocket a reaction
along edges the card is nowhere near. The window needs no special case at either
end of the gesture: early on the card is wider than the mouth and the notch
bounds it, and as the card shrinks into the pocket the window closes in around
it.

**Clipped to `PocketShape`.** Unclipped, the bloom spills up past the mouth and
paints over the part of the card still outside the pocket, hazing the middle of
it; clipped, the light exists only where there is pocket to emit it. This has a
knock-on the numbers had to absorb: every stroke's reach is now entirely
*inward*, so the widths came down to roughly half again and the bloom's opacity
to well under half. At the previous figures the same layers washed ~46pt of the
card sitting in the mouth — a soft blob following the notch rather than a lit
edge behind it. The mid and the core carry the definition; the bloom is only the
falloff behind them.

**A retracted gesture takes the light with it.** `PocketGlow` is `Animatable`,
and that is the whole reason. Almost nothing in it is an animatable modifier —
the layer widths are `StrokeStyle.lineWidth`s inside masks, which SwiftUI cannot
interpolate — so under an ordinary transaction the parent's body ran once, the
view snapped to its final numbers, and the *old* image was left to fade out on
the default opacity transition: a full-brightness, full-width glow sitting on
the page for the length of the spring while the sheet slid away underneath it.
Declaring intensity and span as `animatableData` makes SwiftUI re-evaluate the
body on every frame of that spring, so the band thins and dims in step with the
mouth it belongs to. Every layer's opacity is now proportional to intensity as
well, so the content is already invisible by the time the mount threshold
removes it — otherwise the removal itself is the thing you see.

`-skinAbort` drives the case: pull to 0.6 of the span, hold, release short.

Once a card has settled, a back chevron sits left of the step dots, and dragging the card up 55% of 140pt lifts it back out of the pocket to the deck (the sheet sinks as it goes). `-skinDemo -skinLift` ends the demo with that lift instead of Continue.

The pocket is Figma `shape` (1027:18114): flat-topped with a 20pt notch and a dy −20, blur 12, 16% shadow. The wallet screen keeps the previous shape as `WalletCutShape`. Once the card is in, the pocket sheet keeps rising until it covers the whole screen, and once it has stopped, the confirm screen (Figma `Skin Option 35`, 1027:17958) fades in over it: a wash across the top, the card with its drop shadow, and, on the two sticker cards (skin_09 and skin_14) only, three stickers (`SkinConfirmStage.swift`). The wash and rays start fading in 0.2s into the settle. The title is never faded: the dark version is drawn above the sheet, masked to its shape, and grows from 32 to 40pt with the settle, so the type turns from white to dark exactly where the sheet passes under it. The wash is the design's grey mixed slightly toward the card's own colour. The controls sheet's *Card tint* slider sets how much, 0.35 by default. The rays are a looping Lottie, `skin_confirm_rays.lottie` (`SkinConfirmRays`), built in After Effects: `python3 Tools/build_confirm_rays_layers.py` renders the design's four rays with their progressive blur baked in, `Tools/ae/build_confirm_rays.jsx` builds the CONFIRM_RAYS comp (750 × 518, 60fps, a seamless 4s loop: the rays sway about the point their funnels narrow to, stretch and breathe, and a fifth copy sweeps wide across them), `Tools/ae/export_confirm_rays.jsx` exports it, and `python3 Tools/pack_confirm_rays.py` packs it. The Lottie is the white rays only; the colour under them and the white fades across the header's foot are the app's, so the colour follows the card while the rays stay white. It's mounted only once a card is chosen. While the sheet moves (rising, or sinking as the card is lifted back) only the plain white sheet shows: the confirm layers fade out the moment a lift starts and come back only once the sheet is still again.
`-skinSlow 6` stretches the retract, which is otherwise over in less time than
two screenshots take.

The glow is its own layer rather than an overlay on the pocket, which it was
while the card passed behind the sheet. With a copy now drawn in front, the
light has to be in front of *that* — it is on the near edge of the mouth, so a
card sliding into it should be lit, not cover it. Order through the pull:
sheet, card copy, glow.

Colours come from `SkinPalette`, read off the card being confirmed rather than
authored — 22 hand-written palettes would go stale the first time a skin is
re-exported. The art is drawn into a 24 × 24 bitmap and bucketed into 18 hue
bins weighted by saturation × brightness, then up to three bins at least two
apart are taken, so the band reads as distinct colours rather than one hue
sampled three times. Half these skins are leather or brushed metal and peak
below s 0.22; those fall to one hue at three strengths, which is the brief's
"shades/tints if there is only one colour". That floor sits at 0.28 — measured
saturation there is 0.05–0.15, and a band that faint is a plain white glow with
no travel in it, while pushing further makes a silver card glow lilac.
`-palAudit` prints all 22 palettes.

**The dashed drop target.** `Rectangle 1891598615` — fill at 10%, stroke at
100%, 2.5pt centred, dashed 9 on 9 with a round dash cap. Both colours come
from the card being dragged, so the outline belongs to the skin you are
choosing rather than being green on all twenty-two. The design's 006B3B is the
green-leather card's own colour, and `SkinPalette.ink` is calibrated against
exactly that value — that card measures s 0.50 in its dominant bin, so a 1.6×
boost at a fixed 0.42 brightness lands on h150 s0.80 b0.42, near enough the same
green. `-palAudit` prints the ink alongside the glow. `.stroke` rather than
`.strokeBorder`, since the design specifies Position: Center and `strokeBorder`
insets the line by half its width.

Its position is **fixed on screen**, which is not the obvious reading. Riding
the sheet at a constant offset below the mouth was the first attempt and it does
not work: the sheet rises on an ease-out, so the outline sits at 664 at mid-pull
and 582 at the end — it starts inside the Continue button and climbs out of it,
which looks like a layout bug for the first half of every gesture. Pinned at 560
it cannot collide, and the sheet reveals it by rising past it, so it reads as
printed on the pocket rather than floating over it. 560 is bounded on both
sides: the notch floor at the deepest drag is 470 + 51 = 521, so anything higher
is still being cut by the mouth when the gesture ends, and Continue starts at
732, so with a 141pt outline anything lower runs into the button. The 235 × 141
size is the designer's own, and those numbers are presumably how they arrived at
it too.

**It is pocket-sized before it arrives.** The scale used to run across the whole
seat, so the card was still 248 wide as it entered a 241pt notch — visibly wider
than the hole it was going into — and only reached its seated 235 once it was
already inside. `seatAtMouth` is the seat at which the card first reaches the
notch floor, and the resize finishes there; past it the card slides in at a
constant width. It is bisected rather than solved because both sides move — the
card descends with the seat while the sheet rises on an ease-out — and it is
measured against the *seated* height rather than the live one, which would be
circular: the live height is what it is used to compute.

**The card seats in the outline, and stops there.** The descent used to run on
the raw gesture: a fixed 0.58 scale and a 210pt drop, which put the card at
168 × 110 centred on 654 — two thirds the width of the box it was aiming at and
8pt past its bottom edge. It now lands on `dropFitScale`, fitted to the inner
edge of the 2.5pt stroke. The two shapes are not the same aspect — the card is
1.524 : 1 and the outline 1.667 : 1 — so "matched" has to mean one of them, and
the only one that looks deliberate is the card sitting *inside* the outline with
the dashes still reading as a container: 211 × 138.5, 12pt of outline showing
either side and a hair over 1pt top and bottom.

`seat` is the driver, and it reaches 1 at `commitFraction` rather than at the
end of the span. That makes the card lining up with the outline and the gesture
arming the same instant — the card seats, the phone ticks, the hint says
release — and dragging past it does nothing at all.

It tracks the finger linearly, unlike the sheet, which leads on an ease-out.
Putting the card on that curve too stacked one lead on another: the card was 96%
seated by the time the drag was 60% through, so the whole back half of the
gesture had nothing left to do — which is exactly the stretch the outline's
reveal has to live in. Linear keeps 66pt of card showing above the mouth at 60%
and 14pt at 90%.

**The outline is sized to the card, not the other way round — and per skin.**
This took three goes and the reason is worth writing down: **there is no single
card aspect.** Figma draws the card 248.7 × 163.2, 1.524 : 1, and that number is
right for the layout and wrong for every individual card. The 22 renders are
trimmed tight to their own content and run from 1.444 (skin_01, whose charm
hangs off the corner) to 1.637 (skin_12).

So: the design's 235 × 141 makes the outline 1.667 : 1, which no card matches —
fitting the card inside it left 12pt of empty outline either side. Taking the
height from the nominal 1.524 gave 154.21, which matches the average card and
nothing else: 8.6pt of gap on skin_01, 10.6pt of overhang on skin_12. The
outline now keeps the design's 235 width and reads its height off **the skin
being dragged**, via `SkinArt`, which is what `.scaledToFit()` is doing to the
card anyway.

The **centre** is the anchor rather than the top edge, so a taller skin grows
the outline about a fixed point instead of walking its bottom edge toward
Continue — and it keeps `dropTravel` and `dropFitScale` constant, since only the
height varies. The tallest outline then runs 555.7…718.5: 13.5pt clear of
Continue at 732, and 17.3pt below the notch floor at the deepest drag, so the
mouth never cuts it. The stroke is 1pt, butt cap, mitre join, per the designer's
stroke panel; it was 2.5pt round.

**The corner is measured too.** The outline was a flat 22pt `.continuous`, and
both halves of that were wrong. The renders do not share a corner — they run
20.4pt to 33.6pt at the seated width, so 22 was under almost every one of them
and barely two thirds of the lego card's — and `.continuous` compounded it,
because a squircle sits much closer to the corner at the 45° point than a
circular arc of the same radius. The dashes bulged past the card's rounding at
exactly the four places the eye checks.

`SkinArt.cornerRadius` reads it off the artwork's alpha as the inset along the
45° diagonal, which for a circular corner of radius r is exactly r(1 − 1/√2).
That measure is chosen for robustness, not elegance: the first rows of these
renders are specular highlight and soft shadow rather than card — skin_03's very
first row is 46 stray pixels of glare — and the plush and lego cards have no
crisp edge at all, so reading the top edge's profile gives nonsense. Fitting a
superellipse to the full profile offline agrees on the *shape*, n ≈ 1.8…2.0,
which is circular rather than a squircle and is why the outline is now drawn
`.circular`; it disagrees wildly on the radius for the soft-edged cards, 18…42pt
against the diagonal's 20…34pt, which is the fit chasing fuzz. The measurement
runs on an alpha-only bitmap — a quarter the memory of RGBA — and reads the
render's *bottom*-left corner, since CoreGraphics draws bottom-up and the charm
on skin_01 and the sparkle on skin_03 both sit at a top corner. `-artAudit`
prints aspect, outline and radius for all 22.

**A second copy of the card rides in front of the sheet.** The descending card
passes *behind* the pocket — that is what the depth order is for — so from the
moment it crosses the mouth there was nothing to look at: it vanished, then
reappeared as the hero. `draggedCopy` is the same card drawn above the sheet
from `cardWidth`, `frontScale` and `frontDrop`, the same three values
`card(_:)` gives the front card during a pull, where its stack transform is
identity. The two coincide exactly, so there is no second image to see — only
the one that is no longer being cut off.

An earlier attempt put the card *inside* the outline on an opacity ramp instead,
crossfading by occlusion as the real card was swallowed. It worked, but it is a
substitute for the card rather than the card, and it is gone.

**The copy costs the depth, and two things buy it back.** Drawn in front of the
sheet the card reads as sliding *down over* the pocket rather than into it,
because nothing occludes it any more.

`mouthShadow` is the shadow the sheet's lip casts on whatever is inside, built
from `PocketCap` — the region *above* the mouth — blurred, nudged down 7pt and
clipped to the pocket, which keeps only the part that falls in. A stroke along
the edge was the obvious alternative and it is wrong: a stroke lights the notch
symmetrically, and a cast shadow has to come from the solid side. `PocketCap`
carries 70pt of headroom above the edge for the same reason — the mouth is the
top of its own frame, and with nothing above it the blur fades the shadow out
from the very line it is supposed to be cast by. Measured on the white sheet it
darkens to 216/255 at the lip and is back to white 25pt down. It lands on the
sheet either side of the card as well as on the card, which is the other half of
the job: the lip reads as having thickness, so the card looks like it emerges
from an edge rather than crossing a drawn line.

`MouthBend` is a Metal `distortionEffect` that pinches the image toward the
mouth from both sides, so the card compresses into the edge the way something
passing under a thick rounded lip would. It is applied *inside* the stage-sized
frame and before that frame is positioned, so the shader's coordinate space is
the stage's and the geometry passed in is the sheet's, expressed in the card
layer's frame; attached further out the effect would live in a space that moves
with the card.

**It follows the notch, not a straight line.** The first version took a single
`edgeY`, which pinched along a rectangle's top edge across the full width —
visibly not the shape it was supposed to belong to. A shader sees one pixel at a
time and cannot walk a `Path`, so `mouthY` rebuilds the profile from the four
joints between the path's eight cubics (`PocketShape.notchShoulders`) with a
smoothstep across each shoulder, which is within a point of the real bezier and
has no crease. The geometry stays in Swift and arrives as uniforms rather than
being duplicated in Metal.

**One-sided, and zero at the edge itself.** The falloff was symmetric about the
contour, so it distorted the card on both sides — including the part still
outside the pocket, where there is no lip to do it. Dropping the outside half
alone is not enough: the weight peaks *at* the contour, so cutting it there
leaves a full-`amount` jump across one pixel and tears the card along the mouth.
A half-sine is zero at the edge, peaks `reach / 2` inside and returns to zero at
`reach`, so the whole effect lives inside the shape with no seam at either end
of it. Measured against `-noBend`: above the mouth the two frames are now
byte-identical — max difference 0 — against up to 231 inside the band. Beyond
`reach` there is a mean difference of 1.5, which is the layer being resampled by
the effect at all rather than any displacement.

Verified by diffing a capture against `-noBend` and taking the peak-difference
row per column, which traces where the pinch is actually centred: at pull 0.62
it runs 524 at the shoulders, 566 through the floor and back to 520 — against a
sheet edge at 522 and a notch floor at 573. Before, it was a flat 522 all the
way across.

Building it needs the Metal toolchain — `xcodebuild -downloadComponent
MetalToolchain`, 688MB, which was not installed here. Controls ▸ Mouth turns it
off and tunes amount and reach.

**Backgrounds are authored per skin**, from `Card skins & bg` (849:58131) —
`bg_01`…`bg_22`, replacing what used to be here (the card's own art blown up,
blurred and darkened). `.fill` is the design's geometry rather than a guess: the
backdrop is 973 × 1616 and `Skin Option 8` places it at 489.71 × 812 offset
x = -57.53, which is exactly filling by height and letting the sides run off.

One addition the design does not have. Every design frame uses a dark skin, so
white-on-backdrop was never tested against brushed silver, gold or yellow
plush — and on those the title falls to roughly 1.3:1 against the background
while the subtitle and the swipe hint disappear outright. A scrim would fix it
and would also darken the nineteen backdrops that were fine, which the design
deliberately leaves clean, so the type carries two black shadows instead: a
tight one for the glyph edges and a wider soft one for the mass. Black shadows
are invisible on a dark backdrop, so the other nineteen are untouched
(`OnTexture`).

`PocketShape` is the Figma vector `793:28368` traced as a SwiftUI `Path`: a
rectangle whose top edge carries a centred notch, the mouth of the wallet. Its
control points are the exported SVG's, with the shadow inset removed and x
normalised by the 385.342pt design width so it scales cleanly.

### Shake to shuffle

The avatar step takes a shake as well as a swipe or a chip tap; the existing
gestures are untouched. A highlighted chip under the avatar names it, because an
accelerometer gesture is invisible otherwise — it reads as an offer, so it gets
brand blue rather than the grey caption the other hints use, and it swaps to
"Shuffling…" while the spin runs.

It is a short walk, not a jump. `select` already dissolves between avatars, so
stepping through six to nine of them at 95ms reads as a spin that settles, which
is what "land on a random avatar" wants; a single jump to a random index is
indistinguishable from a swipe. The hop count skips multiples of the set size so
a shuffle can never land back where it started.

Detection is UIKit's own — `motionEnded` with `.motionShake`, not an
accelerometer and a threshold of our own invention that would disagree with the
rest of the system. The catch is that `motionEnded` goes to the first responder
and SwiftUI never makes one unless something asks, so `ShakeDetector` hosts a
bare controller whose only job is to raise its hand. It is mounted as a 1 × 1
background rather than a zero-size view: a zero-size view is not reliably in the
window hierarchy, and a controller outside the hierarchy cannot become first
responder.

That is the part that can fail silently, and there is nothing on screen to say
so, hence `-shakeProbe`:

```
SHAKEPROBE becameFirstResponder=true isFirstResponder=true inWindow=true bounds=(1.0, 1.0)
```

The gesture itself cannot be driven from here — `simctl` has no shake command,
XCUIDevice does not expose one, and sending ⌃⌘Z to the Simulator needs an
Accessibility grant this process does not have. `-shakeDemo` runs the shuffle
through the same entry point the gesture calls, which covers everything except
the one hop from UIKit into `onShake`.

### The avatar row

Fifteen avatars now, from `Avatars` (905:61038), so the row scrolls — the five
fixed chips it replaces come to 948pt on a 375pt screen at fifteen.

The row is 80pt tall and its contents carry 14pt of vertical padding *inside*
the scroll view. A `ScrollView` clips to its own bounds and a chip's layout
height is only its 52pt — the selection ring sits 5.5pt outside that and a 9pt
blur spreads further still, so without the padding both were sliced off flat,
top and bottom.

**What is arriving at either edge is blurred, faded and small**, and sharpens as
it comes in. That is Image Playground's suggestion rows, per the reference
recording, and the recording is worth having measured rather than watched: its
rows change contents in ten discrete episodes of 0.2–0.4s across 12.5s, with the
items staggered inside each one. So the blur is a property of where an item *is*,
not a transition played once on a set change — which is also the version that
still reads correctly under a finger halfway through a drag.

`scrollTransition(.interactive)` is what makes it positional without any
arithmetic: `phase.value` runs −1 at the leading edge, 0 fully on screen and +1
at the trailing edge, live during the drag. No geometry readers, no offset
tracking, and it resolves itself when the scroll settles. Controls ▸ Avatar row
tunes edge blur, fade and shrink.

The row is inset half a chip either side, so the first and last can reach the
middle rather than stopping against the edge with the blur still on them, and it
scrolls itself to the selection on `onChange(of: index)` — the hero can also be
changed by swiping it or by shaking the phone, and a selection the row is not
showing is worse than no row.

**The assets are sliced from one export of the section, not fetched per avatar.**
`rawImages` is capped at 20 and arrives unlabelled — the trap that cost real
time on the category assets — and this node has more than 20 source images
under it, so that route both truncates and scrambles. A single composed render
has neither problem: the coloured circle is already behind its character.

Two things about that export. It is **not** the section's stated bounds — it
comes back 8610 × 5250 where 2790 × 1670 at 3× would be 8370 × 5010, i.e. 40pt
of margin per side, and the margin is the same dark as the section so there is
no transparent edge to measure from. And guessing the offset went wrong twice
before I stopped guessing: `make_avatars.py` finds the grid by projection
instead, counting non-dark pixels down each column and across each row, and the
five column humps and three row humps are the circles. That agrees with the
design to a quarter of a pixel — detected column step 1574.25 against
524.802 × 3 = 1574.41 — and survives a re-export at any padding or scale. The
corners are cut to a circle on the way out, so the asset is an avatar rather
than an avatar in a dark box.

### Haptics

| Trigger | Feel |
|---|---|
| Throwing the card up | Detents along the travel, then a light impact on commit. |
| Pulling the card down | A pulse train that **grows** with the pull. |
| Either direction, passing the commit threshold | One firm rigid impact. |
| Either direction, released short of it | A soft light tick. |
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

`armed()` is deliberately not a stronger detent. The detents are a texture you
feel *through* — all light impacts of rising intensity — so "you can let go now"
had to be a different sensation rather than a slightly firmer version of the
last thing you felt; it is a single rigid impact at full intensity, fired once
per crossing. `aborted()` is its opposite: soft, because nothing happened and it
only needs to close the loop.

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

## Request top up

Figma section `Request top up` (935:62729) for the screens, and the designer's
screen recording for everything after the tap. The request step is deliberately
plain — an amount, three quick picks, a note, the CTA — because the brief is the
animation, not the form.

The flow is a round trip, and it starts and ends on the wallet — **empty at the
start**:

| Beat | What happens |
|---|---|
| **wallet, empty** | `Wallet Page` (962:66753). No balance, no history: `Đ 0`, `Your wallet is empty`, and the page's staggered entrance. |
| **entry** | The form. The CTA is dead until an amount is entered. |
| **sending** | The page blurs away under a near-black veil; a bloom in the card's own colours climbs in from below the bottom edge under a spinner and `Requesting top up`. |
| **sent** | The bloom grows and flies out through the top, the line becomes `Top up request sent`, and the amount counts up out of a blur. |
| **wallet, filled** | The page rearranges into 935:61643 — the art rises, the balance counts up from zero, the pocket rises 257pt and the transaction list arrives, and the receipt unfolds out of the button's notch. |

Starting from empty is what gives the return an event. Opening on a wallet that
already had 10.56 and eight transactions in it made coming back a smaller
moment than the animation leading into it: the balance ticked up and a card
appeared. From zero, the whole page changes shape.

The return is also the part the recording does not have. Its last frame is a
dark, empty screen, which is a fine place for a clip to end and a dead end in a
build — so the bloom's exit hands straight back to the wallet, where the result
actually lives.

The balance goes up the instant the request lands, which is not what requesting
a top-up does — someone else still has to pay it. That is the prototype's
assumption, made so the return has something to show.

**Replay**, in the controls sheet, runs the whole round trip hands-free from the
empty state, entrance included. So does `-topUpAuto`.

### How money is set

Three screens show an amount and the design gives all three the same treatment,
so it lives in one place (`MoneyStyle`, `MoneyText`) rather than three.

**The mark is a real glyph, not an icon.** `U+E001` — Noontree ships the new UAE
dirham symbol in the private-use area. It used to be `U+0110`, Đ, Latin capital
D with stroke, picked because the font has no dirham at any of the obvious
codepoints: not the currency block, not the Arabic forms. It was the wrong
glyph and it looked it — one stroke instead of two, and the wrong proportions.
Dumping the font's cmap shows it maps exactly two private-use codepoints, and
drawing both outlines identifies them: `E000` is the Arabic د.إ ligature,
`E001` is the Latin mark the design uses. So there was nothing to export. A
glyph is also strictly better than an image here — it takes the weight, the
size, the tracking and the gradient the digits beside it take.

**The digits have a gradient and tracking, and did not.** Every amount in the
design is `bg-clip-text` over a vertical ramp, stopping at 21.25% and 77.5%
rather than at the ends, with `letter-spacing: -0.25`:

| Where | Type | Ramp |
|---|---|---|
| Wallet balance (935:61648, 962:66758) | Noontree **ExtraBold 40**, mark at the same size | white → white at 80% |
| Request entry (935:61359) | Noontree **Bold**, mark 24 and digits 40 | `#1D2539` → `#475067` |
| Confirmation | ExtraBold, matching the wallet | white → white at 80% |

The stops matter more than they look: keeping the top quarter at full strength
is what makes the number read as lit from above instead of faded. The build had
Bold, no tracking, a flat fill, and a mark set in a different size *and* a
different colour from the digits beside it — four things that each made it look
slightly not-the-design and together made it look like a different typeface.

The gradient goes on the row, not on the two `Text`s. A `ShapeStyle` handed to
`foregroundStyle` resolves over the view it is applied to, so styling them
separately gives the 24pt mark its own 24pt-tall ramp instead of the top slice
of the 40pt one — visible as a mark that is paler at its baseline than the
digits next to it.

While in there: the owner line's tracking is the design's own 2.2 (it was 1.6,
a guess), and the quick-pick chips are `B16/Medium` for both halves — the mark
had been set 3pt smaller and a weight heavier, which is not what a chip does.

### The button lifts toward the finger

`Request top up` was flat: no press state at all, and one haptic that fired
after the gesture rather than inside it.

`PressLift` is a `ButtonStyle` that does the opposite of the usual treatment.
Instead of scaling *down* — the control being pushed into the page — it grows
6% while held and its shadow deepens and drops (0.12/10/3 → 0.24/22/12), so the
button rises off the surface, then springs back on release. On a page where the
button is the one thing to touch, being pulled up under the thumb is the
livelier read.

Both halves get a haptic: a medium impact going down and a lighter one coming
back up. That is what makes a press feel like it has a floor. A single impact
on the *action* — what a plain `Button` does — puts the feedback after the
gesture has already finished.

The shadow is cast from a shape drawn under the label rather than from the
label itself, because a shadow on a label is cast from the label's alpha, and
the label has text in it: without the explicit shape, every letter casts its
own.

The request screen's own CTA takes the same treatment (`NeutralCTA(lift: true)`).
Onboarding's CTAs do not — they are the end of a form and want to stay quiet —
which is why it is opt-in rather than the default.

### The copy is not the recording's

The recording was shot on the *add money* screen, so it reads `Topping up
wallet` → `Wallet topped up`. This flow only asks someone else for the money,
and the wallet page it lands on writes the result as `Top up request sent`
(935:61868). Same two-beat structure, this flow's own words.

### Why the page goes dark

The recording's source screen is already dark, so its ghosted content is white
type dimming down. This screen is light, and the same read has to be built the
other way round: the page keeps its own surfaces and a **95.5–97%** black veil
goes over it, leaving the white keys, chips and note field showing through as
the faint light shapes the bloom rises out of.

The window between those two numbers is narrower than it looks. At 1.0 the
page vanishes outright and the bloom rises out of nothing. At 0.955 the note
field and the CTA read as a grey-brown haze across the middle of the screen —
the bloom's own light landing on them additively — which looks like dirt rather
than depth. 0.972 keeps the ghost and loses the haze.

### The bloom

Five flat-filled ellipses under **one** large blur, composited `plusLighter`
(`AuroraBloom.swift`). Its colours come from `SkinPalette`, the same extractor
the pocket glow uses, so the light is always the card's own.

Three things about it took measuring rather than guessing:

**One blur over the group, not one per lobe.** Per-lobe blurs keep their own
edges and the cluster reads as five blobs. A single pass over the stack is what
melts them into one body of light.

**The lobes are pushed apart, not dimmed.** `SkinPalette` forces its colours to
full brightness, so a violet arrives as roughly (1, 0.4, 1) — two of those
stacked on the same spot clip every channel. Four piled at the bottom centre
turned the whole lower third of the screen into a flat white slab with the
card's colour showing only as a fringe at the top. The obvious fix, dropping
every opacity under a half, fixed the slab and took all the saturation with it:
the bloom went to a grey wash. What the reference actually has is each colour
holding its own part of the *width* at full strength, meeting in narrow seams.
So the lobes are bright, narrower, and spread across the span — one tall apex
near the middle, two lower and dimmer shoulders either side — and the white is
confined to where they cross.

**The contact band is painted.** The cream in the middle of the cluster falls
out of the blend and is not drawn. The hot line along the very bottom edge does
not: it is whiter and tighter than any overlap of two saturated colours. That
one is an explicit white lobe, sunk far enough below the screen that only its
own top shows.

Nothing is masked. A `.mask` around a `plusLighter` group isolates the group
from the page behind it and the blend stops working — the same trap the pocket
glow hit. The cluster is feathered by its own shapes and by hanging below the
screen edge, so the blur's bottom tail is clipped rather than fading out in
view. `bloomSink` is what sets that, and it is shallow on purpose: at 96pt the
hottest part of the cluster was entirely off-screen and the bloom read as a
soft wash with no contact edge at all.

### Keeping it alive

The lobes drift, swell and bob on three incommensurate periods each — the
wander, the swell at 1.37 of it, the vertical bob at 0.8 — so the cluster never
returns to the same shape inside the couple of seconds it is on screen. One
shared period read as a pulse rather than as movement.

Which lobe gets which kind of movement matters more than the amounts. The apex
carries the swell and almost no sway, because the peak rising and falling is
what the eye reads and sliding it sideways only wobbles the dome. The shoulders
carry the wide sway, because they are what makes the colour travel across the
width. The contact band barely moves at all: it is the horizon the rest of the
cluster sits on, and drifting it makes the bottom edge of the screen look loose.

Measured over the dwell, frame-to-frame change went from 0.46 to 1.14 mean
absolute difference — about 2.5× — and it is flat across the window rather than
spiky, which is what says it is drift and not a jump.

### The exit is measured, not chosen

The sweep's lift used to be a constant. At 980pt the bloom grew, rose about
three-quarters of the way, and then faded out with a tail still sitting in the
lower half of the screen — which reads as the light switching off rather than
leaving.

The lift is now derived from the cluster's own geometry, in
`TopUpScreen.sweepLift`: the bottom of the lowest lobe, scaled about the box's
centre, plus that lobe's bob and the blur's own tail (a Gaussian is still faintly
visible about two radii out, and the blur scales with everything else). At
`sweepClear` 1.0 that is exactly enough to put the last visible part of the
cluster above the top edge, and it stays correct after any change to the lobes,
the height, the scale or the blur.

The fade was the other half of the problem. On the same curve as the travel it
dimmed while still on screen, so it has its own curve now — held, then run over
the last 40% — which leaves the *lift* to do the removing.

Traced frame by frame, the bloom's lowest lit row now runs 100% → 75% → 54% →
33% → 14% → gone, monotonically, in about 0.25s.

### The amount counts up out of the blur

The confirmation used to be a check mark and a line of copy. The number that was
actually asked for is the one piece of the request worth keeping, so it lands
with them, at 56pt above the status line.

Three parts, each on its own curve:

**The count is a view, not a transition.** `CountingAmount` conforms to
`Animatable` with the value as its `animatableData`, the same trick the wallet's
`BalanceText` uses. `.contentTransition(.numericText())` rolls whatever digits it
is handed — 0, then 200 — so it rolls once, between the two. Making the number
the view's animatable data is what gets SwiftUI to re-evaluate the body per frame
with the interpolated value, which is what counting is.

**The blur resolves in the first half of the count.** It arrives at 16pt and is
sharp about 0.43s in, so most of the run is spent watching a legible number
climb. Sharpening on the count's own curve made the digits readable only at the
very end, and the whole thing read as a smear that stopped.

**The width is held by the target.** Counting 0 → 200 in a centred row reflows
the block every time the number gains a digit, so the line creeps sideways while
it climbs. The final string is laid out hidden and the live one drawn into that
box trailing-aligned: the ones column stays put and the number grows leftward
into space already reserved.

Two knock-on changes the reveal forced:

* **The hold is derived.** `handOffDelay` is `max(sweep, delay + count) + settle`
  — measured from whichever of the two things happening in the landed state
  finishes last. Holding from the sweep alone had the wallet arrive while the
  number was still climbing, and the fix was not to pad `settle` by hand.
* **The amount leaves on its own, early.** At 56pt it is the biggest thing on
  screen, and fading it with the rest of the screen laid a ghosted `200` over
  the wallet's own balance for the length of the crossfade. It now lifts 26pt
  and fades over 0.26s just before the hand-off — which also keeps the flow's
  one direction: everything here leaves through the top.

Traced frame by frame at 12fps: blurred, then 70 → 99 → 125 → 143 → 167 → 183 →
195 → 200, sharp from the third frame, held, then lifted out with the wallet's
own count-up starting on an empty screen.

### Two curves on one driver

Rise and sweep are the same `phase` change read at two points in the modifier
chain — the technique the skin picker already uses for offset against opacity.

Growth is front-loaded (`easeOut`), so the cluster is already huge by the time
it starts leaving, which is what fills the frame with the middle of the
gradient. The lift and the fade are held back (`easeIn`), so the light is still
bright when it reaches the top. One shared curve gave either a bloom that
shrank away in the middle of the screen or one that left before it had grown.

The curves are read *after* the change, so `phase` is already the new value —
which is how one modifier carries a different curve in each direction.

### The wallet page

`Wallet Page` in three states — empty (962:66753), the receipt landing
(935:61752), filled (935:61643). Mostly exported art, placed at the frame's own
numbers, with these exceptions:

**The type goes dark on a light background.** The copy was white, full stop,
because the design's own background is a mid purple — but the background
follows the card skin now and nine of the 22 are light. `bg_15` is a pale sand
that measures 0.76 relative luminance under the text, where white type sits at
a contrast ratio of **1.29**. That is not a near miss; it is unreadable.

So `WalletInk` chooses the direction from the artwork, by the rule a person
would use: work out the ratio white would get and the ratio the design's dark
ink would get against the band of the image the type actually lands on, and
take whichever is higher. Measured at first use and cached, like `SkinPalette`.
The split is 13 white and 9 dark, and only two are close — `bg_04` (3.68 vs
4.15) and `bg_05` (3.55 vs 4.30), both of which clear WCAG's 3.0 bar for large
text either way.

The band matters as much as the rule. These backgrounds are gradients and
several have a bright top and a dark bottom, so an average over the whole
picture answers a question nobody asked. Both layouts put their type at about
0.6 of the backdrop's height, so one band — 0.55…0.78 vertically, sides
trimmed because the copy is centred — covers both.

**The mascot and the sparkle are gone.** The two objects the frame puts either
side of the card are the design's decoration, not the wallet's content, and
with the card now changing per skin they were two fixed things pinned to a
variable one.

**The card and the background are the skin picker's assets.** Not
wallet-specific exports. The two the wallet frame shipped with measure within
0.4/255 of `skin_17` and 0.3/255 of `bg_17` — they *were* that skin, and the
design simply shipped whichever card the mock happened to be wearing. Reading
them from the skin number instead means one control in the sheet moves three
things at once: the card on the page, the page's background, and the colours
the bloom is built from. Those were always meant to be the same card; the
bloom's brief was "the colour of the user's card", and now the user can see it.
Both superseded exports are deleted.

The card is drawn at its **own** aspect rather than the frame's. Two numbers
have to be recovered for that. The export carries about 5.5pt of shadow bleed
on every side, and the frame squeezes it — 819 × 579 into 273 × 182 is 0.333
across and 0.314 down, so the design's own card is 5.7% shorter than the
artwork it is made of. Measured back out, the body sits at
(54, 77.32, 266.33, 155.6). The skins are then drawn to that rectangle's width
at their own aspect rather than stretched to fill it: the 22 renders run from
1.467 to 1.644 and the squashed box is 1.712, so filling it would take 16% out
of the height of the widest ones — visible on the plush and lego cards in a way
the 5.7% on this one never was.

**The empty state's backdrop is the same image, zoomed.** Its pocket sits 257pt
lower, so it needs purple that much further down, and the design gets it by
drawing the backdrop 1.394× larger from the same top edge rather than by
stretching it — 524/376 and 869/623 are the same number. Keeping both
rectangles makes the fill transition a slow zoom out of the background, which
is what the design implies and cost nothing to honour. Before this the build
used the filled rectangle for both, and the empty page's bottom third was the
base white showing through under the copy.

**The two layouts are one view, not two.** Every position the states disagree
about is written once as a choice between the empty frame's number and the
filled frame's, and they animate because they are offsets on views that stay in
the tree. Branching the layout with `if` cross-fades instead of moving, which
loses the whole point: the art rising, the balance climbing from mid-page to
under the card, the pocket coming up 257pt with the list inside it.

Three more, unchanged from before:

**The white cut is the pocket.** The wallet's wavy white shape and the pocket the
skin picker drops a card into are the *same node* — Figma `Subtract`
(915:61054), the same path, the same shadow filter (dy −8, blur 12, black at
12%). So it is drawn with `PocketShape` rather than traced a second time. Its
crest is measured off the render at y 365, and 358 once the receipt is in.

**Three things move together.** The frame moves them together, so the build does
too: the receipt card pushes in under the button, the cut rises 7pt to make room,
and the transaction list slides down by the receipt's own height. Animating only
the card leaves it overlapping the list.

**The list is clipped to the pocket.** Not decoration — it arrives with the
page's other results while the pocket is still on its way up, and unclipped
that put four transaction rows on the purple backdrop for about a third of a
second. It is clipped to the pocket's real path rather than to a rectangle at
the crest, because the mouth dips 42pt at the notch and a straight cut lets the
list show through it. The clip is a `Shape` with an animatable `crest`, so the
region opens as the sheet rises instead of snapping to its final height on the
first frame.

**The receipt grows from its own notch.** The anchor is what sells it — scaling
from `.top` keeps the notch still while the card unfolds below it, so it reads as
coming out of the button it points at. Scaling from the centre slid the notch off
the button.

The balance counts rather than cuts, which needs `Animatable` on the view:
`.contentTransition(.numericText())` rolls the digits it is handed and so jumps
straight from the old balance to the new one. Making the number the view's
`animatableData` is the only way to get SwiftUI to re-evaluate the body per frame
with an interpolated value.

### The page's entrance

Taken off the designer's reference clip (`ref.mp4`) rather than invented. Two
things are worth measuring there, and the second one is the interesting one.

**It settles downward.** The card's top edge travels from 32px *above* its
resting place down to it, while its opacity goes 0 → 1 in the first third of
that — so the element is solid for most of the move and what you read is the
settling, not the appearing. Nearly every list entrance slides *up*; this one
does not, and it reads as the page being laid down rather than pushed in. The
elements below the card cross 50% at 0.02s, 0.28s and 0.5s after it, top to
bottom.

The curve is `interpolatingSpring(stiffness: 320, damping: 28)` — tension and
friction as themselves, damping ratio 0.78, settling in about 0.29s with a
touch of overshoot. It replaced a `spring(response: 0.72)`, which is a 0.72s
period and took most of a second to stop moving; the stagger came down with it,
to 0.055s. Travel is 14pt, with the opacity on its own shorter `easeOut(0.18)`
so the element is opaque well before it stops. The pocket and the nav are the
exception: they come up 46pt from off the bottom, because sliding a sheet
*down* into place reads as a mistake.

**The card arrives keystoned.** Tracking its four corners frame by frame, the
bottom edge is measurably narrower than the top — the width ratio runs 0.890 →
0.931 → 0.977 → 1 over the entrance while both edge centres stay on 370px, so
it is a rotation about the horizontal axis with the top tipped toward the
camera, not a slide or a scale.

It is *not* `rotation3DEffect`, and the reason is the other measurement: the
card's **height does not change** — 353px at t = 0.133 and 356px settled. A
rigid rotation cannot do both. Driving SwiftUI's own effect to the right width
ratio costs 17–27% of the height depending on how the angle and the perspective
are split between them, and at that point the card reads as squashed rather
than as leaning.

What the reference has is the perspective *divide* without the foreshortening,
which is one 3×3 projective matrix about the plane's centre:

```
x' = x / (1 + q·y),  y' = y / (1 + q·y),  q = 2k / h
```

The edges come out magnified by 1/(1∓k), so the width ratio is (1−k)/(1+k) and
the projected height is h/(1−k²) — 0.3% over size at k = 0.058. Height
preserved, by construction.

Two things went wrong on the way to that working, and both are recorded in
`Keystone` because neither is guessable:

* **`ProjectionTransform.concatenating(_:)` does not order the way
  `CGAffineTransform`'s does.** Composing translate · keystone · translate-back
  keystones about a *corner* instead of the centre, in either order, which
  shrinks the whole plane rather than tipping it. The matrix is written out
  term by term instead.
* **SwiftUI's divide does not land where the matrix puts it.** Even written out,
  the rendered plane loses size: swept at three amounts the height comes back
  at 0.894 / 0.803 / 0.729 of full, and the width at about 0.86. That is
  1/(1 + c·k) with c = 4.2 down and 1.9 across, close enough to fit, so it is
  corrected with a scale rather than argued with — which restores the size and
  leaves the ratio between the two edges, the whole effect, alone.

Verified on the build: a width ratio of 0.887 against the reference's 0.890, a
top edge 6.7% over resting width against the reference's 9.1%, and 99.4% of the
height against the reference's 100%. `-walletEntry` pins the page in this pose,
which is the only way to screenshot it — the whole entrance is over in 0.3s.

### The wallet's art

Five exports from the two wallet frames — `wallet_mascot`, `wallet_sparkle`,
`wallet_txns`, `wallet_nav`, `wallet_receipt` — plus the card and background,
which come from the skin set. Stored at 3× their rendered size.

Two things about getting them out of Figma:

**Node exports have no transparency.** `download_assets` renders the node onto
the canvas, so the card, the mascot and the sparkle all came back matted onto
opaque white — invisible against a white page, and a white box against the purple
one. The `rawImages` are the original uploads and do have alpha, but they arrive
unlabelled: asking for one *node* at a time narrows the set to two to four
candidates, which can then be told apart by resolution and alpha coverage. The
list layer, the nav and the receipt keep their mattes on purpose — all three sit
on white.

**The sparkle's frame coordinates are wrong for the render.** The frame reports
its box at x 359, which is off the right edge of a 375-wide screen, while the
render clearly puts it at 304. It is also squeezed: a square source drawn at
44 × 66. Both are measured off the rendered frame, which is the only ground
truth that counts.

### Where the build departs from the frame

* **No amount, no request.** The frame draws the CTA enabled with the amount at
  0. A request for nothing is not a request, so it is gated on a non-empty
  amount — one tap on a quick pick, and tap-to-reset keeps the amount, so
  replays cost nothing.
* **The note fills from a tap.** There is no text keyboard in this flow — the
  keypad is numeric — so the field toggles the design's own sample line
  (935:61604) in and out. Typing a note is not part of the motion.
* **The header's grid backdrop is not drawn.** The frame's `BG` instance carries
  a faint grid over the top 188pt. It contributes nothing to the animation and
  is gone under the veil within half a second of the tap.
* **The currency mark is U+0110.** Noontree has no dirham glyph — its cmap has
  neither U+20AE nor the Arabic forms — but it does carry D-with-stroke, which
  is the same crossed D the design draws. Shipping an asset for a character
  already in the face would be the worse trade.

### Driving it without touch

| Argument | Effect |
|---|---|
| `-scene "Top up"` | Opens on this scene. |
| `-topUpSkin N` | Wallet card skin, by asset number 1–22. |
| `-topUpPhase Sending` / `Sent` | Holds one beat, amount pre-filled — the sequence is under three seconds and captures are ~0.4s apart, so stepping through it any other way walks straight over the middle. |
| `-topUpAuto` | Runs the whole round trip once, hands-free, a second after the flow appears. For screen recordings. |
| `-topUpDwell N` | Seconds the bloom sits there. |
| `-topUpStill` | Freezes the lobes' drift, for stills. |
| `-topUpOpen` | Opens straight on the request screen, so a still of it — or of a beat of its animation, with `-topUpPhase` — does not need the wallet driven first. |
| `-walletFilled` | Opens on the settled page: balance in, list in. |
| `-walletEntry` | Holds the wallet in its pre-entrance pose, drawn at full strength. The only way to see the card's arrival keystone — the entrance is over in 0.3s. |
| `-pressHeld` | Pins every lifted control to its pressed look. The only way to screenshot a press: it is a gesture, and the Simulator has no way to script one that is still being held. |

```bash
xcrun simctl launch <udid> com.noon.gyroqr -scene "Top up" -topUpAuto -topUpSkin 12
```

### The card skin, in the controls sheet

The animation's colours are read off the wallet's card skin, so picking that
card is the one control it cannot do without: a plain strip of the 22 renders in
the picker's own browse order, and under it the two or three colours
`SkinPalette` actually pulled out of the chosen one. The bloom is heavily
blurred and additive, so seeing the inputs is the only way to tell a dull card
from a badly sampled one.

The default is `skin_17`, which is the design's own — the card and background
the wallet frame shipped with are that skin, to within half a level out of 255.
`skin_12`, the iridescent violet, gives the strongest bloom of the 22 and lands
closest to the recording's purple; it is the one to pick when the bloom is what
is being looked at. No card gives the reference's purple *and* amber — the
recording was shot against whichever skin that wallet was wearing, and the
point of reading the palette off the art is that it stops being a fixed
choice.

## Kid's onboarding flow

Figma section `Flow for claude` (845:48674) — six steps, wired end to end. It is
the app's default scene; **Controls ▸ Scene** switches to the two standalone
prototypes, and **Controls ▸ Onboarding step** jumps straight to any step so
reviewing step 6 doesn't mean typing an OTP first.

| # | Step | Figma | Notes |
|---|---|---|---|
| 1 | Splash | 845:48810 | The designer's clip, played once. Tap to skip. |
| 2 | Email | 845:49201 | Card rises over the clip's held last frame. |
| 3 | OTP | 845:48967 | dotLottie illustration, 4 boxes, success/error toast. |
| 4 | Skin | 845:49960 | The existing `SkinSelectScreen`, unchanged. |
| 5 | Avatar | 845:50352 | Swipe or tap to cycle five avatars. |
| 6 | Interests | 845:50568 | Eight tiles, three required. |

Every step is authored at the design's native 375 × 812 and the stage is scaled
to the device, so the layout code carries Figma's numbers and nothing else.
`OnboardingSpec.F` names each style the way Figma does, so `F.h32` *is*
`H32/Extrabold`.

### Noontree

The brand face is registered at launch by `NoonFont`, not declared in
`UIAppFonts` — the Info.plist here is generated (`GENERATE_INFOPLIST_FILE`) and
an array key has no `INFOPLIST_KEY_*` equivalent.

The supplied folder is a webfont-style export, so **each weight is its own
family** (`Noontree SemiBold`, `Noontree ExtraBold`, …); only Regular and Bold
share the `Noontree` family name. Asking one family for a weight —
`.custom("Noontree", size:).weight(.semibold)` — therefore renders Regular, and
the bug hides well because the text still looks like Noontree. Every weight is
addressed by PostScript name instead.

Two more traps worth knowing:

- The `.woff`/`.woff2` files at the top of that folder are **useless to iOS** —
  CoreText reads TTF/OTF only. The OTFs are in the `Noontree/` subfolder.
- A font that fails to register raises nothing; `Font.custom` just falls through
  to the system face. `NoonFont.register()` counts and asserts, and
  `-fontAudit` prints what CoreText actually resolved:

```bash
xcrun simctl launch --console-pty <udid> com.noon.gyroqr -fontAudit
```

Sizes use `Font.custom(_:fixedSize:)`. This is a prototype measured against
Figma frames, so Dynamic Type scaling would only make that comparison lie.

### The two media assets

**The splash clip ships as HEVC, not the WebM deliverable.** The source is the
AE render `Splash / Nano Splash new.mp4`; its VP9 WebM (CRF 32, ~450 KB) is what
the web gets, but iOS cannot decode VP9 at all: `AVPlayer` shows a black screen
and says nothing useful about why. `Tools/make_onboarding.py` encodes the bundled
`splash_burst.mp4` as HEVC tagged `hvc1` at CRF 22: ~560 KB, VMAF 97.0 against a
98.7 lossless ceiling, level with the WebM's 97.2. The source is `yuv420p` with
no alpha, so an opaque mp4 loses nothing. That script also saves the clip's final frame, because the email
step's backdrop *is* that frame — the design rebuilds the same burst from ~60
vector layers and blend modes, and re-deriving it in SwiftUI would be a lot of
work for a picture the video already contains exactly. Splash → email is
therefore a crossfade, not a push: it reads as one continuous shot.

**The OTP illustration is loaded as a dotLottie archive, not as bare JSON.** The
`.lottie` is a zip carrying the animation plus its six WebP layers; loading the
archive is what lets those images resolve without hand-wiring an image provider.
That needs `lottie-ios` (4.6.1, via SPM). If `-resolvePackageDependencies` fails
with `Couldn't get revision ... Needed a single revision`, the SPM clone cache is
stale — `rm -rf ~/Library/Caches/org.swift.swiftpm/repositories/lottie-ios*` and
re-resolve.

The clip's 600 × 400 canvas has air above and below the artwork, so it is framed
at its own aspect and then **cropped** to the design's 141pt-tall block. Scaling
the canvas down instead would shrink the envelope and arrows below design size.

### Interest icons

The tiles use `Category assets` (848:53680) — ten categories, each drawn twice.
`Tools/make_categories.py` builds all twenty imagesets from
`Tools/category_src/`; sources came off the node's `rawImages` where they had
alpha and its per-node `export` at 3× where they did not.

Two traps.

Not every render has an alpha channel. Figma hands back whichever bytes were
uploaded, and six of these twenty were flattened onto the sheet's near-black
background. Keying those by luminance eats the icon's own dark detail — the
shadow under a lamp, the dark base of a makeup case — so the background is
removed with a flood fill seeded from the border: only near-black *connected to
the edge* goes, and an enclosed dark region survives. A 2px feather on the
boundary keeps the result off a light tile without a sticker outline.

`sports_a` is a ball and a boot at opposite ends of a 2:1 canvas, which trims to
a 2.5 aspect and sizes down to a sliver. The sheet gets around this by cropping
the two objects into separate rectangles; the script does the same, finding the
gap from the art itself (it sits at 39% — halving the image cuts through the
boot) and stacking them on a diagonal to land near the 1.3 the sheet uses.

Sizing is by **constant area**, not a fixed box. These trim to aspects between
0.75 and 2.5 — a tall perfume bottle and a wide pair of sunglasses are the
extremes — and one box makes the wide ones look like slivers and the tall ones
tower. `CategoryArt` matches area instead, taking the aspect from the asset, so
re-exporting a render needs no code change.

The earlier eight icons had a different problem worth remembering: Figma's
per-node export of *those* came back with the tile's plate and a slice of its
blue border baked in, because each was a rectangle whose fill was a scaled crop
of a shared sheet. They were cut out of the reference sheet directly instead.
The new sheet's nodes are the renders themselves, so `export` is usable.

**Which set is the real one is unresolved.** The sheet draws all ten twice — an
upper chrome/iridescent set and a lower playful-3D set — and says nothing about
which is intended. Both ship. **Controls ▸ Onboarding step ▸ Interest icons**
switches them, `-categoryArt Chrome|Playful` at launch does the same, and the
default is Chrome only because it is the set the sheet lists first.

### Haptics

| Trigger | Feel |
|---|---|
| Any CTA | Medium impact. |
| OTP digit | Light, 0.55 — this fires four times in a row, so anything heavier becomes a rumble. |
| Wrong OTP | The system's `.error` notification pattern, plus a shake. |
| Correct OTP | `.success`. |
| Avatar cycle | Rigid, 0.6. Fires once per change whether you swiped or tapped a chip. |
| Interest tile | Light to add, selection tick to remove — and `.success` on the tick that arms Continue. |

The error pattern is a notification generator rather than hand-rolled impacts:
its double-buzz already reads as "rejected" and nothing built from impacts
communicates that as clearly.

### Where the build departs from the frames

Three deliberate deviations, all because a static frame can hide a problem a
build cannot:

- **OTP column spacing** is 32/16 rather than the design's 48/24. The design
  frame parks the keypad at y 515, directly over its own Resend row. Tightening
  the two gaps buys back the 45pt that row needs; translating the column instead
  slid the illustration under the status bar.
- **The OTP illustration has two sizes.** The design draws the burst at full
  bleed — about 500pt of canvas across a 375pt screen, so it runs off both
  edges — and 231pt tall. At that size the column below reaches y 612 and the
  keypad starts at ~542, so one of the two has to give; the gaps above are
  already as tight as they go. So the keyboard picks the size. Down is the
  design, which is what you see when the step opens; raising the keypad shrinks
  the burst to 290pt wide, which is exactly the 97pt the boxes and Resend row
  need. Because the art sits in the same `VStack`, everything below follows on
  its own — no manual lift to keep in sync. Focus is held back 680ms so the
  relaxed state is read first and the shrink registers as the keypad arriving.
  `-otpNoFocus` holds the keyboard down for a look at the design size.
- **The CTA tray** is a plain surface with a hairline on the white steps, and
  **nothing at all** on the email step. Figma's `Button Container` is a 32.5pt
  backdrop blur with *no fill*: over white that renders as a grey slab, and over
  the email step's smooth burst a blur of that gradient is indistinguishable
  from the gradient — so the design has no visible container there. Two attempts
  to draw one both looked like defects: `ultraThinMaterial` read as a murky
  purple slab, and blurring the still behind it needed a white veil to keep the
  disabled button legible, which put a hard-edged pale band across the art. The
  button carries its own legibility instead — the design only ever draws it
  enabled, so its disabled pattern (muted ink on a subtle surface) assumes a
  white page, and `NeutralCTA` gives that state an edge to sit inside.
- **`Tuning.invertX` / `invertY` now default to true.** Asked for as "invert the
  x & y settings by default"; those are the two toggles under **Controls ▸
  Input**, which belong to the QR card's gyro. Since reversed: both are false
  again, asked for as "invert both axis relative to current settings".

### The email field, and why a control can be hittable and dead

Worth recording, because the first diagnosis was wrong.

The field stopped taking taps when the keyboard lift went in, because that
change also added `.onTapGesture { focused = false }` to the **step's root** as a
tap-to-dismiss. A tap gesture on an *ancestor* of a `TextField` claims the touch,
so the field never focuses — and here it actively unfocused it. Hit testing is
unaffected, so the control looks completely alive.

`HitProbe` exists for this. It takes a control's own centre in window
coordinates and runs the same `hitTest` the touch system runs:

```bash
xcrun simctl launch --console-pty <udid> com.noon.gyroqr -onbStep Email -hitProbe
```

Two traps it taught:

- **A `UITapGestureRecognizer` on the `UIWindow` is ambient.** UIKit keeps one
  there in every SwiftUI app, with or without any gesture of your own. It read
  as the culprit until the same probe reported it with every app gesture
  removed. The probe now skips the window and only counts recognizers below it.
- **`REACHED` does not mean tappable.** A hit test says which view owns the
  point, not which recognizer wins the touch. The probe reports competing
  recognizers and `isUserInteractionEnabled` separately for that reason.

The fix scopes tap-to-dismiss to the backdrop image, which is a sibling of the
card rather than an ancestor of the field.

The probe also turned up a second, independent problem: the text line is only
**22pt tall inside the 56pt row**, so most of the field was never a touch target
regardless of gestures. The row now has a `Color.clear` tap layer in
`.background` — behind the field, so the field still wins its own taps and the
layer only catches what lands on the label and the padding. It has to be a
background and not a gesture on the row itself, or it becomes the ancestor
problem again.

### Driving it without touch

There is a UI test bundle (`GyroQRUITests`) for anything that needs a real
finger — genuine taps and typing, through the same path a user's touch takes:

```bash
xcodebuild test -project GyroQR.xcodeproj -scheme GyroQR \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

It exists because the two cheaper options both fall short. `simctl` cannot
synthesise taps at all. The native Simulator integration needs a system-wide
Xcode selection that this machine does not have — `/var/db/xcode_select_link` is
absent, and `xcode-select -p` only *looks* right because there is one Xcode
installed for it to fall back to. Fix that with:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

For everything that does not need a finger, each step has a scripted driver that
replays through the same entry points the gestures use — haptics included:

```bash
xcrun simctl launch <udid> com.noon.gyroqr -onbStep OTP -otpDemo
xcrun simctl launch <udid> com.noon.gyroqr -onbStep Skin -skinDemo
```

`-onbStep <Splash|Email|OTP|Skin|Avatar|Interests|Done>` starts on that step.
`-otpDemo` types a wrong code, then the right one (`4891`). `-skinDemo` cycles,
confirms, and presses Continue so the hand-off to the next step runs too.

Added since: `-otpNoFocus` holds the OTP keyboard down so the design-size
illustration can be captured. `-skinIndex N` opens the picker on a given card,
which is how a specific skin's glow palette gets looked at without throwing the
stack round to it. `-skinPull 0…1` and `-skinThrow 0…1` park the confirm pull or
the upward throw at a fixed fraction and hold it — the throw one matters because
`-skinThrow 1.0` is the frame that decides whether the hand-off is visible: if
the card is entirely clear of the stack there, dropping it to the back of the
z-order on release cannot be seen. `-interestsAll` opens the interests step with
everything selected, which is the state where the check badge and the render
compete for the same corner. `-palAudit` prints every skin's extracted palette,
for when a glow comes out a colour the card does not obviously contain.

For the cycle transition: `-skinFlick` throws the card with no travel time at
all, which is the case that exposed the gesture-mapped transition, and
`-cycleDuration 3.0` stretches the commit so screenshots — roughly 0.4s apart —
can step through a curve they would otherwise walk straight over. On the avatar
step, `-shakeDemo` runs a shuffle and `-shakeProbe` prints whether the shake
detector won first responder.

### Running on a device

`Tools/run_device.sh` builds, installs and launches on the connected iPhone:

```bash
Tools/run_device.sh                    # build, install, launch
Tools/run_device.sh -onbStep Avatar    # extra args go to the app
Tools/run_device.sh --build-only
```

**Why this exists.** Xcode's Run destination menu lists *Any iOS Device* — a
build-only placeholder meant for archiving — right next to the real phone.
Selecting it and pressing Run gives:

> A build only device cannot be used to run this target.

It gets selected by accident whenever the phone drops out of the list for a
moment (cable, lock screen, Xcode still pairing) and Xcode falls back. The catch
is that the choice is **persisted** in

```
GyroQR.xcodeproj/project.xcworkspace/xcuserdata/*/UserInterfaceState.xcuserstate
```

as `ActiveRunDestination`, so every reopen restores it and the error looks like a
project defect rather than a stale selection. To clear it: quit Xcode (it
rewrites that file on quit, so deleting it while Xcode is open does nothing),
delete the file, reopen, pick the phone, then quit cleanly once so the choice
sticks. The scheme itself is fine — `buildForRunning = "YES"` with a proper
`BuildableProductRunnable`.

The script sidesteps the menu entirely. Note it resolves **two** identifiers for
the same phone, which are not interchangeable: `xcodebuild` takes the hardware
UDID (`00008150-…`), `devicectl` takes the CoreDevice UUID (`3A48D73D-…`).

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

## The invite screen — the 2026 redesign

Figma `1 Child details` (980:15528) replaced `779:22071`, and it is a thorough
redesign rather than a reskin: the photographic backdrop is gone for a lilac
gradient with a ray pattern, the flat magenta card is now a moulded chrome
object with the QR recessed into it, the avatar and the three mascots are gone,
and a headline has arrived above the card. Nine imagesets went with the old
design — 2.3MB.

What survived untouched is the bottom of the screen. The OR rule, the invite
link and the share button are the same component at the same numbers, so that
code did not move.

### Taking it apart

`Tools/build_invite_layers.py`. **Every plane comes from a source that actually
determines it**, and that is the whole point of the script, because the first
version did not work that way — it used the two-ground solve that had worked on
the account page, and on this screen that solve has no signal.

The reason is the canvas. Figma renders a node onto the page's background, and
on this page that background is **pure white**. The solve is

```
1 - α = (C1 - C2) / (G1 - G2)
```

with `G1` the canvas and `G2` what the plane sits on — and this screen's own
background runs from pale lilac at the top to *white* at the bottom under its
overlay. So `G1 - G2` goes to zero exactly where the sparkles are, α comes out
of a division by nothing, and every plane ends up carrying a rectangular slab
of background. The right sparkle's matte measured **0.43 mean alpha around its
whole border**. That is invisible at rest, because the slab *is* the
background, and obvious the moment the card tilts and drags it along. On the
account page the canvas was blue against a purple page and the same code was
fine.

So each plane is now cut by the method its own material suits:

| Plane | Cut from | Why that one |
|---|---|---|
| `bg` | `980:15529`, exported whole | A node export carries none of its siblings, so the page is simply an export. |
| `frame`, `star_l`, `star_r` | the original uploads | `download_assets` returns the images the designer placed, and those have real alpha. |
| `panel` | its own export against the white canvas | A dark, opaque object on white: `\|C − white\|` *is* its matte. No second ground needed. |
| `qr` | solved against the panel | Ink on a dark panel is the one place on this screen where a solve has real signal. |

**The uploads have alpha but not the node's transform**, so the transforms come
from the CSS, written out term by term: the left sparkle is rotated 75.57° and
blurred 1pt, the right one is flipped vertically and rotated −150.66°. Two sign
conventions matter and both are easy to get backwards — PIL rotates
counter-clockwise where CSS rotates clockwise, and Tailwind emits
`rotate(a) scaleY(-1)`, which CSS applies right to left, so the flip goes
first.

**Size and position come from the render, not the CSS.** With an exact matte in
hand this is easy — composite the plane at a candidate offset and see how well
the result matches the finished screen over the plane's own footprint — and it
is necessary, because the CSS gets within a point or two and no further. It is
also how the right sparkle's *size* was settled: its CSS says the image fills a
120.6 × 230.2 box and it plainly does not, so rather than guess which of
Figma's fill modes that is, the scale is swept and the render decides. It came
out at **0.70** of the box.

Solving the matte and the placement together is what needed clever scoring.
Solving them one at a time does not need any.

**Every plane now reports the number that would have caught this.** The border
ring is the tell: a plane whose matte is its own silhouette has almost nothing
there, and a plane carrying a slab has a ring mean in the tenths.

```
inv_frame    ring alpha mean 0.0001   max 0.004
inv_panel    ring alpha mean 0.0000   max 0.005
inv_qr       ring alpha mean 0.0142   max 0.512
inv_star_l   ring alpha mean 0.0000   max 0.000
inv_star_r   ring alpha mean 0.0000   max 0.000
```

One more trap inside the QR's solve. `α = (C − G)/(1 − G)` per channel needs
one channel's answer, and the dimmest is the natural choice — it is the one
that does not over-claim on an antialiased edge. It is also wrong here,
because the group is not all white modules: the nano badge in the middle is
yellow, so its blue channel is *darker* than the panel under it, that channel
answers negative, and taking the minimum punched the badge's interior out into
a hole. The panel is dark enough that any ink on it is brighter in at least one
channel, which is what makes the **brightest** channel the safe one.

### The light bands have to be clipped to the card, not to its box

One boundary survived the matte work, and it was not a matte at all.

Under tilt a pale rectangle sat at the card's *rest* position while the card
itself rotated away from it. The tell was that it did not move with the card:
whatever was drawing it belonged to the card's box rather than to the card.

It was the sheen and the iridescence. Both are large additive gradients swept
across the card by the tilt, and both were clipped to `spec.corner` — the
card's **rectangle**. On the card this replaced that was the right clip,
because a flat magenta panel *is* its rectangle. This one is a moulded object
with rounded corners well inside its box, so the bands were painting light onto
the transparent corners and the result was a rectangle of lit nothing.
Confirmed before fixing by turning both off: the rectangle went with them.

The fix is a `lightMask` on the card — an image whose alpha is the card's
**coverage**, which the builder derives from the frame's own alpha. Coverage,
not alpha: the two differ over the chrome's outer glow, where the alpha is a
tenth or two, and masking the card by its own alpha would square that and dim
the glow away. Hardening it gives a mask that is 1 over every part of the card,
glow included, and 0 only where the card genuinely is not.

Where the mask goes matters. It is applied to the whole lit card — body plus
bands, after the clip — and not around the bands on their own, because they
blend against what is under them and wrapping them in a mask would give them
their own compositing group and stop the blend reaching the card. That is the
same trap the pocket glow hit, noted further down.

Cards that *are* their rectangle need none of this: `lightMask` is nil for the
profile card, whose plate fills its 32pt-radius box.

### Two things the design context does not tell you

**The headline has a stroke.** `get_design_context` reports the gradient fill
and the drop shadow and says nothing about the 4.8pt white ring that is the
loudest thing about "Invite Kiaan" — Figma text strokes do not come through
it. It was measured off the render instead: a vertical slice through the "I"
puts 4.67pt of white above the glyph and 5 below.

SwiftUI has no text stroke either, so `OutlinedText` draws copies of the
glyphs offset around a circle. One ring is not enough — at 4.8pt even twenty
copies scallop where a letter curves away, because the union of discs at that
radius is not a disc. Two rings, the outer at the stroke width and an inner at
55% of it, fill that in.

**A `lineSpacing` set for a multi-line style pushes a single line down.**
`figmaText` carries the style's line height as `lineSpacing`, which SwiftUI
adds *below* a single line — so the OR row rendered 21.6pt tall instead of 18,
and everything under it sat 3.6pt low. Measured against the render: the link
box was −3.67 out and the share button −4.33. Pinning that one row to its
design height fixed both.

### Where the build sits against the design

Measured on the built app, resampled to the design's 375 × 812 and diffed
against Figma's own render of the screen: **mean 8.4/255**, and what is left
is type antialiasing — native Noontree against rasterised Noontree — plus the
card's rims. No structural difference, nothing misplaced.

| Region | mean | p95 |
|---|---:|---:|
| headline | 11.9 | 89 |
| card | 9.2 | 39 |
| bottom sheet | 8.7 | 26 |

### Rebuilding its layers

`Tools/invite_src/` holds the node exports, checked in:

```bash
python3 Tools/build_invite_layers.py      # needs numpy, Pillow
```

| File | Node | What it is |
|---|---|---|
| `screen3x.png` | `980:15528` | The whole screen, 3x — the ground truth every plane is placed against. |
| `bg3x.png` | `980:15529` | The background, 3x. |
| `panel3x.png` | `980:15538` | The recess's export, 3x. |
| `qr3x.png` | `980:15539` | The modules and the badge, 3x. |
| `raw_frame1.png` | `980:15537` | Its **upload**, not its export. |
| `raw_starL1.png` / `raw_starR4.png` | `980:15987` / `980:16004` | Ditto — the uploads are where the alpha is. |

The `rawImages` are the ones with alpha. Which of the several a node returns is
the right one is worth checking rather than assuming: a node can hand back the
same image twice at two resolutions, once flattened and once not. `Tools/build_layers.py` and `Tools/source_layers/` built the card
this replaced and are kept only as the record of it.

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

## The second card — Share QR

Figma `Share QR` (940:62757), whose card is `940:63003`. Same effect, second
content: pick it under **Controls ▸ Card**, or launch with
`-cardStyle Profile`.

Nothing about the motion is duplicated. `CardSpec` used to be a bag of statics
for the one card; it is a value now, and `GyroCardView` takes one. The depth
model, the light, the shadows, the wobble and the in-plane roll all stay in the
view, and a card is only its planes and where they sit. Its elevations follow
the invite card's fitted values so the two read as the same effect — heroes at
20, name at 13, backdrop below the surface at −8.

Six planes, plus native text:

| Plane | Figma node | Elevation | Notes |
|---|---|---|---|
| `pq_plate` | 940:63004 | −8 | The starburst, whole. Exported on its own, so the rays under everything are real. 8pt of baked bleed. |
| `pq_portrait` | 940:63104 | 20 | The avatar disc. A 140pt ellipse with a 2pt stroke outside it, so the plane is a 144pt circle. |
| `pq_badge1..3` | 940:63587/63590/63593 | 20 | The three interest stickers, one plane each. |
| `pq_qr` | 940:63120 | 20 | A white matte of the modules, not a panel. |
| name / caption | 940:63117 / 63585 | 13 / 0 | Native Noontree — this card's type is white on purple, so there is no matte to lift. |
| close button | inside 940:63100 | 6 | A control just off the surface, not a hero. |

Contact shadows are much lighter here than on the invite card's hero planes.
The design draws none — the disc sits flush on the starburst — and a shadow cast
from a crisp circle, offset by the parallax, reads as a hard crescent ringing the
portrait rather than as contact with a surface. The QR's is per-module, which at
the invite card's strength pooled into a grey haze behind the whole code. The
badges' own shadows are baked into their artwork, so they cast none at runtime.
The parallax carries the depth on its own; **Controls ▸ Contact shadow** scales
what is left.

The badges sit at the portrait's elevation rather than above it. They hang off
the disc's lower edge and belong to it, and any difference in elevation slides
them off the thing they are attached to.

### Every plane is one node

The first version of this split had exactly one input: a flat render of the
finished card. Everything hidden behind something had to be invented — holes
punched where the portrait and the QR sat, filled by a radial ray model and by
diffusion — and the silhouettes had to be found in the pixels by thresholding
against that invented fill.

It is worth recording what that cost, because the failures were subtle enough to
survive several rounds of looking at stills and only showed up under tilt:

* The synthesised backdrop never quite matched its surroundings, so the seam
  slid into view as a pale crescent over the avatar's head.
* The thresholded matte came back as a *blob filling its own frame* — 83% of a
  140 × 168 box, touching all four edges. So the plane carried a slab of
  backdrop, and the moment the card tilted that slab slid across the plate and
  outlined itself; the contact shadow, cast from the same alpha, outlined it
  again. That is the boundary in the screenshots.
* The badges were inside that same box, so their rectangle was the portrait's
  rectangle.

None of it was necessary. Figma will render any node on its own:

**The backdrop is an export, not a reconstruction.** `940:63004` is the
starburst image, and Figma renders it clipped to the card with every layer above
it absent. The rays that show under the portrait and between the QR's modules
are the rays the design draws there. What the export does *not* carry is the two
full-bleed gradient rects stacked over it (`940:63005`, `940:63006`), which are
what turn the source's blue into the card's purple.

Those are fitted rather than exported, and the fit is the one genuinely clever
part of the script. What the rects do to a pixel depends only on *where the
pixel is* — so the map from the bare starburst to the finished card is smooth in
x and y, even though it is not smooth in colour. `reconstruct` estimates it as a
per-channel affine `flat = a·bg + b`, with `a` and `b` taken from a Gaussian
neighbourhood of pixels where both images are known, and then evaluates it
*inside* the holes. The structure comes from the real export; only the tint is
extrapolated, and a tint has nothing sharp in it to get wrong.

Two passes, because most of the "foreground" is not a hole at all: the QR, the
name and the caption are ink on the backdrop and the rays show between every
module and around every letter. The first pass masks their boxes, the second
masks only the pixels the first pass cannot explain — which hands the gaps
between the modules back to the fit. Where a neighbourhood still holds too few
known pixels to fit at all, deep inside the portrait's disc, the estimate falls
back to a wider one and then wider again: push-pull, but on the coefficients
rather than on the colour.

Measured against the card render, over the 71% of it that is visible backdrop:
**mean 1.20/255, p95 4.0, p99 9.6.**

**Each foreground plane is its own export, with its alpha solved.** A single
composite is one equation in two unknowns, which is why no amount of
thresholding one render can say where an object ends. Two composites over
*different* grounds is two equations:

```
C1 = F·α + G1·(1-α)
C2 = F·α + G2·(1-α)     ⟹     1-α = (C1-C2)/(G1-G2)
```

and Figma hands over both for free — the node's own export is the plane over
the page canvas, and the card render is the same plane over the backdrop. Both
grounds are known: the canvas from a plane fitted through the export's own
border ring (it is a gentle gradient, not one flat blue), the backdrop from
`reconstruct`. So α falls out per channel, and the channels are averaged in
proportion to how far apart the two grounds are in each — a channel where they
nearly agree says nothing.

Three things had to be got right for that to work:

* **The ground behind the badges is the portrait, not the plate.** They hang off
  the bottom of the disc. Solving them against the plate alone put the disc's
  own pixels into their alpha and produced three translucent rectangles.
* **Registration is measured, not assumed.** Figma pads an export by whatever
  effect the node carries and does not say by how much; the badges come back
  about 6pt larger than their frames on every side and 5pt lower than centred,
  because each sticker drops a shadow. Matching the two renders on *brightness*
  does not find it — most of what is being compared is ground, and the ground
  is supposed to differ. What does find it is the channel estimates of `1-α`
  agreeing with each other: at the right offset they are three readings of one
  number, and at the wrong one they scatter. Registering by that pulled the
  channel spread from 0.54 to 0.09 and moved the badges 5pt.
* **A sticker and its shadow both live within the shadow's reach of the
  sticker.** The solve is exact where the grounds are far apart and noisy in the
  last percent where they nearly agree, so the raw alpha came back with a faint
  haze of ray structure and ghosts of the neighbouring badges across the whole
  export. The support is the solid body grown by 7pt; the haze outside it cannot
  be real.

The portrait needs none of this. The node is an *ellipse*, so the matte is a
circle — 140pt across with a 2pt stroke outside it, feathered by a pixel. Every
earlier attempt to find that shape in the pixels came back with the pale halo
attached, because the halo is artwork and no threshold separates a soft ring
from the soft backdrop behind it.

**Verifying the split.** Compositing the six planes back over each other and
comparing against Figma's own render of the card is the check that matters, and
it is the reason to trust the numbers above: **mean 1.24/255, p95 4, p99 14**,
with the residual confined to one-pixel rims where a 3× resample disagrees about
antialiasing. Independently, the QR plane's frame is *measured out of the
pixels* at (59.50, 311.67, 232.33, 232.00) and the design puts the module grid
at (59.5, 311.5, 232.001, 232.001) — agreeing to a third of a point without ever
being told.

### The plate's edge has to grow from the card's shape

The export carries the card's 4pt white border and the antialiasing of its 32pt
rounded corners, and neither is backdrop. Growing the plate outward from a
*rectangle* inset by a few points does not remove them: at the corners, a few
points in from the edge is still outside the rounded shape, so the fill spreads
the white border inward and the card's corners come out cream — which showed as
a pale notch at the bottom-right under tilt. The safe region is the rounded
rectangle itself, inset by 10pt; everything outside it takes the nearest pixel
inside, and the whole thing is then padded by 8pt of bleed.

Bleed rather than `scale`, which is the other boundary this card taught. The
plate has to be bigger than the card so its own drift never brings an edge into
view, and `scale` on the layer is the obvious way to get that — but it is
anchored at the card's centre, and this card's portrait sits 176pt *above* that
centre, so a 1.08 scale displaced everything up there by about 14pt. The invite
card gets away with `scale` 1.10 for two reasons worth recording: its QR panel —
the hole that would matter most — sits almost exactly on its card's centre,
where a scale displaces nothing, and its plate is a smooth pastel that blends
invisibly whether it is displaced or not. Neither is true of a starburst.

### Where it departs from the frame

* **The close button is 40pt, not 56.** The frame reports the page header's own
  height there; the disc inside it measures 40 across, centred at (303, 46).
* **The type is native.** The invite card's name is an alpha matte because it is
  dark ink that had to be lifted off a busy plate. This card's name and caption
  are white on purple at known sizes, so they are set in Noontree directly and
  stay crisp at any scale.

### Driving it without touch

| Argument | Effect |
|---|---|
| `-cardStyle Profile` | Opens on the second card. |
| `-motionSource Drag` | Pins the card flat. The Simulator has no gyro, so the default source falls back to Demo and the card is otherwise always mid-swing — this is the only way to screenshot it at rest. |

```bash
xcrun simctl launch <udid> com.noon.gyroqr -scene "QR card" \
  -cardStyle Profile -motionSource Drag
```

### Rebuilding its layers

`Tools/profile_src/` holds the node exports the split needs. They are checked
in, so the usual case is just:

```bash
python3 Tools/build_profile_layers.py      # needs numpy, scipy, Pillow
```

To refresh them, `download_assets` one node at a time and keep the `export`
(not the `rawImages`, which are the original uploads — the badge stickers come
back as the whole interest-icon sprite sheet, with no crop):

| File | Node | Scale |
|---|---|---|
| `Tools/profile_flat3x.png` | `940:63003`, the whole card | 3x, cropped to the card's outer edge (offset 36, 40 px) |
| `profile_src/bg3x.png` | `940:63004`, the starburst | 3x |
| `profile_src/portrait4x.png` | `940:63104`, the avatar ellipse | 4x |
| `profile_src/badge1..3_3x.png` | `940:63587`, `63590`, `63593` | 3x |

The script prints the card-local frame of every plane it cuts; paste those into
`CardSpec.profile`.

## The account page

Figma `Account` (978:15007). The brief here is small and the work is all in one
place: **only the header animates**, so only the header is taken apart.
Everything below y 379 — the two widgets, the four settings lists — is one flat
export, which is the right trade for a region that never moves.

**The header opens first.** The page starts with it collapsed to 101pt — the
status bar and the page header, and nothing else — with the body sitting
directly underneath. It expands to 379 and pushes the body down, and only once
it has settled does anything appear inside it. Doing it in that order is what
makes the header read as *making room* for a profile rather than as a panel
that happens to be resizing while things fly about inside it.

The backdrop is a fixed-size layer anchored at the top and **clipped** to the
current height, not stretched into it. The rays therefore stay where they are
and the expansion reveals more of them, which is what a header opening looks
like; resizing the image slides every ray as it goes.

Then the load-in:

| Beat | Delay | What moves |
|---|---|---|
| **header** | 0 | Expands 101 → 379, pushing the body down. |
| **avatar** | 0.30 | The disc scales up from 62% and overshoots. |
| **stickers** | 0.40 / 0.455 / 0.51 | The three interest stickers pop onto it from 30%. |
| **name, email** | 0.50 / 0.55 | Fade up 10pt. |
| **props** | 0.56 / 0.60 / 0.64 | The ball, the star and the bolt travel in from off-screen. |

(The second column is time from launch; in the code the sequence's delays are
written relative to the expansion, which is the number worth tuning.)

One spring for everything — `interpolatingSpring(stiffness: 320, damping: 28)`,
the same tension and friction the wallet's entrance uses, so the two pages feel
like the same app. Two exceptions, both for a reason. The avatar is the element
the brief asks to *pop*, so it takes the same stiffness with the friction
dropped to 18 — a damping ratio of 0.50 and a visible overshoot. The expansion
takes friction 30, slightly *more*, because it travels 278pt where everything
else travels ten, and the same damping ratio over that distance overshoots by
an amount you can see.

The two icon buttons are not in the sequence at all. They belong to the
collapsed header, so they are on screen before anything expands and stay put
while it does.

The props' *resting* positions are measured; their *entry* positions are
chosen. The design is a still, so there is no reference for where they come
from — each takes the shortest line to its own nearest edge, which is what
makes the three read as one gesture rather than three.

### Taking the header apart

`Tools/build_account_layers.py` — the third version, and the first that does
not start from the finished render.

**Why the first two left ghosts.** Both took Figma's render of the header and
patched out whatever had to move — the props, the avatar, the design's own
status bar — filling each hole with a fitted estimate of the backdrop behind
it. A patch is an estimate, and every one left a faint copy of what used to be
there: a ghost of the ball where the ball rests, of the star, of the status bar
along the top. Invisible while everything sits at home, because then the prop
covers its own ghost; obvious the moment anything is in flight, which on a
load-in page is the whole point.

**So the backdrop is rebuilt from its recipe instead.** The CSS gives it
exactly, and nothing was ever in front of it:

| Layer | What it is |
|---|---|
| header fill | linear `#2188FF → #0A49B8`, top to bottom |
| `978:15076` | the starburst upload, **colour-dodged** onto it |
| `978:15077` | `#7D43EA` in **color** blend mode, full bleed |
| `978:15078` | radial `#7D43EA@0 → #4C17B0@1`, centre (188, 116.5), radii 797 × 237 |

It reproduces the render to **0.61/255 mean, p99 2.0** wherever the render
shows backdrop — which is the check that the recipe is read right. Two details
it took to get there: the dodge and the color blend act on sRGB values
directly, and the radial gradient interpolates colour *and* alpha together
(straight, not premultiplied), which makes its middle 10/255 brighter than a
fade to the end colour. Below the type, where the skyline vectors of
`978:15079` peek in, the backdrop is the render — nothing that moves reaches
that strip.

**Each prop is its own upload at its CSS transform.** The ball is 48.31pt
rotated −13.02° in its 57.95 box; the star fills its box. Composited over the
rebuilt backdrop they land on the render at 2.6 and 1.3/255 — antialiasing —
and at the CSS position to within a third of a point. The bolt is paler and
cooler in the render than in its file, an image adjustment the CSS does not
report, so its alpha is the upload's (an exact edge) and its colour is the
upload's mapped through a quadratic fitted against the render inside the ball.

An earlier cut had searched the props' positions against the *patched*
backdrop and put the ball 4pt low. The search was fitting the patch.

**The avatar scales about its own centre.** It did not: `scaleEffect` came
after the `offset` that places it, and `offset` moves the drawing but not the
layout frame, so the disc scaled about where it would have been at (0, 0) and
grew out of the header's top-left corner. Scaling first, while the frame and
the drawing coincide, and then moving is `AccountScreen.popped`. The stickers
had the same bug.

### The rays entrance

The backdrop does not just appear: the starburst **streams out of its
vanishing point** behind the avatar, speed lines shoot outward along it, and
after about a second the rays settle into the design's placement. It is a
dotLottie, `GyroQR/Account/acct_rays.lottie`, authored in After Effects and
played by `HeaderRays` in place of the static `acct_bg`.

| Layer | What it does |
|---|---|
| `SPEED_LINES` | 26 radial streaks, each a trim-path dash run from the centre past the corner, staggered over 0.04–0.82s |
| `RAYS` | the starburst as its own plane, easing in from 90% at 0.52s and landing at 100% on a spring |
| `RAYS_FLOW_1…5` | soft-edged copies of the starburst flying out from 22% to 175%, 0.12s apart |
| `Base` | the header's purple with no starburst — a vector rectangle with a gradient fill |

**Lottie-safe by construction.** Image layers and shape layers only: no
effects, no blend modes, no merge paths. The two things After Effects can do
that Lottie cannot are both baked:

* **The spring** is FrameForge's inertial bounce on `RAYS`' scale —
  `amplitude 0.06, frequency 2.6, decay 6`, overshooting to 100.8% and settled
  by 1.35s — baked to 60 keyframes with FrameForge, and its last key pinned to
  exactly 100% so the final frame is the design.
* **The blends.** The starburst is colour-dodged and color-blended in Figma,
  and neither survives into Lottie. So the rays plane is the *result* of those
  blends, solved as the least-transparent RGBA that reproduces the backdrop
  when laid over the base: exact to 0.08/255.

The copies that fly outward are feathered to nothing 200pt from the vanishing
point, inside the plane's nearest edge, so a copy at any scale shows rays
thinning out and never a boundary. The final plane never goes below 90%: its
top edge is 210pt above the vanishing point and the header's is 187, so
anything smaller would show it.

`HeaderRays` shows the animation's frame 0 as its placeholder while the
archive loads — the purple with no rays — so there is no flash, and Replay
rebuilds it to play from the top.

**The Base is a vector gradient, not the rebuilt plane.** It was the plane;
it was replaced in AE with a rectangle and a two-stop linear gradient, which
is far lighter. It sits within 3–12/255 of the design, darker through the
middle — a linear ramp cannot carry the design's radial vignette. Its stops
are in the comp to adjust.

### Driving it without touch

| Argument | Effect |
|---|---|
| `-scene Account` | Opens on this page. |
| `-accountEntry` | Holds the header collapsed and empty, on the rays' frame 0. |

```bash
xcrun simctl launch <udid> com.noon.gyroqr -scene Account
```

### Rebuilding its layers

`Tools/account_src/` holds the sources, checked in:

| File | Node |
|---|---|
| `raw_rays1.png` | `978:15076`'s upload — the starburst |
| `raw_ball_r2.png`, `raw_star_r1.png`, `raw_bolt_r1.png` | the props' uploads, with real alpha |
| `header3x.png` | `978:15074` rendered whole — used only to check, and for the skyline strip and the bolt's grade |
| `avatar3x.png` | `978:15212`, the avatar ellipse |
| `body3x.png` | `978:15228`, everything below the header |

```bash
python3 Tools/build_account_layers.py     # asset catalog + Tools/ae/account_rays/
```

It prints the rebuild's error against the render and each plane's, so a bad
source shows up as a number rather than as a ghost on the device.

### Rebuilding the rays

In After Effects, with any project open (the comp goes in its own folder,
nothing else is touched, and the project is not saved):

```bash
osascript -e 'tell application "Adobe After Effects 2026" to DoScriptFile "'$PWD'/Tools/ae/build_account_rays.jsx"'
```

Then the spring — select `RAYS` ▸ Scale, FrameForge **Spring** (0.06 / 2.6 /
6), **Bake** — and export and pack:

```bash
osascript -e 'tell application "Adobe After Effects 2026" to DoScriptFile "'$PWD'/Tools/ae/export_lottie.jsx"'
python3 Tools/pack_account_rays.py
```

`export_lottie.jsx` samples every animated property on every frame, which
bakes eases and expressions alike, then drops the samples a straight line
already predicts. ExtendScript cannot read gradient colours, so a gradient
fill is exported with a request instead: the layer is rendered alone and
`pack_account_rays.py` reads its colours back along the gradient's own line.
The packer refuses a JSON with an expression, an effect, a blend mode or a
merge path in it. The build script never throws — an uncaught error in AE
opens a modal that blocks every scripting channel until it is clicked — so a
failure shows up in `Tools/ae/account_rays/build_log.txt` instead.

## The button lab

Figma `Button` (1005:41915) — the `M-NeutralButton` alone on the page — as a
scene for trying press interactions. `ButtonLab.swift`.

The button is the node verbatim, read through the plugin API because the CSS
export flattens its stroke to one grey: a fill `#212121 → #0D0D0D` over the
lower half, a 1pt inside stroke `#E0E0E0 → #575757` top to bottom, a pale inner
glow along the top edge and a black one along the bottom, 12pt circular
corners.

### The round replica

`RoundDome.swift` — the reference recording's own button, a glossy red dome
77pt across on a warm page, rebuilt 1:1 from gradients and shadows before its
light goes onto any other shape. It is the scene's **Round** style.

Every number is read off the recording, which is a phone at 3× so its pixels
are this screen's: radial profiles in eight directions and dense vertical
ones down five columns, at rest (frame 38) and pressed (frame 50). The dome
is centred at (604.5, 573.5) with a radius of 115px; everything is in units of
that radius, `R`.

| | Rest — raised | Pressed — sunk |
|---|---|---|
| face | radial falloff from the light at (0.08, −0.95)R: coral (253, 131, 108) → maroon (52, 10, 15) | vertical ramp, dark red → bright (195, 60, 42) over the lower half |
| top | a faint rim, fading into the page | the **lip's shadow** — a dark *blob* at the top centre, a Gaussian ~0.3R wide, not a band round the edge — under a strong **light-pink rim** that straddles the edge and is gone 40° either side of vertical |
| bottom | dark, into a tight **contact shadow** | a thin dark rim, 0.1R deep, into the page shadow |
| page | a soft shadow, **the same in both states** — fitted over 64 samples at 1.06R across, 0.197R lower, σ 0.134R, 86% of #35070D | same |

The things that made the difference, each found by measuring rather than by
eye: the shadow on the page does not change, so everything that changes is
inside the face; the lip's shadow is concentrated at the top centre; and the
pressed rim is *brighter than any blend of the face with the page*, so it is
drawn over the softened edge, not inside the clipped face. SwiftUI's inner
shadows could not do any of this — they run all the way round a circle, and
stacked they buried the rim under the lip — so each is an explicit crescent:
a circle minus a shifted copy of itself, blurred.

Against the reference, over the dome and its surroundings with the mark and
the reference's text ring left out: **6.1/255 mean at rest, 7.6 pressed**,
every region's signed error within ~8. The mark is a stand-in in type (SF
Pro Expanded Bold, the E reversed), not the brand's artwork. The press is a
75ms crossfade: the reference changes in 4–5 frames, and every sampled pixel
moves monotonically from one end to the other. No scale — the dome is the
same width to the pixel in both frames.

### The Continue button

`SlabDome.swift` — the replica's light on the design's own button, and the
scene's default style, **Continue**: 351 × 52, 12pt corners drawn with iOS's
continuous curve (corner smoothing), the design's greys, `Continue` in
Noontree SemiBold 16.

Every layer is the dome's, in the same order. What the dome measured in
radii this measures in **half-heights** (26pt) — the light is vertical, and
the height is what carries it — so the page shadow, the contact shadow, the
lip and the bottom rim keep the dome's proportions. The rest face's radial
falloff becomes an elliptical one taking the button's proportions.

**The colours are the reference's, mapped onto the design's greys by
luminance**: one straight line through the design's anchors, the foot at
#0D0D0D and the body's #212121, so every stop keeps its brightness *relative*
to the others — which is what the effect is made of. Coral lands on #727272
at the light; the pressed face's bright lower half on #404040, brighter than
the raised face's middle, as the reference's is. At rest the button keeps the
design's own 1pt stroke, #E0E0E0 → #575757, as its rim light.

Two numbers do not come across by proportion, and both are the pressed rim:

* **its weight.** 0.15 of a half-height is a 4pt hairline on this button
  where the dome's rim is 6pt, so it reaches 0.24 of a half-height instead.
* **its colour.** Luminance-mapped it lands on mid grey, and even the
  stroke's #E0E0E0 reads as a pale strip against a #F7F7F7 page. The
  reference's rim is *brighter than its page* in red (245 against 239) —
  that is what makes it read as light — so here it is white.

**Shine** and **Shine width** in the controls sheet set the pressed rim —
its strength, 0 to 1, and its reach as a multiple of the calibrated one —
on both the Continue button and the round replica; 1 and 1× are the
calibrated look. `-buttonShine 0.5 -buttonShineWidth 1.5` sets them at launch.

### In the app

The Continue button is now **the app's primary button**: `DomeButtonStyle`,
frozen at the settings picked in the lab —

| | |
|---|---|
| scale while held | 1.012×, spring 0.26s / 0.68 |
| light change | 75ms each way |
| shine | 1.0, width 0.47× |
| haptic | Impact · Heavy at 1.0 on press, a light 0.4 tap on release (`PressHaptics.flow`, which honours the app-wide haptics switch) |
| drop shadow | 0.5 of the replica's (page and contact shadows together) — `DomeShadow.shared`, one live value, so the lab's **Drop shadow** slider moves every primary button in the app; `-buttonShadow 0.3` at launch |

— on every `M-NeutralButton` in the flows: onboarding's `NeutralCTA` (the
avatar, email and interests steps and *Run it again*), the top-up's *Request
top up*, the invite's *Share invite* and skin select's *Continue*. The surface
(`DomeSurface`) sizes itself to whatever it is drawn behind, so the 56pt
onboarding CTA and the 52pt share button take the same light at their own
heights. A disabled button draws no dome and keeps its flat muted look —
sunk-in on something that cannot be pressed would be a promise it does not
keep. The wallet's white *Request top up* pill is a different component,
`M-NeutralRoundButton`, and keeps `PressLift`.

One lab slider is not in the frozen set: **Lift shadow** only ever applied
to the Lift style, so it had no effect on the Continue button it was tuned
on, and the flows match what was seen.

Two other styles, from the controls sheet — **Round** above, and **Lift**,
the first brief: scale up 3% on a spring and the fill and rim swap ends,
crossfaded over 80ms. An earlier **Push in**, which tried the reference's
effect by eye before the replica existed, is gone.

**A shadow is only as strong as what casts it.** An early page shadow here
came out at almost nothing, and so, it turned out, had `PressLift`'s
elevation since it was written: both cast from a `.black.opacity(0.001)`
copy of the shape, and SwiftUI multiplies the shadow by the caster's alpha.
Both now cast from an opaque copy under the control's own opaque surface.

**The haptic** fires on touch-down, from `ButtonStyle.isPressed`. Two engines
to compare: *Impact* (the five UIKit presets at a chosen intensity — Heavy at
1.0 is the strongest single tap the system gives, and the default) and *Core
Haptics* (a transient event with intensity and **sharpness** set directly —
low sharpness is a thud, high a click, and it is most of what makes a tap read
as strong). A second, lighter tap on release is there to try, off by default.

`-scene Button -pressHeld` pins the pressed look for screenshots;
`-buttonStyle Round` (or `Lift`) opens on another style.

## The parent flow — adding a kid

Figma section `Flow for claude` (1015:44810): eleven frames on six pages,
`GyroQR/Parent/`. Scene **Parent**.

| Page | Frames | |
|---|---|---|
| child | 1, 2 | names, birthday, gender → *Continue* plays the celebration (2) over it, then on |
| email | 3, 4 | the kid's email, the field focused on arrival → *Continue* raises the confirm sheet (4) |
| intro | 5 | "Introducing Kiaan's nano wallet" — plays its entrance, holds 1.7s from arrival (or a tap), then on |
| rules | 6, 7, 8 | auto- or manual-approve; manual opens its limit options (7); the limit field brings up the number pad (8) |
| address | 9, 10 | pick an address → *Continue* plays Let's Go (10) over it |
| invite | 11 | the invite QR screen the app already has |

**Between pages, a crossfade.** The progress bar is the one element every
page shares, so it lives above the pages, stays put and fills on the
`interpolatingSpring(stiffness: 320, damping: 28)` spring while the page under
it fades (0.35s ease-in-out) to the next. A drill (the old page shrinking as the
new one slid over it) made the flow feel hectic, so it went, and with it the
close button: every page past the first has Back. Email → intro is the
showpiece: the confirm sheet fades with its page while the intro's stars
settle from 112% and a few degrees turned, the wallet card swings down from
above the screen tipped 24° back about its horizontal axis and rights itself
with a small overshoot, and the copy fades up under it. Frames 2, 4 and 10 are
overlays on their page and 7 and 8 are states of 6, so they don't
crossfade. The flow ignores the safe area at its root:
a page's clip and scale take the frame they are given, and inside the safe
area that frame stops short of the status bar and the home indicator.

**The art.** The header art is the supplied dotLotties — `Bot Asset`
(child), `Email-Pop` (email), `Nano-Shield` (rules), `Address-Pin` (address)
— and `Lets Go` is frame 10 whole, as `onboard_celebration.json` (in the app
as `parent_celebration.json`, "Kiaan is 10 Years Old") is frame 2. Each header Lottie's position was found by
screenshotting the page with and without it (`-parentNoArt`), which isolates
its pixels, and sliding them over the Figma render until the header matched
best. The shared header background is one 3× export: it is SVGs with blur
filters, which Xcode's SVG renderer drops, rendered in headless Chrome
(`Tools/parent_src/render/`).

**The primary buttons** are `DomeButtonStyle`, the app's button.

**Where it stands against the design**, per band, /255 (the status bar is the
device's; the action bars differ by the button's own light):

| Page | header | title | body |
|---|---|---|---|
| child (1) | 7.8 | 11.2 | 2.7 |
| email sheet (4) | 0.6 | 2.4 | 6.1 |
| intro (5) | 2.1 | 4.0 | 2.9 |
| rules, auto (6) | 1.8 | 8.5 | 2.8 |
| rules, manual (7) | 1.8 | 10.3 | 3.6 |
| address (9) | 1.7 | 7.6 | 3.4 |

The title band's remainder is the Lotties' last frames against Figma's still
art, which are close but not the same pose. (Measured before the close
button came out.)

Three things this took, worth knowing for the next screen built from Figma:

* **CSS sizes a border inside the box.** A card with `p-12` and a 1pt
  border has its content 13 in; an overlaid SwiftUI stroke adds nothing, so
  the padding has to carry the extra point.
* **Multi-line copy goes in one box per line.** `lineSpacing` has to guess
  the face's natural line height and drifts by a point or more per line;
  `ParentLines` puts each line in a box its Figma line height tall.
* **A crossfade can't lean on a removal transition.** Swapping the page
  by `.id` (or a one-element `ForEach`) faded the new page in but dropped the
  old one in a single frame, so every change dipped to white. The model now
  keeps the page being left (`leaving`) mounted and opaque under the new one
  until the fade has covered it, then drops it unseen.
* **`object-cover` images crop.** An image taller than its box is scaled to
  fill and cut top and bottom — stretching it into the box squashes it.

`-scene Parent -parentPage rules` opens on a page (every page before it is on
the stack, so Back works); `-parentManual` and `-parentSheet` open on
frames 7 and 4; `-parentHold` keeps the intro up. `-parentWalk` pushes to the next page and back, for recording the page push. `-parentAutoContinue` focuses the first-name field, then presses Continue, to replay the celebration hand-off. `-sheetStretch 1` (with `-parentSheet`) holds the email sheet at full stretch. `-parentTickDemo` (on the address page) ticks and unticks addresses, for recording the checkbox. `-buttonPress 0.95` sets how far the buttons shrink while held and `-buttonBounce 0.7` how much that scale springs past its target (the controls sheet has the same sliders, with the spring's response; the Button screen shows the primary and the white variant together).

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
| `ShareScreen.swift` | Both QR screens: chrome, layout, scaling. |
| `ScreenSpec.swift` | The invite screen's geometry, colours and type scale, 1:1 from Figma `980:15528`. |
| `CardSpec.swift` | The two card designs — every position, blur, opacity, rotation, and each plane's elevation. |
| `MotionEngine.swift` | Normalises gyro / drag / demo into one smoothed tilt, driven by `CADisplayLink`. Holds `MotionOutput` separately — see below. |
| `GyroCardView.swift` | The card: planes, light, shadow, debug overlay. Shared by both designs. |
| `Tuning.swift` | Every tunable parameter. |
| `ControlsPanel.swift` | The panel. |
| `PocketShape.swift` | The wallet pocket, traced from Figma's vector — plus `PocketEdge`, its mouth on its own, for the glow to stroke. |
| `PocketGlow.swift` | The lit mouth: three layers over `PocketEdge`, ramping on the confirm pull. |
| `SkinPalette.swift` | Two or three colours read off a skin's own artwork, cached. Falls to one hue at three strengths for the metals and leathers. |
| `TopUpFlow.swift` | The round trip: wallet → request → wallet, and the hand-off between them. |
| `TopUpScreen.swift` | Request top up: the entry step and the three-beat confirmation. |
| `TopUpSpec.swift` | Its geometry and copy, 1:1 from Figma `935:62729`. |
| `AuroraBloom.swift` | The light cluster — five lobes, one blur, `plusLighter`. |
| `TopUpTuning.swift` | Its knobs, and which card skin the wallet is wearing. |
| `WalletScreen.swift` | The wallet page in its three states, the entrance, the balance count-up and the receipt card. |
| `WalletSpec.swift` | Its geometry, 1:1 from Figma `962:66753` / `935:61643` / `935:61752`. |
| `MoneyStyle.swift` | The dirham glyph, the tracking and the gradients every amount is set with. |
| `PressLift.swift` | The press-and-lift button style, and its two haptics. |
| `WalletInk.swift` | Whether the wallet's type goes white or dark, measured off the background. |
| `AccountScreen.swift` | The account page and its header load-in. |
| `AccountSpec.swift` | Its geometry, 1:1 from Figma `978:15007`. |
| `Onboarding/ShakeDetector.swift` | `motionEnded` bridged into SwiftUI, for shake-to-shuffle. |

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

**The controls sheet can overflow the device's stack, and the simulator will
not show it.** `ControlsPanel` once built every scene's sections inline in one
`body`. In a debug build Swift gives every branch of that closure its own
stack slots even though only one runs, and once the Button lab's controls
were added the closure outgrew the main thread's stack — 1MB on an iPhone,
8MB in the simulator, which is why every UI test passed while the phone
crashed (`EXC_BAD_ACCESS` in `___chkstk_darwin`, "stuck midway"). Each
scene's sections are now built inside `Deferred`, a view whose content is
made in its own `body`, which SwiftUI calls in a separate update: the
closure that crashed now reserves under 3.3KB, and the largest frame in the
sheet is 7.3KB. Adding a section: put it in a `Deferred`. `-controls` opens
the sheet at launch, for checking this on a device.


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

## Regenerating the asset sets

`Tools/make_categories.py` builds the twenty interest-category imagesets from
`Tools/category_src/`. `Tools/make_backgrounds.py` builds the twenty-two skin
backgrounds from `Tools/bg_src/` — PNG is the wrong container for photographic
textures at this size (the set is 106MB as PNG against 13.5MB as JPEG at q88,
and they are fully opaque), so those emit `.jpg`. Both are idempotent and
re-runnable from the project root.

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

## QR shine lab (experimental)

`-scene "QR shine lab"` opens the invite share screen (Figma 980:15528) with a holo card in place of the chrome frame. It isn't wired into any flow. The flows' invite screen is unchanged: `ShareScreen` takes an optional `inviteCard` / `inviteExtra` / `inviteUnder`, and only the lab passes them.

**The screen.** Backdrop, title, sparkles, OR row, link and Share invite are all the existing invite screen. The card is `CardSpec.inviteHolo`: the invite card's panel, QR and name on the holo base (`slab_base`), which also serves as its light mask. The white sticker halo that Figma's frame render carries is drawn under the card from the base's own silhouette (`HoloHalo`).

**The shines** are the designer's shines layer cut into its twelve stars (`slab_shine_01…12`). Each pixel is shared between cores by a soft partition, measured 2.5× shorter along a star's edge. Each sprite is then faded out on a cosine window: along the edge before it reaches its neighbour, 55–105px across it, and to nothing round every other star's core. The windows are what stop the glow showing a hard band once neighbours slide apart or sit on different bevels.

**Tracks.** Every star rides one of the rim's two bevel highlights, which were found as the brightness ridges across each side:

| Side | Outer | Inner |
|---|---|---|
| Left | x 62 | x 101 |
| Right | x 992 | x 953 |
| Top | y 65 | y 104 |
| Bottom | y 1403 | y 1358 |

Stars alternate outer and inner along each side. Top and bottom stars run along x with the left–right tilt; side stars run along y with the forward–back tilt.

**Staying on the edge.** Each core stops 24px short of its straight run's end: x 184–870 for top and bottom, y 190–1280 for the sides. Each side's light is also masked to the rim:

- **Along the edge**, it fades out past the corner.
- **Across the edge**, it may glow outward past the silhouette but stops at the panel's edge (112px, plus a 60px fade).

**The corner star** sits on the inner arc at 45° and glints when the card tips toward the top-left.

`-shineTracks` draws the eight tracks. `-motionSource Demo` sweeps the tilt, for recording.
