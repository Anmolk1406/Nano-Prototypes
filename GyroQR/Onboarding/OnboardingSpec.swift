import SwiftUI
import Combine

/// Design tokens and shared chrome for the onboarding flow, Figma section
/// `Flow for claude` (845:48674). Every frame in that section is laid out at
/// 375 × 812, so the whole flow is built at native size and scaled to fit —
/// the same approach `ShareScreen` and `SkinSelectScreen` already use.
enum OnboardingSpec {
    static let size = CGSize(width: 375, height: 812)

    /// noon's colour tokens, spelled the way Figma names them.
    enum C {
        static let primary        = Color(hex: 0x1D2539)   // text-n-icon/primary
        static let secondary      = Color(hex: 0x475067)
        static let tertiary       = Color(hex: 0x666D85)
        static let grey100        = Color(hex: 0xF9F9FB)
        static let grey500        = Color(hex: 0x989FB3)
        static let grey800        = Color(hex: 0x343D54)
        static let grey1000       = Color(hex: 0x101628)
        static let surfaceTert    = Color(hex: 0xF2F3F7)   // surface/tertiary
        static let borderSubtle   = Color(hex: 0xF2F3F7)
        static let actionBold     = Color(hex: 0x0F61FF)   // border/action-bold
        static let brandBlue50    = Color(hex: 0xF5FAFF)
        static let brandBlue100   = Color(hex: 0xEBF4FF)
        static let successBold    = Color(hex: 0x0F8857)   // surface/success-bold
        static let errorBold      = Color(hex: 0xD92626)
    }

    /// The type ramp, on Noontree. Each entry is the design's own style name,
    /// so `F.h32` is Figma's `H32/Extrabold` and nothing has to be re-derived
    /// at the call site.
    enum F {
        static let h40  = NoonFont.f(.bold,      40)   // H40/Bold
        static let h32  = NoonFont.f(.extrabold, 32)   // H32/Extrabold
        static let h18  = NoonFont.f(.bold,      18)   // H18/Bold
        static let b16  = NoonFont.f(.medium,    16)   // Body/B16/Medium
        static let b14  = NoonFont.f(.medium,    14)   // Body/B14/Medium
        static let b14s = NoonFont.f(.semibold,  14)   // B14/SemiBold
        static let b12  = NoonFont.f(.medium,    12)   // B12/Medium
        static let a17  = NoonFont.f(.semibold,  17)   // A17/SemiBold
        static let a14  = NoonFont.f(.semibold,  14)   // A14/SemiBold
    }

    // Bottom CTA bar — `Button Container`, e.g. 845:49517.
    static let ctaHeight: CGFloat = 56
    static let ctaRadius: CGFloat = 16
    static let ctaInset: CGFloat = 16
}

extension Color {
    init(hex: UInt32) {
        self.init(red:   Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >>  8) & 0xFF) / 255,
                  blue:  Double( hex        & 0xFF) / 255)
    }
}

// MARK: - shared chrome

/// The 3-dot progress rail carried by the skin / avatar / interests steps
/// (e.g. 845:49946). A filled ring marks the active step; passed steps read as
/// solid, upcoming ones as translucent.
struct StepDots: View {
    let active: Int          // 0-based
    var onDark = false

    private var tint: Color { onDark ? .white : OnboardingSpec.C.actionBold }
    private var idle: Color { onDark ? .white.opacity(0.45) : OnboardingSpec.C.actionBold.opacity(0.25) }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle()
                    .strokeBorder(tint, lineWidth: i == active ? 4 : 0)
                    .background(Circle().fill(i == active ? .clear : (i < active ? tint : idle)))
                    .frame(width: 16, height: 16)
                if i < 2 {
                    Capsule().fill(i < active ? tint : idle).frame(width: 24, height: 4)
                }
            }
        }
        .frame(width: 112, height: 16)
    }
}

/// `M-NeutralButton` — the near-black primary CTA used on every light step,
/// drawn by `DomeButtonStyle`: raised at rest, sunk under a lip with a rim of
/// light on top when pressed, with its haptic on the press and the release.
/// Disabled follows the design system's muted-on-subtle-surface pattern and
/// stays flat — a sunk-in look on a button that cannot be pressed would be a
/// promise it does not keep.
struct NeutralCTA: View {
    let title: String
    var enabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(OnboardingSpec.F.a17)
                .tracking(-0.25)
                .foregroundStyle(enabled ? .white : OnboardingSpec.C.grey500)
                .frame(maxWidth: .infinity)
                .frame(height: OnboardingSpec.ctaHeight)
                // The dome is the enabled surface; this is the disabled one.
                .background(enabled ? .clear : OnboardingSpec.C.surfaceTert)
                .clipShape(RoundedRectangle(cornerRadius: OnboardingSpec.ctaRadius, style: .continuous))
                // The design only ever draws this button enabled, so its
                // disabled pattern — muted ink on a subtle surface — assumes a
                // white page. On the email step the tray is a blurred photo of
                // similar lightness and the control vanishes into it, so the
                // disabled state gets an edge to sit inside.
                .overlay {
                    if !enabled {
                        RoundedRectangle(cornerRadius: OnboardingSpec.ctaRadius, style: .continuous)
                            .strokeBorder(OnboardingSpec.C.grey500.opacity(0.45), lineWidth: 1)
                    }
                }
        }
        .buttonStyle(DomeButtonStyle(corner: OnboardingSpec.ctaRadius))
        .disabled(!enabled)
        .animation(.easeOut(duration: 0.18), value: enabled)
    }
}

/// The tray the CTA sits in, pinned to the bottom of a step.
///
/// Figma's `Button Container` is a 32.5pt backdrop blur with no fill. Over the
/// email step's burst that has to be real glass; over the white steps a
/// material renders as a grey slab, so those get a plain surface with a
/// hairline instead — same intent, no dirty edge.
struct CTABar<Content: View>: View {
    enum Surface {
        case solid
        /// No tray at all — the CTA sits straight on whatever is behind it.
        ///
        /// Figma's `Button Container` is a 32.5pt backdrop blur with *no fill*,
        /// and over the email step's smooth burst a blur of that gradient is
        /// indistinguishable from the gradient. So the design has no visible
        /// container there, and every attempt to draw one looked like a bug:
        /// `ultraThinMaterial` read as a murky purple slab, and blurring the
        /// still behind it needed a white veil to keep the disabled button
        /// legible, which put a hard-edged pale band across the art.
        ///
        /// The button carries its own legibility instead — see `NeutralCTA`.
        case none
    }

    var surface: Surface = .solid
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 4) { content }
            .padding(.horizontal, OnboardingSpec.ctaInset)
            .padding(.top, 16)
            .padding(.bottom, 24)
            .frame(width: OnboardingSpec.size.width)
            .background { backdrop }
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24,
                                              style: .continuous))
    }

    @ViewBuilder
    private var backdrop: some View {
        switch surface {
        case .solid:
            Rectangle().fill(.white)
                .overlay(alignment: .top) {
                    Rectangle().fill(OnboardingSpec.C.borderSubtle).frame(height: 1)
                }
        case .none:
            Color.clear
        }
    }
}

// MARK: - keyboard

/// Publishes the keyboard's height in **device** points.
///
/// The flow renders at 375 × 812 and scales the whole stage to the device, so a
/// keyboard height measured in device points has to be divided by
/// `\.stageScale` before it can be used as an offset inside a step. Getting
/// that wrong is invisible on a 375-wide phone and wrong everywhere else.
struct KeyboardHeight: ViewModifier {
    @Binding var height: CGFloat

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(
                for: UIResponder.keyboardWillShowNotification)) { note in
                guard let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
                        as? CGRect else { return }
                let duration = note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey]
                    as? Double ?? 0.25
                withAnimation(.easeOut(duration: duration)) { height = frame.height }
            }
            .onReceive(NotificationCenter.default.publisher(
                for: UIResponder.keyboardWillHideNotification)) { note in
                let duration = note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey]
                    as? Double ?? 0.25
                withAnimation(.easeOut(duration: duration)) { height = 0 }
            }
    }
}

extension View {
    func keyboardHeight(_ height: Binding<CGFloat>) -> some View {
        modifier(KeyboardHeight(height: height))
    }
}

/// How much the 375 × 812 stage is scaled to reach the device.
private struct StageScaleKey: EnvironmentKey { static let defaultValue: CGFloat = 1 }

extension EnvironmentValues {
    var stageScale: CGFloat {
        get { self[StageScaleKey.self] }
        set { self[StageScaleKey.self] = newValue }
    }
}
