import SwiftUI

/// The QR card. One normalised tilt drives 3D rotation, per-layer elevation
/// parallax, contact shadows, a specular sheen, an iridescent band and a rim
/// light.
///
/// The depth model is physical rather than ad-hoc: the whole card rotates by
/// `θ`, and a layer sitting `h` points above the surface is shifted by
/// `h · tan(θ)` before that rotation. That single relationship is what makes
/// the QR panel read as floating above its card instead of printed on it.
struct GyroCardView: View {
    @ObservedObject var out: MotionOutput
    @ObservedObject var t: Tuning
    /// Optional native panel that rides on the card at its own elevation.
    var caption: (line1: String, line2: String)? = nil

    private var tilt: CGPoint {
        CGPoint(x: out.tilt.x * (t.invertX ? -1 : 1),
                y: out.tilt.y * (t.invertY ? -1 : 1))
    }

    // The light bands are pushed by up to `travel` points. Sizing them off the
    // card's diagonal plus twice that travel guarantees they still cover the
    // card at full deflection — undersize them and their own straight edge
    // slides into view on extreme tilts.
    private static let sheenTravel: CGFloat = 260
    private static let holoTravel:  CGFloat = 300
    private static let lightSpan: CGFloat = {
        let diag = (CardSpec.size.width * CardSpec.size.width
                  + CardSpec.size.height * CardSpec.size.height).squareRoot()
        return diag + 2 * max(sheenTravel, holoTravel) + 80
    }()

    /// Rotation actually applied to the card, in degrees.
    private var yaw:   Double { t.tiltEnabled ? tilt.x * t.tiltDegrees : 0 }
    private var pitch: Double { t.tiltEnabled ? tilt.y * t.tiltDegrees : 0 }

    private var tiltMagnitude: Double { min(1, sqrt(tilt.x * tilt.x + tilt.y * tilt.y)) }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: CardSpec.corner, style: .continuous)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // The card body. Everything in here is clipped to the card, which
            // is what keeps the fuzzy ball bleeding off the left edge as drawn.
            ZStack(alignment: .topLeading) {
                Color(red: 0.898, green: 0.027, blue: 0.988)   // Figma #E507FC
                ForEach(CardSpec.layers.filter { !$0.floats }) { layer($0) }
            }
            .frame(width: CardSpec.size.width, height: CardSpec.size.height)
            // These overlays are deliberately larger than the card, so they must
            // sit in an overlay rather than in the ZStack — otherwise their size
            // would drive the stack's layout and shift every layer off the card.
            .overlay { if t.sheenEnabled { sheen } }
            .overlay { if t.holoEnabled  { holo } }
            .clipShape(shape)
            .overlay { border }

            // Floating planes, drawn outside the clip so they may overhang.
            ForEach(CardSpec.layers.filter { $0.floats }) { layer($0) }

            if let caption { captionPanel(caption) }

            if t.showBounds { bounds }
        }
        .frame(width: CardSpec.size.width, height: CardSpec.size.height)
        .compositingGroup()
        .shadow(color: .black.opacity(0.22),
                radius: 18 + 6 * tiltMagnitude,
                x: t.shadowEnabled ? -tilt.x * t.shadowShift : 0,
                y: 6 + (t.shadowEnabled ? -tilt.y * t.shadowShift : 0))
        // A little in-plane roll. The reference card does ~±2° of this and it
        // is a surprising amount of the liveliness.
        .rotationEffect(.degrees(t.rollEnabled ? tilt.x * t.roll : 0))
        .rotation3DEffect(.degrees(pitch), axis: (x: 1, y: 0, z: 0), perspective: t.perspective)
        .rotation3DEffect(.degrees(yaw),   axis: (x: 0, y: 1, z: 0), perspective: t.perspective)
        .scaleEffect(t.cardScale)
    }

    // MARK: layers

    /// Pre-rotation shift that makes a layer at `elevation` look that far above
    /// the surface once the card is turned. Exact for a flat plane: a point at
    /// height `h` lands where an in-plane point at `h·tan θ` would.
    private func parallax(_ elevation: CGFloat) -> CGSize {
        guard t.parallaxEnabled else { return .zero }
        let e = elevation * t.elevationScale
        return CGSize(width:  e * tan(yaw   * .pi / 180),
                      height: e * tan(pitch * .pi / 180) * -1)
    }

    /// Figma bakes a layer blur into the mascots. Held constant at this size it
    /// reads as a smudge, so it is driven by the left/right tilt instead: sharp
    /// when the card is square to you, defocused as you roll it either way.
    @ViewBuilder
    private func layer(_ l: CardSpec.Layer) -> some View {
        let p = parallax(l.elevation)
        // Nearer planes sit closer to the eye, so they grow a little. Small,
        // but it is what stops parallax reading as a flat slide.
        let grow = t.depthScale ? 1 + (l.elevation / 600) * tiltMagnitude : 1
        let wob  = t.wobbleEnabled ? tilt.x * t.wobble * l.wobble : 0

        Image(l.image)
            .resizable()
            .interpolation(.high)
            .frame(width: l.frame.width, height: l.frame.height)
            .rotationEffect(.degrees(l.rotation + wob))
            .scaleEffect(l.scale * grow, anchor: l.anchor)
            .blur(radius: l.blur * t.blurScale * (t.gyroBlur ? abs(tilt.x) : 1))
            .opacity(l.opacity)
            .shadow(color: .black.opacity(l.shadowOpacity * t.contactShadow),
                    radius: l.shadowRadius,
                    x: -p.width  * 0.75,
                    y: l.shadowRest - p.height * 0.75)
            .offset(x: l.frame.minX + p.width, y: l.frame.minY + p.height)
    }

    /// Figma 779:22701 — kept native rather than rasterised so the text stays
    /// crisp, but parallaxed and shadowed like any other floating plane.
    private func captionPanel(_ c: (line1: String, line2: String)) -> some View {
        let f = CardSpec.captionFrame
        let p = parallax(CardSpec.captionElevation)
        return VStack(spacing: 0) {
            Text(c.line1)
            Text(c.line2)
        }
        .figmaText(ScreenSpec.TypeScale.b16)
        .foregroundStyle(ScreenSpec.Palette.textSecondary)
        .multilineTextAlignment(.center)
        .frame(width: f.width, height: f.height)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(ScreenSpec.Palette.borderHairline, lineWidth: 1)
        }
        .offset(x: f.minX + p.width, y: f.minY + p.height)
    }

    // MARK: light

    /// Broad diagonal specular band that slides across the face.
    private var sheen: some View {
        LinearGradient(stops: [
            .init(color: .white.opacity(0),    location: 0.407),
            .init(color: .white.opacity(0.22), location: 0.481),
            .init(color: .white.opacity(0.45), location: 0.500),
            .init(color: .white.opacity(0.22), location: 0.519),
            .init(color: .white.opacity(0),    location: 0.593),
        ], startPoint: .topLeading, endPoint: .bottomTrailing)
        .frame(width: Self.lightSpan, height: Self.lightSpan)
        .offset(x: -tilt.x * Self.sheenTravel, y: -tilt.y * Self.sheenTravel)
        .blendMode(.plusLighter)
        .opacity(t.sheen * (0.25 + 0.75 * tiltMagnitude))
        .allowsHitTesting(false)
    }

    /// Thin iridescent band — the "holographic foil" read. Fades out when the
    /// card is flat, so a resting card stays true to the Figma design.
    private var holo: some View {
        LinearGradient(stops: [
            .init(color: .clear, location: 0.00),
            .init(color: .clear, location: 0.415),
            .init(color: Color(hue: 0.00, saturation: 0.85, brightness: 1), location: 0.450),
            .init(color: Color(hue: 0.13, saturation: 0.85, brightness: 1), location: 0.479),
            .init(color: Color(hue: 0.33, saturation: 0.85, brightness: 1), location: 0.500),
            .init(color: Color(hue: 0.52, saturation: 0.85, brightness: 1), location: 0.521),
            .init(color: Color(hue: 0.72, saturation: 0.85, brightness: 1), location: 0.550),
            .init(color: Color(hue: 0.88, saturation: 0.85, brightness: 1), location: 0.578),
            .init(color: .clear, location: 0.613),
            .init(color: .clear, location: 1.00),
        ], startPoint: .topLeading, endPoint: .bottomTrailing)
        .frame(width: Self.lightSpan, height: Self.lightSpan)
        .offset(x: tilt.x * Self.holoTravel, y: tilt.y * Self.holoTravel)
        .blendMode(.plusLighter)
        .opacity(t.holo * tiltMagnitude)
        .allowsHitTesting(false)
    }

    /// The 4pt Figma border, with a moving highlight along the lit edge.
    private var border: some View {
        ZStack {
            shape.strokeBorder(.white, lineWidth: CardSpec.border)
            if t.rimEnabled {
                shape
                    .strokeBorder(
                        LinearGradient(colors: [.white, .white.opacity(0.05), .white.opacity(0.55)],
                                       startPoint: UnitPoint(x: 0.5 - tilt.x * 0.5, y: 0.5 - tilt.y * 0.5),
                                       endPoint:   UnitPoint(x: 0.5 + tilt.x * 0.5, y: 0.5 + tilt.y * 0.5)),
                        lineWidth: CardSpec.border)
                    .blendMode(.plusLighter)
                    .opacity(0.9)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: debug

    private var bounds: some View {
        ForEach(CardSpec.layers) { l in
            let p = parallax(l.elevation)
            Rectangle()
                .strokeBorder(l.debugTint, lineWidth: 1)
                .frame(width: l.frame.width, height: l.frame.height)
                .overlay(alignment: .topLeading) {
                    Text(String(format: "%@ %+.0fpt", l.id, l.elevation))
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(l.debugTint)
                        .padding(1)
                        .background(.black.opacity(0.55))
                        .offset(y: -10)
                }
                .offset(x: l.frame.minX + p.width, y: l.frame.minY + p.height)
        }
        .allowsHitTesting(false)
    }
}
