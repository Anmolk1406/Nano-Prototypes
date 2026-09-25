import SwiftUI

/// Knobs for the request-top-up scene, exposed in the controls sheet.
@MainActor
final class TopUpTuning: ObservableObject {

    /// `-topUpSkin 7` picks the wallet's card skin by asset number, and
    /// `-topUpPhase Sending` opens straight into that beat of the animation so
    /// a screenshot can land on it — the sequence is under three seconds long
    /// and captures are ~0.4s apart, so stepping through it any other way
    /// walks straight over the middle.
    init() {
        let a = ProcessInfo.processInfo.arguments
        if let i = a.firstIndex(of: "-topUpSkin"), i + 1 < a.count,
           let v = Int(a[i + 1]), (1...SkinSelectSpec.skinCount).contains(v) { skin = v }
        if let i = a.firstIndex(of: "-topUpDwell"), i + 1 < a.count,
           let v = Double(a[i + 1]) { dwell = v }
        if a.contains("-topUpStill") { drift = 0 }
    }

    /// Which skin the user's wallet card is wearing, as an asset number.
    ///
    /// One number, three things: the card on the wallet page, the page's own
    /// background, and the colours the bloom is built from. They were always
    /// meant to be the same card — the bloom's brief was "the colour of the
    /// user's card" — and now that the wallet actually shows it, they are.
    ///
    /// 17 is the design's own: the card and backdrop the wallet frame shipped
    /// with measure within 0.4/255 of `skin_17` and `bg_17`, so they were that
    /// skin all along. 12, the iridescent violet, gives the strongest bloom of
    /// the 22 — it is the one to pick when the bloom is what is being looked
    /// at.
    @Published var skin: Int = WalletSpec.defaultSkin

    // MARK: the animation

    /// Seconds for the page to blur away and the screen to go dark.
    @Published var fade: Double = 0.42
    /// Seconds for the bloom to climb in from below the edge.
    @Published var rise: Double = 0.68
    /// How long the bloom sits there before the request lands.
    @Published var dwell: Double = 1.9
    /// Seconds for the bloom to grow and fly out through the top.
    @Published var sweep: Double = 0.62
    /// How much the bloom grows on its way out. The reference fills the frame
    /// with the middle of the gradient before it leaves, which needs more than
    /// a lift on its own.
    @Published var sweepScale: Double = 2.7
    /// Multiplies the lift needed for the cluster to clear the top edge.
    ///
    /// The lift itself is derived from the cluster's own geometry — see
    /// `TopUpScreen.sweepLift` — so 1.0 is exactly enough to put every last
    /// visible part of it above the screen. This is here to push past that, or
    /// to pull it short and see what the clipped version looked like.
    @Published var sweepClear: Double = 1.05
    /// Seconds the requested amount takes to count up to itself and sharpen.
    @Published var count: Double = 0.78
    /// How blurred the amount starts, in points. It arrives out of the same
    /// soft light the bloom is made of and resolves as the number lands, so
    /// the confirmation has one visual idea rather than two.
    @Published var countBlur: Double = 16
    /// Seconds the landed state is held *after* the amount has finished. The
    /// hold is measured from whichever of the sweep and the count ends last —
    /// see `TopUpScreen.handOffDelay` — so slowing the count cannot cut it off.
    @Published var settle: Double = 0.55

    // MARK: the look

    /// Radius of the single blur the whole cluster goes under.
    @Published var bloomBlur: Double = 38
    /// How tall the cluster is, in stage points.
    @Published var bloomHeight: Double = TopUpSpec.bloomHeight
    /// Speed of the lobes' drift. 0 freezes it, for stills.
    @Published var drift: Double = 1.0
    /// How far the page is blurred once it has retreated.
    @Published var pageBlur: Double = 24
    /// How black the veil over the page goes.
    ///
    /// Not 1. The page is light and the reference's ghost is the *bright* parts
    /// of the UI showing through — at full opacity the keypad and the amount
    /// vanish outright and the bloom rises out of nothing. The window is narrow
    /// though: at 0.955 the note field and the CTA read as a grey-brown haze
    /// across the middle of the screen, because the bloom's own light lands on
    /// them additively. 0.972 keeps the ghost and loses the haze.
    @Published var veil: Double = 0.972

    /// Bumped by the controls sheet's Replay, which the screen watches.
    @Published var replay = 0

    var skinName: String { String(format: "skin_%02d", skin) }
    var bloomColors: [Color] { SkinPalette.colors(for: skinName) }

    func reset() {
        fade = 0.42; rise = 0.68; dwell = 1.9; sweep = 0.62
        sweepScale = 2.7; sweepClear = 1.05; settle = 0.55
        count = 0.78; countBlur = 16
        bloomBlur = 38; bloomHeight = TopUpSpec.bloomHeight; drift = 1.0
        pageBlur = 24; veil = 0.972
    }
}
