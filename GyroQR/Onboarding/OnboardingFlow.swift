import SwiftUI

/// The six steps of Figma's `Flow for claude` section (845:48674).
enum OnboardingStep: String, CaseIterable, Identifiable {
    case splash    = "Splash"
    case email     = "Email"
    case otp       = "OTP"
    case intro     = "Intro"
    case skin      = "Skin"
    case avatar    = "Avatar"
    case interests = "Interests"
    case done      = "Home"

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
    /// The next arrival fades instead of pushing — the intro into the picker.
    @State private var fading = false
    /// The skin confirmed on the picker — the home wallet shows it. Starts on
    /// the lego card the design draws, for when Home is opened directly.
    @State private var chosenSkin = 11

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
                    .transition(.asymmetric(insertion: .opacity, removal: .opacity))
            case .email:
                // Arrives by crossfade, not a push: this step's backdrop is
                // the splash clip's final frame, so a fade reads as one
                // continuous shot. It leaves by the push like every page.
                EmailPromptView { entered in
                    email = entered.isEmpty ? email : entered
                    go(.otp)
                }
                .transition(.asymmetric(insertion: .opacity, removal: pushOut))
            case .otp:
                OTPView(tune: tune, email: email) { go(.intro) }
                    .transition(push)
            case .intro:
                // It has already faded itself out to white by the time it
                // calls this, so it simply goes; the picker then fades in.
                SkinIntroView { go(.skin, fade: true) }
                    .transition(.asymmetric(insertion: push, removal: .identity))
                    .zIndex(0)
            case .skin:
                SkinSelectScreen(tune: skinTune, onContinue: { go(.avatar) }, onChosen: { chosenSkin = $0 })
                    .transition(fading ? .asymmetric(insertion: .opacity, removal: pushOut) : push)
                    .zIndex(1)
            case .avatar:
                AvatarSelectView(tune: tune, onBack: { go(.skin) }) { _ in go(.interests) }
                    .transition(push)
            case .interests:
                InterestsView(tune: tune, onBack: { go(.avatar) },
                              onContinue: { _ in go(.done) }, onSkip: { go(.done) })
                    .transition(push)
            case .done:
                // The flow's end: the kid's home. Starting over is a test-UI
                // button (controls sheet → Restart the flow), not part of it.
                KidHomeView(skin: chosenSkin)
                    .transition(push)
            }
        }
        .frame(width: OnboardingSpec.size.width, height: OnboardingSpec.size.height)
    }

    /// The parent flow's push (`ParentFlow.push`): a full-width slide with a
    /// fade, mirrored going back.
    private var push: AnyTransition {
        let inEdge: Edge  = forward ? .trailing : .leading
        return .asymmetric(
            insertion: .move(edge: inEdge).combined(with: .opacity),
            removal:   pushOut)
    }

    private var pushOut: AnyTransition {
        .move(edge: forward ? .leading : .trailing).combined(with: .opacity)
    }

    /// As the parent flow moves: the direction lands a frame ahead of the
    /// step, then the step changes on `ParentSpec.page` (stiffness 320,
    /// damping 28). A removal transition is read off the leaving page as it
    /// was last drawn, so a direction set in the same update as the move
    /// would send the old page out by the edge the previous move used.
    ///
    /// `fade` swaps the push for a 0.45s ease-out fade-in, for the one
    /// hand-off that should not drill: the skins intro into the picker.
    private func go(_ next: OnboardingStep, fade: Bool = false) {
        forward = (next.index ?? 0) >= (step.index ?? 0)
        fading = fade
        DispatchQueue.main.async {
            withAnimation(fade ? .easeOut(duration: 0.45) : ParentSpec.page) { step = next }
        }
    }
}

private extension OnboardingStep {
    var index: Int? { OnboardingStep.allCases.firstIndex(of: self) }
}
