import SwiftUI

/// The design's button — Figma `M-PrimaryButton` and `M-SecondaryButton` as
/// overridden in `Button design` (1088:18515): H52, 16pt continuous corners,
/// a flat fill, a 2pt gradient stroke and two inner shadows — with the
/// dome's press kept: raised at rest, sunk while held.
///
/// | | Rest — raised (the design, verbatim) | Pressed — pushed into the surface |
/// |---|---|---|
/// | face | the flat fill | a shade darker: less light reaches down there |
/// | top | a soft inner glow, 4pt down | a deep shadow cast over the face by the surface's edge, and a tight dark line where the face meets it |
/// | bottom | a dark inner shadow, 9pt up | a faint glow — light bounced off the far wall |
/// | edge | the 2pt stroke, light at the top | the stroke in shade at the top, still lit at the bottom |
/// | around | — | a soft dark well hugging the outline: the hole the button sits in |
/// | under | a soft page shadow and a tight contact shadow | both gone — nothing under it is lifted any more |
///
/// With the 0.98 scale and a 0.5pt drop (in `DomeButtonStyle`) the button
/// reads as moving *down*, through the surface, not just changing colour.
/// Figma's shadow sizes are CSS blurs, twice SwiftUI's radius, and are
/// halved where they are drawn.
struct DomeSurface: View {
    var pressed: Bool
    var duration: Double = 0.02
    var tune = SlabDomeTune()

    var body: some View {
        // Sized by whatever it is laid behind, so one surface serves every
        // button in the app; the shadows and the rim draw past its bounds.
        GeometryReader { geo in
            layers(W: geo.size.width, H: geo.size.height)
        }
        .animation(.easeInOut(duration: duration), value: pressed)
    }

    private func layers(W: CGFloat, H: CGFloat) -> some View {
        let h = H / 2
        let shape = RoundedRectangle(cornerRadius: tune.corner, style: .continuous)

        return ZStack {
            // The page shadow under the raised button. Gone when it sinks:
            // a button below the surface casts nothing onto it.
            shape.inset(by: -tune.shadowSpread * h)
                .fill(tune.shadow.color)
                .frame(width: W, height: H)
                .offset(y: tune.shadowDrop * h)
                .blur(radius: tune.shadowBlur * h)
                .opacity(pressed ? 0 : tune.shadowStrength)

            // The well: a soft dark ring hugging the outline, heavier along
            // the top — the edge of the hole the button has gone into.
            shape.inset(by: -tune.wellGrow)
                .fill(tune.well.color)
                .frame(width: W, height: H)
                .offset(y: -tune.wellRise)
                .blur(radius: tune.wellBlur)
                .opacity(pressed ? tune.wellStrength : 0)

            // The contact shadow under the raised button, gone when it sinks.
            shape.inset(by: tune.contactInset * h)
                .fill(tune.shadow.color)
                .frame(width: W, height: H)
                .offset(y: tune.contactDrop * h)
                .blur(radius: tune.contactBlur * h)
                .opacity(pressed ? 0 : tune.contact * tune.shadowStrength)

            // Crossfaded: each layer is the finished face, so the blend
            // between them is exact.
            ZStack {
                face(shape, sunk: false)
                face(shape, sunk: true)
                    .opacity(pressed ? 1 : 0)
            }
            .frame(width: W, height: H)

            // The pressed rim, over the edge and a little past it.
            crescent(shape, W: W, H: H, drop: tune.topRimDrop * h, blur: tune.topRimBlur * h,
                     colour: tune.rimLight, grow: tune.topRimGrow * h)
                // Kept to the top edge, fading down the corners and sides:
                // full to 12% of the height, gone by 42%. The mask is larger
                // than the button so the rim can reach past its edge, so its
                // stops are placed relative to where the button sits in it.
                .mask(LinearGradient(stops: [.init(color: .black, location: 0),
                                             .init(color: .black, location: (2 * h + 0.12 * H) / (H + 4 * h)),
                                             .init(color: .clear, location: (2 * h + 0.42 * H) / (H + 4 * h))],
                                     startPoint: .top, endPoint: .bottom)
                        .frame(width: W + 4 * h, height: H + 4 * h))
                .opacity(pressed ? tune.topRim : 0)
        }
        .frame(width: W, height: H)
    }

    /// The design's face, or — `sunk` — the face pushed into the surface.
    private func face(_ shape: RoundedRectangle, sunk: Bool) -> some View {
        let fill = sunk ? tune.sunkFill : tune.fill
        // The sunk face's top shadows — cast down from the top edge — scale
        // with `topShade`; the bounce light along the bottom does not.
        let shadows = sunk
            ? tune.sunkInner.map { $0.y > 0 ? SlabDomeTune.InnerShadow(color: $0.color.opacity(tune.topShade), y: $0.y, blur: $0.blur) : $0 }
            : [tune.innerTop, tune.innerBottom]
        let stroke = sunk && tune.strokeOnPress
                          ? [tune.sunkStrokeTop.color, tune.sunkStrokeBottom.color]
                          : [tune.strokeTop.color, tune.strokeBottom.color]
        var style = AnyShapeStyle(fill.color)
        for s in shadows {
            style = AnyShapeStyle(style.shadow(.inner(color: s.color.color, radius: s.blur / 2, y: s.y)))
        }
        // The fill stops halfway under the stroke. Filled to the edge, its
        // antialiased rim — darkened by the inner shadows — showed as a dark
        // hairline outside the light stroke, worst on the sunk face.
        return shape.inset(by: tune.strokeWidth / 2)
            .fill(style)
            .overlay {
                shape.strokeBorder(LinearGradient(colors: stroke, startPoint: .top, endPoint: .bottom),
                                   lineWidth: tune.strokeWidth)
            }
    }

    /// The shape minus a copy of itself shifted by `drop`, blurred: a band
    /// along the edge the shift points away from, fading out down the sides.
    private func crescent(_ shape: RoundedRectangle, W: CGFloat, H: CGFloat, drop: CGFloat,
                          blur: CGFloat, colour: RGBA, grow: CGFloat) -> some View {
        let s = shape.inset(by: -grow)
        return s.fill(colour.color)
            .frame(width: W, height: H)
            .overlay {
                s.frame(width: W, height: H)
                    .offset(y: drop)
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
            .blur(radius: blur)
            .mask(s.frame(width: W, height: H))
    }
}

/// The lab's button: a `DomeSurface` at the design's size with its label.
struct SlabDome<Label: View>: View {
    var pressed: Bool
    var duration: Double = 0.02
    var tune = SlabDomeTune()
    @ViewBuilder var label: Label

    var body: some View {
        let h = tune.size.height / 2
        DomeLabel(pressed: pressed, dim: tune.pressedLabel) { label }
            .frame(width: tune.size.width, height: tune.size.height)
            .background { DomeSurface(pressed: pressed, duration: duration, tune: tune) }
            .animation(.easeInOut(duration: duration), value: pressed)
            .frame(width: tune.size.width + 6 * h, height: tune.size.height + 6 * h)
    }
}

/// The label's side of the light: a little dimmer while the button is sunk.
/// The design's type is flat, so there is no shadow under it.
struct DomeLabel<Content: View>: View {
    var pressed: Bool
    var dim: Double = 0.9
    @ViewBuilder var content: Content

    var body: some View {
        content.opacity(pressed ? dim : 1)
    }
}

/// The drop shadow's strength and the press scale for every primary button in
/// the app — one value each, so a slider moves them all at once. The drop
/// shadow is 0: the design draws the button at rest with none, and the rest
/// state follows the design exactly. `-buttonShadow 0.3` sets it at launch.
@MainActor
final class DomeShadow: ObservableObject {
    static let shared = DomeShadow()
    @Published var strength: Double = 0
    /// How far the button shrinks while held: 0.98 is 2% smaller.
    /// `-buttonPress 0.95` sets it at launch.
    @Published var pressScale: Double = 0.98
    /// How much the scale springs past its target, on the way down and on
    /// the way back up: 0 settles without overshoot, 0.55 dips a little
    /// below the held size and pops a little past full size on release.
    /// `-buttonBounce 0.7` sets it at launch.
    @Published var pressBounce: Double = 0.06
    /// The scale spring's response: how long one swing takes.
    @Published var pressResponse: Double = 0.2
    /// How far the button drops while held, in points — with the scale, the
    /// move that makes it read as going *down* into the surface.
    @Published var pressDepth: Double = 0.5
    /// The sunk face's top shade, 0 to 1 — see `SlabDomeTune.topShade`.
    /// `-buttonTopShade 0.5` sets it at launch.
    @Published var topShade: Double = 1
    /// The same, for the white button: its cool-grey shade read heavy
    /// against the white face at full strength. `-buttonWhiteTopShade 0.4`
    /// sets it at launch.
    @Published var whiteTopShade: Double = 0.6
    /// The well round the sunk button, 0 (off) to 1 — see
    /// `SlabDomeTune.wellStrength`. `-buttonWell 0.5` sets it at launch.
    @Published var well: Double = 0
    /// Whether the stroke changes colour while held — see
    /// `SlabDomeTune.strokeOnPress`. `-buttonStrokeChange 0` turns it off.
    @Published var strokeChange = false

    static let defaults = (scale: 0.98, bounce: 0.06, response: 0.2)

    /// The press's scale spring — bounce is one minus the damping fraction.
    var pressSpring: Animation {
        .spring(response: pressResponse, dampingFraction: max(0.12, 1 - pressBounce))
    }

    func resetPress() {
        pressDepth = 0.5; topShade = 1; whiteTopShade = 0.6; well = 0; strokeChange = false
        pressScale = Self.defaults.scale
        pressBounce = Self.defaults.bounce
        pressResponse = Self.defaults.response
    }

    private init() {
        let a = ProcessInfo.processInfo.arguments
        if let i = a.firstIndex(of: "-buttonShadow"), i + 1 < a.count, let v = Double(a[i + 1]) { strength = v }
        if let i = a.firstIndex(of: "-buttonPress"), i + 1 < a.count, let v = Double(a[i + 1]) { pressScale = v }
        if let i = a.firstIndex(of: "-buttonBounce"), i + 1 < a.count, let v = Double(a[i + 1]) { pressBounce = v }
        if let i = a.firstIndex(of: "-buttonTopShade"), i + 1 < a.count, let v = Double(a[i + 1]) { topShade = v }
        if let i = a.firstIndex(of: "-buttonWhiteTopShade"), i + 1 < a.count, let v = Double(a[i + 1]) { whiteTopShade = v }
        if let i = a.firstIndex(of: "-buttonWell"), i + 1 < a.count, let v = Double(a[i + 1]) { well = v }
        if let i = a.firstIndex(of: "-buttonStrokeChange"), i + 1 < a.count, let v = Double(a[i + 1]) { strokeChange = v != 0 }
    }
}

/// **The app's primary button** — the Button lab's variant 3: dark is
/// `M-PrimaryButton` from `2nd variant` (1105:19282), both states as drawn —
/// see `GlassSurface`; `.light` is `M-SecondaryButton` from `Button design`
/// (1088:18515), raised at rest and sunk while held — see `DomeSurface`.
/// The press, shared by both:
///
/// | | |
/// |---|---|
/// | scale while held | 0.98× and 0.5pt down — pressed *into* the page — spring 0.2s, bounce 0.06 |
/// | light change | 20ms each way |
/// | shine | off — a lit top edge fights the shade the sunk face is under |
/// | haptic | Impact · Heavy at 1.0 on press, a light tap at 0.4 on release |
/// | drop shadow | none — the design has none at rest; live, from `DomeShadow` |
/// | stroke | dark: the 2nd variant's pressed stroke; white: keeps its rest colours |
///
/// Apply it to a label that is already the button's size — the surface fills
/// whatever it is drawn behind. Disabled, it draws nothing, so a disabled
/// button keeps whatever flat look its label gives it.
///
/// `.light` is for the secondary action beside a primary — Back, Edit —
/// with dark type.
struct DomeButtonStyle: ButtonStyle {
    var corner: CGFloat = 16
    var variant: Variant = .dark

    enum Variant { case dark, light }

    static let settings: SlabDomeTune = {
        var t = SlabDomeTune()
        t.topRim = 0
        t.topRimDrop *= 0.47
        return t
    }()
    static let lightSettings: SlabDomeTune = {
        var t = SlabDomeTune.light
        t.topRim = 0
        t.topRimDrop *= 0.47
        return t
    }()
    static let duration: Double = 0.02

    func makeBody(configuration: Configuration) -> some View {
        DomeButtonBody(configuration: configuration, corner: corner, variant: variant)
    }
}

private struct DomeButtonBody: View {
    let configuration: ButtonStyle.Configuration
    let corner: CGFloat
    let variant: DomeButtonStyle.Variant
    @ObservedObject private var shadow = DomeShadow.shared
    @Environment(\.isEnabled) private var isEnabled
    /// `-pressHeld` pins the pressed look, for screenshots.
    private static let pinned = ProcessInfo.processInfo.arguments.contains("-pressHeld")

    var body: some View {
        let down = (configuration.isPressed || Self.pinned) && isEnabled
        var tune = variant == .light ? DomeButtonStyle.lightSettings : DomeButtonStyle.settings
        tune.corner = corner
        tune.shadowStrength = shadow.strength * (variant == .light ? 0.55 : 1)
        tune.topShade = variant == .light ? shadow.whiteTopShade : shadow.topShade
        tune.wellStrength = shadow.well
        tune.strokeOnPress = shadow.strokeChange
        // Variant 3, picked in the Button lab: the dark button is the 2nd
        // variant's (`GlassSurface`, label at full strength, as drawn), the
        // white one stays the 1st's.
        let dark = variant == .dark
        var glass = GlassTune.dark
        glass.corner = corner
        return DomeLabel(pressed: down, dim: isEnabled && !dark ? tune.pressedLabel : 1) {
            configuration.label
        }
        .animation(.easeInOut(duration: DomeButtonStyle.duration), value: down)
        .background {
            if isEnabled {
                if dark {
                    GlassSurface(pressed: down, duration: DomeButtonStyle.duration, tune: glass)
                } else {
                    DomeSurface(pressed: down, duration: DomeButtonStyle.duration, tune: tune)
                }
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .offset(y: down ? CGFloat(shadow.pressDepth) : 0)
        .scaleEffect(down ? CGFloat(shadow.pressScale) : 1)
        .animation(shadow.pressSpring, value: down)
        .onChange(of: configuration.isPressed) { _, pressed in
            guard isEnabled else { return }
            if pressed { PressHaptics.flow.pressDown() } else { PressHaptics.flow.pressUp() }
        }
    }
}

/// The button's numbers. Colours, stroke and inner shadows are the Figma
/// overrides verbatim; the shadows under it and the pressed rim are the
/// dome's, in units of the half-height.
struct SlabDomeTune: Equatable {
    var size = CGSize(width: 327, height: 52)
    var corner: CGFloat = 16

    var fill = RGBA(0x212121)
    /// The 2pt inside stroke, top to bottom.
    var strokeWidth: CGFloat = 2
    var strokeTop = RGBA(0xEFEFEF)
    var strokeBottom = RGBA(0xD2D2D2)
    /// The design's two inner shadows; `blur` is Figma's, a CSS blur.
    var innerTop = InnerShadow(color: RGBA(0xD2D2D2, 0.4), y: 4, blur: 8)
    var innerBottom = InnerShadow(color: RGBA(0x000000), y: -9, blur: 9)

    struct InnerShadow: Equatable {
        var color: RGBA
        var y: CGFloat
        var blur: CGFloat
    }

    /// Pressed — pushed into the surface. Not in Figma; built from its colours.
    var sunkFill = RGBA(0x1A1A1A)
    var sunkStrokeTop = RGBA(0x2E2E2E)
    var sunkStrokeBottom = RGBA(0xD2D2D2)
    var sunkInner: [InnerShadow] = [
        // The surface's edge shading the face, deep and wide.
        InnerShadow(color: RGBA(0x000000, 0.95), y: 7, blur: 14),
        // The tight dark line where the face meets that edge.
        InnerShadow(color: RGBA(0x000000, 0.7), y: 2, blur: 3),
        // Light bounced off the far wall, faint along the bottom.
        InnerShadow(color: RGBA(0xD2D2D2, 0.35), y: -3, blur: 6),
    ]
    /// Scales the sunk face's shade along its top: 1 the designed depth, 0
    /// none — then the press is the border, the bounce light and the drop.
    var topShade: Double = 1
    /// Whether the 2pt stroke takes its pressed colours. Off, it keeps the
    /// rest gradient while held — a stroke that changes can read as the
    /// button's outline, and so its size, changing.
    var strokeOnPress = false
    /// The dark well round the sunk button; `wellStrength` scales it, and it
    /// is off by default — on a white card it reads as a smudge above the
    /// button rather than as the edge of a hole.
    var wellStrength: Double = 0
    var well = RGBA(0x000000, 0.22)
    var wellGrow: CGFloat = 1.5
    var wellRise: CGFloat = 0.75
    var wellBlur: CGFloat = 1.5

    /// The pressed catch-light along the top edge.
    var rimLight = RGBA(0xFFFFFF)

    var shadow = RGBA(0x0E0E0E, 0.72)
    /// Scales the page and contact shadows together; 1 is the replica's.
    var shadowStrength: Double = 1
    var shadowSpread: CGFloat = 0.06
    var shadowDrop: CGFloat = 0.197
    var shadowBlur: CGFloat = 0.134
    var contact: Double = 0.9
    var contactInset: CGFloat = 0.03
    var contactDrop: CGFloat = 0.075
    var contactBlur: CGFloat = 0.04

    var topRim: Double = 1.0
    var topRimBlur: CGFloat = 0.07
    var topRimDrop: CGFloat = 0.24
    var topRimGrow: CGFloat = 0.03

    var pressedLabel: Double = 0.9

    /// `M-SecondaryButton`: white, a white-to-#DBDFE6 stroke and two cool
    /// grey inner shadows. The page shadow is a cool grey rather than
    /// near-black, or a white button on a white page reads as a hole.
    static let light: SlabDomeTune = {
        var t = SlabDomeTune()
        t.fill = RGBA(0xFFFFFF)
        t.strokeTop = RGBA(0xFFFFFF)
        t.strokeBottom = RGBA(0xDBDFE6)
        t.innerTop = InnerShadow(color: RGBA(0x989FB3, 0.10), y: 4, blur: 4)
        t.innerBottom = InnerShadow(color: RGBA(0x989FB3, 0.22), y: -6, blur: 6)
        t.sunkFill = RGBA(0xF3F4F7)
        t.sunkStrokeTop = RGBA(0xC9CED9)
        t.sunkStrokeBottom = RGBA(0xFFFFFF)
        // No deep edge shade on white — dropped in Figma (`dev -> design`,
        // 1096:19130): over the white face it read as a grey band. The
        // contact line alone carries the edge.
        t.sunkInner = [
            InnerShadow(color: RGBA(0x989FB3, 0.35), y: 1.5, blur: 3),
            InnerShadow(color: RGBA(0xFFFFFF, 1), y: -3, blur: 6),
        ]
        t.well = RGBA(0x5B6378, 0.18)
        t.shadow = RGBA(0x5B6378, 0.55)
        t.pressedLabel = 0.8
        return t
    }()
}
