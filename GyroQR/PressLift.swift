import SwiftUI

/// A button that rises toward the finger instead of shrinking away from it.
///
/// The usual press treatment scales *down* — the control reads as being pushed
/// into the page. This one does the opposite: on press it grows a little and
/// its shadow deepens and drops, so the button lifts off the surface, and on
/// release it settles back. On a page where the button is the one thing the
/// user is meant to touch, being pulled up under the thumb is the livelier
/// read, and it is what the wallet's `Request top up` pill wanted — flat and
/// dead was the note.
///
/// Both halves get a haptic. A single tap impact fires when the button is
/// pressed and a lighter one when it lets go, which is what makes a press feel
/// like it has a floor: one tick going down, a softer tick coming back. Firing
/// only on the action — the way a plain `Button` does — puts the feedback
/// *after* the gesture instead of inside it.
struct PressLift: ButtonStyle {
    /// How much bigger the control gets while held.
    var scale: CGFloat = 1.06
    var restShadow = Shadow(opacity: 0.12, radius: 10, y: 3)
    var pressedShadow = Shadow(opacity: 0.24, radius: 22, y: 12)
    /// The shape the shadow is cast from. A shadow on a `Button`'s label is
    /// cast from the label's alpha, which for a pill with a capsule background
    /// is the capsule — but the label may also hold text, and text casts its
    /// own shadow, so the shape is drawn explicitly underneath instead.
    var shape: AnyShape = AnyShape(Capsule())
    var haptics = true

    struct Shadow {
        var opacity: Double
        var radius: CGFloat
        var y: CGFloat
    }

    /// `-pressHeld` pins every lifted control to its pressed look, which is
    /// the only way to screenshot it: a press is a gesture and the Simulator
    /// has no way to script one that is still being held.
    private static let pinned = ProcessInfo.processInfo.arguments.contains("-pressHeld")

    func makeBody(configuration: Configuration) -> some View {
        let down = configuration.isPressed || Self.pinned
        let s = down ? pressedShadow : restShadow
        return configuration.label
            .background {
                // Under the label, so the shadow is the control's and not the
                // type's. The shape is filled *opaque*: a shadow's strength is
                // the caster's alpha times the shadow colour's, so the
                // near-clear fill this used to cast from threw a shadow at a
                // thousandth of its opacity — the elevation never showed. Both
                // callers draw an opaque shape of their own over this one.
                shape.fill(.black)
                    .shadow(color: .black.opacity(s.opacity), radius: s.radius, y: s.y)
            }
            .scaleEffect(down ? scale : 1)
            // A spring, not an ease: the lift is meant to feel like the
            // control has mass, and the settle on release is the half of it
            // the user actually notices.
            .animation(.spring(response: 0.26, dampingFraction: 0.62), value: down)
            .onChange(of: down) { _, pressed in
                guard haptics else { return }
                if pressed { Haptics.shared.pressDown() } else { Haptics.shared.pressUp() }
            }
    }
}
