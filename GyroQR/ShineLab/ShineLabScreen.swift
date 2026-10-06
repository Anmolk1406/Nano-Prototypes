import SwiftUI

/// The invite share screen (Figma 980:15528) with the holo card: the same
/// screen the parent flow ends on — backdrop, title, sparkles, link and share
/// button — with the chrome frame swapped for the holo base and the
/// designer's shines running along its rim.
///
/// Experimental and in no flow: reached from the controls sheet's scene list.
/// The flows' invite screen is untouched; this passes the card in.
struct ShineLabScreen: View {
    @ObservedObject var motion: MotionEngine
    @ObservedObject var t: Tuning
    @ObservedObject var tune: ShineLabTuning

    var body: some View {
        ShareScreen(motion: motion, t: t,
                    inviteCard: .inviteHolo,
                    inviteExtra: AnyView(ZStack(alignment: .topLeading) {
                        HoloRimLight(out: motion.out, t: t, tune: tune)
                        ShineRim(out: motion.out, tune: tune,
                                 width: CardSpec.inviteHolo.size.width,
                                 invertX: t.invertX, invertY: t.invertY)
                    }),
                    inviteUnder: AnyView(HoloHalo(tune: tune)),
                    inviteFlatten: true)
            .onAppear {
                t.cardStyle = .invite
                motion.start()
            }
            .onDisappear { motion.stop() }
    }
}

/// The white sticker glow round the card that Figma's frame render carries
/// and the holo base does not: the base's own silhouette in white, grown by
/// 4pt a side and softened, with a wider haze under it.
private struct HoloHalo: View {
    @ObservedObject var tune: ShineLabTuning
    private static let size = CGSize(width: 290, height: 290 * 1491 / 1055)

    var body: some View {
        let w = Self.size.width, h = Self.size.height
        ZStack {
            silhouette(grow: 4).blur(radius: 2.5)
            silhouette(grow: 8).blur(radius: 10).opacity(0.7)
        }
        .frame(width: w, height: h)
        .opacity(tune.halo ? 1 : 0)
        .allowsHitTesting(false)
    }

    private func silhouette(grow: CGFloat) -> some View {
        let w = Self.size.width, h = Self.size.height
        return Image("slab_base").renderingMode(.template).resizable().interpolation(.high)
            .foregroundStyle(.white)
            .frame(width: w, height: h)
            .scaleEffect(x: (w + 2 * grow) / w, y: (h + 2 * grow) / h)
    }
}

/// Rim light for the holo card: the chrome card's moving border highlight —
/// bright on the lit side, faint across the middle, a softer catch on the far
/// side, all following the tilt — laid over the base's rim band rather than a
/// rectangle's stroke. Off with the Light section's Rim light toggle.
private struct HoloRimLight: View {
    @ObservedObject var out: MotionOutput
    @ObservedObject var t: Tuning
    @ObservedObject var tune: ShineLabTuning

    private static let size = CGSize(width: 290, height: 290 * 1491 / 1055)

    var body: some View {
        let tilt = CGPoint(x: out.tilt.x * (t.invertX ? -1 : 1), y: out.tilt.y * (t.invertY ? -1 : 1))
        return LinearGradient(colors: [.white, .white.opacity(0.05), .white.opacity(0.55)],
                              startPoint: UnitPoint(x: 0.5 - tilt.x * 0.5, y: 0.5 - tilt.y * 0.5),
                              endPoint: UnitPoint(x: 0.5 + tilt.x * 0.5, y: 0.5 + tilt.y * 0.5))
            .frame(width: Self.size.width, height: Self.size.height)
            .mask {
                Image("slab_rim_mask").resizable().interpolation(.high)
                    .frame(width: Self.size.width, height: Self.size.height)
            }
            .blendMode(.plusLighter)
            .opacity(t.rimEnabled ? tune.rimStrength : 0)
            .allowsHitTesting(false)
    }
}
