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
    @Published var minStrength: Double = 0.44
    /// Impact strength once the card reaches the settle threshold.
    @Published var maxStrength: Double = 0.90
    /// Shapes how late the ramp bites. 1 = linear, >1 = back-loaded.
    @Published var rampCurve: Double = 1.4

    private let light  = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let heavy  = UIImpactFeedbackGenerator(style: .heavy)
    private let rigid  = UIImpactFeedbackGenerator(style: .rigid)
    private let soft   = UIImpactFeedbackGenerator(style: .soft)
    private let notify = UINotificationFeedbackGenerator()

    private var timer: Timer?
    private var progress: Double = 0
    private var ramping: Bool { timer != nil }

    private init() {}

    func prepare() {
        guard isEnabled else { return }
        light.prepare(); medium.prepare(); heavy.prepare(); rigid.prepare(); soft.prepare(); notify.prepare()
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

    /// A field taking focus, or a checkbox or radio being ticked: a light,
    /// crisp tap — present under the finger, never a click.
    func lightTap() {
        guard isEnabled else { return }
        light.impactOccurred(intensity: 0.6)
    }

    func selectionTick() {
        guard isEnabled else { return }
        light.impactOccurred(intensity: 0.35)
    }

    /// The gesture has passed its commit threshold — let go and it happens.
    ///
    /// Distinct from `detent` on purpose. The detents are a texture you feel
    /// *through*, all light impacts of rising intensity; this is a single firm
    /// one, so "you can release now" is not just a slightly stronger version of
    /// the last thing you felt.
    func armed() {
        guard isEnabled else { return }
        rigid.impactOccurred(intensity: 1.0)
    }

    /// The gesture was released short of its threshold and the card fell back.
    /// Soft, because nothing happened — it only needs to close the loop.
    func aborted() {
        guard isEnabled else { return }
        light.impactOccurred(intensity: 0.28)
    }

    // MARK: onboarding

    /// A CTA was pressed.
    func tap() {
        guard isEnabled else { return }
        medium.impactOccurred(intensity: 0.75)
    }

    /// A control was pressed down, and let go of.
    ///
    /// Two events rather than one, because a press with a lift has two moments
    /// worth feeling: the control taking the touch, and the control settling
    /// back. The release is deliberately softer — equal weights read as a
    /// double-tap rather than as one press.
    func pressDown() {
        guard isEnabled else { return }
        medium.impactOccurred(intensity: 0.8)
    }

    func pressUp() {
        guard isEnabled else { return }
        light.impactOccurred(intensity: 0.42)
    }

    /// One OTP digit landed. Light and crisp — this fires four times in a row,
    /// so anything heavier turns the entry into a rumble.
    func keyTick() {
        guard isEnabled else { return }
        light.impactOccurred(intensity: 0.55)
    }

    /// Cycling to the next avatar.
    func cycleTick() {
        guard isEnabled else { return }
        rigid.impactOccurred(intensity: 0.6)
    }

    /// The OTP was wrong. A notification generator, not an impact: the system's
    /// error pattern is a double-buzz that already reads as "rejected", and
    /// nothing hand-rolled from impacts communicates it as clearly.
    func failure() {
        guard isEnabled else { return }
        notify.notificationOccurred(.error)
    }

    /// The OTP was accepted.
    func success() {
        guard isEnabled else { return }
        notify.notificationOccurred(.success)
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
