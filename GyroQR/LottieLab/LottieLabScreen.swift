import SwiftUI
import Lottie

/// A plain viewer for the approval Lotties from `L0MNA` — each a full
/// 375 × 812 screen (exported at 2×). Pick one and it plays; Replay runs it
/// again.
struct LottieLabScreen: View {
    private static let items: [(title: String, file: String)] = [
        ("Order", "lab_order_approved"),
        ("Task", "lab_task_approved"),
        ("Reward", "lab_task_reward"),
        ("Top-up", "lab_topup_approved"),
    ]

    @State private var pick = 0
    @State private var run = 0

    var body: some View {
        VStack(spacing: 10) {
            Spacer()
            Picker("", selection: $pick) {
                ForEach(Self.items.indices, id: \.self) { i in Text(Self.items[i].title).tag(i) }
            }
            .pickerStyle(.segmented)
            Button("Replay") { run += 1 }
                .buttonStyle(.borderedProminent)
                .tint(.black)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        // The animation sits behind the controls at exactly the screen's
        // size — as the layout's own content, `.fill` would widen the stack.
        .background {
            GeometryReader { geo in
                LottieView { try await DotLottieFile.named(Self.items[pick].file) }
                    .playing(loopMode: .playOnce)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    // A new identity per pick and per replay restarts it.
                    .id("\(pick)-\(run)")
            }
            .ignoresSafeArea()
        }
        .background(Color.white.ignoresSafeArea())
    }
}
