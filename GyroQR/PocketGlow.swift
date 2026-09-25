import SwiftUI

/// The lit mouth of the wallet pocket, in the manner of Siri's screen border.
///
/// The glow tracks the confirm pull: nothing at rest, a faint line as the sheet
/// starts to rise, and a thick travelling band by the time the card is about to
/// drop in. It goes out again on commit — the light is the *anticipation*, so
/// leaving it burning under a settled card would be reading the wrong beat.
///
/// Colours come from the card being confirmed (`SkinPalette`), not from a fixed
/// set, so the pocket lights up in the skin you are choosing.
///
/// `Animatable`, which is the whole reason a retracted gesture now takes the
/// light back with it. Almost nothing here is an animatable modifier — the
/// layer widths are `StrokeStyle.lineWidth`s inside masks, which SwiftUI cannot
/// interpolate — so under an ordinary transaction the parent's body ran once,
/// this view snapped to its final numbers, and the *old* image was left to fade
/// out on the default opacity transition: a full-brightness glow sitting on the
/// page for the length of the spring while the sheet slid away underneath it.
/// Declaring the drivers as `animatableData` makes SwiftUI re-evaluate the body
/// on every frame of that spring instead, so the band thins and dims in step
/// with the sheet it belongs to.
struct PocketGlow: View, Animatable {
    /// Two or three colours from the card art.
    let colors: [Color]
    /// 0…1 — the confirm pull.
    var intensity: Double
    /// Width of the card currently entering the mouth, in this view's points.
    var span: CGFloat
    /// The card's bottom edge, in this view's points. Only the stretch of
    /// mouth at or above it has been touched yet.
    var front: CGFloat
    /// Seconds for the band to travel one full cycle.
    var period: Double = 2.6
    /// Scales every layer's thickness together.
    var thickness: Double = 1

    var animatableData: AnimatablePair<Double, AnimatablePair<CGFloat, CGFloat>> {
        get { AnimatablePair(intensity, AnimatablePair(span, front)) }
        set {
            intensity = newValue.first
            span = newValue.second.first
            front = newValue.second.second
        }
    }

    var body: some View {
        // Nothing mounted at rest: the band runs off a display-linked timeline
        // and there is no reason to pay for it while the screen is idle.
        //
        // The opacities hold at full for almost all of the contact ramp — a
        // glow that faded in across the whole pull read as the pocket warming
        // up on its own rather than as the card lighting it — but the first
        // `mouthFadeIn` of it is a fade rather than a step. Ramping over the
        // whole pull and snapping on at contact are both wrong; this is the
        // narrow version of the former.
        if intensity > 0.002 {
            GeometryReader { geo in
                TimelineView(.animation) { context in
                    let t = context.date.timeIntervalSinceReferenceDate
                    let phase = (t / period).truncatingRemainder(dividingBy: 1)
                    // A slow breath on top of the pull, so a held gesture keeps
                    // moving instead of freezing at a fixed width.
                    let breath = 1 + 0.10 * sin(t * 1.7)
                    glow(phase: phase, breath: breath, size: geo.size)
                }
            }
        }
    }

    private func glow(phase: Double, breath: Double, size: CGSize) -> some View {
        let i = min(1, max(0, intensity))
        // Thickness still grows with the card's engagement — that is the
        // original brief — but it starts at 45% rather than nothing, because
        // the opacities below no longer fade in and a hairline at full
        // brightness is not what "lit on contact" should look like.
        let ramp = 0.45 + 0.55 * i * i
        // Just the onset. Full brightness for the rest of the engagement, and
        // it runs backwards on an aborted pull, so the light goes down with the
        // sheet instead of being cut.
        let fade = min(1, i / SkinSelectSpec.mouthFadeIn)
        let k = thickness * breath
        return ZStack {
            // Outer bloom — the part that spills onto the page. Tightened
            // twice now. At a 54pt stroke under a 33pt blur it had stopped
            // being an outline and become coloured fog over the bottom third
            // of the screen. These numbers are roughly half of what replaced
            // that, because the layer is clipped to the sheet: only the inner
            // half of every stroke survives, so the same widths put a soft
            // blob 50pt deep across the card sitting in the mouth instead of
            // a lit edge behind it.
            band(phase: phase, size: size)
                .mask(mouthMask(width: (5 + 14 * ramp) * k, size: size))
                .blur(radius: (5 + 9 * ramp) * k)
                // Held well down. Clipped to the sheet, this layer's whole
                // reach is *inward*, and at the opacity it carried when it
                // also had somewhere outside to spill it washed ~46pt of the
                // card sitting in the mouth. The mid and the core carry the
                // definition; this one is only the falloff behind them.
                .opacity(0.40 * fade)
                .blendMode(.plusLighter)

            // Mid body, which gives the bloom an edge to grow from.
            band(phase: phase, size: size)
                .mask(mouthMask(width: (3 + 8 * ramp) * k, size: size))
                .blur(radius: (2.5 + 4 * ramp) * k)
                .opacity(0.88 * fade)
                .blendMode(.plusLighter)

            // The filament itself, drawn normally rather than additively.
            //
            // Two reasons it has to be here. Additive layers cancel out
            // against the white sheet, so without this the glow would only
            // ever be a halo *above* the mouth with no line on it. And half
            // these skins throw a bright background field — over one of those,
            // plusLighter clips straight to white and the whole glow
            // disappears. This is the layer that survives both.
            band(phase: phase, size: size)
                .mask(mouthMask(width: (1.2 + 2.4 * ramp) * k, size: size))
                .blur(radius: 0.5)
                .opacity(0.95 * fade)
        }
        .allowsHitTesting(false)
    }

    private func stroke(width: Double) -> some View {
        PocketEdge().stroke(style: StrokeStyle(lineWidth: width,
                                               lineCap: .round, lineJoin: .round))
    }

    /// The stroke, cut down to the stretch of mouth this card is touching.
    ///
    /// Two masks, and they answer different questions. The horizontal one is
    /// *which* stretch belongs to the card; the vertical one is *how much of
    /// it has been reached yet*, which is what makes the light appear at the
    /// outer crown first and spread inward along the shoulders as the card
    /// descends. Without the second, the whole mouth lit at once the instant
    /// contact began anywhere along it.
    ///
    /// Applied to the mask rather than over the finished stack: a `.mask`
    /// around the three layers would group them, and a grouped `plusLighter`
    /// blends against its own group instead of the page.
    private func mouthMask(width: Double, size: CGSize) -> some View {
        stroke(width: width)
            .mask(MouthWindow.gradient(width: size.width, span: span))
            .mask(MouthWindow.reached(height: size.height, edge: front))
    }

    /// The travelling colour band.
    ///
    /// Three copies of the palette laid across three screen widths, slid by up
    /// to one width. Because the pattern repeats exactly once per width, the
    /// offset wraps with no seam and the loop needs no crossfade.
    private func band(phase: Double, size: CGSize) -> some View {
        let w = size.width
        let cycle = colors + colors + colors + [colors[0]]
        return LinearGradient(colors: cycle, startPoint: .leading, endPoint: .trailing)
            .frame(width: w * 3, height: max(size.height, 1))
            .offset(x: -w * CGFloat(phase))
            .frame(width: w, height: max(size.height, 1), alignment: .leading)
    }
}
