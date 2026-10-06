import SwiftUI

/// The button's second variant — Figma `2nd variant` (1105:19282): one
/// `M-StackedActionBar` at rest (1105:19232) and one pressed (1105:19256),
/// drawn in the lab on the same white card as the first. The pressed
/// state is the designer's own, so both faces are drawn verbatim:
///
/// | | Rest | Pressed |
/// |---|---|---|
/// | dark fill | #212121 | radial #424242 → #212121, centred near the top |
/// | dark stroke | #EFEFEF → #D2D2D2 | #D2D2D2 → #8A8A8A |
/// | dark shadows | inner #D2D2D2 50% y4 b8, inner #000 100% y-9 b9 | inner #000 50% b10 spread 4, drop #000 15% y4 b5 |
/// | white fill / stroke | #FFFFFF / #FFFFFF → #DBDFE6 | the same |
/// | white shadows | inner #989FB3 22% y-6 b6, inner #989FB3 10% y4 b4 | inner #989FB3 22% b8 spread 4, drop #DBDFE6 15% y4 b5 |
///
/// The pressed inner shadows have a spread, which SwiftUI's `.inner` shadow
/// style cannot express, so every shadow here is drawn as its own layer the
/// way Figma composites it. Figma blurs are CSS blurs, halved for SwiftUI.
struct GlassSurface: View {
    var pressed: Bool
    var duration: Double = 0.02
    var tune = GlassTune.dark

    var body: some View {
        GeometryReader { geo in
            let W = geo.size.width, H = geo.size.height
            ZStack {
                face(tune.rest, W: W, H: H)
                // Crossfaded: each layer is the finished face, so the blend
                // between them is exact.
                face(tune.pressed, W: W, H: H)
                    .opacity(pressed ? 1 : 0)
            }
            .frame(width: W, height: H)
        }
        .animation(.easeInOut(duration: duration), value: pressed)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: tune.corner, style: .continuous)
    }

    private func face(_ f: GlassTune.Face, W: CGFloat, H: CGFloat) -> some View {
        ZStack {
            ForEach(f.drop.indices, id: \.self) { i in
                let s = f.drop[i]
                shape.inset(by: -s.spread)
                    .fill(s.color.color)
                    .frame(width: W, height: H)
                    .offset(x: s.x, y: s.y)
                    .blur(radius: s.blur / 2)
            }
            ZStack {
                fill(f.fill, W: W, H: H)
                ForEach(f.inner.indices, id: \.self) { i in
                    innerShadow(f.inner[i], W: W, H: H)
                }
            }
            .frame(width: W, height: H)
            // The fill stops halfway under the stroke, so its antialiased
            // rim cannot show as a dark hairline outside the stroke.
            .clipShape(shape.inset(by: tune.strokeWidth / 2))
            shape.strokeBorder(LinearGradient(colors: [f.strokeTop.color, f.strokeBottom.color],
                                              startPoint: f.strokeStart, endPoint: f.strokeEnd),
                               lineWidth: tune.strokeWidth)
                .frame(width: W, height: H)
        }
    }

    @ViewBuilder
    private func fill(_ fill: GlassTune.Fill, W: CGFloat, H: CGFloat) -> some View {
        switch fill {
        case .solid(let c):
            c.color
        case .radial(let inner, let outer, let center, let rx, let ry):
            // An ellipse of the design's own radii, which need not be in the
            // button's proportions — so the gradient is drawn in a frame of
            // the ellipse's size, placed at its centre.
            ZStack {
                outer.color
                EllipticalGradient(colors: [inner.color, outer.color], center: .center,
                                   startRadiusFraction: 0, endRadiusFraction: 0.5)
                    .frame(width: 2 * rx * W, height: 2 * ry * H)
                    .position(x: center.x * W, y: center.y * H)
            }
        }
    }

    /// Figma's inner shadow: everything outside the shape — moved by the
    /// offset and grown inward by the spread — in the shadow's colour,
    /// blurred, and kept inside the shape.
    private func innerShadow(_ s: GlassTune.Shadow, W: CGFloat, H: CGFloat) -> some View {
        let pad = s.blur + abs(s.x) + abs(s.y) + s.spread + 4
        return Rectangle()
            .fill(s.color.color)
            .frame(width: W + 2 * pad, height: H + 2 * pad)
            .overlay {
                shape.inset(by: s.spread)
                    .frame(width: W, height: H)
                    .offset(x: s.x, y: s.y)
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
            .blur(radius: s.blur / 2)
            .frame(width: W, height: H)
            .mask(shape.frame(width: W, height: H))
    }
}

/// The second variant's numbers, read from the nodes through the plugin API.
struct GlassTune: Equatable {
    var corner: CGFloat = 16
    var strokeWidth: CGFloat = 2
    var rest: Face
    var pressed: Face

    struct Shadow: Equatable {
        var color: RGBA
        var x: CGFloat = 0
        var y: CGFloat = 0
        /// Figma's, a CSS blur.
        var blur: CGFloat
        var spread: CGFloat = 0
    }

    enum Fill: Equatable {
        case solid(RGBA)
        /// `center` in unit space; `rx`, `ry` are the ellipse's radii as
        /// fractions of the button's width and height.
        case radial(inner: RGBA, outer: RGBA, center: UnitPoint, rx: CGFloat, ry: CGFloat)
    }

    struct Face: Equatable {
        var fill: Fill
        var strokeTop: RGBA
        var strokeBottom: RGBA
        /// Where the stroke gradient starts and ends — Figma's run a little
        /// past the button's top or bottom edge.
        var strokeStart = UnitPoint.top
        var strokeEnd = UnitPoint.bottom
        var inner: [Shadow] = []
        var drop: [Shadow] = []
    }

    /// `M-PrimaryButton`. Its stroke's transform maps t = 0 to 8% above the
    /// top and t = 1 to the bottom edge.
    static let dark = GlassTune(
        rest: Face(fill: .solid(RGBA(0x212121)),
                   strokeTop: RGBA(0xEFEFEF), strokeBottom: RGBA(0xD2D2D2),
                   strokeStart: UnitPoint(x: 0.5, y: -0.079), strokeEnd: .bottom,
                   inner: [Shadow(color: RGBA(0xD2D2D2, 0.5), y: 4, blur: 8),
                           Shadow(color: RGBA(0x000000, 1), y: -9, blur: 9)]),
        // The radial's transform puts its centre at (0.5, 0.141) with radii
        // 0.575 W across and 1.306 H down: a wide, soft glow under the top
        // edge. The design's hidden #D2D2D2 45% y-5 b4 shadow is left out.
        pressed: Face(fill: .radial(inner: RGBA(0x424242), outer: RGBA(0x212121),
                                    center: UnitPoint(x: 0.5, y: 0.141), rx: 0.575, ry: 1.306),
                      strokeTop: RGBA(0xD2D2D2), strokeBottom: RGBA(0x8A8A8A),
                      strokeStart: UnitPoint(x: 0.5, y: -0.079), strokeEnd: .bottom,
                      inner: [Shadow(color: RGBA(0x000000, 0.5), blur: 10, spread: 4)],
                      drop: [Shadow(color: RGBA(0x000000, 0.15), y: 4, blur: 5)]))

    /// `M-SecondaryButton`. Its stroke runs from the top to 11.5% past the
    /// bottom edge.
    static let light = GlassTune(
        rest: Face(fill: .solid(RGBA(0xFFFFFF)),
                   strokeTop: RGBA(0xFFFFFF), strokeBottom: RGBA(0xDBDFE6),
                   strokeStart: .top, strokeEnd: UnitPoint(x: 0.5, y: 1.115),
                   inner: [Shadow(color: RGBA(0x989FB3, 0.22), y: -6, blur: 6),
                           Shadow(color: RGBA(0x989FB3, 0.10), y: 4, blur: 4)]),
        // The design's hidden #989FB3 10% y4 b4 shadow is left out.
        pressed: Face(fill: .solid(RGBA(0xFFFFFF)),
                      strokeTop: RGBA(0xFFFFFF), strokeBottom: RGBA(0xDBDFE6),
                      strokeStart: .top, strokeEnd: UnitPoint(x: 0.5, y: 1.115),
                      inner: [Shadow(color: RGBA(0x989FB3, 0.22), blur: 8, spread: 4)],
                      drop: [Shadow(color: RGBA(0xDBDFE6, 0.15), y: 4, blur: 5)]))
}
