import SwiftUI

/// Knobs for the onboarding steps, exposed in the controls sheet.
@MainActor
final class OnboardingTuning: ObservableObject {

    // MARK: OTP
    //
    // Any four digits are accepted. That leaves the rejection state — its toast
    // and its error haptic — with no way to reach it, so this forces it.
    @Published var otpAlwaysFails = false

    // MARK: interests

    /// Which of the two icon sets on the `Category assets` sheet the interest
    /// tiles use. The sheet draws all ten categories twice and says nothing
    /// about which is the intended one, so both ship and this picks.
    enum CategoryArt: String, CaseIterable, Identifiable {
        /// The upper set — chrome and iridescent glass.
        case chrome = "Chrome"
        /// The lower set — saturated playful 3D, closer to the eight renders
        /// the design frame was drawn with.
        case playful = "Playful"

        var id: String { rawValue }
        var suffix: String { self == .chrome ? "a" : "b" }
    }

    @Published var categoryArt: CategoryArt = .chrome

    // MARK: avatar cycle

    /// How the outgoing and incoming avatars trade places.
    enum AvatarStyle: String, CaseIterable, Identifiable {
        /// Straight crossfade, no blur.
        case cut = "Cut"
        /// The classic one: the outgoing avatar blurs as it fades and the
        /// incoming one arrives blurred and resolves. Both sides animate on the
        /// same curve, so the eye reads a single dissolve rather than two fades.
        case crossBlur = "Cross"
        /// Cross blur plus a scale punch — the incoming avatar comes in a touch
        /// oversized, the way artwork changes in Music.
        case zoom = "Zoom"
        /// A frosted scrim sweeps over the whole avatar mid-change, so the swap
        /// happens behind glass instead of in front of you.
        case material = "Glass"

        var id: String { rawValue }
    }

    @Published var avatarStyle: AvatarStyle = .crossBlur
    /// Peak blur radius on the inactive avatar.
    @Published var avatarBlur: Double = 20
    @Published var avatarResponse: Double = 0.38
    /// Blur that tracks the drag itself, before any change commits — the
    /// feedback that makes the gesture feel like it is scrubbing something.
    @Published var dragBlur = true
    @Published var dragBlurAmount: Double = 0.10

    // shake to shuffle
    /// How hard a jolt has to be to count, in g of user acceleration —
    /// lower is more sensitive. iOS's own shake needs roughly 2g+.
    @Published var shakeThreshold: Double = 0.9
    /// Jolts needed within 0.6s. One is the most sensitive, and also the
    /// easiest to set off by putting the phone down.
    @Published var shakePeaks: Double = 2
    /// The last jolt seen, for setting the threshold by feel.
    @Published var shakeLastPeak: Double = 0

    // avatar row
    //
    // The row went from five fixed chips to fifteen that scroll, and the
    // reference for it is Image Playground's suggestion rows: what is arriving
    // at the edge is blurred and small, and sharpens as it comes in. Measured
    // off the recording, its set changes in episodes of 0.2–0.4s with the items
    // staggered across them, so the blur is a property of an item's *position*
    // rather than a transition played once.
    /// Blur on an item sitting right at the row's edge.
    @Published var rowBlur: Double = 9
    /// How much an edge item fades.
    @Published var rowFade: Double = 0.55
    /// How much an edge item shrinks.
    @Published var rowShrink: Double = 0.22

    /// `simctl` cannot tap the controls sheet, so the two settings that gate a
    /// state worth capturing can be set at launch:
    ///     -otpFail                      reach the rejection state
    ///     -categoryArt Chrome|Playful
    ///     -avatarStyle Cut|Cross|Zoom|Glass
    init() {
        let a = ProcessInfo.processInfo.arguments
        if a.contains("-otpFail") { otpAlwaysFails = true }
        if let i = a.firstIndex(of: "-categoryArt"), i + 1 < a.count,
           let set = CategoryArt(rawValue: a[i + 1]) {
            categoryArt = set
        }
        if let i = a.firstIndex(of: "-avatarStyle"), i + 1 < a.count,
           let style = AvatarStyle(rawValue: a[i + 1]) {
            avatarStyle = style
        }
        // Screenshots cost ~0.4s each, which steps clean over a 0.38s spring.
        // Slowing it down is how the dissolve gets inspected frame by frame.
        if let i = a.firstIndex(of: "-avatarResponse"), i + 1 < a.count,
           let r = Double(a[i + 1]) {
            avatarResponse = r
        }
    }

    func reset() {
        otpAlwaysFails = false
        categoryArt = .chrome
        avatarStyle = .crossBlur
        avatarBlur = 20
        avatarResponse = 0.38
        dragBlur = true
        dragBlurAmount = 0.10
        shakeThreshold = 0.9; shakePeaks = 2
        rowBlur = 9; rowFade = 0.55; rowShrink = 0.22
    }
}
