import SwiftUI

/// Geometry for the wallet-skin picker, Figma `Card Skin Select` (794:30694),
/// laid out at the design's native 375 × 812.
enum SkinSelectSpec {
    static let size = CGSize(width: 375, height: 812)
    static let skinCount = 22

    /// Browse order, as asset numbers — the deck is not `skin_01…22`.
    ///
    /// Asset order opened on two black cards: skin_01 and skin_02 measure
    /// saturation 0.007 and 0.027 at brightness 0.187 and 0.110, so the first
    /// two slots of the stack were both near-black leather and the picker's
    /// opening frame said nothing about what was in it.
    ///
    /// Built from a measured pass over all 22 — mean saturation and
    /// brightness-weighted mean hue — under two rules. The first four are
    /// strongly coloured and far apart in hue (cyan lego, red, iridescent
    /// violet, yellow plush), since those are the only ones the resting stack
    /// shows at `visibleDepth` 3. And the six near-neutrals — 01, 02, 03, 09,
    /// 14, 17 — are spaced three apart at positions 6, 9, 12, 15, 18 and 21, so
    /// no two of them are ever adjacent, including across the wrap from 22 back
    /// to 1. Every adjacent pair is a clear hue change rather than two
    /// neighbouring oranges.
    static let displayOrder = [11, 4, 12, 10, 20, 1, 6, 18, 3, 15, 5, 14,
                               16, 7, 9, 22, 13, 17, 8, 19, 2, 21]

    /// Asset number for a deck position.
    static func asset(at slot: Int) -> Int {
        displayOrder[((slot % skinCount) + skinCount) % skinCount]
    }

    // Header — identical across every state of the flow.
    static let stepDots  = CGRect(x: 131.599, y: 76, width: 112, height: 16)
    static let titleBox  = CGRect(x: 78.599, y: 112, width: 217, height: 80)
    static let subtitle  = CGRect(x: 78.599, y: 200, width: 217, height: 22)
    static let hintY: CGFloat = 579

    /// The front card of the stack at rest. Figma draws it 248.7 × 163.2; this
    /// is that card at 1.17×, which is what "make the stack bigger" came to.
    /// The settled hero below is left at the design's own width, so confirming
    /// is now a smaller step up than it was.
    static let cardWidth: CGFloat = 290
    static let cardCenterY: CGFloat = 444
    /// The hero card once it has settled in the pocket (794:29993, 315.66 wide
    /// at y 330.68 — so its centre lands at 434).
    static let settledCardWidth: CGFloat = 315.66
    static let settledCardCenterY: CGFloat = 434
    /// Figma's nominal card aspect, 248.7 × 163.2. It is the right number for
    /// the *layout* and the wrong one for any individual card — see `SkinArt`,
    /// which reads each render's real shape. Used here only to fix where the
    /// drop outline's centre sits, so that one number stays put while the
    /// outline's height follows the skin.
    static let cardAspect: CGFloat = 248.7 / 163.2

    // The pocket sheet. `restTop` keeps it just off the bottom; `settledTop`
    // is Figma 794:29872 (y = 242).
    /// 377, the pocket shape's own width (1027:18114) — near enough the 375
    /// stage that the sheet barely overhangs it.
    static let sheetWidth: CGFloat = 377
    static let restTop: CGFloat = 830
    static let settledTop: CGFloat = 242
    /// How far the sheet's top edge travels while the user is still dragging.
    static let dragTop: CGFloat = 470

    static let confirmTitle  = CGRect(x: 51.474, y: 581.166, width: 271.25, height: 50)
    static let confirmSub    = CGRect(x: 51.474, y: 641.166, width: 271.25, height: 28)
    static let continueBtn   = CGRect(x: 16, y: 732, width: 343, height: 56)

    // Gesture travel. Both spans are deliberately long: the pull is where the
    // haptic ramp and the pocket rise are actually read, and the throw is where
    // the stack hand-off is read. A short span skips past both before the hand
    // has finished moving. `SkinTuning.dragTravel` scales them live.
    /// Drag distance, in points, that completes the confirm gesture.
    static let confirmThreshold: CGFloat = 330
    /// Upward drag that sends the front card to the back of the stack. Shorter
    /// than the confirm span on purpose: cycling is the gesture you repeat a
    /// dozen times looking for a skin, so it is the one that wants to be quick.
    /// The confirm pull stays long — it is the one that commits.
    static let cycleThreshold: CGFloat = 150
    /// Fraction of a span that commits on release. Below it the card falls back.
    static let commitFraction: CGFloat = 0.78
    /// Upward drag on the settled card that takes it back out of the pocket.
    /// Short, like the throw: going back is an undo, not a decision.
    static let liftThreshold: CGFloat = 140
    /// Fraction of the lift that commits on release.
    static let liftCommit: CGFloat = 0.55
    /// How far the sheet sinks over a full lift, so the card reads as being
    /// drawn up out of it rather than slid over it.
    static let liftSheetSink: CGFloat = 90
    /// The back button, left of the step dots and on their centre line.
    static let backButton = CGRect(x: 16, y: 64, width: 40, height: 40)

    // Exit for the cards left behind when one is pulled into the pocket.
    //
    // A plain opacity fade was what was here, and three overlapping cards
    // dissolving in place reads as a rendering fault rather than a departure.
    // This mirrors the deal-in's vocabulary — offset, scale, fade — pointed
    // outward instead of inward: the stack lifts away upward, nearest card
    // first, so it looks like the deck being taken off the one you chose.
    /// How far the departing cards travel up.
    ///
    /// 320 was the first answer — off the top edge, on the reasoning that the
    /// settled sheet covers everything from 242 down so a short lift only
    /// parks the deck on the white page. It does leave, and on the way it
    /// crosses the whole upper half of the screen and sweeps over the title.
    /// 112 keeps the topmost card's edge below the subtitle at 222, and the
    /// fade below is what stops it being parked rather than the distance.
    static let exitLift: CGFloat = 112
    /// Seconds for a departing card to fade, against `exitResponse` for its
    /// travel. Half the movement's duration, so each card is gone before it
    /// has covered much ground — the distance was what made the exit
    /// obtrusive, and shortening the travel alone would only have made the
    /// deck hang closer in.
    /// 0.12 against `exitResponse` 0.28, both brought down from 0.17/0.34.
    ///
    /// The deck was still clearing while the chosen card was rising into its
    /// place — the hero's bounce starts 0.12s after the commit and runs half a
    /// second, and the old figures had the last card leaving at 0.15 + 0.17 =
    /// 0.32s. At 0.028 stagger and a 0.12 fade the last one is gone by 0.20s,
    /// so the deck is out of the way before the card it uncovered arrives.
    static let exitFade: Double = 0.12
    /// Spring response for one card's exit, in seconds.
    ///
    /// The exit runs on its own clock rather than on the drag. Mapped to the
    /// pull it fired while the finger was still moving, which put the deck's
    /// departure in the middle of the gesture that chooses a card — two things
    /// competing for the same moment, and it dragged and re-dragged if the pull
    /// was released short. It now starts once the selection has actually
    /// happened.
    static let exitResponse: Double = 0.28
    /// Seconds between one card leaving and the next. Back-to-front, so a card
    /// only moves once the ones it was covering have gone.
    static let exitStagger: Double = 0.028
    /// How much the departing cards shrink on the way out.
    static let exitShrink: CGFloat = 0.13
    /// How far the ejected card rides up.
    ///
    /// This has to clear the stack, not merely leave the front slot. The card
    /// drops to the back of the z-order the moment it is released, so if its
    /// bottom edge is still overlapping the cards behind it at that instant,
    /// the hand-off is visible as a flicker — the thing the old 156 did.
    ///
    /// The card is 190.3pt tall and rests at 348.9…539.2. The card behind it
    /// tops out at 338, so the throw has to lift at least 201pt; 250 clears it
    /// with room and reads as the card genuinely going over the pile.
    static let ejectLift: CGFloat = 250

    // The sideways throw, for `SkinTuning.CycleAxis.side`.
    //
    // Same state machine as the upward throw — the card rides the finger, then
    // arcs back and beds into the parked slot — turned ninety degrees. The
    // card is 290 wide and centred at 187.5, so 300 carries its near edge past
    // the screen entirely; the rise and the tilt are there because a purely
    // horizontal slide reads as a filmstrip rather than as a card being taken
    // off the top of a pile.
    static let ejectShift: CGFloat = 300
    static let sideRise: CGFloat = 46
    static let sideTilt: Double = 13

    enum Palette {
        static let ink        = Color(red: 0x10/255, green: 0x16/255, blue: 0x28/255)
        static let onTexture  = Color.white
        /// The drop target's green, from the designer's `Rectangle 1891598615`.
        static let dropInk    = Color(red: 0x00/255, green: 0x6B/255, blue: 0x3B/255)
    }

    // The drop target on the sheet — now the grid tray, Figma `Grid`
    // (1118:44289), drawn by `SkinDropGrid`.
    //
    // Positioned relative to the *sheet*, not the screen, so it rides up with
    // the pocket as you drag and needs no animation of its own.
    //
    // The size is off the designer's screenshot, and it is worth saying why it
    // is not simply the settled card's footprint, which was the first guess.
    // The sheet only rises to `dragTop` (470) while the finger is down, and
    // Continue sits at 732. A 207pt-tall outline offset 88 below the mouth —
    // where the card genuinely lands once settled — ends up at 558…765 during
    // the drag and runs straight through the button. 104 + 141 = 245 clears it
    // by 17pt, which is presumably how the designer arrived at the same
    // numbers. The outline is a "the card goes in here" marker during the pull,
    // not a footprint: it fades out on commit, before the card arrives.
    /// The outline is the dragged card's footprint: the design's 235 width,
    /// and a height read off **that skin's** artwork.
    ///
    /// The design draws it 235 × 141, and the two cannot both be satisfied at
    /// those numbers — 141 makes the outline 1.667 : 1 against a card nearer
    /// 1.52 — so fitting the card inside the outline was the first answer and
    /// it left 12pt of empty outline either side. Taking the height from the
    /// nominal 1.524 was the second, and it is still wrong for every skin but
    /// the handful near the middle: the renders run 1.444 to 1.637, which is
    /// 8.6pt of gap on skin_01 and 10.6pt of overhang on skin_12.
    static let dropTargetWidth: CGFloat = 235
    static func dropTargetSize(for skin: String) -> CGSize {
        CGSize(width: dropTargetWidth,
               height: SkinArt.height(skin, at: dropTargetWidth))
    }
    static let dropTargetRadius: CGFloat = 22
    /// Screen y of the outline's top edge — **fixed**, not tracked to the
    /// sheet.
    ///
    /// Riding the sheet was the obvious reading and it does not work. The sheet
    /// rises on an ease-out, so a constant offset below the mouth puts the
    /// outline at 664 at mid-pull and 582 at the end: it starts inside the
    /// Continue button and climbs out of it, which looks like a layout bug for
    /// the first half of every gesture. Pinning it instead means it cannot
    /// collide, and the sheet reveals it by rising past it — the outline reads
    /// as printed on the pocket rather than floating over it.
    ///
    /// 560 is bounded on both sides: the notch floor at the deepest drag sits
    /// at 470 + 51 = 521, so anything above that is still being cut by the
    /// mouth when the gesture ends, and Continue starts at 732, so with a 141pt
    /// outline anything below 575 runs into the button.
    static let dropTargetTop: CGFloat = 560
    // The sheet's shadow into its own mouth. Strong on purpose — it is what
    // puts the card behind the shape now that a copy of it is drawn in front.
    /// Solid area carried above the mouth for the blur to spread from.
    static let mouthShadowHead: CGFloat = 70
    static let mouthShadowBlur: CGFloat = 16
    /// How far the cast is nudged down past the edge.
    static let mouthShadowDrop: CGFloat = 9
    /// 0.62, up from 0.42. At the lower figure it measured a real cast — 216
    /// against 255 on the white sheet, falling off over 25pt — and still read
    /// as nothing on the card, which is the surface it exists for: 15% of
    /// darkening on a bright plush card is not depth.
    static let mouthShadowOpacity: Double = 0.62
    /// Fraction of the contact ramp the glow and the shadow fade in over.
    ///
    /// Everything after this is full strength. Fading across the whole pull
    /// read as the pocket warming up on its own; appearing at full in one
    /// frame read as a switch. A quarter of the engagement is ~25pt of card
    /// travel — quick, but not instant.
    static let mouthFadeIn: Double = 0.25


    /// Scale that seats the card in the outline. The two are the same
    /// footprint, so this is just the ratio of the widths — and because only
    /// the height varies by skin, both this and `dropTravel` stay constant.
    ///
    /// For comparison, the old fixed 0.58 scale and 210pt drop landed the card
    /// at 168 × 110 centred on 654 — two thirds the width of the box it was
    /// aiming at and 8pt below its bottom edge.
    static var dropFitScale: CGFloat { dropTargetWidth / cardWidth }
    /// Screen y of the outline's centre — where the card comes to rest.
    ///
    /// The **centre** is the anchor, not the top edge, so that a taller or
    /// shorter skin grows the outline about a fixed point instead of walking
    /// its bottom edge toward Continue. Derived once from the design's own
    /// 560 top and the nominal aspect. The tallest skin's outline then runs
    /// 555.7…718.5: 13.5pt clear of Continue at 732, and 17.3pt below the
    /// notch floor at the deepest drag, so it is never cut by the mouth.
    static let dropCenterY: CGFloat = dropTargetTop + (dropTargetWidth / cardAspect) / 2
    /// How far the card travels down to seat in the outline.
    static var dropTravel: CGFloat { dropCenterY - cardCenterY }

    // The cycle transition's timing. Both of these exist because mapping the
    // transition to the gesture meant a fast flick finished it inside the
    // swipe — the arc and the stack hand-off were simply never seen. The
    // commit now plays over a fixed duration no matter how the card was thrown.
    /// Seconds for the stack hand-off and background transition on commit.
    static let cycleDuration: Double = 0.55
    /// How much of that transition the drag itself scrubs before release. Small
    /// on purpose: enough that the background is visibly *about* to change
    /// while the finger is down, not enough for a flick to consume it.
    static let cyclePreview: Double = 0.12

    /// Transform for a card sitting `slot` places back in the stack.
    /// Slot 0 is the front card; anything past `visibleDepth` is parked out of
    /// sight, which is where the swiped card animates to.
    static let visibleDepth = 3
    static func stack(slot: Int) -> (scale: CGFloat, dy: CGFloat, angle: Double, opacity: Double) {
        stack(slotF: Double(slot))
    }

    /// Same, for a fractional slot. The cycle animates every card forward by a
    /// continuous amount rather than snapping between integer slots, which is
    /// what keeps the hand-off unbroken.
    static func stack(slotF: Double) -> (scale: CGFloat, dy: CGFloat, angle: Double, opacity: Double) {
        let s = max(0, min(slotF, Double(visibleDepth) + 1))
        let scale = 1 - 0.065 * s
        // Rise stops at the last visible slot. Cards parked deeper keep
        // shrinking but hold that height, so each one sits entirely inside the
        // card in front and is hidden by it — no fade required, which is what
        // lets a thrown card genuinely settle at the back.
        let dy    = -17 * min(s, Double(visibleDepth))
        let angles = [0.0, -3.2, 2.6, -1.8, -1.8]
        let i = Int(s), f = s - Double(i)
        let angle = angles[min(i, 4)] * (1 - f) + angles[min(i + 1, 4)] * f
        return (scale, CGFloat(dy), angle, 1.0)
    }
}
