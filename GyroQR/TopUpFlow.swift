import SwiftUI

/// The request-top-up flow: an empty wallet → the request → the wallet with
/// something in it.
///
/// The round trip is the point, and starting from empty is what gives it one.
/// The wallet opens on `Your wallet is empty` with no balance and no history,
/// so the request has something to change: the page rearranges into its filled
/// layout, the balance counts up from zero, the receipt unfolds and the
/// transaction list arrives. Opening on a wallet that already had 10.56 and
/// eight transactions in it made the return a smaller event than the animation
/// leading into it.
///
/// The balance is added the instant the request lands, which is not what a real
/// top-up request does — someone else has to pay it. It is the prototype's
/// assumption, made so the return has something to show.
struct TopUpFlow: View {
    @ObservedObject var tune: TopUpTuning

    private enum Step { case wallet, request }

    @State private var step: Step = .wallet
    @State private var balance = WalletSpec.openingBalance
    /// The wallet has history. False until the first request lands.
    @State private var filled = false
    @State private var receipt = false
    /// Set when the controls sheet asks for a replay, so the request screen
    /// runs itself instead of waiting for a tap.
    @State private var autorun = false
    @State private var pending: DispatchWorkItem?

    var body: some View {
        ZStack {
            WalletScreen(skin: tune.skin, balance: balance,
                         filled: filled, receipt: receipt,
                         onRequest: { open() }, replay: tune.replay)

            if step == .request {
                TopUpScreen(tune: tune, autorun: autorun,
                            onBack: { close() },
                            onDone: { land($0) })
                    // In, a push from the right — the screen has a back
                    // chevron, so it is a push and not a modal. Out, a plain
                    // fade: the confirmation has already taken the screen to
                    // black, and sliding that black slab off would undo the
                    // one thing the animation just established.
                    .transition(.asymmetric(insertion: .move(edge: .trailing),
                                            removal: .opacity))
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.42), value: step)
        .onChange(of: tune.replay) { _, _ in replay() }
        .onAppear {
            // `-topUpAuto` runs the round trip hands-free, for recordings.
            // Long enough after launch for the wallet's own entrance to play.
            if ProcessInfo.processInfo.arguments.contains("-topUpAuto") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { replay() }
            }
            // `-topUpOpen` opens straight on the request screen, so a still
            // of it — or of a beat of its animation, with `-topUpPhase` —
            // does not need the wallet driven first.
            if ProcessInfo.processInfo.arguments.contains("-topUpOpen") {
                step = .request
            }
            // `-walletFilled` opens on the settled page, for stills.
            if ProcessInfo.processInfo.arguments.contains("-walletFilled") {
                balance = 210.56
                filled = true
            }
        }
    }

    // MARK: transitions

    private func open() {
        autorun = false
        // The receipt goes with it, so that coming back always *plays* the
        // card in rather than finding it already there on a second run.
        withAnimation(.easeOut(duration: 0.28)) { receipt = false }
        step = .request
    }

    private func close() {
        autorun = false
        step = .wallet
    }

    /// The request landed. The request screen fades off, and the wallet's
    /// results arrive a beat later — late enough that the rearrangement starts
    /// on a page the eye has already found.
    ///
    /// Two waves, not one. The page changing shape is a big move and the
    /// balance counting is a small precise one; running them on the same curve
    /// buried the count inside the rearrangement. The layout goes first, the
    /// receipt lands on top of it, and the count runs across both.
    private func land(_ amount: Double) {
        pending?.cancel()
        step = .wallet
        autorun = false
        let show = DispatchWorkItem {
            Haptics.shared.success()
            withAnimation(.spring(response: 0.62, dampingFraction: 0.86)) { filled = true }
            withAnimation(.easeOut(duration: 1.05)) {
                balance = WalletSpec.openingBalance + amount
            }
            let card = DispatchWorkItem {
                withAnimation(.spring(response: 0.52, dampingFraction: 0.76)) { receipt = true }
            }
            pending = card
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.26, execute: card)
        }
        pending = show
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.34, execute: show)
    }

    /// Replay from the controls sheet: back to the opening state, then run the
    /// whole thing hands-free.
    private func replay() {
        pending?.cancel()
        balance = WalletSpec.openingBalance
        filled = false
        receipt = false
        step = .wallet
        autorun = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            if autorun { step = .request }
        }
    }
}
