import SwiftUI

/// Every knob the card reads. Exposed in the panel so the effect can be dialled
/// in by hand instead of guessed at in code.
///
/// Defaults are calibrated against the reference clip: ~25° of tilt, a QR panel
/// travelling ±17pt × ±21pt against its card, ±2° of in-plane roll.
@MainActor
final class Tuning: ObservableObject {
    // 3D tilt
    @Published var tiltEnabled = true
    @Published var tiltDegrees: Double = 19
    @Published var perspective: Double = 0.85
    @Published var rollEnabled = true
    /// In-plane Z rotation, degrees at full deflection.
    @Published var roll: Double = 2.2

    // elevation parallax
    @Published var parallaxEnabled = true
    /// Multiplier on every layer's elevation. 1.0 == the values in CardSpec.
    @Published var elevationScale: Double = 1.0
    @Published var depthScale = true

    // shadows
    @Published var shadowEnabled = true
    @Published var shadowShift: Double = 20
    /// Strength of the contact shadows the floating planes cast on the card.
    @Published var contactShadow: Double = 1.0

    // light
    @Published var sheenEnabled = true
    @Published var sheen: Double = 0.38
    @Published var holoEnabled = true
    @Published var holo: Double = 0.16
    @Published var rimEnabled = true

    /// Mascot blur. Scales Figma's baked-in blur radius; with `gyroBlur` on it
    /// is further multiplied by |tilt.x|, so the mascots are sharp at rest and
    /// defocus as the card rolls left or right.
    @Published var blurScale: Double = 0.45
    @Published var gyroBlur = true

    // per-element character
    @Published var wobbleEnabled = true
    @Published var wobble: Double = 5

    // stage
    @Published var cardScale: Double = 1.0
    @Published var backdrop: Backdrop = .design
    @Published var showBounds = false
    @Published var invertX = false
    @Published var invertY = false

    enum Backdrop: String, CaseIterable, Identifiable {
        case design = "Design", dark = "Dark", light = "Light"
        var id: String { rawValue }
    }

    func reset() {
        tiltEnabled = true;   tiltDegrees = 19;   perspective = 0.85
        rollEnabled = true;   roll = 2.2
        parallaxEnabled = true; elevationScale = 1.0; depthScale = true
        shadowEnabled = true; shadowShift = 20;   contactShadow = 1.0
        sheenEnabled = true;  sheen = 0.38
        holoEnabled = true;   holo = 0.16;        rimEnabled = true
        blurScale = 0.45; gyroBlur = true
        wobbleEnabled = true; wobble = 5
        cardScale = 1.0;      showBounds = false
        invertX = false;      invertY = false
    }
}
