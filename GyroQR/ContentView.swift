import SwiftUI

/// The prototypes this app hosts.
enum AppScene: String, CaseIterable, Identifiable {
    case qrCard    = "QR card"
    case skinSelect = "Skin select"
    var id: String { rawValue }
}

struct ContentView: View {
    @StateObject private var motion = MotionEngine()
    @StateObject private var tuning = Tuning()
    @StateObject private var skinTune = SkinTuning()
    @State private var showControls = false
    @State private var scene: AppScene = .skinSelect

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.white.ignoresSafeArea()

            switch scene {
            case .qrCard:     ShareScreen(motion: motion, t: tuning)
            case .skinSelect: SkinSelectScreen(tune: skinTune)
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
                    ControlsPanel(motion: motion, t: tuning, skin: skinTune, scene: $scene, expanded: $showControls)
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
