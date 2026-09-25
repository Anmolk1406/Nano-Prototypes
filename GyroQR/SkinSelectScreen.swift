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
    /// Set by the onboarding flow so Continue advances the step. Standalone the
    /// screen keeps its own behaviour and resets itself for another run.
    var onContinue: (() -> Void)? = nil

    @State private var index = Self.startIndex    // committed front card
    @State private var drag = CGSize.zero
    /// 0…1 — how far the thrown card is through its rise. Tracks the finger,
    /// because lifting a card is direct manipulation and has to follow the
    /// hand.
    @State private var advance: Double = 0
    /// 0…1 — the stack hand-off and the background transition.
    ///
    /// Deliberately *not* the same quantity as `advance`. When one value drove
    /// both, a fast flick took it to 1 inside the swipe and the transition was
    /// over before the finger lifted — the arc and the stack creep were simply
    /// never seen. The drag now scrubs this only as far as
    /// `SkinSelectSpec.cyclePreview`, and the commit carries it the rest of the
    /// way over a fixed duration, so the transition looks the same whether the
    /// card was flicked or dragged.
    @State private var reveal: Double = 0
    /// 0…1 while the released card arcs over and beds into the back slot.
    @State private var tuck: Double = 0
    @State private var confirmed = false
    @State private var settleBounce = false
    @State private var dealt = false              // entry animation has run
    @State private var hintPull: Double = 0       // confirm hint, 0…1
    @State private var hintTask: Task<Void, Never>?
    @State private var interacted = false
    @State private var cycleDetent = 0        // last detent index ticked on the throw
    /// Whether each direction has passed its commit threshold, so the "you can
    /// let go now" tick fires once per crossing rather than every frame.
    @State private var armedThrow = false
    /// Which way the current sideways throw is going: −1 left, +1 right.
    /// Unused on the upward axis. Set once, when the gesture declares itself,
    /// so a finger that drifts back the other way does not fling the card
    /// across the screen mid-throw.
    @State private var throwDir: CGFloat = 1
    /// Which gesture the live drag has committed to, decided on the first
    /// frame past the deadband and held for the rest of it.
    ///
    /// Without this the two gestures run at once on the sideways axis, and the
    /// result is two cards moving on two axes: `advance` carries the front card
    /// out on x while `pull` — derived from `drag.height`, not from state — is
    /// still non-zero, which drops that same card on y *and* mounts
    /// `draggedCopy` in front of the sheet. One diagonal swipe, two cards.
    @State private var axisLock: DragAxis?

    enum DragAxis { case cycle, confirm }

    /// Latched if the confirm pull ever had a non-zero value while the drag was
    /// locked to the throw — which is precisely the condition `draggedCopy`
    /// mounts on, so it is the same question as "did a second card appear".
    /// Read by the UI test through `-skinProbe`; nothing else uses it.
    @State private var crossTalk = false
    @State private var armedPull = false
    /// True while the cycle transition is running.
    ///
    /// Touching down mid-transition used to restart the gesture from the
    /// current finger position, and because `handleDrag` assigns `advance` and
    /// `reveal` directly — no animation, by design, so they track the hand —
    /// that snapped both values out of their running curves. The card and the
    /// background jumped.
    @State private var transitioning = false
    /// 0 while the stack is in play, 1 once it has flown out. Driven by the
    /// selection completing rather than by the drag.
    @State private var exitDrive: Double = 0

    /// `-skinIndex N` opens on a given card, so a specific skin's glow palette
    /// can be looked at without throwing the stack round to it.
    private static var startIndex: Int {
        let a = ProcessInfo.processInfo.arguments
        guard let i = a.firstIndex(of: "-skinIndex"), i + 1 < a.count,
              let n = Int(a[i + 1]) else { return 0 }
        return ((n % SkinSelectSpec.skinCount) + SkinSelectSpec.skinCount) % SkinSelectSpec.skinCount
    }

    /// The deck, in browse order rather than asset order — see
    /// `SkinSelectSpec.displayOrder`.
    private var skins: [String] {
        (0..<SkinSelectSpec.skinCount).map { String(format: "skin_%02d", SkinSelectSpec.asset(at: $0)) }
    }
    private var nextIndex: Int { (index + 1) % SkinSelectSpec.skinCount }

    /// Live gesture spans, scaled independently per direction. Scaling these
    /// rather than the on-screen travel is what changes sensitivity: the card
    /// still moves the same distance, the finger just has further to go to get
    /// it there.
    private var confirmSpan: CGFloat { SkinSelectSpec.confirmThreshold * CGFloat(tune.pullTravel) }
    private var cycleSpan: CGFloat { SkinSelectSpec.cycleThreshold * CGFloat(tune.throwTravel) }

    /// Exposes the gesture's internal state as an accessibility label under
    /// `-skinProbe`.
    ///
    /// The failure this guards was geometry — two cards moving on two axes —
    /// and XCUITest can only see elements, not where they are. It also cannot
    /// query anything mid-drag: `press(forDuration:thenDragTo:)` returns after
    /// the gesture is over. So the app latches the condition itself and the
    /// test reads the latch afterwards.
    @ViewBuilder
    private var probe: some View {
        if ProcessInfo.processInfo.arguments.contains("-skinProbe") {
            Text(verbatim: crossTalk ? "crosstalk" : "clean")
                .accessibilityIdentifier("skinProbe")
                .font(.system(size: 1))
                .frame(width: 1, height: 1)
                .opacity(0.02)
                .allowsHitTesting(false)
        }
    }

    /// A throw of `amount` (0…1 of the span) as a drag vector, so the scripted
    /// drivers work on either axis.
    private func throwVector(_ amount: CGFloat) -> CGSize {
        switch tune.cycleAxis {
        case .up:   CGSize(width: 0, height: -cycleSpan * amount)
        case .side: CGSize(width: cycleSpan * amount, height: 0)
        }
    }

    /// Where the thrown card sits at the current `advance`, before the tuck.
    ///
    /// The only thing the two axes disagree about. Up is a straight lift; side
    /// carries a rise and a tilt as well, because a purely horizontal slide
    /// reads as a filmstrip rather than as a card coming off a pile.
    private var throwShift: (dx: CGFloat, dy: CGFloat, angle: Double) {
        let a = CGFloat(advance)
        switch tune.cycleAxis {
        case .up:
            return (0, -SkinSelectSpec.ejectLift * a, 0)
        case .side:
            return (SkinSelectSpec.ejectShift * a * throwDir,
                    -SkinSelectSpec.sideRise * a,
                    SkinSelectSpec.sideTilt * advance * Double(throwDir))
        }
    }

    /// 0…1 — how far through the confirm pull we are. The raw gesture.
    private var pull: Double {
        if confirmed { return 1 }
        // A drag locked to the throw contributes nothing here however far down
        // it wanders. Gated on the way out rather than at the assignment,
        // because `pull` has to stay derived from `drag` for the abort spring
        // to animate it back.
        guard axisLock != .cycle else { return hintPull }
        let d = Double(max(0, drag.height)) / Double(confirmSpan)
        return max(hintPull, min(1, d))
    }

    /// 0…1 — how far the card is toward its seat in the drop outline.
    ///
    /// Deliberately not `pull`. The visuals used to run on the full span, so
    /// the card carried on descending and shrinking through the last fifth of
    /// the gesture — past the outline it was aiming at — and ended up two
    /// thirds its width, 8pt below its bottom edge. Reaching 1 at
    /// `commitFraction` makes the card seating in the outline and the gesture
    /// arming the same instant: the card lines up, the phone ticks, the hint
    /// says release, and dragging further does nothing.
    /// Linear, unlike the sheet's rise. The sheet leads the finger on an
    /// ease-out, and putting the card on that curve too stacked one lead on
    /// another: the card was 96% seated by the time the drag was 60% through,
    /// so the whole back half of the gesture — which is exactly the stretch
    /// the outline's reveal is supposed to live in — had nothing left to do.
    /// Tracking the finger keeps the card visible above the mouth until the
    /// last few points of travel.
    private var seat: Double { min(1, pull / Double(SkinSelectSpec.commitFraction)) }

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
            // Above the cards. The departing stack sweeps upward through the
            // hint's pull position — there is no band between the subtitle and
            // the card region that stays clear for a whole gesture — so the
            // hint sits on top and relies on `OnTexture` to stay legible over
            // whatever is fading past behind it.
            hint.zIndex(6)
            // The card drops *behind* the sheet on the way in, and is presented
            // on top of it once it has settled — which also carries the
            // departing deck above the sheet, and that turns out to be what
            // makes its exit visible at all. Everything below 242 is white
            // page by then, so a deck that stayed under the pocket would fly
            // out behind it and never be seen. It goes over the top instead,
            // and `exitLift` is large enough to take it off the screen rather
            // than parking it on the sheet.
            //
            // Hoisting just the chosen card into its own layer was the tidier
            // idea and it does not work: the stack's own copy has to hide, its
            // opacity change rides the settle spring, and for a third of a
            // second there are two of the same card at slightly different
            // points on two curves.
            pocket.zIndex(confirmed ? 2 : 4)
            cardStack.zIndex(confirmed ? 5 : 3)
            // Above the sheet, below the glow. The real card is behind the
            // pocket on the way in, so from the moment it crosses the mouth
            // there was nothing to see; this is the same card at the same
            // place, drawn in front, so it stays visible all the way down.
            // Aligned rather than approximated — it is built from the same
            // three values the front card's own layout uses.
            draggedCopy.zIndex(4.5)
            mouthShadow.zIndex(4.6)
            pocketGlow.zIndex(4.8)
            confirmCopy.zIndex(7)
            continueButton.zIndex(8)
            probe.zIndex(9)
        }
        .frame(width: SkinSelectSpec.size.width, height: SkinSelectSpec.size.height,
               alignment: .topLeading)
        .contentShape(Rectangle())
        // Masked rather than guarded inside the handlers. A gesture that is
        // allowed to *begin* mid-transition and then ignored is still live
        // when the transition ends, and its first honoured frame arrives with
        // a large accumulated translation — the same jump, just later.
        .gesture(cardGesture, including: transitioning ? .subviews : .all)
    }

    // MARK: entry

    private func start() {
        Haptics.shared.prepare()
        guard tune.entryEnabled else { dealt = true; scheduleHints(); return }
        dealt = false
        let deal = {
            withAnimation(.spring(response: self.tune.entryResponse, dampingFraction: 0.74)) {
                self.dealt = true
            }
        }
        // A beat of empty backdrop before the cards arrive. Everything timed
        // off the entry has to wait with it, or the scripted drivers start
        // scrubbing a stack that has not been dealt.
        let lead = max(0, tune.entryDelay)
        if lead > 0.001 {
            DispatchQueue.main.asyncAfter(deadline: .now() + lead, execute: deal)
        } else {
            deal()
        }
        scheduleHints()
        if let diag = held("-skinDiag") {
            // A held diagonal, throw-dominant: `amount` of the cycle span on
            // the throw axis and 60% of that same distance downward.
            //
            // Expressed against the throw's own travel rather than the pull's,
            // because the two spans are nothing alike — 150 against 330 — so a
            // fraction of the confirm span swamps any fraction of the cycle
            // one and the lock correctly picks the pull instead, which is not
            // the case this is meant to show. 60% of the throw distance is
            // still ~27% of a confirm pull, which is plenty to have raised the
            // sheet and mounted the copy before the lock existed.
            hintTask?.cancel()
            interacted = true
            DispatchQueue.main.asyncAfter(deadline: .now() + lead + 0.6) {
                withAnimation(.easeOut(duration: 0.5)) {
                    var v = self.throwVector(CGFloat(diag))
                    v.height += abs(v.width) * 0.6
                    self.handleDrag(v)
                }
            }
        } else if let held = heldPull ?? heldThrow {
            hintTask?.cancel()
            interacted = true
            DispatchQueue.main.asyncAfter(deadline: .now() + lead + 0.6) {
                withAnimation(.easeOut(duration: 0.5)) {
                    self.handleDrag(self.heldPull != nil
                                    ? CGSize(width: 0, height: CGFloat(held) * self.confirmSpan)
                                    : self.throwVector(CGFloat(held)))
                }
            }
        }
        if demoMode { runDemo() }
        if abortMode { runAbort() }
        if flickMode {
            DispatchQueue.main.asyncAfter(deadline: .now() + lead + 1.2) {
                self.handleDrag(self.throwVector(1))
                self.endDrag(self.throwVector(1))
            }
        }
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
                withAnimation(.easeOut(duration: 0.42)) {
                    advance = tune.hintCycleAmount
                    reveal = tune.hintCycleAmount
                }
                try? await Task.sleep(for: .milliseconds(560))
                if Task.isCancelled || interacted { return }
                withAnimation(.easeInOut(duration: 0.38)) { advance = 0; reveal = 0 }
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
        let r = depth + (H + depth * 0.15) * CGFloat(reveal)
        return ZStack {
            field(for: index)
            Group {
                switch tune.bgStyle {
                case .crossfade:
                    field(for: nextIndex).opacity(reveal)
                case .arc:
                    ZStack {
                        field(for: nextIndex)
                            .mask { Circle().frame(width: r * 2, height: r * 2).position(centre) }
                        if tune.arcEdge != .none, reveal > 0.001, reveal < 0.999 {
                            arcEdge(radius: r, centre: centre)
                        }
                    }
                    .opacity(reveal > 0.001 ? 1 : 0)
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

    /// A skin's authored background, from `Card skins & bg` (849:58131).
    ///
    /// These replace what used to be here — the card's own art blown up, blurred
    /// and darkened — now that each skin has a real backdrop drawn for it.
    ///
    /// `.fill` is the design's own geometry, not a guess: the backdrop is
    /// 973 × 1616, and `Skin Option 8` places it at 489.71 × 812 offset
    /// x = -57.53, which is exactly filling by height and letting the sides run
    /// off. No scrim, also per the design — the frames carry nothing over the
    /// backdrop.
    private func field(for i: Int) -> some View {
        // Through the deck order too, or the backdrop stops belonging to the
        // card in front of it.
        Image(String(format: "bg_%02d", SkinSelectSpec.asset(at: i)))
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: SkinSelectSpec.size.width, height: SkinSelectSpec.size.height)
            .clipped()
    }

    // MARK: header

    private var header: some View {
        ZStack(alignment: .topLeading) {
            stepDots
                .offset(x: SkinSelectSpec.stepDots.minX, y: SkinSelectSpec.stepDots.minY)
            VStack(spacing: 8) {
                Text("Pick your\nwallet skin")
                    .font(NoonFont.f(.extrabold, 32))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                Text("Make your card uniquely yours")
                    .font(NoonFont.f(.medium, 14))
                    .opacity(0.75)
            }
            .foregroundStyle(SkinSelectSpec.Palette.onTexture)
            .modifier(OnTexture())
            .frame(width: SkinSelectSpec.titleBox.width)
            .offset(x: SkinSelectSpec.titleBox.minX, y: SkinSelectSpec.titleBox.minY)
        }
        .opacity((dealt ? 1 : 0) * (1 - 0.85 * headerDim))
        .offset(y: dealt ? 0 : -14)
        .allowsHitTesting(false)
    }

    /// 0…1 — how much the thrown card is in the header's way.
    ///
    /// Any throw that clears the stack has to reach the title. The card rests
    /// at 348.9 and the card behind it tops out at 338, so clearing takes 201pt
    /// of lift, which puts the card's top edge at 148 — inside the title block
    /// at 112…192. There is no lift that both clears the pile and stays below
    /// the type, so the type gets out of the way instead.
    ///
    /// Tied to the card's height rather than to `advance` alone, so the header
    /// comes back as the card beds in rather than snapping back at the commit.
    private var headerDim: Double {
        // Only the upward throw is in the title's way; a sideways one leaves
        // across the middle of the screen and never reaches it.
        guard tune.cycleAxis == .up else { return 0 }
        return advance * (1 - tuck)
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

    /// How brightly the pocket mouth is lit.
    ///
    /// Gated on contact, not on the pull. Ramping from the first millimetre of
    /// the gesture had the mouth burning while the card was still 200pt above
    /// it, which reads as the pocket lighting up on its own rather than as the
    /// card lighting it. Out again the moment the card commits: the glow is
    /// the anticipation of the drop, so it has no business burning under a
    /// settled card.
    private var glow: Double { confirmed ? 0 : contact }

    /// 0…1 — how far the card's bottom edge is past the notch floor, over two
    /// notch depths of engagement.
    ///
    /// Zero until the two actually meet, which on the current geometry is 43%
    /// of the way through the pull, and full by 61%. Normalising over the
    /// overlap at full seat instead — 176pt — was the first attempt and it is
    /// wrong in an instructive way: the card's *top* edge clears the notch
    /// floor at 73%, so the glow was still ramping up long after the card had
    /// stopped touching the mouth and gone fully inside the pocket. Two notch
    /// depths puts full brightness at the point the card is halfway through
    /// the mouth, and it stays there for the rest of the gesture rather than
    /// blinking out on the way in.
    /// Width of the card at the mouth, in sheet points. Both the glow and the
    /// cast shadow are windowed to it.
    private var mouthSpan: CGFloat { SkinSelectSpec.cardWidth * frontScale }

    /// The card's rendered height at the moment.
    private var cardHeightNow: CGFloat {
        SkinArt.height(skins[index], at: SkinSelectSpec.cardWidth) * frontScale
    }

    /// Screen y of the card's bottom edge.
    private var cardBottomNow: CGFloat {
        SkinSelectSpec.cardCenterY + frontDrop + cardHeightNow / 2
    }

    /// The onset ramp for the sheet's cast shadow.
    private var shadowFade: Double {
        min(1, insideDepth / SkinSelectSpec.mouthFadeIn)
    }

    /// 0…1 — how far the card is into the pocket.
    ///
    /// The card's bottom edge past the notch floor, over two notch depths of
    /// engagement: nothing until the two meet, which on this geometry is 43%
    /// of the way through the pull, and full by 61%.
    ///
    /// Drives the cast shadow, and **does not fall off** — the card is
    /// genuinely inside the pocket at the end of the pull, so the lip still
    /// shades it even once the mouth's edge has stopped glowing. That is the
    /// whole reason this and `contact` are separate quantities rather than one
    /// shared driver, which is what they were.
    private var insideDepth: Double {
        let depth = PocketShape.notchDepth(forWidth: SkinSelectSpec.sheetWidth)
        // Measured from the **crest**, not the notch floor. The new shape
        // crowns, so the first thing the card meets is the highest point of
        // the mouth — keyed to the floor, both this and `contact` stayed at
        // zero through the entire crossing and only woke up once the card was
        // already inside, which is exactly backwards.
        guard cardBottomNow > sheetTop else { return 0 }
        return min(1, Double((cardBottomNow - sheetTop) / (depth * 2)))
    }

    /// 0…1 — how lit the mouth's edge is.
    ///
    /// Rises as the card's bottom edge arrives and **falls again as its top
    /// edge leaves**, so the light is out by the time the card is through. It
    /// used to only rise, which left the mouth burning at the end of the pull
    /// with the card sitting a clear 18pt below it, touching nothing.
    ///
    /// The departure is measured against the middle of the notch rather than
    /// its floor. Against the floor the whole fade would have to happen inside
    /// the last 5% of the gesture — the top edge only clears the floor at 74%
    /// and the gesture arms at 78% — which reads as the light being switched
    /// off. The notch's midline is crossed at 69% and gives the fade a fifth
    /// of the gesture to run in.
    private var contact: Double {
        let depth = PocketShape.notchDepth(forWidth: SkinSelectSpec.sheetWidth)
        let top = SkinSelectSpec.cardCenterY + frontDrop - cardHeightNow / 2
        // Arrival from the crest, departure past the notch's midline.
        let arriving = Double((cardBottomNow - sheetTop) / (depth * 2))
        let leaving = Double((top - (sheetTop + depth / 2)) / leaveSpan)
        return min(1, max(0, arriving)) * (1 - min(1, max(0, leaving)))
    }

    /// How far the card's top edge travels past the notch's midline between
    /// first crossing it and the gesture arming.
    ///
    /// Derived rather than typed in, so the light is out exactly when the card
    /// is through for every skin. The renders are not all the same height —
    /// 143.6 to 162.8 at the seated width — so a fixed offset would leave the
    /// tall ones still glowing and snap the short ones off early.
    private var leaveSpan: CGFloat {
        let h = SkinArt.height(skins[index], at: SkinSelectSpec.cardWidth)
            * SkinSelectSpec.dropFitScale
        let topAtSeat = SkinSelectSpec.cardCenterY + SkinSelectSpec.dropTravel - h / 2
        let depth = PocketShape.notchDepth(forWidth: SkinSelectSpec.sheetWidth)
        let sheetAtCommit = SkinSelectSpec.restTop
            + (SkinSelectSpec.dragTop - SkinSelectSpec.restTop)
            * CGFloat(easeOut(Double(SkinSelectSpec.commitFraction)))
        return max(18, topAtSeat - (sheetAtCommit + depth / 2))
    }

    private var pocket: some View {
        PocketShape()
            .fill(.white)
            .frame(width: SkinSelectSpec.sheetWidth,
                   height: SkinSelectSpec.size.height + 200)
            // Inside the clip: the outline is only visible where there is sheet
            // under it, which is what makes the rising mouth reveal it. The
            // fill is already this path, so clipping costs it nothing.
            .overlay(alignment: .top) { dropTarget }
            .clipShape(PocketShape())
            // The new shape's own filter: dy −8, blur 12, black at 12%.
            .shadow(color: .black.opacity(0.12), radius: 12, y: -8)
            .offset(x: (SkinSelectSpec.size.width - SkinSelectSpec.sheetWidth) / 2, y: sheetTop)
            .allowsHitTesting(false)
    }

    /// The lit mouth, on its own layer above the card copy.
    ///
    /// It used to be an overlay on the pocket, which was fine while the card
    /// passed behind the sheet. Now that a copy is drawn in front, the glow
    /// has to be in front of *that* — the light is on the near edge of the
    /// mouth, so a card sliding into it should be lit, not cover it.
    ///
    /// Clipped to `PocketShape`. Unclipped, the bloom spills up past the mouth
    /// and paints over the part of the card that is still outside the pocket,
    /// which puts a coloured haze across the middle of the card. Clipped, the
    /// light exists only where there is pocket to emit it.
    @ViewBuilder
    private var pocketGlow: some View {
        if tune.glowEnabled {
            PocketGlow(colors: SkinPalette.colors(for: skins[index]),
                       intensity: glow,
                       span: mouthSpan,
                       front: cardBottomNow - sheetTop,
                       period: tune.glowPeriod,
                       thickness: tune.glowThickness)
                // Drawn in 150pt — the mouth is the first 51 and the rest is
                // headroom for the bloom — then clipped in the sheet's full
                // height so `PocketShape` scales to the same width and its
                // notch lands exactly on `PocketEdge`.
                .frame(width: SkinSelectSpec.sheetWidth, height: 150)
                .frame(width: SkinSelectSpec.sheetWidth,
                       height: SkinSelectSpec.size.height + 200, alignment: .top)
                .clipShape(PocketShape())
                // Its own curve, slower than the settle spring, so the light
                // dims out rather than being cut.
                .animation(.easeOut(duration: 0.4), value: confirmed)
                .offset(x: (SkinSelectSpec.size.width - SkinSelectSpec.sheetWidth) / 2,
                        y: sheetTop)
                .allowsHitTesting(false)
        }
    }

    /// The sheet's own shadow, falling into the pocket.
    ///
    /// The card copy restored the card but cost the depth: drawn in front of
    /// the sheet it reads as sliding *down over* the pocket rather than into
    /// it. This is the shadow the sheet's lip would cast on whatever is
    /// inside, so the card darkens as it passes under the edge.
    ///
    /// Built from `PocketCap` — the region *above* the mouth — blurred and
    /// nudged down, then clipped to the pocket, which leaves only the part
    /// that falls inside. A stroke along the edge would have been the obvious
    /// way and it lights the notch symmetrically; a cast shadow has to come
    /// from the solid side.
    ///
    /// It lands on the white sheet either side of the card as well as on the
    /// card, which is the other half of what it is for: the lip reads as
    /// having thickness, so the card looks like it is emerging from an edge
    /// rather than crossing a drawn line.
    private var mouthShadow: some View {
        let head = SkinSelectSpec.mouthShadowHead
        return PocketShape()
            // The sheet itself is the caster, in a frame whose top is the
            // mouth, so the shadow comes off the edge the card disappears
            // behind. Blurred, then lifted so the cast reaches *up* past it.
            .fill(.black)
            .frame(width: SkinSelectSpec.sheetWidth,
                   height: SkinSelectSpec.size.height + 200)
            .blur(radius: SkinSelectSpec.mouthShadowBlur)
            .offset(y: -SkinSelectSpec.mouthShadowDrop)
            .frame(width: SkinSelectSpec.sheetWidth,
                   height: SkinSelectSpec.size.height + 200 + head, alignment: .bottom)
            // Kept to the region *above* the mouth. Clipped the other way —
            // to the pocket — the cast landed on the sheet's own face and on
            // the part of the card already inside it, which is the opposite of
            // what puts the card behind the shape: a shadow on the near side
            // of an edge reads as dirt, not depth.
            .clipShape(PocketCap(headroom: head))
            // Windowed to the card, exactly as the glow is. Cast along the
            // whole 385pt perimeter it read as the sheet being lit from above
            // everywhere at once — a reaction on edges the card is nowhere
            // near. It is the card's shadow, so it belongs where the card is.
            .mask(MouthWindow.gradient(width: SkinSelectSpec.sheetWidth,
                                       span: mouthSpan))
            .opacity(SkinSelectSpec.mouthShadowOpacity
                     * (confirmed ? 0 : shadowFade))
            .animation(.easeOut(duration: 0.3), value: confirmed)
            .offset(x: (SkinSelectSpec.size.width - SkinSelectSpec.sheetWidth) / 2,
                    y: sheetTop - head)
            .allowsHitTesting(false)
    }

    /// y of the card layer's own frame, which the shader's coordinate space
    /// starts from.
    private var stageOrigin: CGFloat {
        SkinSelectSpec.cardCenterY - SkinSelectSpec.size.height / 2
    }

    /// The notch's four shoulder x values in the card layer's space. The sheet
    /// is 385.342 wide on a 375 stage, so it overhangs by 5.171 either side.
    private var sheetNotch: (CGFloat, CGFloat, CGFloat, CGFloat) {
        let s = PocketShape.notchShoulders(forWidth: SkinSelectSpec.sheetWidth)
        let x = (SkinSelectSpec.size.width - SkinSelectSpec.sheetWidth) / 2
        return (s.0 + x, s.1 + x, s.2 + x, s.3 + x)
    }

    /// The dragged card again, in front of the sheet.
    ///
    /// Built from `cardWidth`, `frontScale` and `frontDrop` — the same three
    /// values `card(_:)` gives the front card during a pull, where its stack
    /// transform is identity — so the two coincide exactly and there is no
    /// second image to see, only the one that is no longer being cut off.
    private var draggedCopy: some View {
        Image(skins[index])
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: SkinSelectSpec.cardWidth)
            .scaleEffect(frontScale)
            .offset(y: frontDrop)
            .frame(width: SkinSelectSpec.size.width, height: SkinSelectSpec.size.height)
            // Applied here, inside the stage-sized frame and before the frame
            // is positioned, so the shader's coordinate space is the stage's
            // and `edgeY` is just the sheet's top edge less this frame's own
            // offset. Attaching it further out would put the effect in a
            // space that moves with the card.
            .modifier(MouthBend(edgeY: sheetTop - stageOrigin,
                                notch: sheetNotch,
                                depth: PocketShape.notchDepth(
                                    forWidth: SkinSelectSpec.sheetWidth),
                                rim: PocketShape.rimDrop
                                    * (SkinSelectSpec.sheetWidth / PocketShape.designWidth),
                                sheetW: SkinSelectSpec.sheetWidth,
                                reach: tune.bendEnabled ? tune.bendReach : 0,
                                amount: tune.bendEnabled ? tune.bendAmount : 0))
            .offset(y: SkinSelectSpec.cardCenterY - SkinSelectSpec.size.height / 2)
            .opacity(!confirmed && dealt && pull > 0.001 ? 1 : 0)
            .allowsHitTesting(false)
    }

    /// The dashed outline the card drops into — `Rectangle 1891598615`.
    ///
    /// `.stroke`, not `.strokeBorder`: the design specifies Position: Center,
    /// and `strokeBorder` would inset the line by half its width.
    private var dropTarget: some View {
        // Both the stroke and the fill come from the card being dragged, so
        // the outline belongs to the skin you are choosing rather than being
        // green on all twenty-two. The design's 006B3B is the green-leather
        // card's own colour — `SkinPalette.ink` is calibrated against exactly
        // that value, so skin 19 still lands on it.
        let ink = SkinPalette.ink(for: skins[index])
        let box = SkinSelectSpec.dropTargetSize(for: skins[index])
        // Radius read off the card, and **circular**. The flat 22 was under
        // almost every skin — two thirds of the lego card's 33.6 — and
        // `.continuous` compounded it: a squircle sits much closer to the
        // corner at the 45° point than a circular arc of the same radius, so
        // the dashes bulged past the card's rounding at exactly the four
        // places the eye checks. Fitting the artwork offline puts these
        // corners at n ≈ 1.8…2.0, which is circular.
        let radius = SkinArt.cornerRadius(skins[index], at: box.width)
        return RoundedRectangle(cornerRadius: radius, style: .circular)
            .fill(ink.opacity(0.10))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .circular)
                    // Butt cap and a mitre join, per the designer's stroke
                    // panel — at 1pt over a 22pt continuous corner neither is
                    // really visible, but they are what the panel says.
                    .stroke(ink,
                            style: StrokeStyle(lineWidth: SkinSelectSpec.dropStrokeWidth,
                                               lineCap: .butt,
                                               lineJoin: .miter,
                                               dash: [SkinSelectSpec.dropDash,
                                                      SkinSelectSpec.dropDash]))
            }
            .frame(width: box.width, height: box.height)
            // The pocket view is offset to `sheetTop`, so this converts the
            // outline's fixed screen position into the sheet's own coordinates.
            // Above the mouth it lands outside the clip and simply is not
            // drawn. Centred rather than top-aligned, since the height now
            // follows the skin.
            .offset(y: SkinSelectSpec.dropCenterY - box.height / 2 - sheetTop)
            // Out on commit: the card lands on top of it, and a dashed outline
            // under a settled card reads as a mistake.
            .opacity(confirmed ? 0 : 1)
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

    /// When a card left behind in the stack starts its exit.
    ///
    /// Deepest card first, which is the opposite of what it looks like it
    /// should be. Peeling the nearest one off first is the intuitive reading
    /// and it is wrong: slots 2 and 3 are only invisible because slot 1 covers
    /// them, so lifting slot 1 away *uncovers* them and more cards end up on
    /// screen than started there. Going back-to-front means the deep ones
    /// leave while still hidden, and slot 1 is the only card ever seen in
    /// transit.
    private func exitDelay(slot s: Int) -> Double {
        let fromBack = Double(SkinSelectSpec.visibleDepth - min(s, SkinSelectSpec.visibleDepth))
        return fromBack * SkinSelectSpec.exitStagger
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
        let throwT = throwShift
        let t = isFront
            ? (scale: 1 + (parked.scale - 1) * CGFloat(tuck),
               dy: throwT.dy * CGFloat(1 - tuck) + parked.dy * CGFloat(tuck),
               angle: throwT.angle * (1 - tuck) + parked.angle * tuck,
               opacity: 1.0)
            : SkinSelectSpec.stack(slotF: (Double(s) - reveal) * fan)
        // Sideways only; the upward throw leaves this at zero.
        let frontDx = isFront ? throwT.dx * CGFloat(1 - tuck) : 0

        // The exit, for the cards that are not the one being chosen. This used
        // to be opacity alone, and three overlapping cards dissolving in place
        // reads as a rendering fault rather than a departure. It now mirrors
        // the deal-in — offset, scale, fade — pointed the other way: up and
        // out, so the deck looks like it is being lifted off the chosen card.
        //
        // Driven by `exitDrive`, which the selection sets, not by the pull.
        let exit = isFront ? 0 : exitDrive
        let exitDy = -SkinSelectSpec.exitLift * CGFloat(exit)
        let exitScale = 1 - SkinSelectSpec.exitShrink * CGFloat(exit)

        Image(skins[i])
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: cardWidth(front: isFront))
            .rotationEffect(.degrees(t.angle))
            .scaleEffect(t.scale * (isFront ? frontScale : exitScale) * (dealt ? 1 : 0.9))
            .offset(y: t.dy * (isFront ? 1 : fan) + exitDy + (dealt ? 0 : 34))
            .offset(x: frontDx)
            .offset(y: isFront ? frontDrop : 0)
            .opacity(t.opacity * (dealt ? 1 : 0))
            .animation(.spring(response: tune.entryResponse, dampingFraction: 0.74)
                        .delay(Double(min(s, SkinSelectSpec.visibleDepth)) * tune.entryStagger),
                       value: dealt)
            .animation(.spring(response: SkinSelectSpec.exitResponse, dampingFraction: 0.82)
                        .delay(exitDelay(slot: s)),
                       value: exitDrive)
            // Outside the spring above, so the fade runs on its own shorter
            // curve. It has to be a separate `.animation` at a higher point in
            // the chain: the spring claims the transaction for everything
            // below it, and one animation for both would tie the fade's length
            // to the travel's, which is the whole thing being changed.
            .opacity(isFront ? 1 : 1 - exit)
            .animation(.easeOut(duration: SkinSelectSpec.exitFade)
                        .delay(exitDelay(slot: s)),
                       value: exitDrive)
    }

    private func cardWidth(front: Bool) -> CGFloat {
        front && confirmed ? SkinSelectSpec.settledCardWidth : SkinSelectSpec.cardWidth
    }

    /// The front card shrinks as it is pulled toward the pocket, then springs up
    /// to hero size once it has settled.
    private var frontScale: CGFloat {
        // The settled card springs up *from* the size it seated at rather than
        // from a flat 0.55 — now that the seat is an exact fit to the outline,
        // starting anywhere else puts a shrink in front of the hero bounce.
        if confirmed { return settleBounce ? 1 : SkinSelectSpec.dropFitScale }
        // Finished by the time the card reaches the mouth, not at the end of
        // the travel. Spread over the whole seat the card was still 248 wide
        // as it entered a 241pt notch — visibly wider than the hole it was
        // going into — and only reached its seated 235 once it was already
        // inside. It now sizes itself on the way down and slides in at a
        // constant width, which is also what keeps it aligned with the
        // outline it is aiming at.
        return 1 - (1 - SkinSelectSpec.dropFitScale) * CGFloat(min(1, seat / seatAtMouth))
    }

    /// The seat at which the card — at its final, seated size — first reaches
    /// the notch floor.
    ///
    /// Bisected rather than solved, because both sides move: the card descends
    /// with the seat while the sheet rises on an ease-out. Measured against the
    /// *seated* height rather than the live one, which would be circular —
    /// the live height is what this is used to compute.
    private var seatAtMouth: Double {
        let h = SkinArt.height(skins[index], at: SkinSelectSpec.cardWidth)
            * SkinSelectSpec.dropFitScale
        let depth = PocketShape.notchDepth(forWidth: SkinSelectSpec.sheetWidth)
        func gap(_ s: Double) -> CGFloat {
            let bottom = SkinSelectSpec.cardCenterY
                + SkinSelectSpec.dropTravel * CGFloat(s) + h / 2
            let top = SkinSelectSpec.restTop
                + (SkinSelectSpec.dragTop - SkinSelectSpec.restTop)
                * CGFloat(easeOut(s * Double(SkinSelectSpec.commitFraction)))
            return bottom - (top + depth)
        }
        guard gap(1) > 0 else { return 1 }
        var lo = 0.0, hi = 1.0
        for _ in 0..<24 {
            let m = (lo + hi) / 2
            if gap(m) < 0 { lo = m } else { hi = m }
        }
        return max(0.15, hi)
    }

    private var frontDrop: CGFloat {
        if confirmed {
            return SkinSelectSpec.settledCardCenterY - SkinSelectSpec.cardCenterY
        }
        return SkinSelectSpec.dropTravel * CGFloat(seat)
    }


    // MARK: confirm copy

    private var confirmCopy: some View {
        VStack(spacing: 10) {
            Text("Confirm?").font(NoonFont.f(.extrabold, 34))
            Text("Finalise wallet skin").font(NoonFont.f(.medium, 16)).opacity(0.6)
        }
        .foregroundStyle(SkinSelectSpec.Palette.ink)
        .frame(width: SkinSelectSpec.confirmTitle.width)
        .offset(x: SkinSelectSpec.confirmTitle.minX, y: SkinSelectSpec.confirmTitle.minY)
        .opacity(confirmed && settleBounce ? 1 : 0)
        .allowsHitTesting(false)
    }

    private var continueButton: some View {
        Button {
            Haptics.shared.tap()
            if let onContinue {
                onContinue()
            } else {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) { reset() }
            }
        } label: {
            Text("Continue")
                .font(NoonFont.f(.semibold, 16))
                .foregroundStyle(.white)
                .frame(width: SkinSelectSpec.continueBtn.width,
                       height: SkinSelectSpec.continueBtn.height)
                .background(SkinSelectSpec.Palette.ink)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!confirmed)
        .accessibilityIdentifier("skinContinue")
        .offset(x: SkinSelectSpec.continueBtn.minX, y: SkinSelectSpec.continueBtn.minY)
        // Only once a card is actually chosen. It used to arm gradually through
        // the pull, which put a half-lit disabled button on screen for the
        // whole gesture — something to look at that could not be pressed.
        .opacity(confirmed ? 1 : 0)
        .animation(.easeOut(duration: 0.22), value: confirmed)
    }

    // MARK: hint
    //
    // The hint used to name the two gestures and then get out of the way as
    // soon as one started, which left the part that actually needs coaching —
    // how far is far enough — unsaid. It now follows the gesture: it says what
    // the direction does, then that there is further to go, then that letting
    // go will do it. The armed line is the one that matters; it is the same
    // moment as the `armed()` tick, so the phone and the screen say it
    // together.

    private enum HintPhase {
        case idle, throwing, throwArmed, pulling, pullArmed

        func text(sideways: Bool) -> String {
            switch self {
            case .idle:       sideways ? "Swipe to change" : "Swipe up to change"
            case .throwing:   "Keep going"
            case .throwArmed: "Release to change"
            case .pulling:    "Keep pulling"
            case .pullArmed:  "Release to confirm"
            }
        }

        func glyph(sideways: Bool) -> String? {
            switch self {
            case .idle, .throwing: sideways ? "‹ ›" : "︿"
            case .pulling:         "︾"
            case .throwArmed, .pullArmed: nil
            }
        }

        var armed: Bool { self == .throwArmed || self == .pullArmed }
    }

    private var hintPhase: HintPhase {
        let commit = Double(SkinSelectSpec.commitFraction)
        switch axisLock {
        case .cycle:   return advance >= commit ? .throwArmed : .throwing
        case .confirm: return pull >= commit ? .pullArmed : .pulling
        case nil:      return .idle
        }
    }

    /// Where the hint sits.
    ///
    /// 579 is the design's position and it is only safe when nothing is moving
    /// through it. A pull sends three things across it at once: the chosen card
    /// descends from 385 to 588, the sheet rises to 470, and the drop outline
    /// owns 560 down — so the hint was rendering behind the card for most of
    /// the gesture. Riding just above the sheet does not help either, because
    /// the card is above the sheet.
    ///
    /// The band from roughly 240 to 370 is clear for the whole pull, so the
    /// hint moves up there instead and stays put. The throw needs no such
    /// treatment: the card leaves 579 rather than crossing it.
    private static let pullHintY: CGFloat = 300

    private var hintY: CGFloat {
        hintPhase == .pulling || hintPhase == .pullArmed ? Self.pullHintY : SkinSelectSpec.hintY
    }

    private var hint: some View {
        let phase = hintPhase
        let sideways = tune.cycleAxis == .side
        return HStack(spacing: 6) {
            Text(phase.text(sideways: sideways))
                .font(NoonFont.f(phase.armed ? .semibold : .medium, 15))
                .contentTransition(.opacity)
            if let glyph = phase.glyph(sideways: sideways) {
                Text(glyph).font(.system(size: 13, weight: .bold)).opacity(0.7)
            }
        }
        .foregroundStyle(.white.opacity(phase.armed ? 1 : 0.85))
        .modifier(OnTexture())
        .frame(width: SkinSelectSpec.size.width)
        .offset(y: hintY)
        .opacity(dealt && !confirmed ? 1 : 0)
        .animation(.easeOut(duration: 0.14), value: phase)
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: hintY)
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
        let sideways = tune.cycleAxis == .side
        let throwReach = sideways ? abs(translation.width) : max(0, -translation.height)
        let pullReach = max(0, translation.height)

        // A small deadband either side of zero. Without it the first frame of a
        // throw (translation still ~0) starts the pull ramp and fires a stray
        // tick before the gesture has declared a direction.
        if max(throwReach, pullReach) < 2 {
            axisLock = nil
            advance = 0
            reveal = 0
            cycleDetent = 0
            armedThrow = false
            armedPull = false
            Haptics.shared.stopRamp()
            return
        }

        // Decided once. On the upward axis the sign of the vertical
        // translation settles it; sideways, whichever axis the finger has gone
        // further on. Held after that, so a pull that drifts left stays a pull
        // and a throw that sags stays a throw — and neither can drive the
        // other's geometry.
        if axisLock == nil {
            if sideways {
                axisLock = throwReach > pullReach ? .cycle : .confirm
                if axisLock == .cycle { throwDir = translation.width < 0 ? -1 : 1 }
            } else {
                axisLock = translation.height < 0 ? .cycle : .confirm
            }
        }

        if axisLock == .cycle {
            // Evaluated against the same expression the view uses to decide
            // whether to draw the copy in front of the sheet.
            if pull > 0.001 { crossTalk = true }
            // The card rides the finger; the transition only previews.
            let a = min(1, Double(throwReach) / Double(cycleSpan))
            advance = a
            // Scaled, not clamped. Clamping at `cyclePreview` meant the arc
            // tracked the finger for the first eighth of the throw and then
            // stopped dead for the rest of it — a hard stall mid-gesture,
            // which is where the stutter was coming from. Scaling keeps it
            // moving the whole way and still leaves ~90% of the transition for
            // the fixed-duration part.
            reveal = a * tune.cyclePreview
            // One firm tick as the gesture arms, so "you can let go" is a
            // distinct sensation rather than another detent.
            if !armedThrow, a >= Double(SkinSelectSpec.commitFraction) {
                armedThrow = true
                Haptics.shared.armed()
            }
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
            reveal = 0
            cycleDetent = 0
            armedThrow = false
            Haptics.shared.startRamp()
            Haptics.shared.updateRamp(progress: pull)
            if !armedPull, pull >= Double(SkinSelectSpec.commitFraction) {
                armedPull = true
                Haptics.shared.armed()
            }
        }
    }

    private func endDrag(_ translation: CGSize) {
        guard !confirmed else { return }
        Haptics.shared.stopRamp()
        cycleDetent = 0
        armedThrow = false
        armedPull = false
        let sideways = tune.cycleAxis == .side
        let throwReach = sideways ? abs(translation.width) : max(0, -translation.height)
        let commit = SkinSelectSpec.commitFraction
        let locked = axisLock
        axisLock = nil
        // Resolved on the axis the drag committed to, not by re-reading the
        // translation: a diagonal release could otherwise satisfy both.
        if locked == .confirm, translation.height > confirmSpan * commit {
            settle()
        } else if locked == .cycle, throwReach > cycleSpan * commit {
            cycle()
        } else {
            Haptics.shared.aborted()
            withAnimation(.spring(response: abortResponse, dampingFraction: 0.78)) {
                drag = .zero; advance = 0; reveal = 0; tuck = 0
            }
        }
    }

    /// Carries `advance` the rest of the way to 1, then commits the new front
    /// card and snaps `advance` back to 0 in the same frame. Because the layout
    /// at advance == 1 is identical to the committed layout at 0, nothing moves
    /// at the seam.
    /// Everything here runs on `tune.cycleDuration`, not on how the card was
    /// thrown. A flick and a slow drag produce the same transition.
    private func cycle() {
        Haptics.shared.swipe()
        let d = tune.cycleDuration
        drag = .zero
        transitioning = true

        // One spring for the card, and no delay on any of it.
        //
        // This was three staggered curves — `advance` easing to 1, then `tuck`
        // springing after a hold, so the card would finish rising clear of the
        // stack before dropping behind it. On an overshot throw `advance` is
        // already 1 when the finger lifts, which made that easing a no-op and
        // left the hold as the only thing happening: the card sat still at the
        // top for ~90ms. The fall-back on an under-threshold release was a
        // single spring with no hold, and that is the motion that reads well,
        // so the commit now uses the same shape.
        //
        // The hold is not missed. It existed to hide the depth change, and on
        // an overshot throw the card is already 49pt clear at release; on a
        // marginal one it overlaps by 6pt for a frame or two, on an edge.
        withAnimation(.spring(response: d * 0.76, dampingFraction: 0.80)) {
            advance = 1
            tuck = 1
        }

        // `easeOut`, not `easeInOut`. The finger was already moving the arc
        // when it lifted, and `easeInOut` restarts from zero velocity — a
        // visible hitch right at the seam. `easeOut` leaves at full speed and
        // decelerates into place, which continues the gesture instead of
        // interrupting it.
        withAnimation(.easeOut(duration: d), completionCriteria: .logicallyComplete) {
            reveal = 1
        } completion: {
            var t = Transaction(); t.disablesAnimations = true
            withTransaction(t) {
                index = nextIndex
                advance = 0
                reveal = 0
                tuck = 0
            }
            transitioning = false
            resumeHintsIfIdle()
        }
    }

    private func settle() {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
            confirmed = true
            drag = .zero
            advance = 0
            reveal = 0
            tuck = 0
        }
        Haptics.shared.settle()
        // The deck leaves now, not during the pull — one beat, on its own
        // clock, with the per-card stagger applied in `card(_:)`.
        exitDrive = 1
        // The reveal: the card is hidden behind the sheet at the moment it
        // settles, then springs up on top of it.
        withAnimation(.spring(response: 0.5, dampingFraction: 0.58).delay(0.12)) {
            settleBounce = true
        }
    }

    private func reset() {
        axisLock = nil
        crossTalk = false
        confirmed = false
        settleBounce = false
        exitDrive = 0
        drag = .zero
        advance = 0
        reveal = 0
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

    /// Parks the confirm pull at a fixed fraction and holds it, so the glow can
    /// be looked at without chasing a moving gesture.
    ///     xcrun simctl launch <udid> com.noon.gyroqr -onbStep Skin -skinPull 0.55
    private var heldPull: Double? { held("-skinPull") }

    /// `-skinThrow 1.0` parks the throw at full travel without releasing it —
    /// which is the frame that decides whether the hand-off is visible. If the
    /// card is entirely clear of the stack here, dropping it to the back of the
    /// z-order on release cannot be seen.
    private var heldThrow: Double? { held("-skinThrow") }

    /// `-skinFlick` throws the card with no travel time at all — one frame of
    /// drag straight to the threshold, then release. This is the case that
    /// exposed the problem: when the transition tracked the gesture, a flick
    /// finished it inside the swipe and nothing was visible.
    private var flickMode: Bool { ProcessInfo.processInfo.arguments.contains("-skinFlick") }

    /// `-skinAbort` pulls the card two thirds of the way down, holds, then
    /// releases short of the threshold — the case where everything that came
    /// up has to go back down again. Pair it with `-skinSlow 2.5` to stretch
    /// the retract, which is otherwise over in less time than it takes to
    /// capture two screenshots.
    private var abortMode: Bool { ProcessInfo.processInfo.arguments.contains("-skinAbort") }

    private var abortResponse: Double {
        let a = ProcessInfo.processInfo.arguments
        guard let i = a.firstIndex(of: "-skinSlow"), i + 1 < a.count,
              let v = Double(a[i + 1]), v > 0 else { return 0.42 }
        return 0.42 * v
    }

    private func held(_ flag: String) -> Double? {
        let a = ProcessInfo.processInfo.arguments
        guard let i = a.firstIndex(of: flag), i + 1 < a.count,
              let v = Double(a[i + 1]) else { return nil }
        return max(0, min(1, v))
    }

    /// Pull to 0.6 of the span — comfortably under `commitFraction` — hold,
    /// then let go.
    private func runAbort() {
        let down = confirmSpan * 0.6
        let lead = max(0, tune.entryDelay)
        for i in 0...24 {
            DispatchQueue.main.asyncAfter(deadline: .now() + lead + 1.0 + Double(i) * 0.03) {
                self.handleDrag(CGSize(width: 0, height: CGFloat(i) / 24 * down))
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + lead + 2.2) {
            self.endDrag(CGSize(width: 0, height: down))
        }
    }

    private func runDemo() {
        func at(_ t: Double, _ f: @escaping () -> Void) {
            DispatchQueue.main.asyncAfter(deadline: .now() + t, execute: f)
        }
        let down = confirmSpan
        let lead = max(0, tune.entryDelay)
        for base in [1.6 + lead, 3.4 + lead] {           // two throws
            for i in 0...16 {
                at(base + Double(i) * 0.035) {
                    self.handleDrag(self.throwVector(CGFloat(i) / 16))
                }
            }
            at(base + 0.62) { self.endDrag(self.throwVector(1)) }
        }
        for i in 0...34 {                                 // slow pull-down
            at(5.2 + lead + Double(i) * 0.05) {
                self.handleDrag(CGSize(width: 0, height: CGFloat(i) / 34 * down))
            }
        }
        at(7.1 + lead) { self.endDrag(CGSize(width: 0, height: down)) }
        // Hosted in the onboarding flow, carry on through Continue so the
        // hand-off to the next step is exercised too.
        at(9.0 + lead) { self.onContinue?() }
    }
}

/// Keeps white type legible over any of the 22 backdrops.
///
/// Every design frame uses a dark skin, so white-on-backdrop was never tested
/// against brushed silver, gold or yellow plush — and on those the title falls
/// to roughly 1.3:1 against the background while the subtitle and the swipe
/// hint disappear outright. A scrim would fix it and would also darken the
/// nineteen backdrops that were fine, which the design deliberately leaves
/// clean.
///
/// Two shadows instead: a tight one to give each glyph an edge, a wider soft
/// one for the mass. Black shadows are invisible on a dark backdrop, so this
/// costs the other nineteen nothing.
struct OnTexture: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: .black.opacity(0.34), radius: 1.5, y: 0.5)
            .shadow(color: .black.opacity(0.28), radius: 9, y: 2)
    }
}

/// The mouth pinch, in its own modifier so the `distortionEffect` call site
/// stays readable and so `amount == 0` genuinely means *no effect* rather than
/// a zero-displacement shader still rasterising the layer every frame.
struct MouthBend: ViewModifier {
    var edgeY: CGFloat
    /// The notch's shoulder x values, in the distorted view's own space.
    var notch: (CGFloat, CGFloat, CGFloat, CGFloat)
    var depth: CGFloat
    /// How far the far left and right of the top edge sit below the crest. The
    /// new shape crowns rather than running straight, so the profile outside
    /// the notch is a ramp and the shader needs both ends of it.
    var rim: CGFloat
    /// The sheet's width, for that ramp to run across. Its *origin* is not
    /// passed: the sheet is 376 on a 375 stage, so it starts half a point
    /// outside and the shader can treat x = 0 as its left edge.
    var sheetW: CGFloat
    var reach: Double
    var amount: Double

    func body(content: Content) -> some View {
        if amount > 0.01, reach > 0.01 {
            content.distortionEffect(
                ShaderLibrary.mouthBend(.float(Float(edgeY)),
                                        .float(Float(reach)),
                                        .float(Float(amount)),
                                        .float(Float(notch.0)),
                                        .float(Float(notch.1)),
                                        .float(Float(notch.2)),
                                        .float(Float(notch.3)),
                                        .float(Float(depth)),
                                        .float(Float(rim)),
                                        .float(Float(sheetW))),
                maxSampleOffset: CGSize(width: 0, height: amount))
        } else {
            content
        }
    }
}
