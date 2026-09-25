import SwiftUI

/// Request top up — Figma section `Request top up` (935:62729) for the screen,
/// and the designer's screen recording for what happens after the tap.
///
/// Three beats, and only the middle two are the brief:
///
/// * **entry** — amount, quick picks, note, CTA, keypad.
/// * **sending** — the page blurs away under a near-black veil and a bloom of
///   the card's own colours climbs in from below the bottom edge, under a
///   spinner and `Requesting top up`.
/// * **sent** — the bloom grows, flies out through the top, and the line
///   becomes `Top up request sent`.
///
/// The recording runs this on the *add money* screen, which is already dark, so
/// its ghosted content is white type dimming down. This flow's screen is light,
/// so the same read is built the other way round: the page keeps its own
/// surfaces and a 95.5% black veil goes over it, leaving the white keys, chips
/// and amount field showing through as the faint light shapes the bloom rises
/// out of. Taking the veil to full black loses them and the bloom then comes
/// out of nothing.
struct TopUpScreen: View {
    @ObservedObject var tune: TopUpTuning
    /// Runs the sequence itself shortly after appearing, for the flow's Replay.
    var autorun = false
    var onBack: () -> Void = {}
    /// The request landed — hands the amount back so the wallet can add it.
    var onDone: (Double) -> Void = { _ in }
    var onClose: () -> Void = {}

    enum Phase { case entry, sending, sent }

    @State private var phase: Phase = .entry
    @State private var amount = ""
    @State private var note = ""
    /// Cancelled on reset, so a replay part-way through the dwell cannot land
    /// its `sent` on top of the run that replaced it.
    @State private var pending: DispatchWorkItem?
    /// Set a beat before the wallet comes back, to lift the amount out first.
    @State private var handing = false

    var body: some View {
        GeometryReader { geo in
            let scale = max(geo.size.width / TopUpSpec.size.width,
                            geo.size.height / TopUpSpec.size.height)
            stage
                .frame(width: TopUpSpec.size.width, height: TopUpSpec.size.height)
                .scaleEffect(scale, anchor: .center)
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
        }
        .ignoresSafeArea()
        .onAppear {
            applyLaunchPhase()
            if autorun && phase == .entry {
                amount = amount.isEmpty ? "200" : amount
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                    if phase == .entry { send() }
                }
            }
        }
        .onDisappear { pending?.cancel() }
    }

    // MARK: stage

    private var stage: some View {
        ZStack(alignment: .topLeading) {
            Color.white

            page
                .blur(radius: tune.pageBlur * retreat)
                // A touch of scale, so the retreat has a direction and is not
                // only a loss of contrast.
                .scaleEffect(1 + 0.025 * retreat)
                .animation(.easeOut(duration: tune.fade), value: phase)

            Color.black
                .opacity(tune.veil * retreat)
                .frame(width: TopUpSpec.size.width, height: TopUpSpec.size.height)
                .animation(.easeOut(duration: tune.fade), value: phase)

            bloom
            amountReveal
            status
        }
        .frame(width: TopUpSpec.size.width, height: TopUpSpec.size.height,
               alignment: .topLeading)
        .contentShape(Rectangle())
        // Once it has landed, tapping anywhere puts the screen back so the
        // sequence can be run again without leaving the scene.
        .onTapGesture { if phase == .sent { reset() } }
    }

    /// How far the page has retreated: 0 while it is live, 1 from the tap on.
    private var retreat: Double { phase == .entry ? 0 : 1 }

    // MARK: the bloom
    //
    // Two curves on one driver, at different points in the chain. Growth wants
    // to be front-loaded — the cluster is already huge by the time it starts
    // leaving, which is what fills the frame with the middle of the gradient —
    // while the lift and the fade want to hold and then go, so the light is
    // still bright when it reaches the top. One shared curve gave either a
    // bloom that shrank away in the middle of the screen or one that left
    // before it had grown.

    private var bloom: some View {
        let span = TopUpSpec.bloomSpan
        let height = CGFloat(tune.bloomHeight)
        return AuroraBloom(colors: tune.bloomColors,
                           blur: tune.bloomBlur,
                           drift: tune.drift)
            .frame(width: span, height: height)
            .scaleEffect(bloomScale, anchor: .center)
            .animation(growCurve, value: phase)
            .offset(y: bloomLift)
            .animation(travelCurve, value: phase)
            .opacity(bloomAlpha)
            .animation(fadeCurve, value: phase)
            // Parked centred, with its own bottom sunk below the screen's.
            .offset(x: (TopUpSpec.size.width - span) / 2,
                    y: TopUpSpec.size.height + TopUpSpec.bloomSink - height)
    }

    private var bloomScale: CGFloat {
        switch phase {
        case .entry:   return 0.86      // a little under size, so the rise grows
        case .sending: return 1
        case .sent:    return CGFloat(tune.sweepScale)
        }
    }

    private var bloomLift: CGFloat {
        switch phase {
        case .entry:   return CGFloat(tune.bloomHeight)   // fully below the edge
        case .sending: return 0
        case .sent:    return -sweepLift
        }
    }

    /// How far the bloom has to travel to be gone — measured, not chosen.
    ///
    /// A fixed number left a tail of the cluster sitting in the lower half of
    /// the screen fading out in place, which reads as the light switching off
    /// rather than leaving. The lift has to clear the *lowest* thing in the
    /// cluster after the sweep has scaled it: the bottom of the lowest lobe,
    /// scaled about the box's centre, plus the bob that lobe can add and the
    /// blur's own tail — a Gaussian is still faintly visible about two radii
    /// out, and the blur scales with everything else.
    ///
    /// Deriving it means the sweep still fully exits after any change to the
    /// lobes, the height, the scale or the blur.
    private var sweepLift: CGFloat {
        let height = CGFloat(tune.bloomHeight)
        let boxTop = TopUpSpec.size.height + TopUpSpec.bloomSink - height
        let centre = boxTop + height / 2
        let scale = CGFloat(tune.sweepScale)
        let lowest = centre + (AuroraBloom.lowestExtent * height - height / 2) * scale
        let tail = (CGFloat(tune.bloomBlur) * 2.2 + AuroraBloom.lowestBob) * scale
        return (lowest + tail) * CGFloat(tune.sweepClear)
    }

    private var bloomAlpha: Double {
        switch phase {
        case .entry: return 0
        case .sending: return 1
        case .sent: return 0
        }
    }

    /// Curves are read after the change, so `phase` is already the new one —
    /// which is how one modifier can carry a different curve in each direction.
    private var growCurve: Animation {
        switch phase {
        case .entry:   return .easeOut(duration: tune.fade)
        case .sending: return .easeOut(duration: tune.rise)
        case .sent:    return .easeOut(duration: tune.sweep * 0.85)
        }
    }

    private var travelCurve: Animation {
        switch phase {
        case .entry:   return .easeOut(duration: tune.fade)
        case .sending: return .easeOut(duration: tune.rise)
        case .sent:    return .easeIn(duration: tune.sweep)
        }
    }

    /// The fade is held back and then run late, so the bloom is at full
    /// strength for most of its travel and the *lift* is what removes it. On
    /// the same curve as the travel it dimmed while still on screen, which is
    /// the light going out rather than going away.
    private var fadeCurve: Animation {
        switch phase {
        case .entry:   return .easeOut(duration: tune.fade * 0.7)
        case .sending: return .easeOut(duration: tune.rise * 0.55)
        case .sent:    return .easeIn(duration: tune.sweep * 0.42)
                              .delay(tune.sweep * 0.55)
        }
    }

    // MARK: the amount
    //
    // The number that was asked for, arriving with the confirmation: counting
    // up to itself out of a blur, in the flow's biggest digits.
    //
    // Two things here are the same trick used elsewhere in the app and worth
    // naming, because neither is the obvious way to write it.
    //
    // * The count is a view that conforms to `Animatable`, not a transition on
    //   a `Text`. `.contentTransition(.numericText())` rolls whatever digits it
    //   is handed, and it is handed 0 and then 200 — so it rolls once, from one
    //   to the other. Making the number the view's `animatableData` is what
    //   gets SwiftUI to re-evaluate the body per frame with the interpolated
    //   value, which is what counting *is*. (`BalanceText` on the wallet does
    //   the same for the balance.)
    // * The blur, the scale and the count run on separate `.animation` calls at
    //   different points in the chain. The number wants to be still moving when
    //   it is already sharp — if they share a curve the digits are legible only
    //   at the very end, and the count reads as a smear that stops.

    private var amountReveal: some View {
        CountingAmount(value: phase == .sent ? amountValue : 0,
                       target: amountValue)
            .animation(.easeOut(duration: tune.count)
                .delay(TopUpSpec.revealDelay), value: phase)
            // Resolves in the first half of the count, so most of the run is
            // spent watching a sharp number climb.
            .blur(radius: phase == .sent ? 0 : tune.countBlur)
            .scaleEffect(phase == .sent ? 1 : 1.07)
            .opacity(phase == .sent ? 1 : 0)
            .animation(.easeOut(duration: tune.count * 0.55)
                .delay(TopUpSpec.revealDelay), value: phase)
            .opacity(handing ? 0 : 1)
            .offset(y: handing ? -TopUpSpec.revealExitLift : 0)
            .animation(.easeIn(duration: TopUpSpec.revealExit), value: handing)
            .frame(width: TopUpSpec.size.width)
            .offset(y: TopUpSpec.revealY - TopUpSpec.revealDigits / 2)
            .allowsHitTesting(false)
    }

    // MARK: status line

    private var status: some View {
        HStack(spacing: 10) {
            mark
            Text(phase == .sent ? TopUpSpec.doneLabel : TopUpSpec.pendingLabel)
                .font(OnboardingSpec.F.b16)
                .tracking(-0.15)
                .foregroundStyle(.white)
                .id(phase == .sent)      // so the two labels crossfade
                .transition(.opacity)
        }
        .frame(width: TopUpSpec.size.width)
        .opacity(phase == .entry ? 0 : 1)
        .animation(.easeOut(duration: 0.3), value: phase)
        .offset(y: TopUpSpec.statusY - 11)
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var mark: some View {
        ZStack {
            if phase == .sent {
                // `ic_check_circle` is a filled disc with the tick knocked out
                // of it, so tinting it white gives the reference's mark exactly
                // — a white dot with a dark check — with no second layer.
                Image("ic_check_circle")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 17, height: 17)
                    .foregroundStyle(.white)
                    .transition(.scale(scale: 0.5).combined(with: .opacity))
            } else {
                Spinner().frame(width: 16, height: 16)
            }
        }
        .frame(width: 18, height: 18)
        .animation(.spring(response: 0.34, dampingFraction: 0.7), value: phase)
    }

    // MARK: the page

    private var page: some View {
        ZStack(alignment: .topLeading) {
            backButton
                .frame(width: TopUpSpec.backButton.width,
                       height: TopUpSpec.backButton.height)
                .offset(x: TopUpSpec.backButton.minX, y: TopUpSpec.backButton.minY)

            Text(TopUpSpec.title)
                .font(OnboardingSpec.F.b16)
                .tracking(-0.15)
                .foregroundStyle(OnboardingSpec.C.primary)
                .frame(width: TopUpSpec.size.width, alignment: .center)
                .offset(y: TopUpSpec.titleY)

            amountLine
                .frame(width: TopUpSpec.size.width, height: TopUpSpec.amountHeight)
                .offset(y: TopUpSpec.amountY)

            chips
                .frame(width: TopUpSpec.size.width)
                .offset(y: TopUpSpec.chipsY)

            noteField
                .frame(width: TopUpSpec.noteBox.width, height: TopUpSpec.noteBox.height)
                .offset(x: TopUpSpec.noteBox.minX, y: TopUpSpec.noteBox.minY)

            NeutralCTA(title: TopUpSpec.cta, enabled: !amount.isEmpty, lift: true) { send() }
                .frame(width: TopUpSpec.ctaBox.width)
                .offset(x: TopUpSpec.ctaBox.minX, y: TopUpSpec.ctaBox.minY)

            keypad
                .offset(y: TopUpSpec.padTop)
        }
        .frame(width: TopUpSpec.size.width, height: TopUpSpec.size.height,
               alignment: .topLeading)
        // The page stops taking taps the moment it starts retreating, so a
        // second tap on a ghosted CTA cannot start the sequence twice.
        .allowsHitTesting(phase == .entry)
    }

    private var backButton: some View {
        Button(action: onBack) {
            ZStack {
                Circle().fill(.white)
                Circle().strokeBorder(OnboardingSpec.C.borderSubtle, lineWidth: 1)
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(OnboardingSpec.C.primary)
            }
        }
        .buttonStyle(.plain)
    }

    /// 935:61359 — one run, `dhm` at 24 and the number at 40, both Bold,
    /// tracking −0.25, under a vertical ramp from `text/primary` to
    /// `text/secondary`. It used to be a 26pt mark in the secondary colour and
    /// flat-filled digits with no tracking, which read as two separate things
    /// rather than one amount.
    private var amountLine: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            if amount.isEmpty {
                Text(MoneyStyle.dirham)
                    .font(NoonFont.f(.bold, 24))
                    .tracking(MoneyStyle.tracking)
                    .foregroundStyle(MoneyStyle.onPage)
                    .padding(.trailing, 7)
                caret
                Text("0")
                    .font(NoonFont.f(.bold, 40))
                    .tracking(MoneyStyle.tracking)
                    .foregroundStyle(OnboardingSpec.C.grey500)
                    .padding(.leading, 7)
            } else {
                MoneyText(amount: amount, markSize: 24, digitSize: 40,
                          weight: .bold, style: MoneyStyle.onPage)
                caret
            }
        }
    }

    /// Blinks on a periodic timeline rather than a repeating animation — the
    /// page is under a blur for half of this screen's life and a live animation
    /// there costs a re-render of the blurred layer every frame.
    private var caret: some View {
        TimelineView(.periodic(from: .now, by: 0.55)) { timeline in
            let on = Int(timeline.date.timeIntervalSinceReferenceDate / 0.55) % 2 == 0
            RoundedRectangle(cornerRadius: 1)
                .fill(OnboardingSpec.C.actionBold)
                .frame(width: 2, height: 32)
                .opacity(on ? 1 : 0.15)
        }
        .frame(width: 2, height: 32)
    }

    private var chips: some View {
        HStack(spacing: 8) {
            ForEach(TopUpSpec.quickAmounts, id: \.self) { value in
                Button {
                    Haptics.shared.selectionTick()
                    amount = "\(value)"
                } label: {
                    // `B16/Medium` at `text/secondary`, tracking −0.15 —
                    // 935:61361. Both halves the same size and weight: the
                    // mark was set 3pt smaller and a weight heavier, which is
                    // not what a chip does.
                    HStack(spacing: 4) {
                        Text(TopUpSpec.currency)
                        Text("\(value)")
                    }
                    .font(NoonFont.f(.medium, 16))
                    .tracking(-0.15)
                    .foregroundStyle(OnboardingSpec.C.secondary)
                    .padding(.horizontal, 13)
                    .frame(height: TopUpSpec.chipHeight)
                    .background(.white, in: Capsule())
                    .overlay { Capsule().strokeBorder(TopUpSpec.chipBorder, lineWidth: 1) }
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// There is no text keyboard in this flow — the keypad is numeric — so the
    /// field fills and clears with the design's own sample line. It is a
    /// prototype of the motion, and typing a note is not part of it.
    private var noteField: some View {
        Button {
            Haptics.shared.tap()
            note = note.isEmpty ? TopUpSpec.noteSample : ""
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(TopUpSpec.noteLabel)
                    .font(OnboardingSpec.F.b12)
                    .foregroundStyle(OnboardingSpec.C.tertiary)
                if !note.isEmpty {
                    Text(note)
                        .font(OnboardingSpec.F.b14)
                        .foregroundStyle(OnboardingSpec.C.primary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 12)
            .padding(.top, 11)
            .background(OnboardingSpec.C.grey100,
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: keypad

    private var keypad: some View {
        ZStack(alignment: .topLeading) {
            Rectangle().fill(TopUpSpec.padSurface)
                .frame(width: TopUpSpec.size.width, height: TopUpSpec.padHeight)

            ForEach(0..<11, id: \.self) { i in
                // The last row is offset by one: its first slot is empty, so
                // the zero sits in the middle column and the backspace at the
                // right, which is what the frame draws.
                let row = i < 9 ? i / 3 : 3
                let column = i < 9 ? i % 3 : i - 8
                key(at: i)
                    .offset(x: TopUpSpec.keyOrigin.x
                               + (TopUpSpec.keySize.width + TopUpSpec.keyGap.width)
                               * CGFloat(column),
                            y: TopUpSpec.keyOrigin.y - TopUpSpec.padTop
                               + (TopUpSpec.keySize.height + TopUpSpec.keyGap.height)
                               * CGFloat(row))
            }
        }
        .frame(width: TopUpSpec.size.width, height: TopUpSpec.padHeight,
               alignment: .topLeading)
    }

    /// Slots 0–8 are the digits, 9 is the zero in the middle of the last row,
    /// 10 is the backspace at its right. The last row's first slot is empty and
    /// the backspace has no key behind it — both straight from the frame.
    @ViewBuilder
    private func key(at slot: Int) -> some View {
        let size = TopUpSpec.keySize
        if slot < 9 {
            digitKey("\(slot + 1)").frame(width: size.width, height: size.height)
        } else if slot == 9 {
            digitKey("0").frame(width: size.width, height: size.height)
        } else {
            Button {
                guard !amount.isEmpty else { return }
                Haptics.shared.keyTick()
                amount.removeLast()
            } label: {
                Image(systemName: "delete.left")
                    .font(.system(size: 19, weight: .regular))
                    .foregroundStyle(OnboardingSpec.C.grey800)
                    .frame(width: size.width, height: size.height)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private func digitKey(_ digit: String) -> some View {
        Button {
            Haptics.shared.keyTick()
            // Six digits is past anything the quick picks suggest, and it keeps
            // the amount inside its line.
            if amount.count < 6 { amount += digit }
        } label: {
            Text(digit)
                .font(NoonFont.f(.medium, 18))
                .foregroundStyle(OnboardingSpec.C.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.white,
                            in: RoundedRectangle(cornerRadius: TopUpSpec.keyRadius,
                                                 style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: sequence

    private func send() {
        guard phase == .entry else { return }
        phase = .sending
        let land = DispatchWorkItem {
            phase = .sent
            Haptics.shared.settle()
            // Long enough for the bloom to clear the top and the check to be
            // read, and no longer: past that the screen is just black.
            // Two steps, nested so a reset part-way through cancels both:
            // the amount lifts out, then the wallet comes back.
            let leave = DispatchWorkItem {
                handing = true
                let handOff = DispatchWorkItem { onDone(amountValue) }
                pending = handOff
                DispatchQueue.main.asyncAfter(deadline: .now() + TopUpSpec.revealExit,
                                              execute: handOff)
            }
            pending = leave
            DispatchQueue.main.asyncAfter(
                deadline: .now() + max(0, handOffDelay - TopUpSpec.revealExit),
                execute: leave)
        }
        pending = land
        DispatchQueue.main.asyncAfter(deadline: .now() + tune.dwell + tune.rise,
                                      execute: land)
    }

    /// How long the landed state is held, measured from whichever of the two
    /// things happening in it finishes last: the bloom leaving through the top,
    /// or the amount finishing its count. Taking it from the sweep alone —
    /// which is what it used to do — meant the wallet arrived while the number
    /// was still climbing, and the fix was not to pad `settle` by hand but to
    /// hold from the end of the count as well.
    private var handOffDelay: Double {
        max(tune.sweep, TopUpSpec.revealDelay + tune.count) + tune.settle
    }

    /// The typed amount as a number. Empty is unreachable — the CTA is dead
    /// until something is entered — but it costs nothing to be safe about it.
    private var amountValue: Double { Double(amount) ?? 0 }

    private func reset() {
        pending?.cancel()
        pending = nil
        handing = false
        phase = .entry
    }

    /// `-topUpPhase Sending` / `Sent` holds a beat of the sequence for a
    /// screenshot, with the amount pre-filled so the ghost underneath is the
    /// one the design has. (`-topUpAuto`, which runs the whole thing, is the
    /// flow's job now — it has to open this screen first.)
    private func applyLaunchPhase() {
        let a = ProcessInfo.processInfo.arguments
        guard let i = a.firstIndex(of: "-topUpPhase"), i + 1 < a.count else { return }
        if amount.isEmpty { amount = "200" }
        switch a[i + 1].lowercased() {
        case "sending": phase = .sending
        case "sent":    phase = .sent
        default:        break
        }
    }
}

/// The requested amount, as a view that interpolates.
///
/// `target` is only there to hold the width. Counting 0 → 200 in a centred
/// `HStack` reflows the block on every digit the number gains, so the whole
/// line creeps sideways while it climbs; laying out the final string and
/// drawing the live one into that box trailing-aligned pins the ones column and
/// lets the number grow leftward into space that is already reserved.
private struct CountingAmount: View, Animatable {
    var value: Double
    var target: Double

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    private static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()

    private static func text(_ v: Double) -> String {
        formatter.string(from: v.rounded() as NSNumber) ?? "0"
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 9) {
            Text(MoneyStyle.dirham)
                .font(NoonFont.f(.extrabold, TopUpSpec.revealMark))
            digits(Self.text(target))
                .hidden()
                .overlay(alignment: .trailing) { digits(Self.text(value)) }
        }
        .tracking(MoneyStyle.tracking)
        .foregroundStyle(MoneyStyle.onSurface)
    }

    private func digits(_ string: String) -> some View {
        Text(string)
            .font(NoonFont.f(.extrabold, TopUpSpec.revealDigits))
            .monospacedDigit()
            .fixedSize()
    }
}

/// The ring that turns while the request is in flight.
private struct Spinner: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let turn = timeline.date.timeIntervalSinceReferenceDate
                .truncatingRemainder(dividingBy: 1.1) / 1.1
            Circle()
                .trim(from: 0, to: 0.78)
                .stroke(.white.opacity(0.85),
                        style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                .rotationEffect(.degrees(turn * 360))
        }
    }
}
