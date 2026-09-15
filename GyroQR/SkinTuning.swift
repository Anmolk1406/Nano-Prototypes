import SwiftUI

/// Knobs for the skin-select scene, exposed in the controls sheet.
@MainActor
final class SkinTuning: ObservableObject {
    // entry
    @Published var entryEnabled = true
    /// Spring response for the deal-in. Total motion is this plus the stagger.
    @Published var entryResponse: Double = 0.38
    @Published var entryStagger: Double = 0.045

    // idle hints
    @Published var hintsEnabled = false
    /// How much of a real cycle the hint plays back.
    @Published var hintCycleAmount: Double = 0.16
    /// How much of a real confirm pull the hint plays back.
    @Published var hintPullAmount: Double = 0.13
    @Published var hintRepeat: Double = 5.0

    // gesture
    /// Scales both drag spans. 1 = the tuned default; lower is twitchier,
    /// higher draws the gesture out further.
    @Published var dragTravel: Double = 1.0
    /// How many detent ticks fire across an upward throw.
    @Published var cycleDetents: Double = 5

    // background transition
    @Published var bgStyle: BGStyle = .crossfade

    // arc reveal
    /// How far below the screen the reveal circle is centred. Larger = flatter
    /// arc; smaller = a tighter dome sweeping up.
    @Published var arcDepth: Double = 360
    @Published var arcEdge: ArcEdge = .glow
    @Published var arcEdgeWidth: Double = 26
    @Published var arcEdgeIntensity: Double = 0.55

    enum BGStyle: String, CaseIterable, Identifiable {
        case crossfade = "Crossfade", arc = "Arc"
        var id: String { rawValue }
    }

    enum ArcEdge: String, CaseIterable, Identifiable {
        case none = "None", rim = "Rim", glow = "Glow", bloom = "Bloom"
        var id: String { rawValue }
    }

    func reset() {
        entryEnabled = true; entryResponse = 0.38; entryStagger = 0.045
        hintsEnabled = false; hintCycleAmount = 0.16; hintPullAmount = 0.13; hintRepeat = 5.0
        dragTravel = 1.0; cycleDetents = 5
        bgStyle = .crossfade; arcDepth = 360; arcEdge = .glow; arcEdgeWidth = 26; arcEdgeIntensity = 0.55
    }
}
