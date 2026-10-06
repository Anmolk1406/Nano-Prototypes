import SwiftUI
import UIKit
import Lottie

/// The skin picker's last screen, Figma `Skin Option 35` (1027:17958): the
/// card chosen, the pocket sheet risen to cover the whole screen, and on it a
/// light wash across the top and — on the sticker cards only — the stickers.
/// Its type is `SkinConfirmHeader`, which is not faded but handed over.
///
/// Laid over the sheet, fixed to the screen, and shown only while the sheet
/// is still: `SkinSelectScreen` fades it in once the sheet has covered the
/// screen and out before the sheet moves again, so during the rise and the
/// lift the plain white sheet is the only base. The chosen card, Confirm and
/// Continue stay the picker's own layers above it.
///
/// **The wash** is the one place the card's colour shows: the design's grey
/// (#C3CAD3) mixed a little toward the card's own palette, and only a little
/// — `SkinTuning.confirmTint`, 0.35 by default — so a red or a violet card
/// colours the top of the page without painting it. The rays over it stay
/// white.
///
/// **The rays** — the soft light shapes in the wash — are a looping Lottie,
/// `SkinConfirmRays`, white over the app's colour.
struct SkinConfirmStage: View {
    let skin: String
    /// 0…1 — how far the wash leans toward the card's colour.
    var tint: Double
    /// Whether the rays' Lottie is mounted and playing.
    var live = true

    var body: some View {
        ZStack(alignment: .topLeading) {
            SkinConfirmBackdrop(top: SkinConfirmSpec.wash(for: skin, amount: tint),
                                live: live)
            // Only on the cards that carry the same stickers in their art.
            if SkinConfirmSpec.stickerSkins.contains(skin) { stickers }
        }
        .frame(width: SkinSelectSpec.size.width, height: SkinSelectSpec.size.height,
               alignment: .topLeading)
        .allowsHitTesting(false)
    }

    // MARK: stickers

    private var stickers: some View {
        ZStack(alignment: .topLeading) {
            ForEach(SkinConfirmSpec.stickers, id: \.name) { s in
                Image(s.name)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: s.frame.width, height: s.frame.height)
                    // Figma's drop shadow: 1, 2, blur 2, black at 12%.
                    .shadow(color: .black.opacity(0.12), radius: 1, x: 1, y: 2)
                    .offset(x: s.frame.minX, y: s.frame.minY)
            }
        }
    }
}

/// The confirm screen's type and step dots — dark, on the sheet.
///
/// Not part of `SkinConfirmStage`, which fades: text has to be on screen for
/// the whole change. `SkinSelectScreen` draws this above the sheet and masks
/// it to the sheet's shape, while the picker's white header sits below the
/// sheet — so as the sheet passes under the title the type turns from white
/// to dark exactly at its edge, and back the other way when the sheet sinks.
///
/// `scale` is for that hand-over: the white title is 32pt and this one 40,
/// so the two are drawn at one size throughout — this at `scale` of its own
/// size, the white one grown to match — and the morph between the sizes
/// runs with the sheet.
struct SkinConfirmHeader: View {
    var scale: CGFloat = 1

    var body: some View {
        ZStack(alignment: .topLeading) {
            SkinConfirmDots()
                .frame(width: SkinSelectSpec.size.width)
                .offset(y: SkinConfirmSpec.dotsY)
            VStack(spacing: 2) {
                gradientTitle
                Text("Swipe up or go back to try another")
                    .font(NoonFont.f(.medium, 16))
                    .tracking(-0.15)
                    .foregroundStyle(.black)
                    .frame(height: 22)
            }
            .multilineTextAlignment(.center)
            .frame(width: SkinConfirmSpec.titleWidth)
            .scaleEffect(scale, anchor: .top)
            .offset(x: (SkinSelectSpec.size.width - SkinConfirmSpec.titleWidth) / 2,
                    y: SkinConfirmSpec.titleY)
        }
        .frame(width: SkinSelectSpec.size.width, height: SkinSelectSpec.size.height,
               alignment: .topLeading)
        .allowsHitTesting(false)
    }

    /// 40pt extrabold, black running into violet toward the top right —
    /// the design's 49.87° linear gradient, black to 52.8% and #7924FF at
    /// 104.2%. Masked by the type so the gradient spans the whole block, as
    /// CSS's `background-clip: text` does, rather than restarting per line.
    private var gradientTitle: some View {
        let title = Text("Pick your\nwallet skin")
            .font(NoonFont.f(.extrabold, 40))
            .tracking(-0.25)
            .lineSpacing(SkinConfirmSpec.titleLineGap)
            .frame(width: SkinConfirmSpec.titleWidth)
        return title
            .foregroundStyle(.clear)
            .overlay {
                GeometryReader { geo in
                    let (a, b) = SkinConfirmSpec.cssGradient(angle: 49.8657, size: geo.size,
                                                             from: 0.52835, to: 1.042)
                    LinearGradient(colors: [.black, SkinConfirmSpec.titleAccent],
                                   startPoint: a, endPoint: b)
                }
                .mask(title)
            }
    }

}

/// The step dots on the sheet: the current step a grey-800 ring round a
/// grey-800 dot, the rest grey 800 at a fifth.
///
/// The design's grey 300 (#EAECF0) for the upcoming steps is 1.1:1 against
/// the wash — the rail was all but invisible, and more so on a card whose
/// tint lightens the wash. Grey 800 at 20% shows at any tint and takes on its
/// colour, rather than sitting on it as a flat grey.
private struct SkinConfirmDots: View {
    private var idle: Color { SkinConfirmSpec.grey800.opacity(0.2) }

    var body: some View {
        HStack(spacing: 4) {
            ZStack {
                Circle().fill(.white)
                Circle().strokeBorder(SkinConfirmSpec.grey800, lineWidth: 1.5)
                Circle().fill(SkinConfirmSpec.grey800).frame(width: 8, height: 8)
            }
            .frame(width: 16, height: 16)
            ForEach(0..<2, id: \.self) { _ in
                Capsule().fill(idle).frame(width: 24, height: 4)
                Circle().fill(idle).frame(width: 16, height: 16)
            }
        }
    }
}

// MARK: backdrop

/// The top 259pt of the design — `Whatsapp chat template` (1027:17959):
/// a grey-to-white wash, the rays over it, and five white fades stacked
/// across its foot so it melts into the page with no edge.
struct SkinConfirmBackdrop: View {
    /// The wash's top colour — the design's #C3CAD3, or the card's tint of it.
    var top: Color
    /// Whether the rays' Lottie is mounted and playing.
    var live = true

    var body: some View {
        ZStack(alignment: .topLeading) {
            // `Rectangle 1891598603`: grey at 8.9% of its height to white.
            LinearGradient(stops: [.init(color: top, location: 0.08884),
                                   .init(color: .white, location: 1)],
                           startPoint: .top, endPoint: .bottom)
                .frame(width: 379.754, height: 307.256)
                .offset(x: -2.376, y: -20.296)
            fade(y: 74.619, h: 184.726)
            // `Rectangle 1891598609`: #E9E9E9 at 0 alpha from 3.6%, to white
            // at 74.5%.
            LinearGradient(stops: [.init(color: Color(white: 0.9143).opacity(0), location: 0.03646),
                                   .init(color: .white, location: 0.7445)],
                           startPoint: .top, endPoint: .bottom)
                .frame(width: 375, height: 171.182)
                .offset(x: 0.001, y: 117.952)
            SkinConfirmRays(live: live)
            fade(y: 180.576, h: 86.942)
            fade(y: 167.782, h: 99.736)
            fade(y: 173.711, h: 69.956)
            fade(y: 199.433, h: 68.086)
            fade(y: 199.433, h: 149.567)
        }
        .frame(width: SkinSelectSpec.size.width, height: SkinConfirmSpec.backdropHeight,
               alignment: .topLeading)
        .clipped()
    }

    /// The design's clear-to-white fades, white by 79% of their height.
    private func fade(y: CGFloat, h: CGFloat) -> some View {
        LinearGradient(stops: [.init(color: .white.opacity(0), location: 0),
                               .init(color: .white, location: 0.79015)],
                       startPoint: .top, endPoint: .bottom)
            .frame(width: 377.029, height: h)
            .offset(x: -1.015, y: y)
    }
}

/// The rays in the wash: `skin_confirm_rays.lottie`, built in After Effects
/// (`Tools/ae/build_confirm_rays.jsx`) from the design's four rays — each with
/// its progressive blur baked in — swaying about the point their funnels
/// narrow to, stretching and breathing, with a fifth copy sweeping wide
/// across them, on a seamless 4s loop. Authored at 2x over exactly this
/// 375 × 259 area (750 × 518), so it is laid over the wash at the wash's own
/// size.
///
/// **What is the Lottie's and what is the app's.** The Lottie is the rays
/// alone, white, on a transparent ground. The colour — the wash the app
/// leans toward the chosen card — and the white fades across the header's
/// foot are drawn here, so the colour can follow the card. The rays stay
/// white: light on a coloured ground is what makes them read. Tinted to the
/// wash's own colour, as they first were, they vanished into it.
///
/// `live` mounts it only while the confirm screen can be seen, so it is not
/// playing behind the picker.
struct SkinConfirmRays: View {
    var live = true

    var body: some View {
        Group {
            if live {
                LottieView { try await DotLottieFile.named(SkinConfirmSpec.raysAnimation) }
                    .playing(loopMode: .loop)
                    .resizable()
            }
        }
        .frame(width: SkinSelectSpec.size.width, height: SkinConfirmSpec.backdropHeight)
        .allowsHitTesting(false)
    }
}

// MARK: numbers

enum SkinConfirmSpec {
    static let backdropHeight: CGFloat = 259
    static let dotsY: CGFloat = 76
    static let titleY: CGFloat = 112
    static let titleWidth: CGFloat = 345
    /// Extra space between the title's lines, over the font's own.
    static let titleLineGap: CGFloat = 0
    static let titleAccent = Color(hex: 0x7924FF)
    static let grey300 = Color(hex: 0xEAECF0)
    static let grey800 = Color(hex: 0x343D54)
    /// Where the pocket sheet's top stops once it covers the screen: the whole
    /// notch — crest to floor, `PocketShape.notchDepth` — and a little over
    /// above the top edge, so no part of the mouth is left showing.
    static var coverTop: CGFloat {
        -(PocketShape.notchDepth(forWidth: SkinSelectSpec.sheetWidth) + 12)
    }

    /// The wash's grey leaned toward the card: mixed with the card's first
    /// palette colour by `amount`. The palette's colours are forced bright
    /// for the pocket glow, which is what keeps a small mix reading as a
    /// tint rather than a darkening.
    static func wash(for skin: String, amount: Double) -> Color {
        mix((r: 0.7662, g: 0.7930, b: 0.8275), toward: skin, amount)   // #C3CAD3
    }

    private static func mix(_ base: (r: Double, g: Double, b: Double),
                            toward skin: String, _ amount: Double) -> Color {
        guard amount > 0, let c = SkinPalette.colors(for: skin).first else {
            return Color(.sRGB, red: base.r, green: base.g, blue: base.b)
        }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(c).getRed(&r, green: &g, blue: &b, alpha: &a)
        let k = min(1, max(0, amount))
        return Color(.sRGB,
                     red: base.r + (Double(r) - base.r) * k,
                     green: base.g + (Double(g) - base.g) * k,
                     blue: base.b + (Double(b) - base.b) * k)
    }

    /// A CSS `linear-gradient(<angle>deg, …)` over a box of `size`, as the
    /// two unit points its `from` and `to` stops land on.
    static func cssGradient(angle: Double, size: CGSize,
                            from: Double, to: Double) -> (UnitPoint, UnitPoint) {
        let a = angle * .pi / 180
        let dx = sin(a), dy = -cos(a)
        let len = abs(size.width * dx) + abs(size.height * dy)
        func at(_ t: Double) -> UnitPoint {
            let s = (t - 0.5) * len
            return UnitPoint(x: 0.5 + s * dx / max(1, size.width),
                             y: 0.5 + s * dy / max(1, size.height))
        }
        return (at(from), at(to))
    }

    /// The skins whose art carries the stickers — the black and the silver
    /// "sticker" cards, `skin_09` and `skin_14`. Every other card's confirm
    /// screen goes without.
    static let stickerSkins: Set<String> = ["skin_09", "skin_14"]
    /// The picker's white title is 32pt against this one's 40.
    static let titleGrowth: CGFloat = 40.0 / 32.0

    struct Sticker { let name: String; let frame: CGRect }
    /// The design's three, at their frames in the 375 × 812 screen.
    static let stickers = [
        Sticker(name: "confirm_sticker_squiggle", frame: CGRect(x: 18.994, y: 239.080, width: 57.012, height: 55.007)),
        Sticker(name: "confirm_sticker_star", frame: CGRect(x: 309.747, y: 179.511, width: 48.715, height: 59.988)),
        Sticker(name: "confirm_sticker_heart", frame: CGRect(x: 307.563, y: 633.852, width: 56.808, height: 56.629)),
    ]

    /// The rays' Lottie, `skin_confirm_rays.lottie` — the CONFIRM_RAYS comp,
    /// packed by `Tools/pack_confirm_rays.py`.
    static let raysAnimation = "skin_confirm_rays"
}
