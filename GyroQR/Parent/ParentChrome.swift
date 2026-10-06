import SwiftUI
import Lottie

// The pieces every page of the parent flow is built from, measured off
// frame 1 (1015:44811) — the others repeat them to the point.

/// A page laid out at the design's 375 × 812 and scaled to fill the device,
/// like every other screen in the app. The device draws its own status bar
/// and home indicator, so the design's are not.
struct ParentStage<Content: View>: View {
    /// Off for a layer over the pages, like the progress bar.
    var background = true
    @ViewBuilder var content: Content

    var body: some View {
        GeometryReader { geo in
            let scale = max(geo.size.width / ParentSpec.size.width,
                            geo.size.height / ParentSpec.size.height)
            ZStack(alignment: .topLeading) {
                if background { ParentSpec.C.surface }
                content
            }
            .frame(width: ParentSpec.size.width, height: ParentSpec.size.height, alignment: .topLeading)
            .scaleEffect(scale, anchor: .center)
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .ignoresSafeArea()
    }
}

/// `Background Image` (1015:44812): 375 × 235 of lilac with the shapes art
/// and a white wash from 61% down so it fades into the page. One 3× export
/// of the node rather than rebuilt: the shapes are an SVG with a blur filter,
/// which Xcode's SVG renderer drops.
struct ParentHeaderBackground: View {
    var body: some View {
        Image("parent_header_bg")
            .resizable()
            .frame(width: 375, height: 235)
            .allowsHitTesting(false)
    }
}

/// The progress bar from `header stack` (1015:44820): 72 × 4, on the
/// screen's centre line 28pt into the 56pt stack under the status bar. The
/// design pairs it with a close button; the flow has Back wherever there is
/// somewhere to go back to, so the bar stands alone — and it sits above the
/// pages rather than in them, so it stays put and fills while they fade.
struct ParentProgressBar: View {
    var progress: CGFloat
    /// White on the purple header; on a light page (the intro's stars)
    /// white would vanish, so there it takes the header's purple instead.
    var onLight = false

    var body: some View {
        ZStack(alignment: .leading) {
            Capsule().fill(onLight ? ParentSpec.C.selectedStroke.opacity(0.16) : .white.opacity(0.4))
            Capsule().fill(onLight ? ParentSpec.C.selectedStroke : .white).frame(width: 72 * progress)
        }
        .frame(width: 72, height: 4)
        .animation(ParentSpec.spring, value: progress)
        .animation(ParentSpec.fade, value: onLight)
        .frame(width: 375)
        // The design sets it 2pt right of centre, in what the close button
        // left; with the close button gone it sits on the centre line.
        .offset(y: 47 + 26)
    }
}

/// The flow's progress bar drawn by a page, under its overlay, while the
/// flow's own is hidden — see `ParentModel.overlay`. The same bar at the same
/// place, so the hand-over does not show.
///
/// Fixed to the page that draws it. It used to read the page off the flow's
/// stack, which meant that the moment a move began, the *leaving* page's bar
/// switched to the next page's fill and animated towards it — a change
/// inside a view in the middle of its removal transition, and that froze the
/// push: both pages stuck at their start positions, the new one off-screen.
struct ParentOverlayBar: View {
    @EnvironmentObject private var model: ParentModel
    let page: ParentPage

    var body: some View {
        ParentProgressBar(progress: page.progress, onLight: page == .intro)
            .opacity(model.overlay ? 1 : 0)
            .allowsHitTesting(false)
    }
}

/// `Header` (1015:44827): the page's art, overlapped 48pt by an ExtraBold
/// title with a gradient in it, and one line of subtitle — 155 tall from y 103.
struct ParentTitleHeader<Art: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var art: Art

    var body: some View {
        VStack(spacing: 0) {
            art
                .frame(width: 235, height: 125)
                .padding(.bottom, -48)
                .zIndex(0)
            VStack(spacing: 2) {
                ParentGradientTitle(text: title)
                Text(subtitle)
                    .parentType(ParentSpec.T.b14m)
                    .foregroundStyle(ParentSpec.C.textSecondary)
                    .truncationMode(.tail)
                    .frame(width: 311.28)
            }
            .zIndex(1)
        }
        .padding(.bottom, 8)
        .frame(width: 374)
        .offset(x: -0.5, y: 103)
    }
}

/// A gradient headline with the design's white sticker outline.
///
/// `linear-gradient(<angle>, #000 52.8%, #7924FF 104.2%)` over the whole text
/// box, masked by the type — so the letters show the box's gradient, not one
/// stretched to each word — on a white outline round the glyphs, and a soft
/// shadow under the lot. The outline is not in the design context (Figma
/// text strokes do not come through it); measured off the renders it is
/// 4.5–5pt on the 40pt titles, the same 4.8 as the invite headline, drawn
/// the same way: two rings of offset copies, since one ring scallops.
struct ParentGradientTitle: View {
    let text: String
    var style = ParentSpec.T.h40
    var width: CGFloat = 374
    var angle: Double = 28.681
    var outline: CGFloat = 4.8
    var shadow: (radius: CGFloat, y: CGFloat) = (3.5, 1)
    /// The gradient's colour at 100%. The design ends it past the box —
    /// #7924FF at 104.2% — so what the box shows is the colour there.
    var endColor = Color(hex: 0x6F21EA)

    private static let rings: [(count: Int, scale: CGFloat)] = [(20, 1.0), (12, 0.55)]

    var body: some View {
        let h = style.line
        // A CSS angle is measured from "to top", clockwise; the gradient line
        // runs through the centre and is long enough to reach the corners.
        let a = angle * .pi / 180
        let dir = CGPoint(x: sin(a), y: -cos(a))
        let len = abs(width * sin(a)) + abs(h * cos(a))
        let start = UnitPoint(x: 0.5 - dir.x * len / 2 / width, y: 0.5 - dir.y * len / 2 / h)
        let end = UnitPoint(x: 0.5 + dir.x * len / 2 / width, y: 0.5 + dir.y * len / 2 / h)
        return ZStack {
            ZStack {
                ForEach(Array(Self.rings.enumerated()), id: \.offset) { _, ring in
                    ForEach(0..<ring.count, id: \.self) { i in
                        let t = Double(i) / Double(ring.count) * 2 * .pi
                        glyphs.foregroundStyle(.white)
                            .offset(x: cos(t) * outline * ring.scale, y: sin(t) * outline * ring.scale)
                    }
                }
            }
            .compositingGroup()
            .shadow(color: .black.opacity(0.15), radius: shadow.radius, x: 0, y: shadow.y)

            LinearGradient(stops: [
                .init(color: .black, location: 0.52835),
                // #7924FF sits at 104.2%, past the end: its colour at 100%.
                .init(color: endColor, location: 1),
            ], startPoint: start, endPoint: end)
            .frame(width: width, height: h)
            .mask { glyphs }
        }
        .frame(width: width, height: h)
    }

    private var glyphs: some View {
        Text(text)
            .parentType(style)
            .fixedSize()
            .frame(width: width, height: style.line)
    }
}

/// A dotLottie in the header's art slot, played once on appear.
struct ParentLottie: View {
    let name: String
    /// The Lottie's canvas in points — its 2× pixel size halved.
    let size: CGSize
    /// Where its canvas's top-left sits, relative to the 235 × 125 art box.
    let origin: CGPoint

    /// `-parentNoArt` hides the header Lotties, so a screenshot with and one
    /// without isolate the Lottie's own pixels for calibrating `origin`.
    private static let hidden = ProcessInfo.processInfo.arguments.contains("-parentNoArt")

    var body: some View {
        LottieView { try await DotLottieFile.named(name) }
            .playing(loopMode: .playOnce)
            .resizable()
            .frame(width: size.width, height: size.height)
            .offset(x: origin.x + size.width / 2 - 235 / 2,
                    y: origin.y + size.height / 2 - 125 / 2)
            .frame(width: 235, height: 125)
            .opacity(Self.hidden ? 0 : 1)
            .allowsHitTesting(false)
    }
}

/// `M-StackedActionBar` in its white tray: 12 all round, 52pt buttons, and
/// the 24pt home-bar strip under them — 100 tall for one row, at the page's
/// foot. The tray casts the design's stack of soft upward shadows onto the
/// page behind it.
///
/// While the keyboard is up the bar rides its top edge instead — the row
/// alone, no home strip — as frames 3 and 8 draw it, on every page: a field
/// anywhere in the flow would otherwise put the keyboard over the button
/// that moves on.
struct ParentActionBar<Buttons: View>: View {
    @ObservedObject private var keyboard = ParentKeyboard.shared
    @ViewBuilder var buttons: Buttons

    var body: some View {
        let onKeyboard = keyboard.top != nil
        VStack(spacing: 0) {
            buttons.padding(12)
            if !onKeyboard { Color.white.frame(height: 24) }
        }
        .frame(width: 375)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20, style: .continuous)
                .fill(.white)
                .shadow(color: Color(hex: 0xE0E0E0).opacity(0.10), radius: 3.75, y: -7)
                .shadow(color: Color(hex: 0xE0E0E0).opacity(0.09), radius: 6.75, y: -27)
                .shadow(color: Color(hex: 0xE0E0E0).opacity(0.05), radius: 9, y: -60)
                .shadow(color: Color(hex: 0xE0E0E0).opacity(0.01), radius: 10.75, y: -107)
        }
        .offset(y: keyboard.top.map { $0 - 76 } ?? 712)
    }
}

/// The app's primary button, at the bar's 52pt.
struct ParentPrimaryButton: View {
    let title: String
    var enabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .parentType(ParentSpec.T.a16)
                .foregroundStyle(enabled ? .white : ParentSpec.C.textTertiary)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(enabled ? .clear : ParentSpec.C.field,
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(DomeButtonStyle())
        .disabled(!enabled)
    }
}

/// A 56pt field box: `#F5F7FA`, 12 corners, a small label over its value.
struct ParentFieldBox<Value: View>: View {
    let label: String
    var focused = false
    @ViewBuilder var value: Value

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .parentType(ParentSpec.T.b12r)
                .foregroundStyle(ParentSpec.C.textTertiary)
            value
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .frame(height: 56)
        .background(focused ? ParentSpec.C.surface : ParentSpec.C.field,
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .animation(ParentSpec.spring, value: focused)
        .parentFocusRing(focused)
    }
}

/// A field taking focus: a 1.5pt purple ring closes in on the box with a
/// faint purple lift under it (the box itself turns white — its own fill), on the flow's spring — enough to see where the
/// cursor went, not so much that the page jumps.
struct ParentFocusRing: ViewModifier {
    let focused: Bool
    var corner: CGFloat = 12

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: corner, style: .continuous)
        return content
            .overlay {
                shape.strokeBorder(ParentSpec.C.selectedStroke, lineWidth: 1.5)
                    .opacity(focused ? 1 : 0)
                    .scaleEffect(focused ? 1 : 1.03)
            }
            .shadow(color: ParentSpec.C.selectedStroke.opacity(focused ? 0.16 : 0), radius: 8, y: 3)
            .animation(ParentSpec.spring, value: focused)
    }
}

extension View {
    func parentFocusRing(_ focused: Bool, corner: CGFloat = 12) -> some View {
        modifier(ParentFocusRing(focused: focused, corner: corner))
    }
}

/// A section's heading: `B16/SemiBold`, 4pt in from the fields under it.
struct ParentSectionTitle: View {
    let text: String
    var body: some View {
        Text(text)
            .parentType(ParentSpec.T.b16s)
            .foregroundStyle(ParentSpec.C.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
    }
}

/// `M-RowActionBar` — Back and a primary, side by side, in the action bar.
struct ParentRowActions: View {
    var back = "Back"
    let onBack: () -> Void
    let primary: String
    var enabled = true
    let onPrimary: () -> Void

    var body: some View {
        ParentActionBar {
            HStack(spacing: 12) {
                ParentSecondaryButton(title: back, action: onBack)
                ParentPrimaryButton(title: primary, enabled: enabled, action: onPrimary)
            }
        }
    }
}
