import SwiftUI

/// The blurred light that rises out of the bottom of the screen while a top-up
/// request is in flight, in the colours of the user's own card skin.
///
/// Four flat-filled ellipses under **one** large blur, composited
/// `plusLighter`. Three things about that are deliberate:
///
/// * The lobes overlap on purpose. Purple over amber in an additive blend is
///   most of the cream the reference has where the colours meet, so the middle
///   of the cluster is not painted — it falls out of the blend. What the blend
///   does *not* give is the hot line along the very bottom edge, which is
///   whiter and tighter than any overlap of two saturated colours: that one is
///   an explicit white lobe, sunk far enough below the screen that only its
///   own top shows.
/// * The lobes are pushed apart rather than dimmed. `SkinPalette` hands back
///   colours forced to full brightness, so a violet arrives as roughly
///   (1, 0.4, 1) — two of those stacked on the same spot clip every channel,
///   and four piled at the bottom centre turned the whole lower third into a
///   flat white slab with the card's colour showing only as a fringe at the
///   top. Dropping every opacity under a half fixed the slab and cost all the
///   saturation with it: the bloom went to a grey wash. What the reference
///   actually has is each colour holding its own part of the width at full
///   strength, meeting in narrow seams — so the lobes are bright, narrower,
///   and spread across the span, and the white is confined to where they
///   cross.
/// * One blur over the group, not one per lobe. Per-lobe blurs keep their own
///   edges and the cluster reads as four blobs; a single pass over the stack is
///   what melts them into one body of light.
/// * Nothing is masked. A `.mask` around a `plusLighter` group isolates the
///   group from the page behind it and the blend stops working — the same trap
///   the pocket glow hit. The cluster is feathered by its own shapes and by
///   hanging below the screen edge, so the bottom tail is clipped rather than
///   fading out in view.
///
/// Rise, sweep and fade are all the caller's job: this view is only the look,
/// which keeps the transforms in one place where their curves can differ.
struct AuroraBloom: View {
    /// Read off the card's artwork by `SkinPalette` — two or three colours,
    /// and tints of one hue for the cards that have no hue of their own.
    let colors: [Color]
    var blur: Double = 38
    /// Multiplies the drift speed. 0 freezes the cluster, for stills.
    var drift: Double = 1

    private struct Lobe {
        /// Centre and size as fractions of the cluster's box.
        let x, y, w, h: CGFloat
        let colour: Int
        let opacity: Double
        let speed: Double
        let phase: Double
        /// Points of horizontal and vertical wander, and how much the lobe
        /// swells, at `drift` 1.
        let sway: CGFloat
        let bob: CGFloat
        let swell: Double
    }

    /// Bottom-weighted and off-centre, which is what the reference does: the
    /// big lobe sits right of centre, a second colour banks up the left edge,
    /// and a low wide one lies along the bottom so the contact band stays the
    /// brightest part of the cluster.
    private static let lobes: [Lobe] = [
        // The apex — one tall lobe near the middle, which is what gives the
        // cluster a single peak instead of a ridge. It carries the most swell
        // and the least sway: the peak rising and falling is the movement the
        // eye actually reads, and sliding it sideways only wobbles the whole
        // dome.
        Lobe(x: 0.54, y: 0.62, w: 0.62, h: 0.60, colour: 1, opacity: 0.85,
             speed: 0.62, phase: 0.0, sway: 18, bob: 30, swell: 0.13),
        // Shoulders. Lower and dimmer than the apex on purpose: at the same
        // brightness out near the edges they stopped being shoulders and became
        // two separate bright corners with a dip between them. These get the
        // wide sway — they are what makes the colour travel across the width.
        Lobe(x: 0.22, y: 0.84, w: 0.56, h: 0.40, colour: 0, opacity: 0.80,
             speed: 0.85, phase: 1.9, sway: 40, bob: 20, swell: 0.16),
        Lobe(x: 0.80, y: 0.88, w: 0.50, h: 0.34, colour: 2, opacity: 0.62,
             speed: 0.71, phase: 3.4, sway: 44, bob: 22, swell: 0.18),
        // The base, carrying colour the full width under both shoulders.
        Lobe(x: 0.48, y: 1.00, w: 0.98, h: 0.20, colour: 1, opacity: 0.45,
             speed: 0.53, phase: 5.1, sway: 26, bob: 12, swell: 0.10),
        // The contact band. Sits mostly below the screen edge, so what shows
        // is its own top — a narrow hot line rather than a white field. Barely
        // moves: this one is the horizon the rest of the cluster sits on, and
        // drifting it makes the bottom edge of the screen look loose.
        Lobe(x: 0.50, y: 1.08, w: 0.90, h: 0.15, colour: white, opacity: 0.55,
             speed: 0.44, phase: 2.6, sway: 14, bob: 7, swell: 0.07),
    ]

    /// `colour` sentinel for the contact band, which is not one of the card's.
    private static let white = -1

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                cluster(at: timeline.date.timeIntervalSinceReferenceDate * drift,
                        in: geo.size)
            }
        }
        .allowsHitTesting(false)
    }

    private func colour(_ i: Int) -> Color {
        guard i != Self.white, !colors.isEmpty else { return .white }
        return colors[i % colors.count]
    }

    private func cluster(at t: Double, in size: CGSize) -> some View {
        ZStack {
            ForEach(Self.lobes.indices, id: \.self) { i in
                let l = Self.lobes[i]
                // Three incommensurate periods per lobe — wander, swell, and
                // the vertical bob at 0.8 of the wander — so the cluster never
                // returns to the same shape inside the couple of seconds it is
                // on screen. One shared period read as a pulse.
                let wander = sin(t * l.speed + l.phase)
                let rise = cos(t * l.speed * 0.8 + l.phase)
                let breathe = sin(t * l.speed * 1.37 + l.phase * 1.6)
                Ellipse()
                    .fill(colour(l.colour))
                    .frame(width: size.width * l.w, height: size.height * l.h)
                    .scaleEffect(1 + l.swell * breathe)
                    .opacity(l.opacity)
                    .offset(x: size.width * (l.x - 0.5) + CGFloat(wander) * l.sway,
                            y: size.height * (l.y - 0.5) + CGFloat(rise) * l.bob)
            }
        }
        .frame(width: size.width, height: size.height)
        .blur(radius: blur)
        .blendMode(.plusLighter)
    }

    /// How far below the cluster box's own top the lowest lobe reaches, as a
    /// fraction of the box height — its centre plus half its height, plus the
    /// swell and the bob it can add.
    ///
    /// The sweep needs this: to carry the cluster fully off the top of the
    /// screen the lift has to clear the *lowest* thing in it, and hard-coding
    /// that number meant every change to the lobes left a tail fading out
    /// mid-screen.
    static let lowestExtent: CGFloat = {
        lobes.map { l in
            l.y + l.h / 2 * (1 + CGFloat(l.swell))
        }.max() ?? 1.2
    }()

    /// The largest bob any lobe adds, in points — the rest of the sweep's
    /// clearance calculation.
    static let lowestBob: CGFloat = lobes.map(\.bob).max() ?? 0
}
