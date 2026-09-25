import SwiftUI

/// How money is set, everywhere in the flow.
///
/// Three screens show an amount — the wallet's balance, the request screen's
/// entry line, and the confirmation — and the design gives all three the same
/// treatment. Keeping that in one place is the only way it stays the same
/// after the next change to any one of them.
enum MoneyStyle {

    /// The dirham mark.
    ///
    /// `U+E001`, a private-use codepoint that Noontree ships the real glyph in
    /// — the new UAE dirham symbol, a D with two horizontal strokes. This used
    /// to be `U+0110` (Đ, Latin capital D with stroke), picked because the
    /// font has no dirham at any of the obvious codepoints: the currency block
    /// has none, and neither do the Arabic forms. It was the wrong glyph and
    /// it looked it — one stroke instead of two, and the wrong proportions.
    ///
    /// The font does carry it. `Noontree-*.otf` maps exactly two private-use
    /// codepoints, `U+E000` and `U+E001`; dumping both glyphs' outlines shows
    /// `E000` is the Arabic د.إ ligature and `E001` is the Latin mark the
    /// design uses. So there is no icon to export and none should be: a real
    /// glyph takes the weight, the size, the tracking and the gradient that
    /// the digits beside it take, and stays sharp at any scale.
    static let dirham = "\u{E001}"

    /// `font/heading/h40/letter-spacing`. Every amount in the design carries
    /// it, including the mark.
    static let tracking: CGFloat = -0.25

    /// The vertical gradient the design fills its amounts with — a `bg-clip-text`
    /// ramp from the bold text colour to the subtle one, stopping at 21.25%
    /// and 77.5% rather than at the ends. Those stops matter more than they
    /// look: they keep the top quarter of the digits at full strength, so the
    /// number reads as lit from above rather than as faded.
    static func fill(_ top: Color, _ bottom: Color) -> LinearGradient {
        LinearGradient(stops: [.init(color: top, location: 0.2125),
                               .init(color: bottom, location: 0.775)],
                       startPoint: .top, endPoint: .bottom)
    }

    /// On the card's own surface — `on-surface-bold` to `on-surface-subtle`.
    static let onSurface = fill(.white, .white.opacity(0.8))
    /// On a white page — `text/primary` to `text/secondary`.
    static let onPage = fill(Color(hex: 0x1D2539), Color(hex: 0x475067))
}

/// An amount, set the way the design sets one: the mark and the digits in a
/// single run with one gradient across both.
///
/// The gradient goes on the row rather than on each `Text`. A `ShapeStyle`
/// handed to `foregroundStyle` resolves over the view it is applied to, so
/// putting it on the two texts separately gives the 24pt mark its own 24pt-tall
/// ramp instead of the top slice of the 40pt one — visible as a mark that is
/// paler at its baseline than the digits beside it.
struct MoneyText: View {
    var amount: String
    var markSize: CGFloat
    var digitSize: CGFloat
    var weight: NoonFont.Weight = .extrabold
    var style: LinearGradient = MoneyStyle.onSurface
    /// Extra room between the mark and the first digit. The design sets them
    /// as one run with a space; a space in Noontree at 40pt is wider than the
    /// render shows, so the gap is explicit.
    var gap: CGFloat = 7

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: gap) {
            Text(MoneyStyle.dirham)
                .font(NoonFont.f(weight, markSize))
            Text(amount)
                .font(NoonFont.f(weight, digitSize))
                .monospacedDigit()
        }
        .tracking(MoneyStyle.tracking)
        .foregroundStyle(style)
    }
}
