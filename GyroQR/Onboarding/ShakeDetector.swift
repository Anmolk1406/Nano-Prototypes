import SwiftUI
import UIKit
import CoreMotion

/// Reports a shake into SwiftUI, two ways.
///
/// * **The accelerometer**, at a threshold we choose. UIKit's own shake wants
///   a hard, sustained shake — in practice a violent one — and its threshold
///   is not adjustable. So device motion is read at 60Hz and a shake is
///   `peaks` jolts of user acceleration (gravity removed) above `threshold`
///   g within 0.6s, each at least 80ms apart so one jolt is not counted
///   twice. Then it rests for 1s, so one shake is one shuffle.
/// * **UIKit's `motionEnded`**, still, as the floor: anything the system
///   calls a shake also counts. `motionEnded` goes to the first responder,
///   and SwiftUI never makes one unless something asks, so this hosts a bare
///   controller whose only job is to raise its hand.
///
/// Mounted as a 1 × 1 background rather than a `.frame(.zero)`: a zero-size
/// view is not reliably in the window hierarchy, and a controller outside the
/// hierarchy cannot become first responder.
struct ShakeDetector: UIViewControllerRepresentable {
    var threshold: Double = 0.9
    var peaks: Int = 2
    var onPeak: ((Double) -> Void)?
    var onShake: () -> Void

    func makeUIViewController(context: Context) -> Reporter {
        let vc = Reporter()
        update(vc)
        return vc
    }

    func updateUIViewController(_ vc: Reporter, context: Context) {
        update(vc)
    }

    private func update(_ vc: Reporter) {
        vc.onShake = onShake
        vc.onPeak = onPeak
        vc.threshold = threshold
        vc.peaks = max(1, peaks)
    }

    final class Reporter: UIViewController {
        var onShake: () -> Void = {}
        var onPeak: ((Double) -> Void)?
        var threshold = 0.9
        var peaks = 2

        private let motion = CMMotionManager()
        private var jolts: [TimeInterval] = []
        private var restUntil: TimeInterval = 0
        /// Above the threshold now — a jolt is counted on the way up, once.
        private var high = false

        override var canBecomeFirstResponder: Bool { true }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            let won = becomeFirstResponder()
            // The one thing here that can silently fail. UIKit routes shakes to
            // the first responder, so if this does not win, no shake is ever
            // seen and there is nothing on screen to say so.
            //     xcrun simctl launch --console-pty <udid> com.noon.gyroqr \
            //         -onbStep Avatar -shakeProbe
            if ProcessInfo.processInfo.arguments.contains("-shakeProbe") {
                print("SHAKEPROBE becameFirstResponder=\(won) "
                      + "isFirstResponder=\(isFirstResponder) "
                      + "inWindow=\(view.window != nil) "
                      + "bounds=\(view.bounds.size)")
            }
            startMotion()
        }

        override func viewDidDisappear(_ animated: Bool) {
            super.viewDidDisappear(animated)
            resignFirstResponder()
            motion.stopDeviceMotionUpdates()
        }

        private func startMotion() {
            guard motion.isDeviceMotionAvailable, !motion.isDeviceMotionActive else { return }
            motion.deviceMotionUpdateInterval = 1.0 / 60
            motion.startDeviceMotionUpdates(to: .main) { [weak self] m, _ in
                guard let self, let a = m?.userAcceleration else { return }
                self.sample(g: (a.x * a.x + a.y * a.y + a.z * a.z).squareRoot(),
                            at: m?.timestamp ?? 0)
            }
        }

        private func sample(g: Double, at t: TimeInterval) {
            guard g > threshold else { high = false; return }
            guard !high else { return }
            high = true
            onPeak?(g)
            guard t >= restUntil else { return }
            if let last = jolts.last, t - last < 0.08 { return }
            jolts = jolts.filter { t - $0 < 0.6 } + [t]
            if jolts.count >= peaks {
                jolts.removeAll()
                restUntil = t + 1.0
                onShake()
            }
        }

        override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
            guard motion == .motionShake else {
                super.motionEnded(motion, with: event)
                return
            }
            guard ProcessInfo.processInfo.systemUptime >= restUntil else { return }
            onShake()
        }
    }
}

extension View {
    /// Calls `action` when the device is shaken, while this view is on screen
    /// — `peaks` jolts over `threshold` g within 0.6s, or a system shake.
    func onShake(threshold: Double = 0.9, peaks: Int = 2,
                 onPeak: ((Double) -> Void)? = nil,
                 perform action: @escaping () -> Void) -> some View {
        background {
            ShakeDetector(threshold: threshold, peaks: peaks, onPeak: onPeak, onShake: action)
                .frame(width: 1, height: 1)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}
