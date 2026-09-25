import SwiftUI

/// Step 5 — `Profile Pic` (845:50352).
///
/// Built from the design's own avatar renders and its type/spacing tokens; the
/// picker interaction is mine, since the frame only shows a resting state. Swipe
/// the big avatar either way to cycle, or tap a chip to jump — both land on the
/// same `select` path so the haptic fires once per change however you got there.
struct AvatarSelectView: View {
    @ObservedObject var tune: OnboardingTuning
    var onContinue: (Int) -> Void

    private let avatars = (1...15).map { "onb_av_\($0)" }
    @State private var index = 0
    @State private var drag: CGFloat = 0
    @State private var appeared = false
    /// 0…1 pulse driven by a commit, for the treatments that need a transient
    /// rather than a steady state (the glass scrim).
    @State private var flash: Double = 0
    /// True for the length of a shake-shuffle, so a second shake mid-spin does
    /// not start a competing one.
    @State private var shuffling = false
    /// Pulses the hint chip when a shake is picked up, so the gesture is
    /// acknowledged even before the avatar has finished moving.
    @State private var hintPulse = false

    var body: some View {
        ZStack(alignment: .top) {
            backdrop

            VStack(spacing: 0) {
                StepDots(active: 1)
                    .padding(.top, 76)

                VStack(spacing: 8) {
                    Text("Choose an avatar\nfor yourself")
                        .font(OnboardingSpec.F.h32)
                        .tracking(-0.25)
                        .lineSpacing(2)
                    Text("You can change this any time")
                        .font(OnboardingSpec.F.b16)
                        .tracking(-0.15)
                        .foregroundStyle(OnboardingSpec.C.tertiary)
                }
                .multilineTextAlignment(.center)
                .foregroundStyle(OnboardingSpec.C.primary)
                .frame(width: 279)
                .padding(.top, 20)

                hero.padding(.top, 28)

                shakeHint.padding(.top, 18)

                Spacer(minLength: 0)

                row.padding(.bottom, 20)

                CTABar {
                    NeutralCTA(title: "Continue") { onContinue(index) }
                }
            }
            .frame(height: OnboardingSpec.size.height)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 18)
        }
        .frame(width: OnboardingSpec.size.width, height: OnboardingSpec.size.height,
               alignment: .top)
        .onShake { shuffle() }
        .onAppear {
            Haptics.shared.prepare()
            withAnimation(.spring(response: 0.46, dampingFraction: 0.84)) { appeared = true }
            if ProcessInfo.processInfo.arguments.contains("-avatarDemo") { runDemo() }
            // `simctl` has no shake command, so the shuffle is reachable by
            // launch argument as well as by the real gesture.
            if ProcessInfo.processInfo.arguments.contains("-shakeDemo") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { self.shuffle() }
            }
        }
    }

    /// The gesture is invisible unless it is named, so it gets a highlighted
    /// chip rather than the grey caption the other hints use — it is an offer,
    /// not a label.
    private var shakeHint: some View {
        HStack(spacing: 7) {
            Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                .font(.system(size: 13, weight: .semibold))
            Text(shuffling ? "Shuffling…" : "Shake to shuffle")
                .font(OnboardingSpec.F.b14s)
                .tracking(-0.1)
        }
        .foregroundStyle(OnboardingSpec.C.actionBold)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(OnboardingSpec.C.brandBlue100, in: Capsule())
        .overlay(Capsule().strokeBorder(OnboardingSpec.C.actionBold.opacity(0.22), lineWidth: 1))
        .scaleEffect(hintPulse ? 1.08 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.55), value: hintPulse)
        .animation(.easeOut(duration: 0.2), value: shuffling)
    }

    /// Shake to land somewhere random.
    ///
    /// Implemented as a short walk rather than a single jump: `select` already
    /// dissolves between avatars, so stepping through six to nine of them at
    /// 95ms reads as a spin that settles, which is what "land on a random
    /// avatar" wants. A single jump to a random index is indistinguishable from
    /// a swipe. The hop count skips multiples of the set size so a shuffle can
    /// never land back where it started.
    private func shuffle() {
        guard !shuffling, appeared else { return }
        shuffling = true
        hintPulse = true
        Haptics.shared.tap()

        var hops = Int.random(in: 6...9)
        if hops % avatars.count == 0 { hops += 1 }

        for n in 1...hops {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08 + Double(n) * 0.095) {
                self.select(self.index + 1)
                if n == hops {
                    self.shuffling = false
                    self.hintPulse = false
                    Haptics.shared.success()
                }
            }
        }
    }

    /// Cycles on a timer so the dissolve can be captured mid-flight.
    ///     xcrun simctl launch <udid> com.noon.gyroqr -onbStep Avatar \
    ///         -avatarDemo -avatarStyle Zoom
    private func runDemo() {
        for n in 1...6 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4 + Double(n) * 1.3) {
                self.select(self.index + 1)
            }
        }
    }

    /// `BG` 845:50353 — a 188pt brand-blue wash at the top of the screen that
    /// the header sits on.
    private var backdrop: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [OnboardingSpec.C.brandBlue100, .white],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: 188)
            Color.white
        }
    }

    // MARK: hero

    /// Blur carried by the drag itself, so the gesture reads as scrubbing
    /// through the set rather than nudging one picture around.
    private var scrubBlur: CGFloat {
        guard tune.dragBlur else { return 0 }
        return min(CGFloat(tune.avatarBlur) * 0.6, abs(drag) * CGFloat(tune.dragBlurAmount))
    }

    private var hero: some View {
        ZStack {
            ForEach(Array(avatars.enumerated()), id: \.offset) { i, name in
                let active = i == index
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 280, height: 280)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(.white, lineWidth: 6))
                    .shadow(color: .black.opacity(0.10), radius: 18, y: 10)
                    // Both sides of the swap animate on one curve, so the eye
                    // reads a single dissolve instead of two fades crossing.
                    .blur(radius: active ? 0 : inactiveBlur)
                    .scaleEffect(active ? 1 : inactiveScale)
                    .opacity(active ? 1 : 0)
            }
        }
        .frame(width: 280, height: 280)
        .overlay {
            if tune.avatarStyle == .material {
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(Circle().strokeBorder(.white.opacity(0.5), lineWidth: 6))
                    .opacity(flash)
                    .allowsHitTesting(false)
            }
        }
        .blur(radius: scrubBlur)
        .rotationEffect(.degrees(Double(drag) * 0.02))
        .offset(x: drag * 0.35)
        .gesture(
            DragGesture(minimumDistance: 8)
                .onChanged { drag = $0.translation.width }
                .onEnded { v in
                    let step = v.translation.width < -50 ? 1 : (v.translation.width > 50 ? -1 : 0)
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) { drag = 0 }
                    if step != 0 { select(index + step) }
                }
        )
        .animation(.spring(response: tune.avatarResponse, dampingFraction: 0.85), value: index)
    }

    private var inactiveBlur: CGFloat {
        switch tune.avatarStyle {
        case .cut, .material: 0
        case .crossBlur, .zoom: CGFloat(tune.avatarBlur)
        }
    }

    private var inactiveScale: CGFloat {
        switch tune.avatarStyle {
        case .cut, .material: 1
        case .crossBlur: 0.96
        case .zoom: 1.14
        }
    }

    // MARK: row

    /// The avatar row.
    ///
    /// Fifteen of them, so this scrolls — a fixed `HStack` comes to 948pt on a
    /// 375pt screen. What is arriving at either edge is blurred, faded and
    /// small, and sharpens as it comes in, which is Image Playground's
    /// suggestion rows: the reference recording changes a row's contents in
    /// 0.2–0.4s episodes with the items staggered across them, so the effect
    /// belongs to where an item *is* rather than to a transition played once.
    ///
    /// `scrollTransition` is what makes that a property of position rather
    /// than something driven by hand. `phase.value` runs −1 at the leading
    /// edge, 0 fully on screen, +1 at the trailing edge, and it is live during
    /// the drag, so the reveal tracks the finger and resolves itself when the
    /// scroll settles — no offset arithmetic and no geometry readers.
    private var row: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(Array(avatars.enumerated()), id: \.offset) { i, name in
                        Button { select(i) } label: { chip(name, on: i == index) }
                            .buttonStyle(.plain)
                            .id(i)
                            .scrollTransition(.interactive, axis: .horizontal) { view, phase in
                                let t = abs(phase.value)
                                return view
                                    .blur(radius: t * CGFloat(tune.rowBlur))
                                    .opacity(1 - t * tune.rowFade)
                                    .scaleEffect(1 - t * CGFloat(tune.rowShrink))
                            }
                    }
                }
                // Half a chip of inset, so the first and last can reach the
                // middle of the row instead of stopping against the edge with
                // the blur still on them.
                .padding(.horizontal, 26)
                // And room above and below. A `ScrollView` clips to its own
                // bounds, and the chip's layout height is only its 52pt — the
                // selection ring sits 5.5pt outside that and a 9pt blur
                // spreads further still, so both were being sliced off flat
                // top and bottom. The frame below is 52 + 2 × 14.
                .padding(.vertical, 14)
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .frame(height: 80)
            // The hero can also be changed by swiping it or shaking the phone,
            // and a selection the row is not showing is worse than no row.
            .onChange(of: index) { _, i in
                withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                    proxy.scrollTo(i, anchor: .center)
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: index)
    }

    private func chip(_ name: String, on: Bool) -> some View {
        Image(name)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 52, height: 52)
            .clipShape(Circle())
            .overlay(
                Circle().strokeBorder(on ? OnboardingSpec.C.actionBold : .clear,
                                      lineWidth: 3)
                .padding(-4)
            )
    }

    /// Wraps, so cycling never dead-ends at either edge.
    private func select(_ raw: Int) {
        let next = (raw % avatars.count + avatars.count) % avatars.count
        guard next != index else { return }
        index = next
        Haptics.shared.cycleTick()

        guard tune.avatarStyle == .material else { return }
        // The scrim has to peak mid-change and clear, so it needs its own
        // there-and-back rather than a value that tracks `index`.
        let r = tune.avatarResponse
        withAnimation(.easeOut(duration: r * 0.45)) { flash = 1 }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(r * 0.45))
            withAnimation(.easeIn(duration: r * 0.75)) { flash = 0 }
        }
    }
}
