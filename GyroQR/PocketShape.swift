import SwiftUI

/// The white sheet the wallet card drops into, Figma `Rectangle 1891598503`
/// (node 793:28368). A rectangle whose top edge carries a centred notch — the
/// mouth of the wallet pocket.
///
/// Traced from the exported SVG path, which lives in a 385.342pt-wide box. The
/// control points below are that path with its (6, 12) shadow inset removed;
/// x is normalised by the design width so the shape can be drawn at any size.
struct PocketShape: Shape {
    /// Design width the control points were authored against.
    static let designWidth: CGFloat = 385.342
    /// Depth of the notch at the design width.
    static let notchDepth: CGFloat = 51

    func path(in rect: CGRect) -> Path {
        let k = rect.width / Self.designWidth          // uniform scale for x and notch depth
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * k, y: rect.minY + y * k)
        }
        var path = Path()
        path.move(to: p(0, 0))
        path.addLine(to: p(72.6917, 0))
        path.addCurve(to: p(77.2186, 0.1089),  control1: p(75.0167, 0),      control2: p(76.1792, 0))
        path.addCurve(to: p(93.7414, 12.6674), control1: p(84.6372, 0.8864), control2: p(91.0066, 5.7276))
        path.addCurve(to: p(95.058, 17),       control1: p(94.125, 13.6397), control2: p(94.436, 14.7598))
        path.addCurve(to: p(97.691, 25.6653),  control1: p(96.303, 21.4803), control2: p(96.925, 23.7205))
        path.addCurve(to: p(130.737, 50.7821), control1: p(103.161, 39.5448), control2: p(115.9, 49.2272))
        path.addCurve(to: p(139.791, 51),      control1: p(132.816, 51),     control2: p(135.141, 51))
        path.addLine(to: p(243.551, 51))
        path.addCurve(to: p(252.605, 50.7821), control1: p(248.201, 51),     control2: p(250.526, 51))
        path.addCurve(to: p(285.65, 25.6653),  control1: p(267.442, 49.2272), control2: p(280.181, 39.5448))
        path.addCurve(to: p(288.284, 17),      control1: p(286.417, 23.7205), control2: p(287.039, 21.4803))
        path.addCurve(to: p(289.6, 12.6674),   control1: p(288.906, 14.7598), control2: p(289.217, 13.6397))
        path.addCurve(to: p(306.123, 0.1089),  control1: p(292.335, 5.7276), control2: p(298.705, 0.8864))
        path.addCurve(to: p(310.65, 0),        control1: p(307.163, 0),      control2: p(308.325, 0))
        path.addLine(to: p(385.342, 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }

    /// How far below the sheet's top edge the notch floor sits, at a given width.
    static func notchDepth(forWidth w: CGFloat) -> CGFloat {
        notchDepth * (w / designWidth)
    }
}
