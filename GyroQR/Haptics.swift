import UIKit
import SwiftUI

/// Haptics for the skin-select scene.
///
/// The pull-to-confirm needs a rumble that *grows* as the card is dragged down.
/// That is built here as a train of discrete impacts rather than one continuous
/// Core Haptics event: the pulse train is audible on every device, survives the
/// gesture-tracking run loop mode, and gives a tunable gap — which a continuous
/// event cannot express at all.
@MainActor
final class Haptics: ObservableObject {
    static let shared = Haptics()

    @Published var isEnabled = true
    /// Seconds between pulses while the card is being pulled down.
    @Published var pulseGap: Double = 0.06 { didSet { if ramping { schedule() } } }
    /// Impact strength at the very start of the pull.
    @Published var minStrength: Double = 0.18
    /// Impact strength once the card reaches the settle threshold.
    @Published var maxStrength: Double = 1.0
    /// Shapes how late the ramp bites. 1 = linear, >1 = back-loaded.
    @Published var rampCurve: Double = 1.4

    private let light  = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let heavy  = UIImpactFeedbackGenerator(style: .heavy)
    private let rigid  = UIImpactFeedbackGenerator(style: .rigid)

    private var timer: Timer?
    private var progress: Double = 0
    private var ramping: Bool { timer != nil }

    private init() {}

    func prepare() {
        guard isEnabled else { return }
        light.prepare(); medium.prepare(); heavy.prepare(); rigid.prepare()
    }

    // MARK: discrete

    /// A card was swiped to the back of the stack.
    func swipe() {
        guard isEnabled else { return }
        light.impactOccurred(intensity: 0.7)
    }

    /// The card has settled into the pocket.
    func settle() {
        guard isEnabled else { return }
        rigid.impactOccurred(intensity: 1.0)
        // A softer tap a beat later reads as the card bedding in.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.085) { [weak self] in
            guard let self, self.isEnabled else { return }
            self.medium.impactOccurred(intensity: 0.55)
        }
    }

    /// A detent while the card is being thrown up. The throw used to be silent
    /// until it committed, so most of the gesture had nothing to feel.
    func detent(progress p: Double) {
        guard isEnabled else { return }
        light.impactOccurred(intensity: CGFloat(0.25 + 0.55 * max(0, min(1, p))))
    }

    func selectionTick() {
        guard isEnabled else { return }
        light.impactOccurred(intensity: 0.35)
    }

    // MARK: the pull ramp

    func startRamp() {
        guard isEnabled, !ramping else { return }
        prepare()
        progress = 0
        schedule()
        pulse()                     // fire immediately so the pull starts with a tick
    }

    func updateRamp(progress p: Double) {
        progress = max(0, min(1, p))
    }

    func stopRamp() {
        timer?.invalidate()
        timer = nil
    }

    private func schedule() {
        timer?.invalidate()
        let t = Timer(timeInterval: max(0.015, pulseGap), repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.pulse() }
        }
        // .common, or the train stops dead the moment the drag starts tracking.
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func pulse() {
        guard isEnabled else { return }
        if ProcessInfo.processInfo.arguments.contains("-hapticLog") {
            let band = progress < 0.34 ? "light" : (progress < 0.72 ? "medium" : "heavy")
            let shapedL = pow(progress, max(0.2, rampCurve))
            print(String(format: "PULSE t=%.3f p=%.2f %@ strength=%.2f",
                         Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 100),
                         progress, band,
                         minStrength + (maxStrength - minStrength) * shapedL))
        }
        let shaped = pow(progress, max(0.2, rampCurve))
        let strength = minStrength + (maxStrength - minStrength) * shaped
        // Step the generator as well as the amplitude — a heavy tap at 0.4 feels
        // different from a light tap at 0.4, and the change in character is what
        // sells "getting closer".
        switch progress {
        case ..<0.34:  light.impactOccurred(intensity: CGFloat(strength))
        case ..<0.72:  medium.impactOccurred(intensity: CGFloat(strength))
        default:       heavy.impactOccurred(intensity: CGFloat(strength))
        }
    }
}
