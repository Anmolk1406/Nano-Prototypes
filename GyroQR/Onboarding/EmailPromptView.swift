import SwiftUI

/// Step 2 — `Let's get started` (845:49201).
///
/// The backdrop is the splash clip's final frame, held as a still. The design
/// rebuilds that burst from ~60 vector layers plus blend modes; re-deriving it
/// in SwiftUI would be a lot of work for a picture we already have pixel-exact
/// out of the video the designer supplied.
struct EmailPromptView: View {
    var onSend: (String) -> Void

    @State private var email = ""
    @State private var appeared = false
    @State private var keyboard: CGFloat = 0
    @FocusState private var focused: Bool
    @Environment(\.stageScale) private var stageScale

    /// Anything non-empty. This gates a prototype CTA, not an account, and
    /// having to type a plausible address just to get to the next step is
    /// friction with nothing behind it.
    private var valid: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// The keyboard's height expressed in stage points.
    ///
    /// The step is laid out at 375 × 812 and the stage is then scaled to the
    /// device, so a height measured in device points would over-shift by
    /// exactly that scale factor.
    private var lift: CGFloat { keyboard / max(stageScale, 0.01) }

    var body: some View {
        ZStack(alignment: .top) {
            // Tap-to-dismiss lives here, on the backdrop, and nowhere else.
            // It used to sit on the step's root, where it covered the card too:
            // a tap gesture on an *ancestor* of a `TextField` claims the touch
            // and the field never takes focus. Hit testing still reaches the
            // field in that state, so it looks alive and does nothing.
            Image("splash_hold")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: OnboardingSpec.size.width, height: OnboardingSpec.size.height)
                .clipped()
                .contentShape(Rectangle())
                .onTapGesture { focused = false }

            // The card sits directly on top of the CTA tray, and the tray is
            // pinned to the bottom, so one lift moves both and the CTA lands on
            // the keyboard rather than under it.
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                card
                    .padding(.bottom, 96)          // Figma: bottom 96
                    .offset(y: appeared ? 0 : 40)
                    .opacity(appeared ? 1 : 0)
            }
            .frame(height: OnboardingSpec.size.height)
            .offset(y: -lift)

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                CTABar(surface: .none) {
                    NeutralCTA(title: "Send OTP", enabled: valid) {
                        focused = false
                        onSend(email)
                    }
                }
                .offset(y: appeared ? 0 : 120)
            }
            .frame(height: OnboardingSpec.size.height)
            .offset(y: -lift)
        }
        .frame(width: OnboardingSpec.size.width, height: OnboardingSpec.size.height)
        .keyboardHeight($keyboard)
        .onAppear {
            withAnimation(.spring(response: 0.52, dampingFraction: 0.82).delay(0.08)) {
                appeared = true
            }
            if ProcessInfo.processInfo.arguments.contains("-emailDemo") { runDemo() }
            if ProcessInfo.processInfo.arguments.contains("-hitProbe") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    HitProbe.textField(label: "email")
                }
            }
        }
    }

    /// Raises the keyboard and types, so the lift and the CTA arming can both be
    /// captured without a finger.
    ///     xcrun simctl launch <udid> com.noon.gyroqr -onbStep Email -emailDemo
    private func runDemo() {
        func at(_ t: Double, _ f: @escaping () -> Void) {
            DispatchQueue.main.asyncAfter(deadline: .now() + t, execute: f)
        }
        at(1.2) { focused = true }
        let text = "kiaan"
        for (i, _) in text.enumerated() {
            at(2.2 + Double(i) * 0.18) { email = String(text.prefix(i + 1)) }
        }
        // The Simulator suppresses the software keyboard whenever a hardware
        // one is attached, so on that target the real notification never
        // arrives and the lift cannot be seen. Posting the notification drives
        // the same observer and the same offset maths with a stand-in height;
        // on a device UIKit posts the real one.
        if ProcessInfo.processInfo.arguments.contains("-fakeKeyboard") {
            at(3.4) {
                NotificationCenter.default.post(
                    name: UIResponder.keyboardWillShowNotification, object: nil,
                    userInfo: [
                        UIResponder.keyboardFrameEndUserInfoKey:
                            CGRect(x: 0, y: 538, width: 402, height: 336),
                        UIResponder.keyboardAnimationDurationUserInfoKey: 0.25,
                    ])
            }
        }
    }

    // `Container` 845:49545 — 343 wide, radius 24, 80% white over a 40pt blur.
    private var card: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text("Let’s get started")
                    .font(OnboardingSpec.F.h32)
                    .tracking(-0.25)
                    .foregroundStyle(OnboardingSpec.C.primary)
                Text("Let’s first verify your email ID")
                    .font(OnboardingSpec.F.b16)
                    .tracking(-0.15)
                    .foregroundStyle(OnboardingSpec.C.grey500)
            }
            .multilineTextAlignment(.center)
            .frame(width: 269)

            field
            agreement
        }
        .padding(.top, 24)
        .padding(.bottom, 16)
        .padding(.horizontal, 16)
        .frame(width: 343)
        .background(.white.opacity(0.86))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(.white, lineWidth: 1))
    }

    // `M-Input-alt` 845:49566 — label row above the value, inside one 56pt field.
    private var field: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 2) {
                    Text("Email ID")
                        .foregroundStyle(OnboardingSpec.C.secondary)
                    Text("*")
                        .foregroundStyle(OnboardingSpec.C.errorBold)
                }
                .font(OnboardingSpec.F.b12)
                .tracking(-0.1)

                TextField("name@email.com", text: $email)
                    .accessibilityIdentifier("emailField")
                    .font(OnboardingSpec.F.b14s)
                    .tracking(-0.1)
                    .foregroundStyle(OnboardingSpec.C.primary)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                    .submitLabel(.go)
                    .focused($focused)
                    .onSubmit { if valid { onSend(email) } }
            }
            Image("ic_check_circle")
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundStyle(OnboardingSpec.C.successBold)
                .opacity(valid ? 1 : 0)
                .scaleEffect(valid ? 1 : 0.6)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: valid)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(height: 56)
        // The text line is only ~22pt tall inside a 56pt row, so most of the
        // field is not a touch target. This layer takes the rest.
        //
        // It has to be a `.background` — a sibling layer *behind* the field —
        // and not a gesture on the row itself: a tap gesture on an ancestor of a
        // `TextField` claims the touch and the field never focuses. Behind it,
        // the field still wins its own taps and this only catches what lands on
        // the label and the padding.
        .background {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { focused = true }
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder(focused ? OnboardingSpec.C.actionBold : OnboardingSpec.C.borderSubtle,
                          lineWidth: 1))
        .animation(.easeOut(duration: 0.15), value: focused)
    }

    private var agreement: some View {
        HStack(spacing: 8) {
            Image("ic_info_circle")
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundStyle(OnboardingSpec.C.grey500)
            Text("By continuing I agree to the Terms & Conditions")
                .font(OnboardingSpec.F.b12)
                .tracking(-0.1)
                .foregroundStyle(OnboardingSpec.C.tertiary)
        }
    }
}
