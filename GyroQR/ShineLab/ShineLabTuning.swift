import SwiftUI

/// The lab's knobs, in the controls sheet under the lab's scene.
@MainActor
final class ShineLabTuning: ObservableObject {
    /// How far a shine runs at full tilt, in artwork pixels.
    @Published var travel: Double = 170
    /// Top and bottom run opposite ways, and left and right, so the shines
    /// circle the frame rather than all sliding one way.
    @Published var orbit = false
    /// How bright a shine is with the card flat; full tilt takes it to 1.
    @Published var restGlow: Double = 0.7
    /// Grows a moving shine a little along its streak.
    @Published var stretch: Double = 0.12
    /// Adds the shines onto the base instead of laying them over it.
    /// `-shineAdditive` turns it on at launch.
    @Published var additive = ProcessInfo.processInfo.arguments.contains("-shineAdditive")
    /// The holo card's rim light, over the rim band — the chrome card's
    /// border light, which draws nothing on a card with no border.
    @Published var rimStrength: Double = 0.55
    /// The white sticker glow round the card from Figma's frame render. Off:
    /// with it on, light shows outside the card.
    @Published var halo = false
    /// Draws both bevel tracks on every side. `-shineTracks` turns it on.
    @Published var showEdges = ProcessInfo.processInfo.arguments.contains("-shineTracks")

    func reset() {
        travel = 170; orbit = false; restGlow = 0.7; stretch = 0.12
        additive = false; showEdges = false; rimStrength = 0.55; halo = false
    }
}
