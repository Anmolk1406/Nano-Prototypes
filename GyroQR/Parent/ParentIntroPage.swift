import SwiftUI

/// Frame 5 (1015:45575), `Transitional Screen`: "Introducing Kiaan's nano
/// wallet". A beat between the account and its rules — it plays its
/// entrance, holds a moment and moves on by itself, or on a tap.
///
/// The entrance, as the email sheet fades away behind it:
///
/// 1. **the stars settle** — the backdrop (its nested stars and props are
///    one image) swells in from 112% and a few degrees turned, about the
///    stars' centre, onto its place;
/// 2. **the wallet swings in** from above the screen on a spring, tipped
///    back 24° about its horizontal axis and righting itself as it lands —
///    a small overshoot past flat is the swing;
/// 3. **the copy** fades up under it.
///
/// The empty 212pt `Savings container` the design marks *Pending* is left out.
struct ParentIntroPage: View {
    @EnvironmentObject private var model: ParentModel
    @State private var stars = false
    @State private var card = false
    @State private var copy = false
    @State private var advanced = false

    var body: some View {
        ParentStage {
            // `image 1583514861`: 375 wide, drawn 812 tall.
            Image("parent_intro_bg")
                .resizable()
                .frame(width: 375, height: 812)
                .scaleEffect(stars ? 1 : 1.12, anchor: UnitPoint(x: 0.5, y: 0.3))
                .rotationEffect(.degrees(stars ? 0 : -6), anchor: UnitPoint(x: 0.5, y: 0.3))
                .opacity(stars ? 1 : 0)

            // Ellipse 24671: white to 51.6% of its radius, then fading out.
            Circle()
                .fill(RadialGradient(stops: [
                    .init(color: .white, location: 0),
                    .init(color: .white, location: 0.516102),
                    .init(color: .white.opacity(0), location: 1),
                ], center: .center, startRadius: 0, endRadius: 277.482))
                .frame(width: 554.964, height: 554.964)
                .offset(x: -84.6025, y: 220.2805)

            // `object-cover` in a 337.1 × 224.7 box: the art is taller than
            // the box, so it fills the width and is cropped top and bottom.
            Image("parent_intro_nano")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 337.097, height: 224.731)
                .clipped()
                .rotation3DEffect(.degrees(card ? 0 : 24), axis: (x: 1, y: 0, z: 0),
                                  anchor: .top, perspective: 0.45)
                .offset(x: 187.5 + 3 - 337.097 / 2, y: card ? 201.816 : -260)

            VStack(spacing: 27) {
                ParentLines(lines: ["Introducing ", "\(model.firstName)'s nano wallet"],
                            style: .init(weight: .bold, size: 28, line: 36, tracking: -0.25))
                ParentLines(lines: ["You can add \(model.gender == .girl ? "her" : "his") allowance safely ",
                                    "to this wallet."],
                            style: .init(weight: .medium, size: 16, line: 22, tracking: -0.15),
                            colour: ParentSpec.C.textTertiary)
            }
            .frame(width: 351)
            .opacity(copy ? 1 : 0)
            .offset(x: 12, y: 469 + (copy ? 0 : 12))
        }
        .contentShape(Rectangle())
        .onTapGesture { advance(auto: false) }
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) { stars = true }
            // A lively spring: the card overshoots flat by a few degrees and
            // swings back — the "swing" of swinging in.
            withAnimation(.spring(response: 0.62, dampingFraction: 0.62).delay(0.08)) { card = true }
            withAnimation(.easeOut(duration: 0.35).delay(0.35)) { copy = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + ParentIntroPage.holdFor) { advance(auto: true) }
        }
    }

    /// From arrival to moving on: the entrance takes ~0.8s, then a short read.
    static let holdFor: Double = 1.7

    /// The timer fires once; a tap — including after coming Back here —
    /// always moves on.
    private func advance(auto: Bool) {
        // `-parentHold` keeps the page up, for screenshots.
        if auto && ProcessInfo.processInfo.arguments.contains("-parentHold") { return }
        if auto && advanced { return }
        guard model.stack.last == .intro else { return }
        advanced = true
        model.push(.rules)
    }
}
