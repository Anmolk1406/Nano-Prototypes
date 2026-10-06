import SwiftUI

/// The wallet page — Figma `Wallet Page` in three states: empty (962:66753),
/// the receipt landing (935:61752), and filled (935:61643).
///
/// The flow opens on the empty one. There is no balance and no history, and
/// the first top-up request is what produces both — so the interesting thing
/// about this view is not any one of the three states but the move between
/// them, which is one continuous rearrangement rather than a cut:
///
/// * the art block rises 93pt as the page loses its headline,
/// * the balance climbs from the middle of the page to under the card and
///   counts up to the new amount on the way,
/// * `Your wallet is empty` and its line of help fade out,
/// * the pocket rises 257pt and the transaction list arrives inside it,
/// * and the receipt card unfolds out of the button's notch.
///
/// All of it is driven by one `filled` flag through interpolated positions, so
/// a single `withAnimation` in the flow moves everything together.
struct WalletScreen: View {
    /// Which card the user is wearing. Drives both the card art and the page
    /// behind it — see `WalletSpec.cardArt`.
    var skin = WalletSpec.defaultSkin
    /// Balance in the wallet's own currency. Animated by `BalanceText`, so
    /// handing it a new value inside `withAnimation` counts up to it.
    let balance: Double
    /// Whether the wallet has history — the filled layout, with the list.
    var filled: Bool
    /// Whether the `Top up request sent` card is in.
    let receipt: Bool
    var onRequest: () -> Void = {}
    /// Bumped by the controls sheet's Replay, so the entrance plays again.
    var replay = 0

    /// Runs the staggered entrance once, shortly after the page appears.
    @State private var loaded = false

    var body: some View {
        GeometryReader { geo in
            let scale = max(geo.size.width / WalletSpec.size.width,
                            geo.size.height / WalletSpec.size.height)
            stage
                .frame(width: WalletSpec.size.width, height: WalletSpec.size.height)
                .scaleEffect(scale, anchor: .center)
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
        }
        .ignoresSafeArea()
        .onAppear { enter() }
        .onChange(of: replay) { _, _ in
            loaded = false
            enter()
        }
    }

    /// `-walletEntry` holds the page in its pre-entrance pose, which is how
    /// the card's arrival tilt was fitted to the reference: the whole thing
    /// settles in about 0.3s and there is no way to catch a frame of it.
    private static let held = ProcessInfo.processInfo.arguments.contains("-walletEntry")

    /// One frame's grace, so the first value the animation interpolates from
    /// is the pre-entrance one and not whatever the layout pass settled on.
    private func enter() {
        guard !loaded, !Self.held else { return }
        DispatchQueue.main.async { loaded = true }
    }

    private var stage: some View {
        ZStack(alignment: .topLeading) {
            // Under the cut, and behind the list.
            Color.white

            art
            header
            emptyCopy

            cut
            list
            if receipt { receiptCard }

            // Over the cut: the button straddles the purple/white boundary, and
            // the nav sits over the list.
            requestButton
                .frame(width: WalletSpec.requestButton.width,
                       height: WalletSpec.requestButton.height)
                .offset(x: WalletSpec.requestButton.minX, y: buttonY)
                .modifier(EnterFrom(.above, loaded: loaded, order: 4))

            Image("wallet_nav")
                .resizable()
                .frame(width: WalletSpec.nav.width, height: WalletSpec.nav.height)
                .offset(x: WalletSpec.nav.minX, y: WalletSpec.nav.minY)
                .modifier(EnterFrom(.below, loaded: loaded, order: 5))
        }
        .frame(width: WalletSpec.size.width, height: WalletSpec.size.height,
               alignment: .topLeading)
        .animation(.spring(response: 0.62, dampingFraction: 0.86), value: filled)
    }

    // MARK: where things sit
    //
    // Every position the two layouts disagree about is written once, as a
    // choice between the empty frame's number and the filled frame's. They
    // animate because they are offsets on views that stay in the tree — the
    // alternative, two layout branches swapped by `if`, cross-fades instead of
    // moving and loses the whole point of the transition.

    private var artDrop: CGFloat { filled ? 0 : WalletSpec.Empty.artDrop }
    private var balanceY: CGFloat { filled ? WalletSpec.balanceY : WalletSpec.Empty.balanceY }
    private var buttonY: CGFloat { filled ? WalletSpec.requestButton.minY : WalletSpec.Empty.buttonY }

    private var crest: CGFloat {
        guard filled else { return WalletSpec.Empty.cutCrest }
        return receipt ? WalletSpec.cutCrestWithReceipt : WalletSpec.cutCrest
    }

    // MARK: art

    private var art: some View {
        ZStack(alignment: .topLeading) {
            let back = filled ? WalletSpec.backdrop : WalletSpec.backdropEmpty
            Image(WalletSpec.backdropArt(skin))
                .resizable()
                .frame(width: back.width, height: back.height)
                .offset(x: back.minX, y: back.minY)

            // The mascot ball and the sparkle that the frame puts either side
            // of the card are gone. They are the design's decoration, not the
            // wallet's content, and with the card now changing per skin they
            // were two fixed objects pinned to a variable one.
            skinCard
        }
        .frame(width: WalletSpec.size.width, height: WalletSpec.size.height,
               alignment: .topLeading)
    }

    /// The card, at its own aspect rather than the frame's squeezed one.
    private var skinCard: some View {
        let name = WalletSpec.cardArt(skin)
        let box = WalletSpec.cardBody
        let w = box.width
        let h = SkinArt.height(name, at: w)
        return Image(name)
            .resizable()
            .frame(width: w, height: h)
            // Centred on the body the design draws, so a taller or shorter
            // skin grows about the same point rather than hanging off the top.
            .offset(x: box.midX - w / 2, y: box.midY - h / 2 + artDrop)
            .modifier(EnterFrom(.above, loaded: loaded, order: 0,
                                tilt: WalletSpec.entryKeystone))
    }

    // MARK: header

    /// White type or dark, whichever the background can carry. See `WalletInk`.
    private var ink: WalletInk.Scheme {
        WalletInk.scheme(for: WalletSpec.backdropArt(skin))
    }

    private var header: some View {
        ZStack(alignment: .topLeading) {
            Text(WalletSpec.owner)
                .font(NoonFont.f(.bold, 11))
                .tracking(WalletSpec.ownerTracking)
                .foregroundStyle(ink.subtle)
                .frame(width: WalletSpec.size.width, alignment: .center)
                .offset(y: WalletSpec.ownerY)
                // The empty state has no owner line — the headline below the
                // balance is doing that job there.
                .opacity(filled ? 1 : 0)

            BalanceText(value: balance, style: ink.money)
                .frame(width: WalletSpec.size.width, alignment: .center)
                .offset(y: balanceY)
                .modifier(EnterFrom(.above, loaded: loaded, order: 2))
        }
        .frame(width: WalletSpec.size.width, height: WalletSpec.size.height,
               alignment: .topLeading)
    }

    /// `Your wallet is empty`, and the line of help under it.
    private var emptyCopy: some View {
        ZStack(alignment: .topLeading) {
            Text(WalletSpec.Empty.title)
                .font(NoonFont.f(.bold, 28))
                .tracking(-0.25)
                .foregroundStyle(ink.bold)
                .frame(width: WalletSpec.size.width, alignment: .center)
                .offset(y: WalletSpec.Empty.titleY)
                .modifier(EnterFrom(.above, loaded: loaded, order: 3))

            Text(WalletSpec.Empty.subtitle)
                .font(NoonFont.f(.regular, 14))
                .tracking(-0.1)
                .foregroundStyle(ink.subtle)
                .frame(width: WalletSpec.size.width, alignment: .center)
                .offset(y: WalletSpec.Empty.subtitleY)
                .modifier(EnterFrom(.above, loaded: loaded, order: 3))
        }
        .frame(width: WalletSpec.size.width, height: WalletSpec.size.height,
               alignment: .topLeading)
        .opacity(filled ? 0 : 1)
        .allowsHitTesting(!filled)
    }

    /// `M-NeutralRoundButton` — white pill, dark ink, an arrow in a ring.
    private var requestButton: some View {
        Button(action: onRequest) {
            HStack(spacing: 6) {
                Text(WalletSpec.requestTitle)
                    .font(NoonFont.f(.bold, 14))
                    .tracking(-0.2)
                Image(systemName: "arrow.up")
                    .font(.system(size: 9, weight: .bold))
                    .frame(width: 16, height: 16)
                    .overlay { Circle().strokeBorder(lineWidth: 1.2) }
            }
            .foregroundStyle(OnboardingSpec.C.primary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.white, in: Capsule())
        }
        // Lifts toward the finger rather than shrinking away from it, with a
        // tick going down and a softer one coming back up.
        .buttonStyle(PressLift())
    }

    // MARK: the cut, the list, the receipt

    private var cut: some View {
        WalletCutShape()
            .fill(.white)
            .frame(width: WalletSpec.cutWidth,
                   height: WalletSpec.size.height - crest + 60)
            .shadow(color: WalletSpec.cutShadow.color,
                    radius: WalletSpec.cutShadow.radius,
                    y: WalletSpec.cutShadow.y)
            .offset(x: WalletSpec.cutX, y: crest)
            .modifier(EnterFrom(.below, loaded: loaded, order: 4))
    }

    /// The history, which does not exist until the first top-up lands.
    ///
    /// It arrives with the page's other results rather than on its own curve —
    /// it is the same event — but it comes up from under the pocket's crest
    /// instead of fading in place, so it reads as a list that was always there
    /// and has just been scrolled into view.
    private var list: some View {
        Image("wallet_txns")
            .resizable()
            .frame(width: WalletSpec.transactions.width,
                   height: WalletSpec.transactions.height)
            .offset(x: WalletSpec.transactions.minX,
                    y: receipt ? WalletSpec.transactionsWithReceipt
                               : WalletSpec.transactions.minY)
            // Clipped to the pocket, in the stage's own coordinates — hence
            // the full-stage frame, which is what gives `clipShape` a rect to
            // resolve the path against. Without it the list is simply on top
            // of everything: it arrives with the rest of the results, while
            // the pocket is still on its way up, and for a third of a second
            // four transaction rows sit on the purple backdrop.
            //
            // Clipping to the real path rather than to a rectangle at the
            // crest is worth the three lines: the mouth dips 42pt at the
            // notch, and a straight cut lets the list show through it.
            .frame(width: WalletSpec.size.width, height: WalletSpec.size.height,
                   alignment: .topLeading)
            .clipShape(PocketRegion(crest: crest))
            // Always in the tree, hidden rather than absent. Inserting it with
            // a transition looks equivalent and is not: a view that arrives
            // mid-animation has no previous value for its modifiers to
            // interpolate from, so the clip snapped straight to the *settled*
            // crest while the pocket was still 250pt lower — four transaction
            // rows, ghosted over the purple, for the length of the move.
            .opacity(filled ? 1 : 0)
            .offset(y: filled ? 0 : WalletSpec.listRise)
    }

    /// Grows out of its own notch, so it reads as coming from the button it
    /// points at rather than fading up in place. The anchor is what does that:
    /// scaling from `.top` keeps the notch still while the card unfolds below
    /// it, and scaling from the centre made the notch slide off the button.
    private var receiptCard: some View {
        Image("wallet_receipt")
            .resizable()
            .frame(width: WalletSpec.receipt.width, height: WalletSpec.receipt.height)
            .transition(.scale(scale: 0.9, anchor: .top)
                .combined(with: .offset(y: -18))
                .combined(with: .opacity))
            .offset(x: WalletSpec.receipt.minX, y: WalletSpec.receipt.minY)
    }
}

/// A vertical keystone: the top edge magnified, the bottom reduced, the height
/// left alone.
///
/// This is the card's 3D on the way in, and it is *not* `rotation3DEffect`.
/// Two measurements rule that out. The reference's card is a clear trapezoid —
/// bottom edge 11% narrower than the top on the first clean frames — and its
/// **height does not change**: 353px at t = 0.133 and 356px settled. A rigid
/// rotation cannot do both. Driving SwiftUI's own effect to the right width
/// ratio costs 17–27% of the height depending on how the angle and the
/// perspective are split between them, and at that point the card reads as
/// being squashed rather than as leaning.
///
/// What the reference actually has is the perspective *divide* without the
/// foreshortening, which is one 3×3 projective matrix:
///
///     x' = x / (1 + q·y),  y' = y / (1 + q·y),  q = 2k / h
///
/// about the plane's own centre. The edges come out magnified by 1/(1∓k), so
/// the width ratio is (1−k)/(1+k) — and the projected height is h/(1−k²),
/// which at k = 0.058 is 0.3% over size. Height preserved, by construction.
///
/// The matrix is written out term by term rather than composed from a
/// translate, a keystone and a translate back. Composing it is the obvious way
/// and it does not work: `ProjectionTransform.concatenating(_:)` does not
/// order the way `CGAffineTransform`'s does, and both orders keystone about a
/// *corner* instead of the centre — which shrinks the whole plane rather than
/// tipping it. Measured over three amounts, the corner-anchored version kept
/// 0.894 / 0.803 / 0.729 of the card's height where this one keeps 1.003.
///
/// With the divide folded in, the map is
///
///     X = x + (wk/h)·y − wk/2
///     Y = (1 + k)·y − hk/2
///     W = (2k/h)·y + (1 − k)
///
/// which is `ProjectionTransform`'s nine terms directly, in the row-vector
/// layout it shares with `CGAffineTransform` (m31/m32 are the translation).
/// Checking it at the corners is worth the minute it takes: the top edge comes
/// out w/(1−k) wide, the bottom w/(1+k), and the height h/(1−k²).
private struct Keystone: GeometryEffect {
    /// Fractional magnification at the top edge. 0 is flat.
    var amount: Double

    var animatableData: Double {
        get { amount }
        set { amount = newValue }
    }

    /// What the keystone costs the plane in size, and has to be given back.
    ///
    /// It should cost nothing — the algebra above says the projected height is
    /// h/(1−k²), 0.3% *over* size, and the width is unchanged on average. It
    /// does not work out that way. Swept at three amounts the rendered height
    /// comes back at 0.894, 0.803 and 0.729 of full size, and the width at
    /// about 0.86 — SwiftUI is anchoring the divide somewhere other than where
    /// the matrix puts it, and no arrangement of the nine terms, nor either
    /// order of `concatenating`, moves it.
    ///
    /// So it is corrected rather than argued with. Both shrinkages fit
    /// 1/(1 + c·k) closely, with c = 4.2 down and 1.9 across, and scaling by
    /// the reciprocals restores the plane's size while leaving the *ratio*
    /// between its two edges — the trapezoid, which is the whole effect —
    /// untouched. Verified on the build: 99.4% of full height at the amount
    /// this uses, against a reference that keeps 100%.
    static func stretch(for amount: Double) -> CGSize {
        CGSize(width: 1 + 1.9 * amount, height: 1 + 4.2 * amount)
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        guard size.height > 0, amount != 0 else { return ProjectionTransform() }
        let k = CGFloat(amount)
        let w = size.width, h = size.height
        var t = ProjectionTransform()
        t.m11 = 1;          t.m12 = 0;          t.m13 = 0
        t.m21 = w * k / h;  t.m22 = 1 + k;      t.m23 = 2 * k / h
        t.m31 = -w * k / 2; t.m32 = -h * k / 2; t.m33 = 1 - k
        return t
    }
}

/// The pocket's interior, in stage coordinates, as a clip.
///
/// `crest` is animatable so the region opens as the sheet rises rather than
/// snapping to its final height on the first frame.
private struct PocketRegion: Shape {
    var crest: CGFloat

    var animatableData: CGFloat {
        get { crest }
        set { crest = newValue }
    }

    func path(in rect: CGRect) -> Path {
        WalletCutShape().path(in: CGRect(x: WalletSpec.cutX, y: crest,
                                      width: WalletSpec.cutWidth,
                                      height: rect.height - crest + 60))
    }
}

/// The page's entrance: fade up while settling *down* into place, and — for
/// the card — rotating flat as it lands.
///
/// Taken off the designer's reference clip rather than invented, and what is
/// worth measuring there is the direction and the perspective.
///
/// **It settles downward.** The card's top edge travels from 32px *above* its
/// resting place down to it, while its opacity goes 0 → 1 in the first third
/// of that — so the element is solid for most of the move and what you read is
/// the settling, not the appearing. Nearly every list entrance slides *up*;
/// this one does not, and it reads as the page being laid down rather than
/// pushed in.
///
/// **The card is not flat on the way in.** Tracking its four corners frame by
/// frame, the bottom edge is measurably narrower than the top — the width
/// ratio runs 0.931 → 0.977 → 1 over the entrance while both edge centres stay
/// on 370px, so it is not a slide or a scale but a rotation about the
/// horizontal axis with the top tipped toward the camera. The two edges agree
/// on the amount: a top edge 3.6% over size and a bottom edge 3.6% under it
/// both give (h/2)·sin θ ≈ 0.036·d, and the numbers falling out of two
/// independent measurements is what says the model is the right one.
private struct EnterFrom: ViewModifier {
    enum Edge { case above, below }

    let edge: Edge
    let loaded: Bool
    /// Position in the stagger, not a duration — the delay is derived so the
    /// whole sequence retimes from one number.
    let order: Int
    /// How hard the plane is keystoned on arrival. 0 for everything but the
    /// card, which is the only one big enough for a perspective to read.
    var tilt: Double = 0

    init(_ edge: Edge, loaded: Bool, order: Int, tilt: Double = 0) {
        self.edge = edge
        self.loaded = loaded
        self.order = order
        self.tilt = tilt
    }

    /// Seconds between one element starting and the next.
    private static let step = 0.055
    private static let travel: CGFloat = 14
    /// The pocket and the nav come from off the bottom of the screen, which is
    /// where they live — sliding a sheet down into place reads as a mistake.
    private static let sheetTravel: CGFloat = 46

    /// `interpolatingSpring(stiffness:damping:)` *is* tension and friction —
    /// the same two numbers a spring is specified with everywhere else — so
    /// 320 and 28 go in as themselves. Damping ratio 28 / (2√320) = 0.78, just
    /// under critical, which settles in about 0.29s with a touch of overshoot.
    /// The entrance used to be a `spring(response: 0.72)`, which is a 0.72s
    /// period and took most of a second to stop moving.
    private static let curve = Animation.interpolatingSpring(stiffness: 320, damping: 28)

    /// Under `-walletEntry` the page holds its pre-entrance *pose* but is
    /// drawn at full strength, because a transform cannot be measured off a
    /// transparent card.
    private static let held = ProcessInfo.processInfo.arguments.contains("-walletEntry")

    func body(content: Content) -> some View {
        let delay = Double(order) * Self.step
        let d: CGFloat = edge == .above ? -Self.travel : Self.sheetTravel
        return content
            .modifier(Keystone(amount: loaded ? 0 : tilt))
            .scaleEffect(loaded ? CGSize(width: 1, height: 1) : Keystone.stretch(for: tilt),
                         anchor: .center)
            .offset(y: loaded ? 0 : d)
            .animation(Self.curve.delay(delay), value: loaded)
            .opacity(loaded || Self.held ? 1 : 0)
            // Opacity on its own, shorter curve: the reference has the card at
            // full strength about a third of the way through its travel.
            .animation(.easeOut(duration: 0.18).delay(delay), value: loaded)
    }
}

/// The balance, as a view that interpolates.
///
/// `Animatable` on the view rather than a transition on the text: the point is
/// to *count*, and the only way SwiftUI will re-evaluate a body per frame with
/// an interpolated number is to make that number the view's `animatableData`.
/// `.contentTransition(.numericText())` rolls the digits it is handed, which
/// jumps straight from the old balance to the new one.
struct BalanceText: View, Animatable {
    var value: Double
    var style: LinearGradient = MoneyStyle.onSurface

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    private static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f
    }()

    /// An empty wallet reads `0`, not `0.00` — the design's own empty state.
    /// Only exactly zero, so the count-up never switches format part-way
    /// through and snaps the digits' width.
    private var text: String {
        value == 0 ? "0" : (Self.formatter.string(from: value as NSNumber) ?? "0.00")
    }

    var body: some View {
        // `H40/ExtraBold` with the design's own gradient — the mark is part of
        // the same run, at the same size, so it takes the same ramp. It used
        // to be Bold, two sizes, and flat white.
        MoneyText(amount: text, markSize: 40, digitSize: 40, style: style)
    }
}
