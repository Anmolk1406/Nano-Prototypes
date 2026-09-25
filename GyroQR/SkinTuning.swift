import SwiftUI

/// Knobs for the skin-select scene, exposed in the controls sheet.
@MainActor
final class SkinTuning: ObservableObject {

    /// `-cycleDuration 2.0` stretches the commit transition so it can be
    /// stepped through with screenshots, which are ~0.4s apart and otherwise
    /// walk straight over a 0.55s curve.
    init() {
        let a = ProcessInfo.processInfo.arguments
        if let i = a.firstIndex(of: "-cycleDuration"), i + 1 < a.count,
           let v = Double(a[i + 1]) { cycleDuration = v }
        if let i = a.firstIndex(of: "-cyclePreview"), i + 1 < a.count,
           let v = Double(a[i + 1]) { cyclePreview = v }
        // `-entryDelay 0` starts the deal-in immediately, which is what the
        // capture args want; `-cycleAxis Side` picks the sideways throw.
        if let i = a.firstIndex(of: "-entryDelay"), i + 1 < a.count,
           let v = Double(a[i + 1]) { entryDelay = v }
        if let i = a.firstIndex(of: "-cycleAxis"), i + 1 < a.count,
           let ax = CycleAxis.allCases.first(where: {
               $0.rawValue.lowercased().contains(a[i + 1].lowercased()) }) {
            cycleAxis = ax
        }
        // `-noBend` for a side-by-side against the straight cut.
        if a.contains("-noBend") { bendEnabled = false }
    }

    // entry
    @Published var entryEnabled = true
    /// Spring response for the deal-in. Total motion is this plus the stagger.
    @Published var entryResponse: Double = 0.55
    @Published var entryStagger: Double = 0.120
    /// Seconds before the deal-in starts.
    ///
    /// The stack used to be mid-flight on the first frame the screen was
    /// visible, which means the entry is competing with whatever brought the
    /// user here. A beat of empty backdrop first lets the screen arrive before
    /// the cards do.
    @Published var entryDelay: Double = 0.35

    // idle hints
    @Published var hintsEnabled = false
    /// How much of a real cycle the hint plays back.
    @Published var hintCycleAmount: Double = 0.16
    /// How much of a real confirm pull the hint plays back.
    @Published var hintPullAmount: Double = 0.13
    @Published var hintRepeat: Double = 5.0

    // gesture
    //
    // The two directions are scaled separately. They are not the same kind of
    // gesture: the throw is the one you repeat a dozen times hunting for a
    // skin, so it wants to be quick, while the pull is the one that commits and
    // has the haptic ramp and the pocket rise inside it, so it earns its
    // length. One shared multiplier meant tuning either one moved both.
    /// Which way the deck is cycled.
    @Published var cycleAxis: CycleAxis = .up
    /// Scales the throw's span, whichever axis it is on.
    @Published var throwTravel: Double = 1.0
    /// Scales the downward pull's span.
    @Published var pullTravel: Double = 1.0
    /// How many detent ticks fire across an upward throw.
    @Published var cycleDetents: Double = 5

    // cycle transition
    /// Seconds for the stack hand-off and background transition on commit.
    /// Fixed, so a flick and a slow drag look the same.
    @Published var cycleDuration: Double = SkinSelectSpec.cycleDuration
    /// How much of that transition the drag itself scrubs before release.
    @Published var cyclePreview: Double = SkinSelectSpec.cyclePreview

    // pocket glow
    /// Siri-style lit edge on the pocket mouth while the card is pulled in.
    @Published var glowEnabled = true
    /// Seconds for the colour band to travel one full cycle.
    @Published var glowPeriod: Double = 2.6
    /// Scales every glow layer's thickness together.
    @Published var glowThickness: Double = 1.0

    // mouth
    /// Pinches the card into the pocket's mouth — a Metal `distortionEffect`,
    /// so it is the one thing here that can fail to load rather than merely
    /// look wrong. Off leaves the straight cut.
    @Published var bendEnabled = true
    /// Points of displacement at the edge.
    @Published var bendAmount: Double = 6
    /// How far either side of the edge the pinch reaches.
    @Published var bendReach: Double = 30

    // background transition
    @Published var bgStyle: BGStyle = .crossfade

    // arc reveal
    /// How far below the screen the reveal circle is centred. Larger = flatter
    /// arc; smaller = a tighter dome sweeping up.
    @Published var arcDepth: Double = 360
    @Published var arcEdge: ArcEdge = .glow
    @Published var arcEdgeWidth: Double = 26
    @Published var arcEdgeIntensity: Double = 0.55

    /// Up, or sideways either way. The confirm pull stays downward in both —
    /// it is the gesture that commits, and it has the pocket to aim at.
    enum CycleAxis: String, CaseIterable, Identifiable {
        case up = "Swipe up", side = "Swipe sideways"
        var id: String { rawValue }
    }

    enum BGStyle: String, CaseIterable, Identifiable {
        case crossfade = "Crossfade", arc = "Arc"
        var id: String { rawValue }
    }

    enum ArcEdge: String, CaseIterable, Identifiable {
        case none = "None", rim = "Rim", glow = "Glow", bloom = "Bloom"
        var id: String { rawValue }
    }

    func reset() {
        entryEnabled = true; entryResponse = 0.55; entryStagger = 0.120
        entryDelay = 0.35; cycleAxis = .up
        hintsEnabled = false; hintCycleAmount = 0.16; hintPullAmount = 0.13; hintRepeat = 5.0
        throwTravel = 1.0; pullTravel = 1.0; cycleDetents = 5
        cycleDuration = SkinSelectSpec.cycleDuration
        cyclePreview = SkinSelectSpec.cyclePreview
        glowEnabled = true; glowPeriod = 2.6; glowThickness = 1.0
        bendEnabled = true; bendAmount = 6; bendReach = 30
        bgStyle = .crossfade; arcDepth = 360; arcEdge = .glow; arcEdgeWidth = 26; arcEdgeIntensity = 0.55
    }
}
