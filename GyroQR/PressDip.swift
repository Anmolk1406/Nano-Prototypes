import SwiftUI

/// The press for small controls — a back chevron, a radio card, a checkbox:
/// a slight dip under the finger and back on a spring, with a light tap on
/// the way down. The primary buttons have `DomeButtonStyle`; this is the same
/// gesture without the dome.
struct PressDip: ButtonStyle {
    var scale: CGFloat = 0.96
    var haptic = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.interpolatingSpring(stiffness: 320, damping: 28), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, down in
                if down, haptic { Haptics.shared.lightTap() }
            }
    }
}

/// Hands a button's pressed state to its container, for a control whose
/// press should move something larger than its own label — a card whose
/// tappable part is only its header.
struct PressReport: ButtonStyle {
    @Binding var pressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, down in pressed = down }
    }
}
