import SwiftUI

/// The white sheet the wallet card drops into, Figma `Subtract` (915:61054) in
/// `Frame 2147241934` (915:61051). A rectangle whose top edge carries a centred
/// notch — the mouth of the wallet pocket.
///
/// Traced from the exported SVG path, which lives in a 376pt-wide box. Two
/// things about it that the previous shape did not have, and that the rest of
/// the screen has to account for:
///
///  * The top edge is **not flat**. It sits at y 11 at the far left and right
///    and rises to 2.74 at the notch's outer shoulders, so the sheet has a
///    gentle crown rather than a straight lip.
///  * Everything here is therefore measured from the **crest** — the path's
///    topmost point — which is what `SkinSelectSpec.restTop` and friends now
///    refer to. The authored path is shifted up by its own 2.741 so the crest
///    is y 0 and nothing is drawn above the frame.
struct PocketShape: Shape {
    /// Design width the control points were authored against.
    static let designWidth: CGFloat = 376
    /// Depth of the notch floor below the crest, at the design width.
    static let notchDepth: CGFloat = 42.259
    /// How far the far left and right of the top edge sit below the crest.
    static let rimDrop: CGFloat = 8.259

    func path(in rect: CGRect) -> Path {
        var path = Self.edgePath(in: rect)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }

    /// Just the mouth — the top edge with its notch, left open.
    ///
    /// Split out so the glow can stroke exactly the line the sheet's fill ends
    /// on. Stroking the closed shape instead would also light the sides and the
    /// bottom, which sit off screen, and spend the blur on geometry nobody
    /// sees.
    static func edgePath(in rect: CGRect) -> Path {
        let k = rect.width / Self.designWidth      // uniform scale for x and y
        /// The authored path's own top inset, removed so the crest is y 0.
        let lift: CGFloat = 2.74118
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * k, y: rect.minY + (y - lift) * k)
        }
        var path = Path()
        path.move(to: p(0, 11.0002))
        path.addLine(to: p(67.5736, 2.74118))
        path.addCurve(to: p(95.9583, 21.5226),
                      control1: p(79.4929, 1.28438), control2: p(89.8977, 11.1562))
        path.addCurve(to: p(136, 45.0002),
                      control1: p(104.051, 35.364), control2: p(119.42, 45.0002))
        path.addLine(to: p(240, 45.0002))
        path.addCurve(to: p(280.042, 21.5226),
                      control1: p(256.58, 45.0002), control2: p(271.949, 35.364))
        path.addCurve(to: p(308.426, 2.74118),
                      control1: p(286.102, 11.1562), control2: p(296.507, 1.28438))
        path.addLine(to: p(376, 11.0002))
        return path
    }

    /// How far below the crest the notch floor sits, at a given width.
    static func notchDepth(forWidth w: CGFloat) -> CGFloat {
        notchDepth * (w / designWidth)
    }

    /// x-extent of the notch at the design width — the stretch of edge that
    /// dips, and so the only part of the mouth a card can pass through. Read
    /// off the path above: the crown leaves the top edge at 67.57 and rejoins
    /// it at 308.43.
    static let notchSpan: ClosedRange<CGFloat> = 67.5736...308.426

    static func notchRange(forWidth w: CGFloat) -> ClosedRange<CGFloat> {
        let k = w / designWidth
        return (notchSpan.lowerBound * k)...(notchSpan.upperBound * k)
    }

    /// The four x values where the mouth's profile changes, at the design
    /// width: the crown leaves the top edge at 67.57, reaches the notch floor
    /// at 136, leaves the floor at 240 and rejoins the top edge at 308.43.
    ///
    /// The path itself is four cubics; these are the joints between them, and
    /// they are what lets the profile be evaluated without the path — which a
    /// shader has to do, since it only ever sees one pixel at a time.
    static let notchShoulders: (CGFloat, CGFloat, CGFloat, CGFloat) =
        (67.5736, 136, 240, 308.426)

    /// `notchShoulders` at a given width.
    static func notchShoulders(forWidth w: CGFloat) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
        let k = w / designWidth
        let s = notchShoulders
        return (s.0 * k, s.1 * k, s.2 * k, s.3 * k)
    }
}

/// The pocket mouth on its own, for the confirm glow.
struct PocketEdge: Shape {
    func path(in rect: CGRect) -> Path { PocketShape.edgePath(in: rect) }
}

/// Everything *above* the pocket's mouth.
///
/// Two jobs: it is the source the sheet's cast shadow is blurred from, and it
/// is the region that shadow is clipped to — the cast belongs on the card
/// outside the pocket, not on the sheet inside it.
///
/// `headroom` is how much solid area to carry above the edge. A blur needs
/// something to spread from, and the mouth is the top of its own frame — with
/// nothing above it the blur would fade the shadow out from the very line it
/// is supposed to be cast by.
struct PocketCap: Shape {
    var headroom: CGFloat = 70

    func path(in rect: CGRect) -> Path {
        let inner = CGRect(x: rect.minX, y: rect.minY + headroom,
                           width: rect.width, height: max(1, rect.height - headroom))
        var path = PocketShape.edgePath(in: inner)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

/// The stretch of the mouth a card is crossing, as a horizontal mask.
///
/// Shared by the glow and by the sheet's cast shadow, which have to agree:
/// both are effects *of* the card being there, and lighting or shading the
/// whole perimeter for a 235pt card gives the pocket a reaction along edges the
/// card is nowhere near.
///
/// The card's own width, clipped to the notch. That covers both ends of the
/// gesture without a special case: early on the card is wider than the mouth
/// and the notch bounds it, and as the card shrinks into the pocket the window
/// closes in around it.
enum MouthWindow {
    /// Soft fall-off at each end.
    static let feather: CGFloat = 40

    static func gradient(width: CGFloat, span: CGFloat) -> LinearGradient {
        let notch = PocketShape.notchRange(forWidth: width)
        let centre = (notch.lowerBound + notch.upperBound) / 2
        let half = min((notch.upperBound - notch.lowerBound) / 2, max(24, span) / 2)
        let w = max(width, 1)

        // Gradient stops have to be monotonic, and clamping to the frame can
        // tie two of them together at either end.
        var stops: [Gradient.Stop] = []
        var last: CGFloat = -1
        let marks: [(CGFloat, Double)] = [(centre - half - feather, 0),
                                          (centre - half,           1),
                                          (centre + half,           1),
                                          (centre + half + feather, 0)]
        for (x, alpha) in marks {
            let at = max(min(1, max(0, x / w)), last + 0.0001)
            stops.append(.init(color: .white.opacity(alpha), location: min(1, at)))
            last = at
        }
        return LinearGradient(stops: stops, startPoint: .leading, endPoint: .trailing)
    }

    /// How much of the mouth the card has actually reached, as a vertical mask.
    ///
    /// The horizontal window says *which stretch* of the mouth belongs to the
    /// card; this says *how much of it has been touched yet*. Keeps the part of
    /// the profile at or above the card's leading edge and cuts the rest, so
    /// the light appears where the two first meet — the outer crown, where the
    /// sheet's edge is highest — and spreads inward along the shoulders to the
    /// floor as the card descends. Without it the whole mouth lights at once
    /// the instant contact begins anywhere.
    ///
    /// `edge` is the card's bottom edge in the mask's own coordinate space.
    static func reached(height: CGFloat, edge: CGFloat, feather: CGFloat = 12) -> LinearGradient {
        let h = max(height, 1)
        var stops: [Gradient.Stop] = []
        var last: CGFloat = -1
        let marks: [(CGFloat, Double)] = [(0, 1), (edge - feather, 1), (edge, 0), (h, 0)]
        for (y, alpha) in marks {
            let at = max(min(1, max(0, y / h)), last + 0.0001)
            stops.append(.init(color: .white.opacity(alpha), location: min(1, at)))
            last = at
        }
        return LinearGradient(stops: stops, startPoint: .top, endPoint: .bottom)
    }
}
