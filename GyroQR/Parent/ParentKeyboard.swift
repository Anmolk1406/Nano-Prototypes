import SwiftUI
import UIKit

/// Where the system keyboard's top edge is, in a `ParentStage`'s 375 × 812
/// coordinates — so a page laid out at the design's size can sit its action
/// bar on the keyboard the way frames 3 and 8 draw it.
///
/// The stage is the design scaled to fill the screen and centred, so a
/// screen point maps back by undoing the centring and dividing by the scale.
@MainActor
final class ParentKeyboard: ObservableObject {
    static let shared = ParentKeyboard()
    /// The keyboard's top in stage points, or nil while it is down.
    @Published private(set) var top: CGFloat?
    /// Its own animation, so the bar moves with the keyboard.
    private(set) var duration: Double = 0.25

    private init() {
        let nc = NotificationCenter.default
        nc.addObserver(forName: UIResponder.keyboardWillChangeFrameNotification, object: nil, queue: .main) { [weak self] n in
            MainActor.assumeIsolated { self?.update(n) }
        }
        nc.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] n in
            MainActor.assumeIsolated {
                self?.duration = (n.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
                withAnimation(.easeOut(duration: self?.duration ?? 0.25)) { self?.top = nil }
            }
        }
    }

    private func update(_ n: Notification) {
        guard let end = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let screen = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen else { return }
        duration = (n.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
        let size = screen.bounds.size
        let scale = max(size.width / ParentSpec.size.width, size.height / ParentSpec.size.height)
        let offsetY = (size.height - ParentSpec.size.height * scale) / 2
        let visible = end.minY < size.height - 1
        withAnimation(.easeOut(duration: duration)) {
            top = visible ? (end.minY - offsetY) / scale : nil
        }
    }
}
