import SwiftUI

/// Geometry and copy for the request-top-up flow, Figma section
/// `Request top up` (935:62729) — laid out at the design's native 375 × 812
/// like every other screen here.
///
/// The screen is deliberately plain. The brief is the animation that runs
/// *after* the CTA, so the entry step carries only what the flow needs to reach
/// that tap: an amount, three quick picks, a note and the button.
enum TopUpSpec {
    static let size = CGSize(width: 375, height: 812)

    // MARK: chrome

    /// `M-IconButton` in the page header, 935:61328.
    static let backButton = CGRect(x: 12, y: 55, width: 40, height: 40)
    static let title = "Add an amount to request"
    /// The header is 56pt tall at y 45, so its label's box starts here.
    static let titleY: CGFloat = 63

    // MARK: amount
    //
    // 935:61358 — container at (16.5, 174), 343 × 106, holding a 48pt-tall
    // amount line and the quick-pick row 72pt below it.

    static let amountY: CGFloat = 174
    static let amountHeight: CGFloat = 48
    static let chipsY: CGFloat = 246
    static let chipHeight: CGFloat = 34
    static let quickAmounts = [50, 100, 150]

    /// The currency mark. See `MoneyStyle.dirham` — the font does carry the
    /// real glyph, in the private-use area.
    static let currency = MoneyStyle.dirham

    // MARK: note + CTA

    /// 935:61365 — `M-Input-alt`, empty state.
    static let noteBox = CGRect(x: 16, y: 352, width: 343, height: 76)
    static let noteLabel = "Add a note"
    /// The design's own filled state, 935:61604.
    static let noteSample = "Want to get the new RTX 5090"

    /// 935:61356 — `M-NeutralButton`.
    static let ctaBox = CGRect(x: 16, y: 444, width: 343, height: 56)
    static let cta = "Request top up"

    // MARK: keypad
    //
    // `M-Keyboard` at (0, 516), 375 × 296. The key grid is measured off the
    // frame rather than guessed: columns at x 7 / 130 / 252, rows at
    // y 539 / 591 / 643 / 695, each key 115.5 × 46. The last row is only the
    // zero — the backspace sits straight on the panel with no key behind it,
    // which is easy to miss and the thing that gives the row its shape.

    static let padTop: CGFloat = 516
    static let padHeight: CGFloat = 296
    static let keySize = CGSize(width: 115.5, height: 46)
    static let keyOrigin = CGPoint(x: 7, y: 539)
    static let keyGap = CGSize(width: 8, height: 6)
    static let keyRadius: CGFloat = 8
    /// Measured off the frame: #DFE2E6.
    static let padSurface = Color(hex: 0xDFE2E6)
    static let chipBorder = Color(hex: 0xEAECF0)

    // MARK: the confirmation
    //
    // Copy from the flow's own end state rather than the recording's. The
    // recording is the *add money* screen, so it says "Topping up wallet" /
    // "Wallet topped up"; this flow only asks someone else for the money, and
    // the wallet page it lands on writes the result as `Top up request sent`
    // (935:61868). Same two-beat structure, this flow's own words.

    static let pendingLabel = "Requesting top up"
    static let doneLabel = "Top up request sent"
    /// Where the status line sits. Measured off the recording at 51% of the
    /// screen's height — a touch above centre, not on it.
    static let statusY: CGFloat = 415

    // MARK: the amount, on the confirmation
    //
    // The number that was asked for, set above the status line in the flow's
    // biggest type. It is the one piece of the request that survives into the
    // landed state, so it gets the size: the line below it says what happened,
    // this says how much.

    /// Centre of the big amount. A 56pt line here spans roughly 314–382, which
    /// leaves a clear 22pt above the status line's box at 404 — close enough to
    /// read as one block, far enough not to crowd the check.
    static let revealY: CGFloat = 348
    static let revealDigits: CGFloat = 56
    /// The currency mark beside it, set smaller the way the entry line does.
    static let revealMark: CGFloat = 30
    /// How long after the request lands the amount starts resolving. Short —
    /// just enough that the check mark and the copy register first, so the
    /// number arrives into a settled line rather than with it.
    static let revealDelay: Double = 0.12
    /// Seconds the amount takes to leave, just before the wallet comes back.
    ///
    /// It goes early and on its own rather than riding the screen's crossfade.
    /// At 56pt it is by far the biggest thing on the confirmation, and fading
    /// it at the same rate as everything else laid a ghosted `200` over the
    /// wallet's own balance for the length of the transition. Lifting it out
    /// first also keeps the flow's one direction: everything here leaves
    /// through the top.
    static let revealExit: Double = 0.26
    /// How far it lifts on the way out.
    static let revealExitLift: CGFloat = 26

    // MARK: the bloom
    //
    // The light cluster is wider than the stage and hangs below it, so the
    // blur's bottom tail is clipped away by the screen edge instead of fading
    // out in view. That is what keeps the contact band at the bottom hot, the
    // way the reference has it.

    static let bloomSpan: CGFloat = 375 * 1.32
    static let bloomHeight: CGFloat = 396
    /// How far below the screen's bottom edge the cluster's own bottom parks.
    ///
    /// Shallow on purpose. At 96 the hottest part of the cluster — the band
    /// where the low lobe meets the others — was entirely off-screen and the
    /// bloom read as a soft wash with no contact edge at all.
    static let bloomSink: CGFloat = 40
}
