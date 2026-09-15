import SwiftUI

/// Geometry for the wallet-skin picker, Figma `Card Skin Select` (794:30694),
/// laid out at the design's native 375 × 812.
enum SkinSelectSpec {
    static let size = CGSize(width: 375, height: 812)
    static let skinCount = 22

    // Header — identical across every state of the flow.
    static let stepDots  = CGRect(x: 131.599, y: 76, width: 112, height: 16)
    static let titleBox  = CGRect(x: 78.599, y: 112, width: 217, height: 80)
    static let subtitle  = CGRect(x: 78.599, y: 200, width: 217, height: 22)
    static let hintY: CGFloat = 579

    /// The front card of the stack at rest (Figma 794:29722, 248.7 × 163.2).
    static let cardWidth: CGFloat = 248.7
    static let cardCenterY: CGFloat = 444
    /// The hero card once it has settled in the pocket (794:29993, 315.66 wide
    /// at y 330.68 — so its centre lands at 434).
    static let settledCardWidth: CGFloat = 315.66
    static let settledCardCenterY: CGFloat = 434

    // The pocket sheet. `restTop` keeps it just off the bottom; `settledTop`
    // is Figma 794:29872 (y = 242).
    static let sheetWidth: CGFloat = 385.342
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
    /// Upward drag that sends the front card to the back of the stack.
    static let cycleThreshold: CGFloat = 215
    /// Fraction of a span that commits on release. Below it the card falls back.
    static let commitFraction: CGFloat = 0.78
    /// How far the ejected card rides up. Independent of the span — the finger
    /// travels further now, the card does not.
    static let ejectLift: CGFloat = 156

    enum Palette {
        static let ink        = Color(red: 0x10/255, green: 0x16/255, blue: 0x28/255)
        static let onTexture  = Color.white
        static let btnIdle    = Color(white: 0.82)
        static let btnArmed   = Color(white: 0.55)
    }

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
