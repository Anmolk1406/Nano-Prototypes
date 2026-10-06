import SwiftUI

/// The end of the kids onboarding — `Home - Full screen` (1163:23865): the
/// kid's new wallet at the top, then noon's marketplaces, a quest and the
/// arcade, scrolling over a "Shop, Earn & Save" footer that sits still
/// behind the page and is uncovered at the end; the bottom nav floats over it
/// all.
///
/// The wallet is built here, because it shows the skin the kid chose: that
/// skin's card, on its own backdrop dimmed to night. The other sections are
/// the design's art, exported at 3× (with their alpha), with the three
/// buttons drawn live on top.
struct KidHomeView: View {
    /// The confirmed skin's asset number, e.g. 11 for `skin_11` / `bg_11`.
    var skin: Int

    // Section tops in the page, from the frame.
    private static let marketTop: CGFloat = 493
    private static let questTop: CGFloat = 998
    private static let gameTop: CGFloat = 1614
    private static let gameBottom: CGFloat = 2236
    /// Where the footer sits on screen, behind the page.
    private static let footerTop: CGFloat = 422

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Behind the page: the footer, still, uncovered as the page ends.
            Color(hex: 0xF4EEFE)
            Image("home_footer").resizable().frame(width: 375, height: 390)
                .offset(y: Self.footerTop)

            ScrollViewReader { proxy in
            ScrollView(.vertical) {
                ZStack(alignment: .topLeading) {
                    // Scroll anchors, for `-homeScroll quest|game|end`.
                    VStack(spacing: 0) {
                        Color.clear.frame(height: Self.questTop - 60)
                        Color.clear.frame(height: 1).id("quest")
                        Color.clear.frame(height: Self.gameTop - Self.questTop - 1)
                        Color.clear.frame(height: 1).id("game")
                        Color.clear.frame(height: Self.gameBottom + (812 - Self.footerTop) - Self.gameTop - 2)
                        Color.clear.frame(height: 1).id("end")
                    }
                    wallet
                    Image("home_switcher").resizable().frame(width: 375, height: 92).offset(y: 45)
                    Image("home_market").resizable().frame(width: 375, height: 512)
                        .offset(y: Self.marketTop)
                    section("home_quest", top: Self.questTop, cta: "Earn dhm5")
                    section("home_game", top: Self.gameTop, cta: "Play Now")
                }
                // Room after the arcade so it can scroll clear of the footer.
                .frame(width: 375, height: Self.gameBottom + (812 - Self.footerTop), alignment: .topLeading)
            }
            .scrollIndicators(.hidden)
            .frame(width: 375, height: 812)
            .onAppear {
                let a = ProcessInfo.processInfo.arguments
                if let i = a.firstIndex(of: "-homeScroll"), i + 1 < a.count {
                    let id = a[i + 1]
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        proxy.scrollTo(id, anchor: id == "end" ? .bottom : .top)
                    }
                }
            }
            }

            Image("home_nav").resizable().frame(width: 375, height: 144)
                .offset(y: 668)
                .allowsHitTesting(false)
        }
        .frame(width: 375, height: 812, alignment: .topLeading)
        .clipped()
    }

    private func section(_ art: String, top: CGFloat, cta: String) -> some View {
        ZStack(alignment: .topLeading) {
            Image(art).resizable().frame(width: 375, height: 622)
            // `Quest / CTA` and `Game / CTA`: 200 × 52, 30 into a band 508 down.
            KidPillButton(title: cta, size: .large) {}
                .frame(width: 200, height: 52)
                .offset(x: 87.5, y: 538)
        }
        .offset(y: top)
    }

    // MARK: wallet

    private var skinName: String { String(format: "skin_%02d", skin) }
    private var bgName: String { String(format: "bg_%02d", skin) }

    /// `Wallet` (1163:23881): 375 × 577, 24pt bottom corners.
    private var wallet: some View {
        ZStack(alignment: .topLeading) {
            backdrop

            // The chosen skin's card, 272 wide, centred, from y 171.
            Image(skinName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 272, height: 192.15)
                .shadow(color: .black.opacity(0.55), radius: 5, y: 5)
                .position(x: 188, y: 171 + 192.15 / 2)

            // The "EMPTY WALLET" tag, turned −20°, over the card's corner.
            Image("home_empty_tag")
                .resizable()
                .frame(width: 104, height: 51.6)
                .frame(width: 104, height: 37.725)
                .clipped()
                .shadow(color: .black.opacity(0.32), radius: 2, x: -2, y: 7)
                .rotationEffect(.degrees(-20))
                .position(x: 6 + 110.631 / 2, y: 196.43 + 71.02 / 2)

            cactus(width: 82, height: 78.775, centreX: 41, top: 307, flipped: false,
                   shadowX: 92.5, shadowTop: 376.5)
            cactus(width: 52.918, height: 50.837, centreX: 330.46, top: 324, flipped: true,
                   shadowX: 380.5, shadowTop: 368)

            // `Wallet / Copy`, from y 386.
            VStack(spacing: 8) {
                Text("Ask your parents to add money")
                    .font(NoonFont.f(.semibold, 16))
                    .tracking(-0.15)
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(height: 22)
                ParentGradientTitle(text: "Wallet is Ready",
                                    style: ParentSpec.TypeStyle(weight: .bold, size: 32, line: 40, tracking: -0.25),
                                    width: 375, angle: 27.0966, outline: 3.8,
                                    endColor: Color(hex: 0x7924FF), startStop: 0.41842, endStop: 0.77963)
            }
            .frame(width: 375)
            .offset(y: 386)

            KidPillButton(title: "Top up wallet", icon: true, size: .small) {}
                .frame(width: 143, height: 40)
                .offset(x: 117, y: 480)
        }
        .frame(width: 375, height: 577, alignment: .topLeading)
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 24, bottomTrailingRadius: 24, style: .continuous))
        .offset(y: -1)
    }

    /// The skin's own backdrop, dimmed to night and darkened toward the
    /// edges by the design's navy vignette (`Wallet / BG overlay`: transparent
    /// to 61.6% of a 194 × 305 ellipse round (187.5, 271), #03194A at its rim,
    /// overlay blend).
    private var backdrop: some View {
        // Every layer is pinned to the wallet's own 375 × 577 frame. The
        // backdrop image is larger than that (435 × 773 from −30, −64), and
        // as a sized child of the stack it set the stack's size, which slid
        // the navy tint off the image — untinted bands showed down the right
        // and along the foot.
        ZStack(alignment: .topLeading) {
            Color(hex: 0x03194A)
            Image(bgName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 435, height: 772.92)
                .clipped()
                .position(x: -30 + 435 / 2, y: -64 + 772.92 / 2)
            // Night: the design's navy over the skin's own art, so every skin
            // reads as its colours at dusk rather than as a black wash.
            Color(hex: 0x03194A).opacity(0.62)
            EllipticalGradient(stops: [.init(color: Color(hex: 0x03194A).opacity(0), location: 0.61605),
                                       .init(color: Color(hex: 0x03194A), location: 1)],
                               center: .center, startRadiusFraction: 0, endRadiusFraction: 0.5)
                .frame(width: 2 * 193.78, height: 2 * 304.89)
                .position(x: 187.5, y: 0.59 + 271.05)
                .blendMode(.overlay)
        }
        .frame(width: 375, height: 577)
        .clipped()
    }

    private func cactus(width: CGFloat, height: CGFloat, centreX: CGFloat, top: CGFloat,
                        flipped: Bool, shadowX: CGFloat, shadowTop: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            // Its soft cast shadow on the floor (the design's blurred path).
            Ellipse().fill(.black.opacity(0.4))
                .frame(width: 100, height: 8)
                .blur(radius: 6)
                .position(x: shadowX, y: shadowTop + 17)
            Image("home_cactus")
                .resizable()
                .frame(width: width, height: height * 1.0409)
                .frame(width: width, height: height, alignment: .top)
                .clipped()
                .scaleEffect(x: flipped ? -1 : 1)
                .position(x: centreX, y: top + height / 2)
        }
        .frame(width: 375, height: 577, alignment: .topLeading)
        .allowsHitTesting(false)
    }
}

/// `Button / Neutral` in this frame: a #212121 pill with a 3pt white rim and
/// two inner shadows (black 8pt up, #A9A9A9 4pt down, both blur 5). Small is
/// 40 tall, A14 SemiBold with a plus; Large is 52 tall, A16 Bold. It presses
/// like the app's buttons: the shared scale, spring and depth, and their
/// haptics.
struct KidPillButton: View {
    enum Size { case small, large }
    let title: String
    var icon = false
    var size: Size = .large
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if icon {
                    Image("ic_plus").resizable().frame(width: 20, height: 20)
                }
                Text(title)
                    .font(NoonFont.f(size == .small ? .semibold : .bold, size == .small ? 14 : 16))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                Capsule().fill(Color(hex: 0x212121)
                    .shadow(.inner(color: .black, radius: 2.5, y: -8))
                    .shadow(.inner(color: Color(hex: 0xA9A9A9), radius: 2.5, y: 4)))
            }
            .overlay(Capsule().strokeBorder(.white, lineWidth: 3))
            .contentShape(Capsule())
        }
        .buttonStyle(KidPillPress())
    }
}

private struct KidPillPress: ButtonStyle {
    @ObservedObject private var shadow = DomeShadow.shared

    func makeBody(configuration: Configuration) -> some View {
        let down = configuration.isPressed
        return configuration.label
            .offset(y: down ? shadow.pressDepth : 0)
            .scaleEffect(down ? shadow.pressScale : 1)
            .brightness(down ? -0.04 : 0)
            .animation(shadow.pressSpring, value: down)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed { PressHaptics.flow.pressDown() } else { PressHaptics.flow.pressUp() }
            }
    }
}
