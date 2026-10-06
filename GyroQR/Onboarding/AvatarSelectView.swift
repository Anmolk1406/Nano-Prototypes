import SwiftUI
import Lottie

/// Step 5 — `Profile Pic` (1113:27374).
///
/// The design's five 3D avatars, each on its own gradient disc, with a row
/// of them to pick from. The purple swoosh and the two chrome stars are a
/// Lottie built in After Effects (comp `AVATAR_STROKE_STARS`, 375 × 812 so
/// it lays straight over the stage): the swoosh draws on behind the avatar,
/// the stars pop in over it. Swipe the big avatar either way to cycle, tap a
/// chip to jump, or shake to shuffle — all land on `select`, so the haptic
/// fires once per change however you got there.
struct AvatarSelectView: View {
    @ObservedObject var tune: OnboardingTuning
    var onBack: () -> Void = {}
    var onContinue: (Int) -> Void

    /// One avatar: its render, and the colour its disc runs to from white.
    struct Avatar {
        let image: String
        let tint: UInt32
        /// Where the render sits over the 72pt chip circle — its size and
        /// top-left, from each chip's mask group; the hero scales these up.
        let width: CGFloat, height: CGFloat, x: CGFloat, y: CGFloat
        /// Where the disc's gradient starts, as a fraction above its top.
        let lead: CGFloat
        /// The swoosh behind it. The first is the design's #A477FF; the
        /// others are picked to sit against each disc rather than match it.
        let swoosh: UInt32
    }

    static let avatars: [Avatar] = [
        .init(image: "onb3d_av_1", tint: 0x4ED7DE, width: 129.502, height: 194.253, x: -31.962, y: 6.683, lead: 7.32445, swoosh: 0xA477FF),
        .init(image: "onb3d_av_2", tint: 0x5759E3, width: 177.477, height: 266.216, x: -53.363, y: 8.841, lead: 5.96249, swoosh: 0xFF7A8A),
        .init(image: "onb3d_av_3", tint: 0xA9DE4E, width: 101.507, height: 203.017, x: -16.799, y: 0.483, lead: 6.64347, swoosh: 0x4E8BFF),
        .init(image: "onb3d_av_4", tint: 0x4ED7DE, width: 131.716, height: 197.574, x: -31.164, y: 5.906, lead: 3.91955, swoosh: 0xFFB23F),
        .init(image: "onb3d_av_5", tint: 0x3598D2, width: 135.787, height: 203.681, x: -27.783, y: 7.472, lead: 1.87661, swoosh: 0xFF7AD9),
    ]
    private var avatars: [Avatar] { Self.avatars }

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
    @State private var smallKick = StarKick()
    @State private var bigKick = StarKick()

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.white
            KidGridBackdrop()

            // Behind the avatar: the swoosh only, drawn white and tinted
            // here, so a change of avatar can ease its colour across.
            decor(only: "STROKE")
                .colorMultiply(Color(hex: avatars[index].swoosh))
                .animation(.easeInOut(duration: 0.35), value: index)

            hero.position(x: 187.5, y: 400)

            // Over it: the stars, one view each so each can twitch about its
            // own centre when the avatar changes. Same file, same start, so
            // all three stay in step.
            decor(only: "STAR_SM")
                .scaleEffect(smallKick.scale, anchor: Self.smallStar)
                .rotationEffect(smallKick.turn, anchor: Self.smallStar)
            decor(only: "STAR_BIG")
                .scaleEffect(bigKick.scale, anchor: Self.bigStar)
                .rotationEffect(bigKick.turn, anchor: Self.bigStar)

            KidTitle(lines: [
                KidTitleLine(text: "Choose an avatar", frame: CGRect(x: 45, y: 118.485, width: 286, height: 48), angle: 35.5795),
                KidTitleLine(text: "for yourself", frame: CGRect(x: 90.505, y: 149.665, width: 194, height: 48), angle: 46.5235),
            ], bars: [
                CGRect(x: 104.297, y: 147.607, width: 171.947, height: 24.712),
                CGRect(x: 55.562, y: 139.479, width: 215.139, height: 16.006),
            ])

            // Not in the frame: the gesture is invisible unless it is named.
            // It sits in the gap between the disc (ends ~y 540) and the row
            // (starts at 621).
            shakeHint.position(x: 187.5, y: 580)

            row.offset(y: 621.07 - 14)

            KidHeaderBar(active: 1, onBack: onBack)

            ParentActionBar {
                ParentPrimaryButton(title: "Continue") { onContinue(index) }
            }
        }
        .frame(width: OnboardingSpec.size.width, height: OnboardingSpec.size.height,
               alignment: .topLeading)
        .onShake(threshold: tune.shakeThreshold, peaks: Int(tune.shakePeaks.rounded()),
                 onPeak: { tune.shakeLastPeak = $0 }) { shuffle() }
        .onAppear {
            Haptics.shared.prepare()
            appeared = true
            if ProcessInfo.processInfo.arguments.contains("-avatarDemo") { runDemo() }
            // `simctl` has no shake command, so the shuffle is reachable by
            // launch argument as well as by the real gesture.
            if ProcessInfo.processInfo.arguments.contains("-shakeDemo") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { self.shuffle() }
            }
        }
    }

    /// An offer rather than a label, so a highlighted chip rather than the
    /// grey caption the other hints use.
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
        .allowsHitTesting(false)
    }

    private static let layers = ["STROKE", "STAR_SM", "STAR_BIG"]

    /// `avatar_stroke_stars` with every layer but `layer` switched off by
    /// opacity. The swoosh is drawn white, for `colorMultiply` to tint.
    private func decor(only layer: String) -> some View {
        var view = LottieView(animation: .named("avatar_stroke_stars"))
            .playing(loopMode: .playOnce)
            .resizable()
        for other in Self.layers where other != layer {
            view = view.valueProvider(FloatValueProvider(0), for: AnimationKeypath(keypath: "\(other).Transform.Opacity"))
        }
        if layer == "STROKE" {
            view = view.valueProvider(ColorValueProvider(LottieColor(r: 1, g: 1, b: 1, a: 1)),
                                      for: AnimationKeypath(keypath: "STROKE.**.Color"))
        }
        return view
            .frame(width: 375, height: 812)
            .allowsHitTesting(false)
    }

    // The stars' centres on the 375 × 812 canvas, from the comp.
    private static let smallStar = UnitPoint(x: 280.512 / 375, y: 273.963 / 812)
    private static let bigStar = UnitPoint(x: 84.569 / 375, y: 483.326 / 812)

    struct StarKick {
        var scale: CGFloat = 1
        var turn: Angle = .zero
    }

    /// The stars' response to a change of avatar — kept small on purpose: a
    /// quick swell and a few degrees of turn, sprung back with a little
    /// overshoot, about 0.5s in all; the big star follows the small one by
    /// 60ms.
    private func kickStars() {
        func kick(_ k: Binding<StarKick>, turn: Double, scale: CGFloat, after delay: Double) {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.22, dampingFraction: 0.7)) {
                    k.wrappedValue = StarKick(scale: scale, turn: .degrees(turn))
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.55)) { k.wrappedValue = StarKick() }
                }
            }
        }
        // The turns are opposite ways, so the pair reads as a twinkle, not a
        // shared nudge. Keep the small star's anticlockwise: turned
        // clockwise its full-canvas Lottie view stopped drawing after the
        // first kick (seen in the Simulator; the big star was unaffected).
        kick($smallKick, turn: -8, scale: 1.08, after: 0)
        kick($bigKick, turn: 6, scale: 1.06, after: 0.06)
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

    // MARK: hero

    /// Blur carried by the drag itself, so the gesture reads as scrubbing
    /// through the set rather than nudging one picture around.
    private var scrubBlur: CGFloat {
        guard tune.dragBlur else { return 0 }
        return min(CGFloat(tune.avatarBlur) * 0.6, abs(drag) * CGFloat(tune.dragBlurAmount))
    }

    /// `Group 2147227458`: a 269pt disc with a 5.8pt white rim outside it,
    /// its white-to-tint gradient turned 15°, and the render masked to a
    /// 272pt circle over it.
    private var hero: some View {
        ZStack {
            ForEach(avatars.indices, id: \.self) { i in
                let active = i == index
                heroFace(avatars[i])
                    // Both sides of the swap animate on one curve, so the eye
                    // reads a single dissolve instead of two fades crossing.
                    .blur(radius: active ? 0 : inactiveBlur)
                    .scaleEffect(active ? 1 : inactiveScale)
                    .opacity(active ? 1 : 0)
            }
        }
        .frame(width: 284, height: 284)
        .overlay {
            if tune.avatarStyle == .material {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 280.77, height: 280.77)
                    .opacity(flash)
                    .allowsHitTesting(false)
            }
        }
        .blur(radius: scrubBlur)
        .rotationEffect(.degrees(Double(drag) * 0.02))
        .offset(x: drag * 0.35)
        .contentShape(Circle())
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

    private func heroFace(_ a: Avatar) -> some View {
        ZStack {
            Circle()
                .fill(disc(a))
                .frame(width: 269.235, height: 269.235)
                .rotationEffect(.degrees(-15))
                .padding(-5.769)
                .background(Circle().fill(.white))
            render(a, circle: 272.272)
        }
        // The mask circle sits 0.9pt above the disc's centre.
        .frame(width: 284, height: 284)
    }

    /// White to the avatar's tint, starting a little above the circle as
    /// each disc's gradient does.
    private func disc(_ a: Avatar) -> LinearGradient {
        LinearGradient(colors: [.white, Color(hex: a.tint)],
                       startPoint: UnitPoint(x: 0.5, y: -a.lead / 71.197), endPoint: .bottom)
    }

    /// The render placed over a circle `circle` points across, clipped to it.
    private func render(_ a: Avatar, circle: CGFloat) -> some View {
        let k = circle / 72
        return Image(a.image)
            .resizable()
            .frame(width: a.width * k, height: a.height * k)
            .offset(x: (a.x + a.width / 2 - 36) * k, y: (a.y + a.height / 2 - 36) * k)
            .frame(width: circle, height: circle)
            .clipShape(Circle())
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

    /// `Frame 2147242415`: 72pt chips 12 apart from x 16, the selected one in
    /// a 2pt #0F61FF ring 4pt out. Five of them come to 408pt, wider than the
    /// screen, so the row scrolls — the design shows the fifth half off the
    /// edge.
    private var row: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(avatars.indices, id: \.self) { i in
                        Button { select(i) } label: { chip(avatars[i], on: i == index) }
                            .buttonStyle(.plain)
                            .id(i)
                    }
                }
                .padding(.horizontal, 16)
                // Room for the ring, which sits outside the chip.
                .padding(.vertical, 14)
            }
            .scrollIndicators(.hidden)
            .frame(width: 375, height: 100)
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

    private func chip(_ a: Avatar, on: Bool) -> some View {
        ZStack {
            Circle()
                .fill(disc(a))
                .frame(width: 71.197, height: 71.197)
                .offset(x: 0.376 + 71.197 / 2 - 36, y: 0.645 + 71.197 / 2 - 36)
            render(a, circle: 72)
        }
        .frame(width: 72, height: 72)
        .overlay(
            Circle().strokeBorder(OnboardingSpec.C.actionBold, lineWidth: 2)
                .frame(width: 84, height: 84)
                .opacity(on ? 1 : 0)
        )
    }

    /// Wraps, so cycling never dead-ends at either edge.
    private func select(_ raw: Int) {
        let next = (raw % avatars.count + avatars.count) % avatars.count
        guard next != index else { return }
        index = next
        Haptics.shared.cycleTick()
        kickStars()

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
