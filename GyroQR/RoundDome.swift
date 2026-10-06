import SwiftUI

/// A 1:1 replica of the reference recording's round red button — a glossy
/// dome, 77pt across, on a warm page — built from gradients and shadows so
/// the same light can later go onto any shape.
///
/// Every number here was read off the recording (`ScreenRecording_09-25-2026
/// 19-35-39_1.mov`, 60fps, 3× — so its pixels are this screen's pixels):
/// radial colour profiles in eight directions from the dome's centre and
/// dense vertical ones down five columns, at rest (frame 38) and pressed
/// (frame 50). Positions are in units of the dome's radius, `R`.
///
/// **At rest** the dome is lit from just above its top edge: the face is a
/// radial falloff from coral (253, 131, 108) to maroon (52, 10, 15),
/// centred at (0.08, −0.95)R — the light's position — with the logo in the
/// middle. The top edge fades softly into the page; the bottom runs dark
/// straight into the shadow on the page.
///
/// **Pressed** it is lit from below and sunk under a lip:
///
/// * the face is a *vertical* ramp — dark red at the top to bright
///   (195, 60, 42) across the lower half,
/// * the lip of the hole throws a deep shadow half a radius into the top of
///   the face, darkest around 0.3R in,
/// * right at the top edge a strong light-pink rim catches the light,
/// * along the bottom edge a dark rim runs into the shadow outside.
///
/// **The shadow on the page does not change.** Below the dome it measures
/// the same in both frames to within a few levels — it is the dome's, and
/// the dome does not move; everything that changes happens inside the face.
/// And measured, the dome does not scale either.
///
/// The transition is 4–5 frames in the reference, and every sampled pixel
/// moves monotonically from one end to the other — a blend, not a slide —
/// so the two faces are crossfaded over the press.
struct RoundDome: View {
    /// 0 at rest, 1 pressed. Animated by the caller.
    var pressed: Bool
    var duration: Double = 0.075
    var tune = RoundDomeTune()

    var body: some View {
        let R = tune.radius
        ZStack {
            // The shadow on the page: a dark disc a quarter-radius lower,
            // well blurred. The same at rest and pressed.
            Circle()
                .fill(tune.shadow.color)
                .frame(width: 2 * R * tune.shadowScale, height: 2 * R * tune.shadowScale)
                .offset(y: tune.shadowDrop * R)
                .blur(radius: tune.shadowBlur * R)

            // The contact shadow: tight and dark right under the raised
            // dome, where it meets the page. The reference is still the
            // dome's own maroon at its lower boundary, darker than the broad
            // shadow alone can make it. Gone when it sinks.
            Circle()
                .fill(tune.shadow.color)
                .frame(width: 2 * R * 0.97, height: 2 * R * 0.97)
                .offset(y: tune.contactDrop * R)
                .blur(radius: tune.contactBlur * R)
                .opacity(pressed ? 0 : tune.contact)

            ZStack {
                restFace(R)
                pressedFace(R)
                    .opacity(pressed ? 1 : 0)
            }
            .frame(width: 2 * R, height: 2 * R)
            .clipShape(Circle())
            // The dome's edge is soft in the reference — it blends into the
            // page over about 0.1R. The logo, drawn on top, stays sharp.
            .blur(radius: tune.edgeSoftness * R)

            // The pressed rim of light *straddles* the edge: the pixels on
            // the boundary are pinker and lighter than any blend of the dark
            // face with the page could be, so it is drawn over the softened
            // edge rather than inside the clipped face.
            crescent(R, drop: tune.topRimDrop, blur: tune.topRimBlur,
                     colour: RGBA(0xFFC6B5), radius: 1.045)
                // Kept to the top: in the reference the rim is gone by about
                // 40° either side of vertical, where a bare crescent still
                // shows as a hairline down to the equator.
                .mask(LinearGradient(stops: [.init(color: .black, location: 0),
                                             .init(color: .black, location: 0.12),
                                             .init(color: .clear, location: 0.42)],
                                     startPoint: .top, endPoint: .bottom)
                        .frame(width: 2.2 * R, height: 2.2 * R))
                .opacity(pressed ? tune.topRim : 0)

            CrewMark(size: R)
                .opacity(pressed ? tune.pressedMark : 1)
        }
        .animation(.easeInOut(duration: duration), value: pressed)
        .frame(width: 2 * R * 1.6, height: 2 * R * 1.6)
    }

    /// Radial falloff from the light just above the top edge.
    private func restFace(_ R: CGFloat) -> some View {
        let reach = 1.8     // in R: the far side of the dome from the light
        let stops: [(Double, RGBA)] = [
            (0.00, RGBA(0xFF8C74)), (0.40, RGBA(0xFC7F6A)), (0.55, RGBA(0xE86A59)),
            (0.70, RGBA(0xC3584A)), (0.90, RGBA(0x94392F)), (1.08, RGBA(0x742823)),
            (1.26, RGBA(0x5D1D1B)), (1.45, RGBA(0x4B1517)), (1.62, RGBA(0x3C0E12)),
            (1.80, RGBA(0x340A0F)),
        ]
        return Circle()
            .fill(RadialGradient(
                stops: stops.map { .init(color: $0.1.color, location: $0.0 / reach) },
                center: UnitPoint(x: 0.5 + tune.lightX / 2, y: 0.5 + tune.lightY / 2),
                startRadius: 0, endRadius: reach * R)
                // A faint rim light on the top edge even at rest: 0.1R in,
                // the reference is 18 levels greener than the face behind.
                .shadow(.inner(color: RGBA(0xFFC9B8, tune.restRim).color,
                               radius: 0.04 * R, y: 0.03 * R)))
    }

    /// Lit from below, sunk under a lip.
    ///
    /// Three layers over a vertical ramp, each sized off the recording:
    ///
    /// * **the lip's shadow** is a dark *blob* at the top centre, not a band
    ///   round the edge — its strength falls from ~95% on the centre line to
    ///   45% a third of a radius out and under 20% at 0.6R, a Gaussian about
    ///   0.3R wide. It is the dark V above the mark.
    /// * **the bottom rim**, a thin dark crescent along the lower edge,
    ///   0.1R deep, running into the shadow on the page.
    /// * **the top rim** of light is drawn by the caller, over the edge.
    private func pressedFace(_ R: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(LinearGradient(stops: [
                    .init(color: RGBA(0x7A2319).color, location: 0.00),
                    .init(color: RGBA(0x7C241C).color, location: 0.35),
                    .init(color: RGBA(0x862620).color, location: 0.40),
                    .init(color: RGBA(0x942B21).color, location: 0.50),
                    .init(color: RGBA(0xA53123).color, location: 0.60),
                    .init(color: RGBA(0xB73926).color, location: 0.70),
                    .init(color: RGBA(0xC23C2A).color, location: 0.78),
                    .init(color: RGBA(0xC33C2A).color, location: 1.00),
                ], startPoint: .top, endPoint: .bottom))

            // The lip: an ellipse at the top centre, heavily blurred.
            Ellipse()
                .fill(RGBA(0x3E0C0E).color)
                .frame(width: tune.lipWidth * R, height: tune.lipHeight * R)
                .offset(y: tune.lipY * R)
                .blur(radius: tune.lipBlur * R)
                .opacity(tune.lipShadow)

            crescent(R, drop: -tune.bottomRimDrop, blur: tune.bottomRimBlur,
                     colour: RGBA(0x4A1512), radius: 1.0)
                .opacity(tune.bottomRim)
        }
    }

    /// A circle minus a copy of itself shifted by `drop`·R, blurred: a
    /// crescent thickest where the shift points away from, fading to nothing
    /// at the sides. Positive `drop` puts it along the top edge.
    private func crescent(_ R: CGFloat, drop: CGFloat, blur: CGFloat,
                          colour: RGBA, radius: CGFloat) -> some View {
        let d = 2 * R * radius
        return Circle()
            .fill(colour.color)
            .frame(width: d, height: d)
            .overlay {
                Circle()
                    .frame(width: d, height: d)
                    .offset(y: drop * R)
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
            .blur(radius: blur * R)
            .mask(Circle().frame(width: d, height: d))
    }
}

/// The dome's numbers, all in units of its radius so the look survives a
/// resize. Defaults are the calibrated reference.
struct RoundDomeTune: Equatable {
    var radius: CGFloat = 38.33          // 115px at 3× in the recording
    var lightX: CGFloat = 0.08
    var lightY: CGFloat = -0.95
    var restRim: Double = 0.8

    // The page shadow, fitted against 64 samples round the lower half of
    // both frames: a disc 1.06R across, 0.197R lower, σ 0.134R, 86%.
    var shadow = RGBA(0x35070D, 0.86)
    var shadowScale: CGFloat = 1.06
    var shadowDrop: CGFloat = 0.197
    var shadowBlur: CGFloat = 0.134
    var edgeSoftness: CGFloat = 0.016
    var contact: Double = 1.0
    var contactDrop: CGFloat = 0.075
    var contactBlur: CGFloat = 0.04

    var lipShadow: Double = 0.85
    var lipWidth: CGFloat = 0.85
    var lipHeight: CGFloat = 0.55
    var lipY: CGFloat = -0.7
    var lipBlur: CGFloat = 0.13
    var topRim: Double = 1.0
    var topRimBlur: CGFloat = 0.045
    var topRimDrop: CGFloat = 0.15
    var bottomRim: Double = 0.5
    var bottomRimBlur: CGFloat = 0.05
    var bottomRimDrop: CGFloat = 0.12

    var pressedMark: Double = 0.9
}

/// The reference's mark: CREW stacked two over two, the E mirrored, in a
/// wide geometric face — light grey with a soft bevel and a drop shadow.
/// A stand-in drawn in type, not the brand's artwork.
struct CrewMark: View {
    var size: CGFloat

    var body: some View {
        VStack(spacing: -size * 0.16) {
            Text("CR")
            Text("\u{018E}W")    // Ǝ — the reference's E faces backwards
        }
        .font(.system(size: size * 0.56, weight: .bold).width(.expanded))
        .kerning(-size * 0.03)
        .foregroundStyle(LinearGradient(colors: [RGBA(0xF6F1F0).color, RGBA(0xD4CBCA).color],
                                        startPoint: .top, endPoint: .bottom))
        .shadow(color: .black.opacity(0.45), radius: size * 0.02, x: size * 0.01, y: size * 0.025)
        .allowsHitTesting(false)
    }
}
