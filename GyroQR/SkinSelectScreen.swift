import SwiftUI

/// Wallet-skin picker, Figma `Card Skin Select` (794:30694).
///
/// Two gestures on one axis:
///  * drag **up**   — throw the front card to the back of the stack and cycle on
///  * drag **down** — pull the card into the pocket to confirm
///
/// The design's own flow drops the swiped card off the bottom; here it tucks
/// back into the stack instead, so the 22 skins cycle endlessly.
struct SkinSelectScreen: View {
    @ObservedObject var tune: SkinTuning

    @State private var index = 0                  // committed front card
    @State private var drag = CGSize.zero
    /// 0…1 — how far the current card is through its trip to the back. Drives
    /// the stack advance *and* the background arc together, so the two never
    /// disagree.
    @State private var advance: Double = 0
    /// 0…1 while the released card arcs over and beds into the back slot.
    @State private var tuck: Double = 0
    @State private var confirmed = false
    @State private var settleBounce = false
    @State private var dealt = false              // entry animation has run
    @State private var hintPull: Double = 0       // confirm hint, 0…1
    @State private var hintTask: Task<Void, Never>?
    @State private var interacted = false
    @State private var cycleDetent = 0        // last detent index ticked on the throw

    private var skins: [String] { (1...SkinSelectSpec.skinCount).map { String(format: "skin_%02d", $0) } }
    private var nextIndex: Int { (index + 1) % SkinSelectSpec.skinCount }

    /// Live gesture spans. Scaling these rather than the on-screen travel is
    /// what changes sensitivity: the card still moves the same distance, the
    /// finger just has further to go to get it there.
    private var confirmSpan: CGFloat { SkinSelectSpec.confirmThreshold * CGFloat(tune.dragTravel) }
    private var cycleSpan: CGFloat { SkinSelectSpec.cycleThreshold * CGFloat(tune.dragTravel) }

    /// 0…1 — how far through the confirm pull we are.
    private var pull: Double {
        if confirmed { return 1 }
        let d = Double(max(0, drag.height)) / Double(confirmSpan)
        return max(hintPull, min(1, d))
    }

    var body: some View {
        GeometryReader { geo in
            let scale = max(geo.size.width / SkinSelectSpec.size.width,
                            geo.size.height / SkinSelectSpec.size.height)
            content
                .frame(width: SkinSelectSpec.size.width, height: SkinSelectSpec.size.height)
                .scaleEffect(scale, anchor: .center)
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
        }
        .ignoresSafeArea()
        .onAppear { start() }
        .onDisappear { hintTask?.cancel() }
    }

    private var content: some View {
        ZStack(alignment: .topLeading) {
            background.zIndex(0)
            header.zIndex(1)
            hint.zIndex(1)
            // The card drops *behind* the sheet on the way in, and is presented
            // on top of it once it has settled.
            pocket.zIndex(confirmed ? 2 : 4)
            cardStack.zIndex(confirmed ? 5 : 3)
            confirmCopy.zIndex(6)
            continueButton.zIndex(7)
        }
        .frame(width: SkinSelectSpec.size.width, height: SkinSelectSpec.size.height,
               alignment: .topLeading)
        .contentShape(Rectangle())
        .gesture(cardGesture)
    }

    // MARK: entry

    private func start() {
        Haptics.shared.prepare()
        guard tune.entryEnabled else { dealt = true; scheduleHints(); return }
        dealt = false
        withAnimation(.spring(response: tune.entryResponse, dampingFraction: 0.74)) {
            dealt = true
        }
        scheduleHints()
        if demoMode { runDemo() }
    }

    /// Idle coaching: nudge the card the way it wants to be thrown, then the way
    /// it wants to be pulled. Both play a fraction of the real transition so the
    /// user sees the actual consequence, not a generic wiggle.
    private func scheduleHints() {
        hintTask?.cancel()
        guard tune.hintsEnabled else { return }
        hintTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(700))
            while !Task.isCancelled {
                guard !interacted, !confirmed else { return }
                // 1 — how to cycle
                withAnimation(.easeOut(duration: 0.42)) { advance = tune.hintCycleAmount }
                try? await Task.sleep(for: .milliseconds(560))
                if Task.isCancelled || interacted { return }
                withAnimation(.easeInOut(duration: 0.38)) { advance = 0 }
                try? await Task.sleep(for: .milliseconds(520))
                if Task.isCancelled || interacted { return }
                // 2 — how to confirm
                withAnimation(.easeOut(duration: 0.38)) { hintPull = tune.hintPullAmount }
                Haptics.shared.selectionTick()
                try? await Task.sleep(for: .milliseconds(480))
                if Task.isCancelled || interacted { return }
                withAnimation(.easeInOut(duration: 0.36)) { hintPull = 0 }
                try? await Task.sleep(for: .seconds(tune.hintRepeat))
            }
        }
    }

    // MARK: background
    //
    // Both the current and the incoming skin are always mounted; `advance` is
    // the only driver, so the transition tracks the throw exactly and lands
    // fully opaque at the moment the index commits — nothing to resynchronise.
    private var background: some View {
        let W = SkinSelectSpec.size.width, H = SkinSelectSpec.size.height
        let depth = CGFloat(tune.arcDepth)
        let centre = CGPoint(x: W / 2, y: H + depth)
        let r = depth + (H + depth * 0.15) * CGFloat(advance)
        return ZStack {
            field(for: index)
            Group {
                switch tune.bgStyle {
                case .crossfade:
                    field(for: nextIndex).opacity(advance)
                case .arc:
                    ZStack {
                        field(for: nextIndex)
                            .mask { Circle().frame(width: r * 2, height: r * 2).position(centre) }
                        if tune.arcEdge != .none, advance > 0.001, advance < 0.999 {
                            arcEdge(radius: r, centre: centre)
                        }
                    }
                    .opacity(advance > 0.001 ? 1 : 0)
                }
            }
        }
        .frame(width: W, height: H)
        .clipped()
    }

    /// Edge treatments for the arc mask — all additive strokes on the same
    /// circle as the mask, so they sit exactly on the reveal boundary.
    @ViewBuilder
    private func arcEdge(radius r: CGFloat, centre: CGPoint) -> some View {
        let w = CGFloat(tune.arcEdgeWidth)
        let i = tune.arcEdgeIntensity
        switch tune.arcEdge {
        case .none:
            EmptyView()
        case .rim:
            Circle().stroke(.white.opacity(i), lineWidth: max(1, w * 0.08))
                .frame(width: r * 2, height: r * 2).position(centre)
                .blendMode(.plusLighter)
        case .glow:
            Circle().stroke(.white.opacity(i), lineWidth: w * 0.5)
                .frame(width: r * 2, height: r * 2).position(centre)
                .blur(radius: w * 0.45)
                .blendMode(.plusLighter)
        case .bloom:
            ZStack {
                Circle().stroke(.white.opacity(i * 0.8), lineWidth: w)
                    .frame(width: r * 2, height: r * 2).position(centre)
                    .blur(radius: w)
                Circle().stroke(.white.opacity(i), lineWidth: max(1, w * 0.10))
                    .frame(width: r * 2, height: r * 2).position(centre)
                    .blur(radius: 1)
            }
            .blendMode(.plusLighter)
        }
    }

    /// A skin's full-bleed field, derived from its own card art.
    private func field(for i: Int) -> some View {
        ZStack {
            Color.black
            Image(skins[i])
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: SkinSelectSpec.size.width * 2.6)
                .blur(radius: 26)
                .scaleEffect(1.25)
            LinearGradient(colors: [.black.opacity(0.28), .black.opacity(0.05), .black.opacity(0.35)],
                           startPoint: .top, endPoint: .bottom)
        }
        .frame(width: SkinSelectSpec.size.width, height: SkinSelectSpec.size.height)
        .clipped()
        .drawingGroup()          // rasterise the blur once per skin, not per frame
    }

    // MARK: header

    private var header: some View {
        ZStack(alignment: .topLeading) {
            stepDots
                .offset(x: SkinSelectSpec.stepDots.minX, y: SkinSelectSpec.stepDots.minY)
            VStack(spacing: 8) {
                Text("Pick your\nwallet skin")
                    .font(.system(size: 32, weight: .bold))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                Text("Make your card uniquely yours")
                    .font(.system(size: 14, weight: .medium))
                    .opacity(0.75)
            }
            .foregroundStyle(SkinSelectSpec.Palette.onTexture)
            .frame(width: SkinSelectSpec.titleBox.width)
            .offset(x: SkinSelectSpec.titleBox.minX, y: SkinSelectSpec.titleBox.minY)
        }
        .opacity(dealt ? 1 : 0)
        .offset(y: dealt ? 0 : -14)
        .allowsHitTesting(false)
    }

    private var stepDots: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle()
                    .strokeBorder(.white, lineWidth: i == 0 ? 4 : 0)
                    .background(Circle().fill(i == 0 ? .clear : .white.opacity(0.45)))
                    .frame(width: 16, height: 16)
                if i < 2 {
                    Capsule().fill(.white.opacity(0.45)).frame(width: 24, height: 4)
                }
            }
        }
        .frame(width: SkinSelectSpec.stepDots.width, height: SkinSelectSpec.stepDots.height)
    }

    // MARK: pocket

    private var sheetTop: CGFloat {
        if confirmed { return SkinSelectSpec.settledTop }
        return SkinSelectSpec.restTop
            + (SkinSelectSpec.dragTop - SkinSelectSpec.restTop) * CGFloat(easeOut(pull))
    }

    private var pocket: some View {
        PocketShape()
            .fill(.white)
            .frame(width: SkinSelectSpec.sheetWidth,
                   height: SkinSelectSpec.size.height + 200)
            .shadow(color: .black.opacity(0.10), radius: 12, y: -6)
            .offset(x: (SkinSelectSpec.size.width - SkinSelectSpec.sheetWidth) / 2, y: sheetTop)
            .allowsHitTesting(false)
    }

    // MARK: cards

    private func slot(of card: Int) -> Int {
        (card - index + SkinSelectSpec.skinCount) % SkinSelectSpec.skinCount
    }

    /// Depth for a card. Normally derived from its slot; a thrown card drops to
    /// the very back the instant it is released, because it has gone over the
    /// top of the stack and should be occluded on the way down rather than
    /// shrinking on top of everything and blinking out at the end.
    ///
    /// This has to be `zIndex` on a *stable* `ForEach`. Re-sorting the array
    /// mid-flight churns view identity and snaps the running animation straight
    /// to its end state — the card disappears in one frame instead of settling.
    private func depth(of card: Int) -> Double {
        let s = slot(of: card)
        if s == 0 && tuck > 0.001 { return -1 }
        return Double(SkinSelectSpec.skinCount - s)
    }

    private var cardStack: some View {
        ZStack {
            ForEach(0..<SkinSelectSpec.skinCount, id: \.self) { i in
                card(i).zIndex(depth(of: i))
            }
        }
        .frame(width: SkinSelectSpec.size.width, height: SkinSelectSpec.size.height)
        // A full-screen ZStack centres on the screen midpoint, 38.5pt above where
        // the design puts the card. Nudge the stack so slot 0 rests on the Figma
        // position.
        .offset(y: SkinSelectSpec.cardCenterY - SkinSelectSpec.size.height / 2)
        // Behind the pocket while the card is being pulled in; in front of it
        // once the sheet has settled and the card is presented on top.
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func card(_ i: Int) -> some View {
        let s = slot(of: i)
        let isFront = s == 0
        // Entry deals the stack out of a single collapsed pile.
        let fan = dealt ? 1.0 : 0.0
        let parked = SkinSelectSpec.stack(slotF: Double(SkinSelectSpec.visibleDepth) + 1)

        // The thrown card rides up with the finger, then — once released — arcs
        // back down and beds into the parked slot, which is exactly where the
        // committed layout will put it. It never fades: it ends up hidden
        // because the card in front of it is larger and opaque.
        let lift = -SkinSelectSpec.ejectLift * CGFloat(advance)
        let t = isFront
            ? (scale: 1 + (parked.scale - 1) * CGFloat(tuck),
               dy: lift * CGFloat(1 - tuck) + parked.dy * CGFloat(tuck),
               angle: parked.angle * tuck,
               opacity: 1.0)
            : SkinSelectSpec.stack(slotF: (Double(s) - advance) * fan)

        Image(skins[i])
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: cardWidth(front: isFront))
            .rotationEffect(.degrees(t.angle))
            .scaleEffect(t.scale * (isFront ? frontScale : 1) * (dealt ? 1 : 0.9))
            .offset(y: t.dy * (isFront ? 1 : fan) + (dealt ? 0 : 34))
            .offset(y: isFront ? frontDrop : 0)
            // Only the chosen card during the pull; the stack is gone entirely
            // once the card has landed on the sheet.
            .opacity(t.opacity * (isFront ? 1 : (confirmed ? 0 : 1 - pull)) * (dealt ? 1 : 0))
            .animation(.spring(response: tune.entryResponse, dampingFraction: 0.74)
                        .delay(Double(min(s, SkinSelectSpec.visibleDepth)) * tune.entryStagger),
                       value: dealt)
    }

    private func cardWidth(front: Bool) -> CGFloat {
        front && confirmed ? SkinSelectSpec.settledCardWidth : SkinSelectSpec.cardWidth
    }

    /// The front card shrinks as it is pulled toward the pocket, then springs up
    /// to hero size once it has settled.
    private var frontScale: CGFloat {
        if confirmed { return settleBounce ? 1 : 0.55 }
        return 1 - 0.42 * CGFloat(pull)
    }

    private var frontDrop: CGFloat {
        if confirmed {
            return SkinSelectSpec.settledCardCenterY - SkinSelectSpec.cardCenterY
        }
        return 210 * CGFloat(easeOut(pull))
    }

    // MARK: confirm copy

    private var confirmCopy: some View {
        VStack(spacing: 10) {
            Text("Confirm?").font(.system(size: 34, weight: .bold))
            Text("Finalise wallet skin").font(.system(size: 16, weight: .medium)).opacity(0.6)
        }
        .foregroundStyle(SkinSelectSpec.Palette.ink)
        .frame(width: SkinSelectSpec.confirmTitle.width)
        .offset(x: SkinSelectSpec.confirmTitle.minX, y: SkinSelectSpec.confirmTitle.minY)
        .opacity(confirmed && settleBounce ? 1 : 0)
        .allowsHitTesting(false)
    }

    private var continueButton: some View {
        Button {
            Haptics.shared.selectionTick()
            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) { reset() }
        } label: {
            Text("Continue")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(confirmed ? .white : .white.opacity(0.85))
                .frame(width: SkinSelectSpec.continueBtn.width,
                       height: SkinSelectSpec.continueBtn.height)
                .background(continueFill)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!confirmed)
        .offset(x: SkinSelectSpec.continueBtn.minX, y: SkinSelectSpec.continueBtn.minY)
        .opacity(pull > 0.02 || confirmed ? 1 : 0)
    }

    private var continueFill: Color {
        if confirmed { return SkinSelectSpec.Palette.ink }
        return SkinSelectSpec.Palette.btnIdle.mix(with: SkinSelectSpec.Palette.btnArmed, by: pull)
    }

    private var hint: some View {
        HStack(spacing: 6) {
            Text(drag.height > 0 ? "Drag down to confirm" : "Swipe up to change")
                .font(.system(size: 15, weight: .medium))
            Text(drag.height > 0 ? "︾" : "︿").font(.system(size: 13, weight: .bold)).opacity(0.7)
        }
        .foregroundStyle(.white.opacity(0.85))
        .frame(width: SkinSelectSpec.size.width)
        .offset(y: SkinSelectSpec.hintY)
        .opacity(dealt && !confirmed && pull < 0.15 ? 1 : 0)
        .allowsHitTesting(false)
    }

    // MARK: gesture

    private var cardGesture: some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { v in handleDrag(v.translation) }
            .onEnded { v in endDrag(v.translation) }
    }

    /// Shared by the real gesture and the scripted driver, so the replay
    /// exercises the same code — including the haptics.
    private func handleDrag(_ translation: CGSize) {
        guard !confirmed else { return }
        if !interacted { interacted = true; hintTask?.cancel(); hintPull = 0 }
        drag = translation
        // A small deadband either side of zero. Without it the first frame of an
        // upward throw (translation still ~0) starts the pull ramp and fires a
        // stray tick before the gesture has declared a direction.
        if translation.height > -2, translation.height < 2 {
            advance = 0
            cycleDetent = 0
            Haptics.shared.stopRamp()
        } else if translation.height < 0 {
            // throwing the card up: stack and background advance together
            let a = min(1, Double(-translation.height) / Double(cycleSpan))
            advance = a
            // Detents along the way — over this much travel a single tick at
            // the end leaves the whole throw silent.
            let steps = max(1, Int(tune.cycleDetents.rounded()))
            let step = min(steps, Int(a * Double(steps)))
            if step != cycleDetent {
                cycleDetent = step
                if step > 0 { Haptics.shared.detent(progress: a) }
            }
            Haptics.shared.stopRamp()
        } else {
            advance = 0
            cycleDetent = 0
            Haptics.shared.startRamp()
            Haptics.shared.updateRamp(progress: pull)
        }
    }

    private func endDrag(_ translation: CGSize) {
        guard !confirmed else { return }
        Haptics.shared.stopRamp()
        cycleDetent = 0
        if translation.height > confirmSpan * SkinSelectSpec.commitFraction {
            settle()
        } else if -translation.height > cycleSpan * SkinSelectSpec.commitFraction {
            cycle()
        } else {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
                drag = .zero; advance = 0; tuck = 0
            }
        }
    }

    /// Carries `advance` the rest of the way to 1, then commits the new front
    /// card and snaps `advance` back to 0 in the same frame. Because the layout
    /// at advance == 1 is identical to the committed layout at 0, nothing moves
    /// at the seam.
    private func cycle() {
        Haptics.shared.swipe()
        drag = .zero
        // The card beds in faster than the stack settles, so it is gone behind
        // the fan well before the hand-off rather than lingering on screen.
        withAnimation(.spring(response: 0.42, dampingFraction: 0.90)) {
            tuck = 1             // thrown card arcs down into the parked slot
        }
        withAnimation(.spring(response: 0.52, dampingFraction: 0.88), completionCriteria: .logicallyComplete) {
            advance = 1          // stack finishes creeping forward, background completes
        } completion: {
            var t = Transaction(); t.disablesAnimations = true
            withTransaction(t) {
                index = nextIndex
                advance = 0
                tuck = 0
            }
            resumeHintsIfIdle()
        }
    }

    private func settle() {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
            confirmed = true
            drag = .zero
            advance = 0
            tuck = 0
        }
        Haptics.shared.settle()
        // The reveal: the card is hidden behind the sheet at the moment it
        // settles, then springs up on top of it.
        withAnimation(.spring(response: 0.5, dampingFraction: 0.58).delay(0.12)) {
            settleBounce = true
        }
    }

    private func reset() {
        confirmed = false
        settleBounce = false
        drag = .zero
        advance = 0
        tuck = 0
        hintPull = 0
        resumeHintsIfIdle()
    }

    private func resumeHintsIfIdle() {
        interacted = false
        scheduleHints()
    }

    private func easeOut(_ t: Double) -> Double { 1 - pow(1 - t, 2) }

    // MARK: scripted driver
    //
    // The Simulator has no touch input to script, so this replays the whole
    // interaction through the same entry points the gesture uses — haptics
    // included — when launched with `-skinDemo`.
    //     xcrun simctl launch <udid> com.noon.gyroqr -skinDemo
    private var demoMode: Bool { ProcessInfo.processInfo.arguments.contains("-skinDemo") }
    private func runDemo() {
        func at(_ t: Double, _ f: @escaping () -> Void) {
            DispatchQueue.main.asyncAfter(deadline: .now() + t, execute: f)
        }
        let up = cycleSpan, down = confirmSpan
        for (n, base) in [(0, 1.6), (1, 3.4)] {          // two upward throws
            _ = n
            for i in 0...16 {
                at(base + Double(i) * 0.035) {
                    self.handleDrag(CGSize(width: 0, height: -CGFloat(i) / 16 * up))
                }
            }
            at(base + 0.62) { self.endDrag(CGSize(width: 0, height: -up)) }
        }
        for i in 0...34 {                                 // slow pull-down
            at(5.2 + Double(i) * 0.05) {
                self.handleDrag(CGSize(width: 0, height: CGFloat(i) / 34 * down))
            }
        }
        at(7.1) { self.endDrag(CGSize(width: 0, height: down)) }
    }
}

private extension Color {
    /// Linear blend, for the Continue button arming as the pull deepens.
    func mix(with other: Color, by t: Double) -> Color {
        let a = UIColor(self), b = UIColor(other)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        a.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        b.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let f = CGFloat(max(0, min(1, t)))
        return Color(red: r1 + (r2-r1)*f, green: g1 + (g2-g1)*f, blue: b1 + (b2-b1)*f)
    }
}
