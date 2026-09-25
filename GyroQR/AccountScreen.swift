import SwiftUI

/// The account page, Figma `Account` (978:15007) — one load-in, then still.
///
/// The page opens with the header **collapsed** to its chrome, 101pt of purple
/// with the two icon buttons on it and the body sitting directly underneath.
/// It then expands to its full 379 and pushes the body down, and only once it
/// has settled does anything appear inside it:
///
/// 1. the avatar disc **pops** — scales up past its size and settles,
/// 2. the three interest stickers arrive on it, almost together,
/// 3. the ball, the star and the bolt **travel in** from the nearest edge.
///
/// The name and the email fade up alongside. Doing it in that order is what
/// makes the header read as *making room* for a profile rather than as a
/// panel that happens to be resizing while things fly about inside it.
///
/// The reason the header is in pieces at all is the backdrop: each of those
/// seven layers has to come out from *behind* something, and a layer cut to a
/// bounding box carries a slab of purple with it and draws its own edge the
/// moment it moves. `Tools/build_account_layers.py` cuts them to their own
/// alpha and patches the backdrop where they sit.
struct AccountScreen: View {
    /// Bumped by the controls sheet's Replay, so the entrance plays again.
    var replay = 0

    /// The header has opened. Drives the layout; nothing else waits on it.
    @State private var expanded = false
    /// The header's contents have been let in.
    @State private var loaded = false
    @State private var pending: DispatchWorkItem?

    var body: some View {
        GeometryReader { geo in
            let scale = max(geo.size.width / AccountSpec.size.width,
                            geo.size.height / AccountSpec.size.height)
            stage
                .frame(width: AccountSpec.size.width, height: AccountSpec.size.height)
                .scaleEffect(scale, anchor: .center)
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
        }
        .ignoresSafeArea()
        .onAppear { enter() }
        .onChange(of: replay) { _, _ in
            pending?.cancel()
            expanded = false
            loaded = false
            enter()
        }
    }

    /// `-accountEntry` holds the page collapsed and empty. The whole thing is
    /// over in under a second, so this is the only way to look at where it
    /// starts from.
    private static let held = ProcessInfo.processInfo.arguments.contains("-accountEntry")

    /// The header opens a frame after the page appears — one runloop's grace,
    /// so the animation has a previous value to interpolate from rather than
    /// starting at whatever the first layout pass settled on — and its
    /// contents follow once it has.
    private func enter() {
        guard !loaded, !Self.held else { return }
        DispatchQueue.main.async {
            withAnimation(AccountSpec.expand) { expanded = true }
        }
        let fill = DispatchWorkItem { loaded = true }
        pending = fill
        DispatchQueue.main.asyncAfter(deadline: .now() + AccountSpec.expandFor,
                                      execute: fill)
    }

    /// True once the header's contents have been let in.
    private var shown: Bool { loaded && !Self.held }

    /// Where the header currently ends, and therefore where the body starts.
    private var headerBottom: CGFloat {
        expanded && !Self.held ? AccountSpec.headerBottom : AccountSpec.headerCollapsed
    }

    private var stage: some View {
        ZStack(alignment: .topLeading) {
            AccountSpec.pageColour

            // The header. Its art is a fixed-size image anchored at the top
            // and clipped to the current height, so expanding *reveals* the
            // backdrop rather than stretching it — the rays stay put, which
            // is the whole reason this is a clip and not a resize.
            ZStack(alignment: .topLeading) {
                image("acct_bg", AccountSpec.backdrop)
                avatar
                stickers
                props
                type
                chrome
            }
            .frame(width: AccountSpec.size.width, height: headerBottom,
                   alignment: .topLeading)
            .clipped()

            pageBody
            image("wallet_nav", AccountSpec.nav)
        }
        .frame(width: AccountSpec.size.width, height: AccountSpec.size.height,
               alignment: .topLeading)
    }

    /// Everything below the header, pushed down by it.
    private var pageBody: some View {
        Image("acct_body")
            .resizable()
            .frame(width: AccountSpec.bodyWidth, height: AccountSpec.bodyHeight)
            .offset(y: headerBottom)
    }

    private func image(_ name: String, _ box: CGRect) -> some View {
        Image(name)
            .resizable()
            .frame(width: box.width, height: box.height)
            .offset(x: box.minX, y: box.minY)
    }

    // MARK: the header's pieces

    /// The pop. Scale about the disc's own centre — `scaleEffect` on a view
    /// positioned by `offset` scales about the view's centre, which is the
    /// disc's centre, so no anchor is needed.
    private var avatar: some View {
        image("acct_avatar", AccountSpec.avatar)
            .scaleEffect(shown ? 1 : AccountSpec.avatarFrom)
            .opacity(shown ? 1 : 0)
            .animation(AccountSpec.pop.delay(AccountSpec.delay.avatar), value: shown)
    }

    private var stickers: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(AccountSpec.stickers.enumerated()), id: \.offset) { i, s in
                image(s.image, s.frame)
                    .scaleEffect(shown ? 1 : AccountSpec.stickerFrom)
                    .opacity(shown ? 1 : 0)
                    .animation(AccountSpec.pop.delay(AccountSpec.delay.stickers[i]),
                               value: shown)
            }
        }
        .frame(width: AccountSpec.size.width, height: AccountSpec.size.height,
               alignment: .topLeading)
    }

    /// The three props, each travelling in from its own nearest edge.
    private var props: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(AccountSpec.props.enumerated()), id: \.offset) { i, p in
                image(p.image, p.frame)
                    .offset(x: shown ? 0 : p.from.width,
                            y: shown ? 0 : p.from.height)
                    .opacity(shown ? 1 : 0)
                    .animation(AccountSpec.spring.delay(AccountSpec.delay.props[i]),
                               value: shown)
            }
        }
        .frame(width: AccountSpec.size.width, height: AccountSpec.size.height,
               alignment: .topLeading)
    }

    // MARK: type and chrome

    private var type: some View {
        ZStack(alignment: .topLeading) {
            Text(AccountSpec.name)
                .font(NoonFont.f(.bold, 24))
                .tracking(-0.25)
                .foregroundStyle(.white)
                .frame(width: AccountSpec.nameBox.width, alignment: .center)
                .offset(x: AccountSpec.nameBox.minX, y: AccountSpec.nameBox.minY)
                .modifier(FadeUp(shown: shown, delay: AccountSpec.delay.name))

            Text(AccountSpec.email)
                .font(NoonFont.f(.regular, 14))
                .tracking(-0.1)
                .foregroundStyle(.white.opacity(0.8))
                .frame(width: AccountSpec.emailBox.width, alignment: .center)
                .offset(x: AccountSpec.emailBox.minX, y: AccountSpec.emailBox.minY)
                .modifier(FadeUp(shown: shown, delay: AccountSpec.delay.email))
        }
        .frame(width: AccountSpec.size.width, height: AccountSpec.size.height,
               alignment: .topLeading)
    }

    /// The two icon buttons. Not part of the sequence: they belong to the
    /// collapsed header, which is where the page starts, so they are on screen
    /// before anything expands and stay put while it does.
    private var chrome: some View {
        ZStack(alignment: .topLeading) {
            iconButton("qrcode.viewfinder")
                .offset(x: AccountSpec.buttonLeftX, y: AccountSpec.buttonY)
            iconButton("pencil")
                .offset(x: AccountSpec.buttonRightX, y: AccountSpec.buttonY)
        }
        .frame(width: AccountSpec.size.width, height: AccountSpec.size.height,
               alignment: .topLeading)
    }

    private func iconButton(_ glyph: String) -> some View {
        ZStack {
            Circle().strokeBorder(.white.opacity(0.9), lineWidth: 1.4)
            Image(systemName: glyph)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(.white)
        }
        .frame(width: AccountSpec.buttonSize, height: AccountSpec.buttonSize)
    }
}

/// Fade up a few points, on the page's own spring.
private struct FadeUp: ViewModifier {
    let shown: Bool
    let delay: Double
    var rise: CGFloat = 10

    func body(content: Content) -> some View {
        content
            .offset(y: shown ? 0 : rise)
            .animation(AccountSpec.spring.delay(delay), value: shown)
            .opacity(shown ? 1 : 0)
            // Shorter than the spring, so the element is solid before it stops
            // moving — the same split the wallet's entrance uses.
            .animation(.easeOut(duration: 0.2).delay(delay), value: shown)
    }
}
