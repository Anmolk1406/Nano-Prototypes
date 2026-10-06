import SwiftUI

/// The parent's side: adding a kid, Figma section `Flow for claude`
/// (1015:44810) — eleven frames, six pages.
///
/// | Page | Frames | What happens |
/// |---|---|---|
/// | child | 1, 2 | name, birthday, gender → *Continue* plays the celebration (2) over it |
/// | email | 3, 4 | the kid's email → *Continue* raises the confirm sheet (4) |
/// | intro | 5 | "Introducing Kiaan's nano wallet" — a beat, then on |
/// | rules | 6, 7, 8 | auto- or manual-approve; manual opens the limit options (7), the amount field brings up the number pad (8) |
/// | address | 9, 10 | pick an address → *Continue* plays Let's Go (10) over it |
/// | invite | 11 | the invite QR screen the app already has |
///
/// Frames 2, 4 and 10 are overlays on their page, not pages of their own, and
/// 7 and 8 are states of 6 — so only a real change of page moves.
///
/// **Moving between pages is the onboarding flow's push**: the new page comes
/// in from the trailing edge as the old one leaves by the leading edge, both
/// fading, the other way round going back — on the flow's spring, tension 320
/// and friction 28. The progress bar is held still above it: the bar is the
/// one element every page shares, so it stays put and fills while the pages
/// slide under it.
struct ParentFlow: View {
    @ObservedObject var motion: MotionEngine
    @ObservedObject var tuning: Tuning
    @StateObject private var model = ParentModel()

    var body: some View {
        let page = model.stack.last ?? .child
        ZStack {
            Color.white
            pageView(page)
                .id(page)
                .transition(push)
                // Explicit, so the page being removed keeps its place in the
                // stack and runs its transition rather than dropping out.
                .zIndex(1)
            ParentStage(background: false) {
                ParentProgressBar(progress: page.progress, onLight: page == .intro)
            }
            .allowsHitTesting(false)
            // Gone on the invite — the flow is complete there — and handed
            // to the page while it has an overlay up (see `ParentModel.overlay`).
            .opacity(page == .invite || model.overlay ? 0 : 1)
            // Above both pages: the arriving one is raised to 1 to fade in
            // over the one being left, and would otherwise cover the bar.
            .zIndex(2)
        }
        // Full-bleed from the root, keyboard region included — the pages
        // move their own action bars onto the keyboard.
        .ignoresSafeArea()
        .environmentObject(model)
        .onAppear {
            // `-parentWalk` pushes to the next page and back again, so the
            // transition can be recorded without touch input.
            guard ProcessInfo.processInfo.arguments.contains("-parentWalk") else { return }
            let next = ParentPage.allCases[min(ParentPage.allCases.count - 1,
                                               (ParentPage.allCases.firstIndex(of: page) ?? 0) + 1)]
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { model.push(next) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { model.back() }
        }
    }

    /// The onboarding flow's push, pointed by the direction of travel.
    private var push: AnyTransition {
        let inEdge: Edge = model.forward ? .trailing : .leading
        let outEdge: Edge = model.forward ? .leading : .trailing
        return .asymmetric(
            insertion: .move(edge: inEdge).combined(with: .opacity),
            removal: .move(edge: outEdge).combined(with: .opacity))
    }

    @ViewBuilder
    private func pageView(_ page: ParentPage) -> some View {
        switch page {
        case .child:   ParentChildPage()
        case .email:   ParentEmailPage()
        case .intro:   ParentIntroPage()
        case .rules:   ParentRulesPage()
        case .address: ParentAddressPage()
        case .invite:  ParentInvitePage(motion: motion, tuning: tuning)
        }
    }
}

enum ParentPage: Hashable, CaseIterable {
    case child, email, intro, rules, address, invite

    /// Where the header's progress bar stands on this page — the design's
    /// own fills: 13.3 of 72 on the first page.
    var progress: CGFloat {
        switch self {
        case .child: 13.336 / 72
        case .email: 2.0 / 6
        case .intro: 3.0 / 6
        case .rules: 4.0 / 6
        case .address: 5.0 / 6
        case .invite: 1
        }
    }
}

/// Everything the pages share: where the flow is, and what has been entered.
@MainActor
final class ParentModel: ObservableObject {
    /// Every page up to the launch page, so Back works from wherever it opens.
    @Published var stack: [ParentPage] =
        Array(ParentPage.allCases.prefix(through: ParentPage.allCases.firstIndex(of: ParentModel.launchPage)!))

    // The design's own sample data.
    @Published var firstName = "Kiaan"
    @Published var lastName = "Khalid"
    @Published var birthday = DateComponents(calendar: .current, year: 2016, month: 12, day: 12).date ?? .now
    @Published var gender: Gender = .boy
    @Published var email = "kk@noon.com"
    /// `-parentManual` opens Set Rules on manual approval — frame 7.
    @Published var approval: Approval = ProcessInfo.processInfo.arguments.contains("-parentManual") ? .manual : .auto
    @Published var manualRule: ManualRule = .aboveLimit
    @Published var limit = "120"
    /// The saved addresses ticked — any number of them.
    @Published var addresses: Set<Int> = [0]

    enum Gender { case boy, girl }
    enum Approval { case auto, manual }
    enum ManualRule { case aboveLimit, everyOrder }

    /// Which way the last move went, for the push's edges.
    @Published private(set) var forward = true

    /// A page has an overlay up — the confirm sheet, the celebration, Let's
    /// Go — which has to cover the progress bar.
    ///
    /// The bar sits above the pages so it can stay still while they slide,
    /// which also put it above their overlays. While one is up the flow's bar
    /// hides and the page draws the same bar, at the same place, under its
    /// overlay — `ParentOverlayBar`. The swap is instant both ways, so it is
    /// never seen; a move clears it.
    @Published private(set) var overlay = false

    /// A plain assignment: the bar has no animation of its own, so outside a
    /// `withAnimation` the swap is instant anyway. A transaction with
    /// `disablesAnimations` was what used to be here, and set in the same
    /// update as a page move it froze the push — both pages stuck at the
    /// start of their transition, the new one off-screen.
    func setOverlay(_ on: Bool) { overlay = on }

    func push(_ page: ParentPage) { go(forward: true) { $0.append(page) } }

    /// Back a page — past the wallet intro, which is a beat between pages
    /// rather than a page to return to: it moves itself on, so Back from Set
    /// Rules landing on it would send the flow straight forward again.
    func back() {
        guard stack.count > 1 else { return }
        go(forward: false) { s in
            _ = s.popLast()
            while s.count > 1, s.last == .intro { _ = s.popLast() }
        }
    }

    /// The whole flow, from the top — the invite screen's close.
    func restart() { go(forward: false) { $0 = [.child] } }

    /// The direction lands a frame ahead of the page. A removal transition is
    /// read off the leaving page as it was last drawn, so a direction set in
    /// the same update as the move would send the old page out by the edge
    /// the previous move used.
    private func go(forward: Bool, _ change: @escaping (inout [ParentPage]) -> Void) {
        self.forward = forward
        var next = stack
        change(&next)
        let target = next
        DispatchQueue.main.async {
            let move = { withAnimation(ParentSpec.page) { self.stack = target } }
            // Nothing in the leaving page may change in the same update as
            // the move: a change inside a view that has just started its
            // removal transition froze the push, both pages stuck at their
            // start positions. So with an overlay up, the bar is handed back
            // to the flow a frame *before* the move —
            guard self.overlay else { move(); return }
            if target.last == .invite {
                // — except onto the invite, which shows no bar: there the
                // leaving page keeps its own until it has slid away, and the
                // flow's never comes back over Let's Go.
                move()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { self.overlay = false }
            } else {
                self.overlay = false
                DispatchQueue.main.async { move() }
            }
        }
    }

    /// `-parentPage rules` opens on a page, for screenshots.
    static var launchPage: ParentPage {
        let a = ProcessInfo.processInfo.arguments
        guard let i = a.firstIndex(of: "-parentPage"), i + 1 < a.count else { return .child }
        return ParentPage.allCases.first { "\($0)" == a[i + 1] } ?? .child
    }

    var age: Int {
        Calendar.current.dateComponents([.year], from: birthday, to: .now).year ?? 0
    }
}
