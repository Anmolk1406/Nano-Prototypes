import SwiftUI

/// The two QR screens, laid out at their native 375 × 812 and scaled to fit the
/// device. Everything except the card is static chrome; the card is the live
/// gyro piece, and it is the *same* card view in both — only its planes differ.
///
/// | Style | Figma | What it is |
/// |---|---|---|
/// | Invite | `779:22071` | The invite card on a photographic backdrop, with a bottom sheet. |
/// | Profile | `940:62757` | The profile QR on a starburst, with one CTA. |
struct ShareScreen: View {
    @ObservedObject var motion: MotionEngine
    @ObservedObject var t: Tuning
    var onClose: () -> Void = {}

    var body: some View {
        GeometryReader { geo in
            let scale = max(geo.size.width / ScreenSpec.size.width,
                            geo.size.height / ScreenSpec.size.height)
            stage
                .frame(width: ScreenSpec.size.width, height: ScreenSpec.size.height)
                .scaleEffect(scale, anchor: .center)
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private var stage: some View {
        switch t.cardStyle {
        case .invite:  content
        case .profile: profileContent
        }
    }

    /// The card, with the drag fallback for when there is no gyro to read.
    private func card(_ spec: CardSpec) -> some View {
        GyroCardView(out: motion.out, t: t, spec: spec, onClose: onClose)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        motion.beginDrag()
                        motion.setDrag(CGPoint(x:  v.translation.width  / 140,
                                               y: -v.translation.height / 140))
                    }
                    .onEnded { _ in motion.releaseDrag() }
            )
    }

    // MARK: profile — Figma 940:62757
    //
    // A far plainer screen than the invite one: a white page, the card, and a
    // single CTA. The status bar in the frame is a drawn `Phone Header`
    // instance, which the real one covers.

    private var profileContent: some View {
        ZStack(alignment: .topLeading) {
            Color.white

            card(.profile)
                .offset(x: ProfileQRSpec.card.minX, y: ProfileQRSpec.card.minY)

            shareProfileButton
                .frame(width: ProfileQRSpec.cta.width, height: ProfileQRSpec.cta.height)
                .offset(x: ProfileQRSpec.cta.minX, y: ProfileQRSpec.cta.minY)
        }
        .frame(width: ScreenSpec.size.width, height: ScreenSpec.size.height,
               alignment: .topLeading)
    }

    /// 940:63622 — `M-NeutralButton` with a trailing share glyph.
    private var shareProfileButton: some View {
        Button {
            Haptics.shared.tap()
        } label: {
            HStack(spacing: 8) {
                Text(ProfileQRSpec.ctaTitle)
                    .font(OnboardingSpec.F.a17)
                    .tracking(-0.25)
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 17, weight: .medium))
                    .offset(y: -1)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(OnboardingSpec.C.primary,
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: invite — Figma 779:22071

    private var content: some View {
        ZStack(alignment: .topLeading) {
            image("inv_bg", CGRect(origin: .zero, size: ScreenSpec.size))

            title

            // The left sparkle is behind the card in the design; the right one
            // is in front of it. Keeping that order matters — the right one
            // overlaps the frame's edge.
            sparkle("inv_star_l", ScreenSpec.starLeft, depth: -9)

            card(.invite)
                .offset(x: ScreenSpec.card.minX, y: ScreenSpec.card.minY)

            sparkle("inv_star_r", ScreenSpec.starRight, depth: 14)

            closeButton
                .frame(width: ScreenSpec.closeButton.width, height: ScreenSpec.closeButton.height)
                .offset(x: ScreenSpec.closeButton.minX, y: ScreenSpec.closeButton.minY)

            bottomSheet
                .frame(width: ScreenSpec.sheet.width, height: ScreenSpec.sheet.height)
                .offset(x: ScreenSpec.sheet.minX, y: ScreenSpec.sheet.minY)
        }
        .frame(width: ScreenSpec.size.width, height: ScreenSpec.size.height, alignment: .topLeading)
    }

    private func image(_ name: String, _ box: CGRect) -> some View {
        Image(name)
            .resizable()
            .frame(width: box.width, height: box.height)
            .offset(x: box.minX, y: box.minY)
    }

    /// 980:15985 / 980:15986 — the headline and its line of help.
    private var title: some View {
        ZStack(alignment: .topLeading) {
            // Both boxes carry the design's own line height, and the text is
            // centred in it. Letting SwiftUI pick the height instead lands
            // each line a couple of points low, which is what a `lineSpacing`
            // set for a *multi*-line style does to a single line.
            OutlinedText(ScreenSpec.title,
                         font: NoonFont.f(.extrabold, 40),
                         tracking: -0.25,
                         fill: ScreenSpec.titleFill,
                         outline: ScreenSpec.titleOutline)
                .frame(width: ScreenSpec.titleBox.width,
                       height: ScreenSpec.titleBox.height)
                .offset(x: ScreenSpec.titleBox.minX, y: ScreenSpec.titleBox.minY)

            Text(ScreenSpec.subtitle)
                .font(NoonFont.f(.medium, 14))
                .tracking(-0.1)
                .foregroundStyle(.black)
                .frame(width: ScreenSpec.subtitleBox.width,
                       height: ScreenSpec.subtitleBox.height)
                .offset(x: ScreenSpec.subtitleBox.minX, y: ScreenSpec.subtitleBox.minY)
        }
        .frame(width: ScreenSpec.size.width, height: ScreenSpec.size.height,
               alignment: .topLeading)
    }

    /// One of the two sparkles at the screen's edges.
    ///
    /// Page decoration rather than part of the card, so they do not rotate
    /// with it — but they do drift. `depth` is the same idea as a layer's
    /// elevation and in the same units, just applied at the screen level: a
    /// few points of counter-motion is the difference between a background
    /// that is behind the card and one that is painted on the glass.
    private func sparkle(_ name: String, _ box: CGRect, depth: CGFloat) -> some View {
        let tilt = motion.out.tilt
        let d = t.parallaxEnabled ? depth * t.elevationScale : 0
        return image(name, box)
            .offset(x: d * tilt.x * (t.invertX ? -1 : 1) * 0.5,
                    y: -d * tilt.y * (t.invertY ? -1 : 1) * 0.5)
    }

    // MARK: chrome

    // 980:15981 — the page header's leading slot. Glass rather than the old
    // solid white disc: 50% white with a 64% white hairline, which is what
    // lets the ray pattern read through it.
    private var closeButton: some View {
        Button(action: onClose) {
            ZStack {
                Circle().fill(.white.opacity(0.5))
                Circle().strokeBorder(.white.opacity(0.64), lineWidth: 1)
                Image("ic_close")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(ScreenSpec.Palette.textPrimary)
            }
        }
        .buttonStyle(.plain)
    }

    // 779:22703 — Header Container.
    //
    // The container itself has NO fill in the design: the screen background
    // shows through behind the OR row and the invite field. Only the invite
    // field, the action bar and the home bar are white.
    private var bottomSheet: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                orDivider
                linkBox
            }
            .padding(20)

            // M-RowActionBar + Home bar — the only filled parts, and the only
            // ones that cast the container's upward shadow.
            VStack(spacing: 0) {
                shareButton
                    .padding(12)
                ZStack {
                    Color.white
                    Capsule()
                        .fill(ScreenSpec.Palette.homeBar)
                        .frame(width: 124, height: 5)
                }
                .frame(height: 24)
            }
            .background(.white)
            .shadow(color: Color(white: 0.878).opacity(0.5), radius: 11, y: -5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    /// 980:15990. Pinned to the design's 18pt row: `figmaText` carries a
    /// `lineSpacing` for the style's line height, and on a single line SwiftUI
    /// adds that below the glyphs — which pushed this row, and therefore
    /// everything under it, about 3.6pt down the screen.
    private var orDivider: some View {
        HStack(spacing: 12) {
            Rectangle().fill(ScreenSpec.Palette.separator).frame(height: 1)
            Text("OR")
                .figmaText(ScreenSpec.TypeScale.b12)
                .foregroundStyle(ScreenSpec.Palette.textMuted)
                .fixedSize()
            Rectangle().fill(ScreenSpec.Palette.separator).frame(height: 1)
        }
        .frame(height: 18)
    }

    // 779:22709 — Box
    private var linkBox: some View {
        HStack {
            Text(ScreenSpec.inviteLink)
                .figmaText(ScreenSpec.TypeScale.b14)
                .foregroundStyle(ScreenSpec.Palette.textPrimary)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 12)
            Image("ic_copy")
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .foregroundStyle(ScreenSpec.Palette.textPrimary)
        }
        .padding(.horizontal, 18)
        .frame(height: 52)
        .background(.white)
        .clipShape(Capsule())
        // 980:15994 — `inset 0 -3px 6px rgba(152,159,179,0.18)`, which reads as
        // the field being slightly dished. Drawn as a bottom-weighted inner
        // ramp; SwiftUI has no inner shadow.
        .overlay {
            Capsule()
                .fill(LinearGradient(
                    stops: [.init(color: .clear, location: 0.6),
                            .init(color: ScreenSpec.Palette.textMuted.opacity(0.18), location: 1)],
                    startPoint: .top, endPoint: .bottom))
                .allowsHitTesting(false)
        }
        .overlay { Capsule().strokeBorder(ScreenSpec.Palette.borderField, lineWidth: 1) }
    }

    // M-NeutralButton, H52
    private var shareButton: some View {
        Button {} label: {
            HStack(spacing: 8) {
                Image("ic_share")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
                Text("Share invite")
                    .figmaText(ScreenSpec.TypeScale.a16)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            // A vertical ramp, not the flat navy the old screen used, plus the
            // two inset shadows the component carries: a dark lip along the
            // bottom and a faint light one along the top.
            .background(
                LinearGradient(stops: [.init(color: ScreenSpec.Palette.buttonTop, location: 0.5),
                                       .init(color: ScreenSpec.Palette.buttonBottom, location: 1)],
                               startPoint: .top, endPoint: .bottom))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(LinearGradient(
                        stops: [.init(color: .white.opacity(0.18), location: 0),
                                .init(color: .clear, location: 0.22),
                                .init(color: .clear, location: 0.82),
                                .init(color: .black.opacity(0.55), location: 1)],
                        startPoint: .top, endPoint: .bottom))
                    .allowsHitTesting(false)
            }
        }
        .buttonStyle(.plain)
    }
}


/// Type with a thick outline behind it — the sticker treatment the invite
/// screen's headline carries.
///
/// The outline is a Figma *stroke* on the text node, and `get_design_context`
/// does not report those: the CSS it hands back has the drop shadow and the
/// gradient fill and no mention of the 4.8pt white ring that is the loudest
/// thing about the headline. It was measured off the render instead — a
/// vertical slice through the "I" puts 4.67pt of white above the glyph and 5
/// below.
///
/// SwiftUI has no text stroke, so it is drawn as copies of the glyphs offset
/// around a circle. One ring is not enough: at 4.8pt even twenty copies
/// scallop visibly where a letter curves away from the ring's centre, because
/// the union of discs at that radius is not a disc. Two rings — the outer at
/// the stroke width, an inner one at 55% of it — fill that in, and the
/// scalloping goes.
struct OutlinedText: View {
    let text: String
    var font: Font
    var tracking: CGFloat = 0
    var fill: LinearGradient
    var outline: (colour: Color, width: CGFloat)

    init(_ text: String, font: Font, tracking: CGFloat = 0,
         fill: LinearGradient, outline: (colour: Color, width: CGFloat)) {
        self.text = text
        self.font = font
        self.tracking = tracking
        self.fill = fill
        self.outline = outline
    }

    private static let rings: [(count: Int, scale: CGFloat)] = [(20, 1.0), (12, 0.55)]

    var body: some View {
        ZStack {
            ZStack {
                ForEach(Array(Self.rings.enumerated()), id: \.offset) { _, ring in
                    ForEach(0..<ring.count, id: \.self) { i in
                        let a = Double(i) / Double(ring.count) * 2 * .pi
                        base.foregroundStyle(outline.colour)
                            .offset(x: cos(a) * outline.width * ring.scale,
                                    y: sin(a) * outline.width * ring.scale)
                    }
                }
            }
            // One shadow for the whole ring, not one per copy — sixteen
            // stacked shadows read as a smudge.
            .compositingGroup()
            .shadow(color: .black.opacity(0.15), radius: 3.5, y: 1)

            base.foregroundStyle(fill)
        }
    }

    private var base: some View {
        Text(text).font(font).tracking(tracking).fixedSize()
    }
}


/// The profile QR screen, Figma `Share QR` (940:62757) — the parts outside the
/// card, which is all of two rectangles.
enum ProfileQRSpec {
    /// 940:63003.
    static let card = CGRect(x: 12, y: 54, width: 351, height: 656)
    /// 940:63622, inside `Frame 2147229647` at y 724 with its own 16pt inset.
    static let cta = CGRect(x: 16, y: 740, width: 343, height: 56)
    static let ctaTitle = "Share profile"
}
