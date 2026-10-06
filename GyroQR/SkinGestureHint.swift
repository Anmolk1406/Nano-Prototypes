import SwiftUI
import Lottie

/// The two gestures the skin picker coaches, each with its hand animation.
enum CoachGesture {
    /// Swipe up to change — `hint_hand_swipe_up.lottie`, Figma 1060:19706.
    case up
    /// Drag down to confirm — `hint_hand_pull_down.lottie`, Figma 1060:19705.
    case down

    var text: String {
        switch self {
        case .up:   "Swipe up to change"
        case .down: "Drag down to confirm"
        }
    }

    var animation: String {
        switch self {
        case .up:   "hint_hand_swipe_up"
        case .down: "hint_hand_pull_down"
        }
    }
}

/// When things happen in a hand hint, in seconds from its start.
///
/// THE SAME NUMBERS ARE IN `Tools/ae/build_gesture_hint.jsx`, which builds
/// the hand animations, so the card the picker nudges moves while the finger
/// drags and settles back as it lets go. Change one, change the other, and
/// re-run the pipeline:
///
///     python3 Tools/build_gesture_hint_layers.py
///     ae/build_gesture_hint.jsx, then ae/export_gesture_hint.jsx
///     python3 Tools/pack_gesture_hint.py
enum GestureHintTiming {
    /// The finger touches down; the drag starts.
    static let press = 0.35
    /// The drag ends and the finger lifts.
    static let lift = 1.05
    /// The animation's full length, fade included.
    static let total = 2.0
    /// Where the last layer has faded out (the hand, 1.1 → 1.5). The file
    /// runs to 2.0, but its last 0.5s is empty, so playback stops here and
    /// the next gesture starts here.
    static let visibleEnd = 1.5
    /// How long the card takes to settle back after the lift — the hand's
    /// own fade, 1.05 → 1.45.
    static let settle = 0.4

    static var drag: Double { lift - press }

    /// The drag's curve: ease-in-out cubic, as the AE expression has it.
    static var dragCurve: Animation { .timingCurve(0.65, 0, 0.35, 1, duration: drag) }
}

/// The hand animation for one gesture, played once from the start each time
/// `tick` changes.
///
/// Both files are read up front and kept (`preload()`), so a hint's first
/// frame lands on the frame the picker starts the card's nudge from — an
/// asynchronous load here would put the finger a beat behind the card.
struct GestureHintHand: View {
    let gesture: CoachGesture
    let tick: Int

    /// The comp's size in points: 240 × 580 at 2x.
    static let size = CGSize(width: 120, height: 290)
    /// Where the design's 118 × 180.6 frame sits in the comp, and where the
    /// finger's track runs in that frame, in points.
    static let frameOrigin = CGPoint(x: 1, y: 40)
    static let trackX: CGFloat = 38.93

    @MainActor private static var files = [String: DotLottieFile]()

    /// Reads both files, once. Awaited by the coaching before its first
    /// hint (Lottie won't load synchronously on the main thread).
    @MainActor
    static func preload() async {
        for g in [CoachGesture.up, .down] where files[g.animation] == nil {
            files[g.animation] = try? await DotLottieFile.named(g.animation)
        }
    }

    var body: some View {
        LottieView(dotLottieFile: Self.files[gesture.animation])
            .playbackMode(.playing(.fromProgress(0, toProgress: GestureHintTiming.visibleEnd / GestureHintTiming.total,
                                                 loopMode: .playOnce)))
            .resizable()
            .frame(width: Self.size.width, height: Self.size.height)
            .id(tick)
            .allowsHitTesting(false)
    }
}
