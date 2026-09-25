import SwiftUI

/// The six steps of Figma's `Flow for claude` section (845:48674).
enum OnboardingStep: String, CaseIterable, Identifiable {
    case splash    = "Splash"
    case email     = "Email"
    case otp       = "OTP"
    case skin      = "Skin"
    case avatar    = "Avatar"
    case interests = "Interests"
    case done      = "Done"

    var id: String { rawValue }

    /// `-onbStep OTP` starts the flow on that step. The Simulator has no touch
    /// input to script, so this is how a single step gets captured without
    /// driving the controls sheet first.
    static var launchOverride: OnboardingStep? {
        let a = ProcessInfo.processInfo.arguments
        guard let i = a.firstIndex(of: "-onbStep"), i + 1 < a.count else { return nil }
        return OnboardingStep(rawValue: a[i + 1])
    }
}

/// Hosts the onboarding steps and owns the hand-off between them.
///
/// Every step is authored at the design's native 375 × 812 and the whole stage
/// is scaled to the device, which keeps one set of numbers — Figma's — in the
/// layout code. `SkinSelectScreen` does its own scaling internally; nested in a
/// 375 × 812 stage its scale factor lands on 1, so it composes unchanged.
struct OnboardingFlow: View {
    @ObservedObject var skinTune: SkinTuning
    @ObservedObject var tune: OnboardingTuning
    @Binding var step: OnboardingStep

    @State private var email = "kiaankhalid@gmail.com"
    @State private var forward = true

    var body: some View {
        GeometryReader { geo in
            let scale = max(geo.size.width / OnboardingSpec.size.width,
                            geo.size.height / OnboardingSpec.size.height)
            stage
                .frame(width: OnboardingSpec.size.width, height: OnboardingSpec.size.height)
                // Steps that offset by a device-point measurement (a keyboard
                // height) need this to convert into stage points.
                .environment(\.stageScale, scale)
                .scaleEffect(scale, anchor: .center)
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
        }
        .ignoresSafeArea()
        .onChange(of: step) { old, new in
            forward = (new.index ?? 0) >= (old.index ?? 0)
        }
    }

    @ViewBuilder
    private var stage: some View {
        ZStack {
            Color.white
            switch step {
            case .splash:
                SplashView { go(.email) }
                    .transition(.opacity)
            case .email:
                // Crossfade, not a push: this step's backdrop is the splash
                // clip's final frame, so a fade reads as one continuous shot.
                EmailPromptView { entered in
                    email = entered.isEmpty ? email : entered
                    go(.otp)
                }
                .transition(.opacity)
            case .otp:
                OTPView(tune: tune, email: email) { go(.skin) }
                    .transition(push)
            case .skin:
                SkinSelectScreen(tune: skinTune, onContinue: { go(.avatar) })
                    .transition(push)
            case .avatar:
                AvatarSelectView(tune: tune) { _ in go(.interests) }
                    .transition(push)
            case .interests:
                InterestsView(tune: tune, onContinue: { _ in go(.done) }, onSkip: { go(.done) })
                    .transition(push)
            case .done:
                DoneView { go(.splash) }
                    .transition(push)
            }
        }
        .frame(width: OnboardingSpec.size.width, height: OnboardingSpec.size.height)
        .animation(.spring(response: 0.5, dampingFraction: 0.88), value: step)
    }

    private var push: AnyTransition {
        let inEdge: Edge  = forward ? .trailing : .leading
        let outEdge: Edge = forward ? .leading : .trailing
        return .asymmetric(
            insertion: .move(edge: inEdge).combined(with: .opacity),
            removal:   .move(edge: outEdge).combined(with: .opacity))
    }

    private func go(_ next: OnboardingStep) {
        forward = (next.index ?? 0) >= (step.index ?? 0)
        step = next
    }
}

private extension OnboardingStep {
    var index: Int? { OnboardingStep.allCases.firstIndex(of: self) }
}

/// A closing card, so the flow has somewhere to land and can be replayed
/// without relaunching the app.
struct DoneView: View {
    var onRestart: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [OnboardingSpec.C.brandBlue100, .white],
                           startPoint: .top, endPoint: .bottom)
            VStack(spacing: 14) {
                Image("ic_check_circle")
                    .resizable()
                    .frame(width: 56, height: 56)
                    .foregroundStyle(OnboardingSpec.C.successBold)
                Text("You’re all set")
                    .font(OnboardingSpec.F.h32)
                    .tracking(-0.25)
                    .foregroundStyle(OnboardingSpec.C.primary)
                Text("That’s the whole onboarding flow")
                    .font(OnboardingSpec.F.b16)
                    .tracking(-0.15)
                    .foregroundStyle(OnboardingSpec.C.tertiary)
            }
            .scaleEffect(appeared ? 1 : 0.9)
            .opacity(appeared ? 1 : 0)

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                CTABar { NeutralCTA(title: "Run it again") { onRestart() } }
            }
        }
        .frame(width: OnboardingSpec.size.width, height: OnboardingSpec.size.height)
        .onAppear {
            Haptics.shared.success()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.66)) { appeared = true }
        }
    }
}
