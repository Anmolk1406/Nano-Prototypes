import SwiftUI

/// Between the OTP and the skin picker — `Nano Wallet / Skins Intro`: the
/// wallet skins burst on screen and settle into "Introducing nano wallet —
/// this one's yours!" (2.7s at 60fps).
///
/// The designer's render has an alpha channel, so it is bundled as HEVC with
/// alpha (`skins_intro.mov`, hvc1, 1.2MB): iOS cannot decode the VP9 WebM, and
/// HEVC-with-alpha plays transparent on a bare `AVPlayerLayer`. It plays on
/// white — the OTP step it follows is white — and its type is dark.
///
/// When it ends it fades itself out to white (0.35s), and only then hands
/// over; the flow fades the skin picker in from white (0.45s,
/// `OnboardingFlow.go(_:fade:)`). One after the other, not crossed — crossed,
/// the clip's last frame and the picker's textured backdrop showed through
/// each other. The picker's own entrance waits 0.35s, so its deck deals in as
/// the fade lands. Tap to skip, as on the splash — it fades out the same way.
struct SkinIntroView: View {
    var onFinish: () -> Void

    @State private var leaving = false

    var body: some View {
        ZStack {
            Color.white
            VideoLayer(resource: "skins_intro", ext: "mov", onEnd: leave)
                .opacity(leaving ? 0 : 1)
        }
        .frame(width: OnboardingSpec.size.width, height: OnboardingSpec.size.height)
        .contentShape(Rectangle())
        .onTapGesture { leave() }
    }

    static let fadeOut = 0.35

    private func leave() {
        guard !leaving else { return }
        withAnimation(.easeIn(duration: Self.fadeOut)) { leaving = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.fadeOut) { onFinish() }
    }
}
