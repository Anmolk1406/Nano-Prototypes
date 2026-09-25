import SwiftUI
import AVFoundation

/// Step 1 — `Splash Setup - Burst 2` (845:48810).
///
/// The designer's export is VP9-in-WebM, which iOS cannot decode at all, so the
/// build step transcodes it to H.264 (`Tools/make_onboarding.py`). There is no
/// alpha channel in the source, so a plain opaque mp4 loses nothing.
///
/// The clip ends on the hero shot — burst, logo, characters — and the email step
/// keeps that exact frame as its backdrop, so the hand-off reads as one
/// continuous scene rather than two screens.
struct SplashView: View {
    var onFinish: () -> Void

    var body: some View {
        ZStack {
            // Behind the video, so the very first frame can never flash white.
            Color(hex: 0x9B5DE5).ignoresSafeArea()
            VideoLayer(resource: "splash_burst", ext: "mp4", onEnd: onFinish)
                .ignoresSafeArea()
        }
        // Tapping skips ahead — a 2.5s splash gets old fast when you are
        // reviewing the steps that follow it.
        .contentShape(Rectangle())
        .onTapGesture { onFinish() }
    }
}

/// Plays a bundled clip once on an `AVPlayerLayer`.
///
/// `AVKit.VideoPlayer` would bring its own transport controls and inset the
/// video; a bare player layer is what gives an edge-to-edge frame with nothing
/// drawn over it.
private struct VideoLayer: UIViewRepresentable {
    let resource: String
    let ext: String
    var onEnd: () -> Void

    func makeUIView(context: Context) -> PlayerView {
        let v = PlayerView()
        guard let url = Bundle.main.url(forResource: resource, withExtension: ext) else {
            assertionFailure("missing \(resource).\(ext) in the bundle")
            return v
        }
        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        player.isMuted = true
        // Hold the last frame instead of snapping back to black.
        player.actionAtItemEnd = .pause
        v.playerLayer.player = player
        v.playerLayer.videoGravity = .resizeAspectFill

        context.coordinator.observe(item: item, onEnd: onEnd)
        player.play()
        return v
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        private var token: NSObjectProtocol?
        func observe(item: AVPlayerItem, onEnd: @escaping () -> Void) {
            token = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main
            ) { _ in MainActor.assumeIsolated { onEnd() } }
        }
        deinit { if let token { NotificationCenter.default.removeObserver(token) } }
    }

    /// A UIView whose backing layer *is* the player layer, so it resizes with
    /// the view instead of needing a manual `layoutSubviews` pass.
    final class PlayerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
}
