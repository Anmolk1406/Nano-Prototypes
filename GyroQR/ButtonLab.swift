import SwiftUI
import CoreHaptics

/// A test bench for one button: Figma `Button` (1005:41915), the
/// `M-NeutralButton` alone on the page, laid out at the design's 375 × 812.
///
/// On a press: a **strong haptic** the moment the finger lands, and the
/// button's look changes over 80ms and changes back on release. Two looks to
/// compare, picked in the controls sheet:
///
/// * **Push in** — the reference recording, a glossy red dome. At rest it is
///   *raised*: lit from above, a coral bloom across its top, deep maroon at
///   its foot, and a soft shadow on the page below it. Pressed it is *sunk*:
///   the drop shadow collapses to a tight dark ring round the edge, the lip
///   of the hole throws a heavy blurred shadow across the top of the face,
///   and the face below lights up — brighter, not darker, than at rest,
///   which is most of why it reads as pressed in and not just flipped.
/// * **Lift** — the first brief: grows 3% under the finger, and the fill and
///   its gradient stroke swap ends.
struct ButtonLabScreen: View {
    @ObservedObject var tune: ButtonLabTuning

    var body: some View {
        switch tune.style {
        case .round: round
        case .slab: stage(SlabPress(tune: tune))
        case .lift: stage(NeutralPress(tune: tune))
        }
    }

    /// The reference's own button, at the reference's own size — real
    /// points, not the 375 stage, since the recording is a phone at 3×.
    private var round: some View {
        ZStack {
            RGBA(0xEFE2D8).color
            Button { tune.presses += 1 } label: { Color.clear }
                .buttonStyle(RoundPress(tune: tune))
        }
        .ignoresSafeArea()
        .onAppear { tune.haptics.prepare() }
    }

    /// The design's button on the design's 375 × 812 stage — for Continue,
    /// the primary and its white secondary one above the other, as the
    /// parent flow's confirm sheet pairs them.
    private func stage<S: ButtonStyle>(_ style: S) -> some View {
        GeometryReader { geo in
            let scale = max(geo.size.width / 375, geo.size.height / 812)
            ZStack {
                ButtonLabSpec.page
                if tune.style == .slab {
                    VStack(spacing: 28) {
                        section("Variant 1 \u{00B7} 1088:18515") { variantOne(style) }
                        section("Variant 2 \u{00B7} 1105:19282") { variantTwo }
                        section("Variant 3 \u{00B7} dark of 2, white of 1") { variantThree }
                    }
                } else {
                    labButton("Continue", style: style)
                }
            }
            .frame(width: 375, height: 812)
            .scaleEffect(scale, anchor: .center)
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .ignoresSafeArea()
        .onAppear { tune.haptics.prepare() }
    }

    /// One section of the Continue stage: a caption over the design's card.
    private func section<C: View>(_ title: String, @ViewBuilder _ card: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(NoonFont.f(.semibold, 12))
                .foregroundStyle(Color(hex: 0x8A8A8A))
                .padding(.leading, 4)
            card()
                .frame(width: ButtonLabSpec.card.width, height: ButtonLabSpec.card.height)
        }
    }

    /// The first variant: `Button design`'s white card, the pressed state
    /// built here. Its buttons are laid out in frames 3 half-heights larger
    /// on every side, for their shadows — hence the negative spacing.
    private func variantOne<S: ButtonStyle>(_ style: S) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: ButtonLabSpec.cardCorner, style: .continuous)
                .fill(.white)
                .frame(width: ButtonLabSpec.card.width, height: ButtonLabSpec.card.height)
                .shadow(color: .black.opacity(0.12), radius: 8, y: -2)
            VStack(spacing: ButtonLabSpec.gap - 3 * ButtonLabSpec.size.height) {
                labButton("Yes, use this email", style: style)
                labButton("Edit email", style: SlabPress(tune: tune, light: true))
                    .foregroundStyle(ButtonLabSpec.ink)
            }
        }
    }

    /// The second variant: `2nd variant`, both states the designer's own,
    /// on the same white card as the first. The press moves with the first's.
    private var variantTwo: some View {
        ZStack {
            RoundedRectangle(cornerRadius: ButtonLabSpec.cardCorner, style: .continuous)
                .fill(.white)
                .frame(width: ButtonLabSpec.card.width, height: ButtonLabSpec.card.height)
                .shadow(color: .black.opacity(0.12), radius: 8, y: -2)
            VStack(spacing: ButtonLabSpec.gap) {
                labButton("Yes, use this email", style: GlassPress(tune: tune, glass: .dark))
                    .foregroundStyle(.white)
                labButton("Edit email", style: GlassPress(tune: tune, glass: .light))
                    .foregroundStyle(ButtonLabSpec.ink)
            }
        }
    }

    /// The third: variant 2's dark button over variant 1's white one. The
    /// white one's frame is 3 half-heights larger on every side, for its
    /// shadows, so it is laid out at the button's own size and draws past it.
    private var variantThree: some View {
        ZStack {
            RoundedRectangle(cornerRadius: ButtonLabSpec.cardCorner, style: .continuous)
                .fill(.white)
                .frame(width: ButtonLabSpec.card.width, height: ButtonLabSpec.card.height)
                .shadow(color: .black.opacity(0.12), radius: 8, y: -2)
            VStack(spacing: ButtonLabSpec.gap) {
                labButton("Yes, use this email", style: GlassPress(tune: tune, glass: .dark))
                    .foregroundStyle(.white)
                labButton("Edit email", style: SlabPress(tune: tune, light: true))
                    .foregroundStyle(ButtonLabSpec.ink)
                    .frame(width: ButtonLabSpec.size.width, height: ButtonLabSpec.size.height)
            }
        }
    }

    private func labButton<S: ButtonStyle>(_ title: String, style: S) -> some View {
        Button { tune.presses += 1 } label: {
            Text(title)
                .font(NoonFont.f(.semibold, 16))
                .tracking(0)
                .frame(width: ButtonLabSpec.size.width,
                       height: ButtonLabSpec.size.height)
        }
        .buttonStyle(style)
    }
}

/// The design's numbers, verbatim from the node (read through the plugin API,
/// because the CSS export flattens the stroke's gradient to one grey).
enum ButtonLabSpec {
    static let page = Color(hex: 0xF7F7F7)
    static let size = CGSize(width: 327, height: 52)
    static let corner: CGFloat = 16
    /// The white card round the pair: 12pt padding, 16pt corners, a soft
    /// shadow cast upward — `Button design` (1088:18515).
    static let card = CGSize(width: 351, height: 140)
    static let cardCorner: CGFloat = 16
    /// Between the primary and the white one.
    static let gap: CGFloat = 12
    /// The white button's type — the parent flow's, where it is used.
    static let ink = ParentSpec.C.textPrimary

    static let fillTop = Color(hex: 0x212121)
    static let fillBottom = Color(hex: 0x0D0D0D)
    /// The fill's gradient starts halfway down and ends 3% past the bottom —
    /// its transform maps t = 0 to y = 0.5 and t = 1 to y = 1.0309.
    static func fill(flipped: Bool) -> LinearGradient {
        LinearGradient(colors: flipped ? [fillBottom, fillTop] : [fillTop, fillBottom],
                       startPoint: UnitPoint(x: 0.5, y: 0.5),
                       endPoint: UnitPoint(x: 0.5, y: 1.0309))
    }

    /// The 1pt inside stroke, top to bottom over the full height.
    static let rimTop = Color(white: 0.8795)       // #E0E0E0
    static let rimBottom = Color(white: 0.3402)    // #575757
    static func rim(flipped: Bool) -> LinearGradient {
        LinearGradient(colors: flipped ? [rimBottom, rimTop] : [rimTop, rimBottom],
                       startPoint: .top, endPoint: .bottom)
    }
}

// MARK: colour

/// A colour that can be mixed per frame. SwiftUI's `Color` cannot be read
/// back into components cheaply, and the push-in blends a dozen of them on
/// every frame of the press.
struct RGBA: Equatable {
    var r, g, b, a: Double
    init(_ hex: UInt32, _ a: Double = 1) {
        r = Double((hex >> 16) & 0xFF) / 255; g = Double((hex >> 8) & 0xFF) / 255
        b = Double(hex & 0xFF) / 255; self.a = a
    }
    init(r: Double, g: Double, b: Double, a: Double) { self.r = r; self.g = g; self.b = b; self.a = a }
    var color: Color { Color(.sRGB, red: r, green: g, blue: b, opacity: a) }
    func mix(_ o: RGBA, _ t: Double) -> RGBA {
        RGBA(r: r + (o.r - r) * t, g: g + (o.g - g) * t, b: b + (o.b - b) * t, a: a + (o.a - a) * t)
    }
    func opacity(_ k: Double) -> RGBA { RGBA(r: r, g: g, b: b, a: a * k) }
}

/// The round replica's press: the dome's two faces, the haptic, and scale
/// if any is asked for — the reference has none.
private struct RoundPress: ButtonStyle {
    @ObservedObject var tune: ButtonLabTuning
    private static let pinned = ProcessInfo.processInfo.arguments.contains("-pressHeld")

    func makeBody(configuration: Configuration) -> some View {
        let down = configuration.isPressed || Self.pinned
        var dome = RoundDomeTune()
        dome.topRim = tune.shine
        dome.topRimDrop *= tune.shineWidth
        return RoundDome(pressed: down && tune.flipEnabled, duration: tune.flipDuration, tune: dome)
            .contentShape(Circle().scale(0.66))
            .scaleEffect(down ? tune.pressScale : 1)
            .animation(.spring(response: tune.springResponse,
                               dampingFraction: tune.springDamping), value: down)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed { tune.haptics.pressDown() } else { tune.haptics.pressUp() }
            }
    }
}

/// The design's button with the round replica's light — see `SlabDome` —
/// dark, or in white with `light`. Its scale is the app's own, shared with
/// every button: shrinks while held and springs with the shared bounce.
private struct SlabPress: ButtonStyle {
    @ObservedObject var tune: ButtonLabTuning
    var light = false
    @ObservedObject var shadow = DomeShadow.shared
    private static let pinned = ProcessInfo.processInfo.arguments.contains("-pressHeld")

    func makeBody(configuration: Configuration) -> some View {
        let down = configuration.isPressed || Self.pinned
        var slab = light ? SlabDomeTune.light : SlabDomeTune()
        slab.shadowStrength = shadow.strength * (light ? 0.55 : 1)
        slab.topShade = light ? shadow.whiteTopShade : shadow.topShade
        slab.wellStrength = shadow.well
        slab.strokeOnPress = shadow.strokeChange
        slab.topRim = tune.shine
        slab.topRimDrop *= tune.shineWidth
        return SlabDome(pressed: down && tune.flipEnabled, duration: tune.flipDuration,
                        tune: slab) {
            configuration.label
        }
        .contentShape(RoundedRectangle(cornerRadius: ButtonLabSpec.corner, style: .continuous)
            .size(ButtonLabSpec.size)
            .offset(x: 3 * ButtonLabSpec.size.height / 2, y: 3 * ButtonLabSpec.size.height / 2))
        .offset(y: down ? shadow.pressDepth : 0)
        .scaleEffect(down ? shadow.pressScale : 1)
        .animation(shadow.pressSpring, value: down)
        .onChange(of: configuration.isPressed) { _, pressed in
            if pressed { tune.haptics.pressDown() } else { tune.haptics.pressUp() }
        }
    }
}

/// The second variant's press: the same motion as `SlabPress` — the shared
/// scale, spring and depth, the lab's light-change duration and haptic —
/// between the design's two faces.
private struct GlassPress: ButtonStyle {
    @ObservedObject var tune: ButtonLabTuning
    var glass: GlassTune
    @ObservedObject var shadow = DomeShadow.shared
    private static let pinned = ProcessInfo.processInfo.arguments.contains("-pressHeld")

    func makeBody(configuration: Configuration) -> some View {
        let down = configuration.isPressed || Self.pinned
        return configuration.label
            .background {
                GlassSurface(pressed: down && tune.flipEnabled, duration: tune.flipDuration, tune: glass)
            }
            .contentShape(RoundedRectangle(cornerRadius: glass.corner, style: .continuous))
            .offset(y: down ? shadow.pressDepth : 0)
            .scaleEffect(down ? shadow.pressScale : 1)
            .animation(shadow.pressSpring, value: down)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed { tune.haptics.pressDown() } else { tune.haptics.pressUp() }
            }
    }
}

/// The press. A `ButtonStyle` because `isPressed` arrives on touch-down,
/// which is where the haptic and the change of light both belong.
private struct NeutralPress: ButtonStyle {
    @ObservedObject var tune: ButtonLabTuning

    /// `-pressHeld` pins the pressed look, for screenshots — the Simulator
    /// cannot script a touch that is still down.
    private static let pinned = ProcessInfo.processInfo.arguments.contains("-pressHeld")

    func makeBody(configuration: Configuration) -> some View {
        let down = configuration.isPressed || Self.pinned
        let flip = down && tune.flipEnabled
        let curve = Animation.easeInOut(duration: tune.flipDuration)

        // Circular, not continuous: Figma draws plain arcs unless corner
        // smoothing is set, and this node has none.
        let shape = RoundedRectangle(cornerRadius: ButtonLabSpec.corner, style: .circular)
        return ZStack {
            liftBody(shape, flipped: false)
            liftBody(shape, flipped: true)
                .opacity(flip ? 1 : 0)
            configuration.label.foregroundStyle(.white)
        }
        // The swap's curve, read after the state change — so press and
        // release each take `flipDuration`, independent of the spring the
        // scale uses below.
        .animation(curve, value: flip)
        .compositingGroup()
        .shadow(color: .black.opacity(down ? tune.liftShadow : 0),
                radius: down ? 14 : 6, y: down ? 8 : 2)
        .scaleEffect(down ? tune.pressScale : 1)
        .animation(.spring(response: tune.springResponse,
                           dampingFraction: tune.springDamping), value: down)
        .onChange(of: configuration.isPressed) { _, pressed in
            if pressed { tune.haptics.pressDown() } else { tune.haptics.pressUp() }
        }
    }

    /// The lift's two states: the design, and the design with its fill and
    /// rim swapped end for end. Crossfaded — fading one opaque layer over
    /// another is exactly a per-pixel blend of their colours.
    ///
    /// The inner shadows are drawn in both layers, so each layer is the
    /// finished button and the crossfade between them is exact. Figma's
    /// shadow radius is a CSS blur, which is twice SwiftUI's radius.
    private func liftBody(_ shape: RoundedRectangle, flipped: Bool) -> some View {
        shape
            .fill(ButtonLabSpec.fill(flipped: flipped)
                .shadow(.inner(color: Color(white: 0.8235).opacity(0.34), radius: 7, y: 5))
                .shadow(.inner(color: .black, radius: 3.5, y: -5)))
            .overlay {
                shape.strokeBorder(ButtonLabSpec.rim(flipped: flipped), lineWidth: 1)
            }
            .frame(width: ButtonLabSpec.size.width, height: ButtonLabSpec.size.height)
    }
}

// MARK: tuning

@MainActor
final class ButtonLabTuning: ObservableObject {
    enum PressStyle: String, CaseIterable, Identifiable {
        case slab = "Continue", round = "Round", lift = "Lift"
        var id: String { rawValue }
    }
    /// `-buttonStyle Round` (or `Continue`, `Lift`) opens on that style;
    /// `-buttonShine 0.4` and `-buttonShineWidth 1.5` set the pressed rim.
    init() {
        let a = ProcessInfo.processInfo.arguments
        if let i = a.firstIndex(of: "-buttonStyle"), i + 1 < a.count,
           let v = PressStyle.allCases.first(where: { $0.rawValue.lowercased() == a[i + 1].lowercased() }) {
            style = v
            pressScale = Self.defaultScale(v)
            shine = Self.defaultShine(v)
        }
        if let i = a.firstIndex(of: "-buttonShine"), i + 1 < a.count, let v = Double(a[i + 1]) { shine = v }
        if let i = a.firstIndex(of: "-buttonShineWidth"), i + 1 < a.count, let v = Double(a[i + 1]) { shineWidth = v }
    }

    /// The design's button with the round replica's light; the replica
    /// itself, and the first brief's lift, to compare against.
    @Published var style: PressStyle = .slab {
        didSet { pressScale = Self.defaultScale(style); shine = Self.defaultShine(style) }
    }
    /// How big the Round and Lift buttons are while held. 1 for the dome —
    /// the reference does not scale; measured, its dome is the same width
    /// to the pixel pressed and released — and 3% bigger for the lift.
    /// Continue uses the app's shared scale instead, `DomeShadow.pressScale`.
    @Published var pressScale: Double = 1.0
    static func defaultScale(_ s: PressStyle) -> Double {
        switch s { case .slab: 1.0; case .round: 1.0; case .lift: 1.03 }
    }
    @Published var springResponse: Double = 0.26
    @Published var springDamping: Double = 0.68
    /// The change of light: on/off and its duration each way: 20ms, down
    /// from the brief's 80ms — about one frame at 60fps.
    @Published var flipEnabled = true
    @Published var flipDuration: Double = 0.02
    /// An extra drop shadow that deepens while held, 0 to turn it off.
    @Published var liftShadow: Double = 0
    /// The pressed rim of light along the top edge: how strong (0 none, 1
    /// the calibrated look) and how far in it reaches, as a multiple of the
    /// calibrated reach.
    @Published var shine: Double = 0
    /// The round replica's rim is the reference's own; the design's button
    /// has none — a lit top edge fights the shade its sunk face is under.
    static func defaultShine(_ s: PressStyle) -> Double { s == .round ? 1 : 0 }
    @Published var shineWidth: Double = 0.47

    @Published var presses = 0
    /// The lab's own haptic, starting at the app's settings — release tap on.
    let haptics: PressHaptics = {
        let h = PressHaptics()
        h.onRelease = true
        return h
    }()

    func resetMotion() {
        pressScale = Self.defaultScale(style)
        springResponse = 0.26; springDamping = 0.68
        flipEnabled = true; flipDuration = 0.02; liftShadow = 0
        shine = Self.defaultShine(style); shineWidth = 0.47
        DomeShadow.shared.strength = 0
        DomeShadow.shared.resetPress()
    }
}

/// The press haptic, with the two ways iOS can make one.
///
/// * **Impact** is `UIImpactFeedbackGenerator`: five preset characters
///   (light → heavy, plus rigid and soft) at a chosen intensity. Heavy at
///   full intensity is the strongest single tap the system gives.
/// * **Core Haptics** is a transient event with *intensity* and *sharpness*
///   set directly — sharpness is the axis the presets hide: low is a dull
///   thud, high a crisp click, and it is most of what makes a tap read as
///   "strong" rather than just loud.
///
/// The release gets its own, off by default — the brief asks for one on
/// press-down only, and a second tap on release is worth trying rather than
/// assuming.
@MainActor
final class PressHaptics: ObservableObject {
    enum Source: String, CaseIterable, Identifiable {
        case impact = "Impact", core = "Core Haptics"
        var id: String { rawValue }
    }
    enum Style: String, CaseIterable, Identifiable {
        case light = "Light", medium = "Medium", heavy = "Heavy", rigid = "Rigid", soft = "Soft"
        var id: String { rawValue }
        var ui: UIImpactFeedbackGenerator.FeedbackStyle {
            switch self {
            case .light: .light
            case .medium: .medium
            case .heavy: .heavy
            case .rigid: .rigid
            case .soft: .soft
            }
        }
    }

    @Published var enabled = true
    @Published var source: Source = .impact
    @Published var style: Style = .heavy { didSet { generator = UIImpactFeedbackGenerator(style: style.ui); prepare() } }
    @Published var intensity: Double = 1.0
    @Published var sharpness: Double = 0.75
    @Published var onRelease = false
    @Published var releaseIntensity: Double = 0.4

    /// The app's buttons' haptic, at the settings picked in the lab: Heavy at
    /// full intensity on press, a light 0.4 tap on release. Honours the
    /// app-wide haptics switch.
    static let flow: PressHaptics = {
        let h = PressHaptics()
        h.onRelease = true
        h.releaseIntensity = 0.4
        h.gate = { Haptics.shared.isEnabled }
        h.prepare()
        return h
    }()
    var gate: () -> Bool = { true }

    private var generator = UIImpactFeedbackGenerator(style: .heavy)
    private let releaser = UIImpactFeedbackGenerator(style: .light)
    private var engine: CHHapticEngine?

    func prepare() {
        generator.prepare()
        releaser.prepare()
        if engine == nil, CHHapticEngine.capabilitiesForHardware().supportsHaptics {
            engine = try? CHHapticEngine()
            // The engine stops when the app backgrounds or audio resets; the
            // handler restarts it so the next press is not silently dropped.
            engine?.resetHandler = { [weak self] in try? self?.engine?.start() }
            engine?.stoppedHandler = { [weak self] _ in
                Task { @MainActor in try? self?.engine?.start() }
            }
            try? engine?.start()
        }
    }

    func pressDown() {
        guard enabled, gate() else { return }
        switch source {
        case .impact:
            generator.impactOccurred(intensity: intensity)
            generator.prepare()
        case .core:
            transient(intensity: intensity, sharpness: sharpness)
        }
    }

    func pressUp() {
        guard enabled, onRelease, gate() else { return }
        releaser.impactOccurred(intensity: releaseIntensity)
        releaser.prepare()
    }

    private func transient(intensity: Double, sharpness: Double) {
        guard let engine else { return }
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(intensity)),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(sharpness)),
        ], relativeTime: 0)
        if let pattern = try? CHHapticPattern(events: [event], parameters: []),
           let player = try? engine.makePlayer(with: pattern) {
            try? player.start(atTime: CHHapticTimeImmediate)
        }
    }
}
