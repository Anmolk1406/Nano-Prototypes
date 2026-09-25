import SwiftUI

/// The prototypes this app hosts.
enum AppScene: String, CaseIterable, Identifiable {
    case onboarding = "Onboarding"
    case qrCard     = "QR card"
    case skinSelect = "Skin select"
    case topUp      = "Top up"
    case account    = "Account"
    var id: String { rawValue }

    /// `-scene "Top up"` opens straight into a scene. The Simulator has no
    /// touch input to script, so this is how a screen other than the default
    /// gets captured without driving the controls sheet first.
    static var launchOverride: AppScene? {
        let a = ProcessInfo.processInfo.arguments
        guard let i = a.firstIndex(of: "-scene"), i + 1 < a.count else { return nil }
        let want = a[i + 1].lowercased()
        return allCases.first { $0.rawValue.lowercased() == want }
    }
}

struct ContentView: View {
    @StateObject private var motion = MotionEngine()
    @StateObject private var tuning = Tuning()
    @StateObject private var skinTune = SkinTuning()
    @StateObject private var onbTune = OnboardingTuning()
    @StateObject private var topUpTune = TopUpTuning()
    /// The account page has one knob — play its entrance again.
    @State private var acctReplay = 0
    @State private var showControls = false
    @State private var scene: AppScene = AppScene.launchOverride ?? .onboarding
    @State private var step: OnboardingStep = OnboardingStep.launchOverride ?? .splash

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.white.ignoresSafeArea()

            switch scene {
            case .onboarding: OnboardingFlow(skinTune: skinTune, tune: onbTune, step: $step)
            case .qrCard:     ShareScreen(motion: motion, t: tuning)
            case .skinSelect: SkinSelectScreen(tune: skinTune)
            case .topUp:      TopUpFlow(tune: topUpTune)
            case .account:    AccountScreen(replay: acctReplay)
            }

            // Dev affordances, not part of the design.
            VStack(alignment: .trailing, spacing: 8) {
                if scene == .qrCard {
                    TiltReadout(out: motion.out,
                                source: motion.source,
                                available: motion.motionAvailable)
                }
                Button { withAnimation(.snappy) { showControls.toggle() } } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.black.opacity(0.45), in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.trailing, 12)
            .padding(.top, 52)   // clear of the status bar and the close button row

            if showControls {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    ControlsPanel(motion: motion, t: tuning, skin: skinTune, onb: onbTune,
                              topUp: topUpTune,
                              scene: $scene, step: $step, expanded: $showControls,
                              accountReplay: $acctReplay)
                }
                .transition(.move(edge: .bottom))
            }
        }
        .onAppear { if scene == .qrCard { motion.start() } }
        .onDisappear { motion.stop() }
        .onChange(of: scene) { _, new in
            // The display link is only worth running for the scene that reads it.
            if new == .qrCard { motion.start() } else { motion.stop() }
        }
    }
}

/// Its own view so that the 120 Hz tilt only invalidates this label, and not
/// the controls alongside it.
private struct TiltReadout: View {
    @ObservedObject var out: MotionOutput
    let source: MotionEngine.Source
    let available: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(source == .motion && available ? .green : .orange)
                .frame(width: 6, height: 6)
            Text(source == .motion && !available ? "no gyro" : source.rawValue.lowercased())
            Text(String(format: "%+.2f %+.2f", out.tilt.x, out.tilt.y)).monospacedDigit()
        }
        .font(.system(size: 10, weight: .medium, design: .rounded))
        .foregroundStyle(.white.opacity(0.9))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.black.opacity(0.35), in: Capsule())
        .allowsHitTesting(false)
    }
}

#Preview { ContentView() }
