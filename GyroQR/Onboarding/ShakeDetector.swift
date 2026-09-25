import SwiftUI
import UIKit

/// Reports the system shake gesture into SwiftUI.
///
/// UIKit already detects shakes and delivers them as `motionEnded` — there is
/// no reason to run an accelerometer of our own and pick a threshold that
/// disagrees with the rest of the system. The catch is that `motionEnded` goes
/// to the first responder, and SwiftUI never makes one unless something asks,
/// so this hosts a bare controller whose only job is to raise its hand.
///
/// Mounted as a 1 × 1 background rather than a `.frame(.zero)`: a zero-size
/// view is not reliably in the window hierarchy, and a controller outside the
/// hierarchy cannot become first responder.
struct ShakeDetector: UIViewControllerRepresentable {
    var onShake: () -> Void

    func makeUIViewController(context: Context) -> Reporter {
        let vc = Reporter()
        vc.onShake = onShake
        return vc
    }

    func updateUIViewController(_ vc: Reporter, context: Context) {
        vc.onShake = onShake
    }

    final class Reporter: UIViewController {
        var onShake: () -> Void = {}

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
        }

        override func viewDidDisappear(_ animated: Bool) {
            super.viewDidDisappear(animated)
            resignFirstResponder()
        }

        override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
            guard motion == .motionShake else {
                super.motionEnded(motion, with: event)
                return
            }
            onShake()
        }
    }
}

extension View {
    /// Calls `action` when the device is shaken, while this view is on screen.
    func onShake(perform action: @escaping () -> Void) -> some View {
        background {
            ShakeDetector(onShake: action)
                .frame(width: 1, height: 1)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}
