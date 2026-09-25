import SwiftUI
import Lottie

/// Plays a `.lottie` bundle from the app's resources.
///
/// The file the designer exports is a dotLottie archive — a zip carrying the
/// animation JSON plus its six WebP layers. Loading the archive directly is what
/// lets those images resolve; a bare `animation.json` would need an image
/// provider wired up by hand, and the WebPs would have to be unpacked alongside.
struct LottieHost: View {
    let name: String
    var loop: LottieLoopMode = .playOnce
    var speed: CGFloat = 1
    var onFinish: (() -> Void)?

    var body: some View {
        LottieView { try await DotLottieFile.named(name) }
            .playing(loopMode: loop)
            .animationSpeed(speed)
            .animationDidFinish { _ in onFinish?() }
            .resizable()
    }
}
