import SwiftUI

/// Step 3 — `Check your mail` (845:48967 and its sibling states).
///
/// The illustration is the designer's dotLottie (`otp_email_pop.lottie`, from
/// `Email-Pop .lottie`, 480 × 280 at 60fps, 2.5s); the
/// four boxes, the keypad hand-off and the toast are built here.
struct OTPView: View {
    @ObservedObject var tune: OnboardingTuning
    let email: String
    var onVerified: () -> Void

    /// Any four digits are accepted. Pinning it to the design's 4891 meant
    /// retyping one specific code on every pass through the flow for no
    /// prototype value. `OnboardingTuning.otpAlwaysFails` is what reaches the
    /// rejection state now — otherwise its toast and error haptic would have no
    /// way in at all.
    private let count = 4

    @State private var code = ""
    @State private var shake: CGFloat = 0
    @State private var locked = false        // true once the right code lands
    @State private var toast: Toast?
    @FocusState private var focused: Bool
    @State private var keyboard: CGFloat = 0

    // MARK: illustration size
    //
    // The design draws the burst at full bleed — roughly 500pt of canvas across
    // a 375pt screen, so it runs off both edges — and 231pt tall. At that size
    // the column below it reaches y 612, and the keypad starts at ~542. One of
    // the two has to give.
    //
    // So the artwork carries two sizes and the keyboard picks between them.
    // Keyboard down is the design: the step opens at full size, which is what
    // you see before touching anything. Raising the keypad shrinks the burst by
    // exactly the 97pt the boxes and Resend row need, and because the art sits
    // in the same VStack everything below follows on its own — no manual lift,
    // nothing to keep in sync.

    /// Design size, from `Mail ID - OTP` (845:48811 and siblings).
    private let artRelaxedWidth: CGFloat = 500
    /// Small enough that the Resend row clears the number pad by ~27pt.
    private let artCompactWidth: CGFloat = 290
    /// Fraction of the clip's own width that the artwork occupies vertically.
    /// The 480 × 280 canvas draws the art from y 4 to 222 — high in the
    /// canvas, with empty air under it; this is that band plus 4pt each side.
    private let artBandRatio: CGFloat = 226.0 / 480.0
    /// How far the band's centre sits above the canvas centre: 113 vs 140.
    private let artBandLift: CGFloat = 27.0 / 480.0

    private var compact: Bool { keyboard > 0 }
    private var artWidth: CGFloat { compact ? artCompactWidth : artRelaxedWidth }
    private var artHeight: CGFloat { artWidth * artBandRatio }
    private var artCanvasHeight: CGFloat { artWidth * 280 / 480 }

    var body: some View {
        ZStack(alignment: .top) {
            Color.white

            // The design frame parks the keypad at y 515, right over its own
            // Resend row — fine in a static mock, not in a build where you have
            // to tap it. Rather than translate the column (which slides the
            // illustration under the status bar) the two gaps are tightened
            // from 48/24 to 32/16, which buys back the 45pt the row needed.
            VStack(spacing: 32) {
                header
                entry
            }
            .frame(width: 308)
            .padding(.top, 77)               // Figma: container at y 77
        }
        .frame(width: OnboardingSpec.size.width, height: OnboardingSpec.size.height,
               alignment: .top)
        // The field that actually owns the keyboard. Kept invisible and behind
        // the boxes: the boxes are the UI, this is only the text input.
        .overlay(alignment: .top) {
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($focused)
                .opacity(0.001)
                .frame(width: 1, height: 1)
                .allowsHitTesting(false)
                .onChange(of: code) { old, new in handle(old: old, new: new) }
        }
        .toastHost($toast)
        .keyboardHeight($keyboard)
        .animation(.spring(response: 0.46, dampingFraction: 0.86), value: compact)
        .onAppear {
            Haptics.shared.prepare()
            // Held back so the burst is read at design size first and the
            // shrink registers as the keypad arriving, not as a layout glitch.
            // `-otpNoFocus` holds the keyboard down so the relaxed layout can
            // be captured; without it the keypad is up within a second and the
            // design-size state is gone before a screenshot lands.
            if !ProcessInfo.processInfo.arguments.contains("-otpNoFocus") {
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(680))
                    focused = true
                }
            }
            if demoMode { runDemo() }
        }
    }

    // MARK: scripted driver
    //
    // `simctl` cannot synthesise taps, so this replays entry through the same
    // `handle` path the keypad drives — wrong code first, then the right one —
    // which means the haptics and both toasts are genuinely exercised.
    //     xcrun simctl launch <udid> com.noon.gyroqr -onbStep OTP -otpDemo
    private var demoMode: Bool { ProcessInfo.processInfo.arguments.contains("-otpDemo") }

    private func runDemo() {
        func at(_ t: Double, _ f: @escaping () -> Void) {
            DispatchQueue.main.asyncAfter(deadline: .now() + t, execute: f)
        }
        func type(_ s: String, from base: Double) {
            for (i, _) in s.enumerated() {
                at(base + Double(i) * 0.35) { code = String(s.prefix(i + 1)) }
            }
        }
        // Whether this lands as accepted or rejected is down to
        // `otpAlwaysFails`, so one pass exercises whichever state is selected.
        type("7203", from: 1.2)   // deliberately not the design's 4891
    }

    // MARK: input

    private func handle(old: String, new: String) {
        guard !locked else { code = old; return }
        let digits = String(new.filter(\.isNumber).prefix(count))
        if digits != new { code = digits; return }
        if digits.count > old.count { Haptics.shared.keyTick() }
        if digits.count == count { verify(digits) }
    }

    private func verify(_ entered: String) {
        if !tune.otpAlwaysFails {
            locked = true
            focused = false
            Haptics.shared.success()
            toast = Toast(kind: .success, message: "OTP Verified, you’re through!")
            // Let the toast land and be read before the step changes under it.
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(950))
                onVerified()
            }
        } else {
            Haptics.shared.failure()
            toast = Toast(kind: .failure, message: "That code didn’t match")
            withAnimation(.spring(response: 0.28, dampingFraction: 0.32)) { shake = 1 }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(240))
                var t = Transaction(); t.disablesAnimations = true
                withTransaction(t) { shake = 0 }
                withAnimation(.easeOut(duration: 0.2)) { code = "" }
            }
        }
    }

    // MARK: header

    private var header: some View {
        VStack(spacing: 24) {
            VStack(spacing: 20) {
                // A fixed-width placeholder so the artwork's own size never
                // moves the column horizontally; the clip is drawn in an
                // overlay on top of it.
                Color.clear
                    .frame(width: 269, height: artHeight)
                    .overlay {
                        LottieHost(name: "otp_email_pop", loop: .playOnce)
                            .frame(width: artWidth, height: artCanvasHeight)
                            .offset(y: artWidth * artBandLift)
                            // Crop the canvas' empty air vertically only. The
                            // relaxed width is wider than the screen on
                            // purpose — the design bleeds the burst off both
                            // edges — so the horizontal frame is oversized and
                            // never clips. The stage's own clip takes the
                            // overhang.
                            .frame(width: 760, height: artHeight)
                            .clipped()
                    }
                    .allowsHitTesting(false)

                Text("Check your mail")
                    .font(OnboardingSpec.F.h32)
                    .tracking(-0.25)
                    .foregroundStyle(OnboardingSpec.C.primary)
                    .frame(width: 269)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 14) {
                Text("We have sent a 4 digit code to")
                    .font(OnboardingSpec.F.b16)
                    .tracking(-0.15)
                    .foregroundStyle(OnboardingSpec.C.tertiary)
                    .multilineTextAlignment(.center)
                    .frame(width: 215)

                HStack(spacing: 10) {
                    Text(email)
                        .font(OnboardingSpec.F.b14)
                        .tracking(-0.1)
                        .foregroundStyle(OnboardingSpec.C.primary)
                    Image("ic_edit")
                        .resizable()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(OnboardingSpec.C.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(OnboardingSpec.C.surfaceTert)
                .clipShape(Capsule())
            }
        }
        .frame(width: 269)
    }

    // MARK: boxes + resend

    private var entry: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ForEach(0..<count, id: \.self) { i in box(i) }
            }
            .offset(x: shake == 0 ? 0 : -10)
            .contentShape(Rectangle())
            .onTapGesture { if !locked { focused = true } }

            HStack(spacing: 0) {
                Text("Didn’t get it? ")
                    .font(OnboardingSpec.F.b14)
                    .tracking(-0.1)
                    .foregroundStyle(OnboardingSpec.C.tertiary)
                Button {
                    Haptics.shared.tap()
                    code = ""
                    focused = true
                    toast = Toast(kind: .success, message: "New code on its way")
                } label: {
                    Text("Resend")
                        .font(OnboardingSpec.F.a14)
                        .foregroundStyle(OnboardingSpec.C.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .frame(height: 28)
                }
                .buttonStyle(.plain)
                .disabled(locked)
            }
        }
        .frame(width: 308)
    }

    /// One 68 × 80 slot. The box the next digit will land in carries the blue
    /// border; filled and empty boxes both sit on the same grey plate, so the
    /// only thing that moves the eye is the caret box and the digit itself.
    private func box(_ i: Int) -> some View {
        let chars = Array(code)
        let filled = i < chars.count
        let isNext = i == chars.count && !locked

        return ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(OnboardingSpec.C.grey100)
            if filled {
                Text(String(chars[i]))
                    .font(OnboardingSpec.F.h40)
                    .tracking(-0.25)
                    .foregroundStyle(OnboardingSpec.C.grey1000)
                    .transition(.scale(scale: 0.55).combined(with: .opacity))
            }
        }
        .frame(width: 68, height: 80)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(borderColour(isNext: isNext), lineWidth: 1)
        )
        .animation(.spring(response: 0.26, dampingFraction: 0.7), value: filled)
        .animation(.easeOut(duration: 0.15), value: isNext)
    }

    private func borderColour(isNext: Bool) -> Color {
        if shake != 0 { return OnboardingSpec.C.errorBold }
        if locked { return OnboardingSpec.C.successBold }
        return isNext ? OnboardingSpec.C.actionBold : .white
    }
}
