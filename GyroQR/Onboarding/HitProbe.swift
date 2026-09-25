import UIKit

/// Answers "would a real finger on this control reach it?" without a finger.
///
/// `simctl` cannot synthesise taps and the native Simulator integration is
/// unavailable here, so a broken hit path (an ancestor gesture swallowing
/// touches, a zero-size content shape, a transform confusing the hit test) is
/// otherwise invisible until someone tries it on a device.
///
/// This walks the real UIKit hierarchy, takes the control's own centre in window
/// coordinates and runs `hitTest` on it — the same call the touch system makes.
/// If the result is not the control, the chain printed underneath names whatever
/// is on top of it.
enum HitProbe {

    /// Probes the first `UITextField` on screen.
    static func textField(label: String = "field") {
        guard let window = keyWindow else { print("HITPROBE no key window"); return }
        guard let field = firstDescendant(of: window, matching: { $0 is UITextField }) else {
            print("HITPROBE \(label): no UITextField in the hierarchy")
            return
        }
        probe(field, label: label, in: window)
    }

    static func probe(_ view: UIView, label: String, in window: UIWindow) {
        let point = view.convert(view.bounds.center, to: window)
        let hit = window.hitTest(point, with: nil)
        let reached = hit === view || hit?.isDescendant(of: view) == true

        print("HITPROBE \(label): size \(fmt(view.bounds.size)) at \(fmt(point)) "
              + "-> \(reached ? "REACHED" : "BLOCKED")")
        if !reached {
            print("HITPROBE \(label): hit \(chain(from: hit))")
            print("HITPROBE \(label): want \(chain(from: view))")
        }
        ancestorTaps(of: view, label: label)
    }

    /// Reaching the control is only half the story: a hit test says which view
    /// owns the point, not which gesture recognizer wins the touch. A
    /// `UITapGestureRecognizer` on an *ancestor* — what `.onTapGesture` on a
    /// parent compiles down to — can claim the tap and cancel the control's own
    /// handling, so the control stays hittable and is still dead.
    ///
    /// The `UIWindow` is skipped deliberately. UIKit keeps a tap recognizer
    /// there in every SwiftUI app, with or without any gesture of your own — it
    /// showed up as a false positive the first time this ran and sent the
    /// diagnosis off in the wrong direction.
    static func ancestorTaps(of view: UIView, label: String) {
        var suspects = 0
        var deadLayers = 0
        var cursor = view.superview

        while let current = cursor {
            if !(current is UIWindow) {
                let taps = (current.gestureRecognizers ?? [])
                    .filter { $0 is UITapGestureRecognizer && $0.isEnabled }
                if !taps.isEmpty {
                    suspects += taps.count
                    print("HITPROBE \(label): tap recognizer on ancestor "
                          + "\(String(describing: type(of: current))) (\(taps.count))")
                }
            }
            // The blunter killer: interaction switched off anywhere up the chain
            // stops the touch before any gesture gets a look at it.
            if !current.isUserInteractionEnabled {
                deadLayers += 1
                print("HITPROBE \(label): interaction DISABLED on ancestor "
                      + "\(String(describing: type(of: current)))")
            }
            cursor = current.superview
        }

        print("HITPROBE \(label): \(suspects) competing tap recognizer(s), "
              + "\(deadLayers) ancestor(s) with interaction off")
    }

    // MARK: plumbing

    private static var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
    }

    private static func firstDescendant(of view: UIView,
                                        matching test: (UIView) -> Bool) -> UIView? {
        if test(view) { return view }
        for sub in view.subviews {
            if let found = firstDescendant(of: sub, matching: test) { return found }
        }
        return nil
    }

    /// Bottom-up view chain, which is where an offending ancestor shows up.
    private static func chain(from view: UIView?) -> String {
        var names: [String] = []
        var cursor = view
        while let current = cursor, names.count < 7 {
            names.append(String(describing: type(of: current)))
            cursor = current.superview
        }
        return names.isEmpty ? "nil" : names.joined(separator: " < ")
    }

    private static func fmt(_ p: CGPoint) -> String { String(format: "(%.0f, %.0f)", p.x, p.y) }
    private static func fmt(_ s: CGSize) -> String { String(format: "%.0f×%.0f", s.width, s.height) }
}

private extension CGRect {
    var center: CGPoint { CGPoint(x: midX, y: midY) }
}
