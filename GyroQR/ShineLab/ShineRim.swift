import SwiftUI

/// The designer's shines, cut apart and set running along the base's rim.
///
/// Every star rides one of the rim's two bevel lines — the outer highlight or
/// the inner one — and they alternate along each side, so the light is spread
/// over both. Top and bottom stars run along x with the left–right tilt, the
/// side stars along y with the forward–back tilt; nothing runs across the rim.
///
/// Two limits keep a star on its edge. Its core is clamped short of the
/// corner, and each edge's light is masked to the rim itself: along the edge
/// it fades out past the corner, across it it stops at the panel's edge, and
/// all of it is clipped to the base's silhouette — no halo spills out past
/// the card, and none in over the QR. The corner star has no straight run, so it stays on the inner arc
/// and glints when the card tips toward it.
///
/// Laid out in the artwork's own pixels and scaled to `width`; drawn inside
/// the card's own space, so it turns with the card.
struct ShineRim: View {
    @ObservedObject var out: MotionOutput
    @ObservedObject var tune: ShineLabTuning
    let width: CGFloat
    var invertX = false
    var invertY = false

    private typealias Spec = ShineLabSpec
    private var s: CGFloat { width / Spec.canvas.width }

    var body: some View {
        let tilt = CGPoint(x: out.tilt.x * (invertX ? -1 : 1), y: out.tilt.y * (invertY ? -1 : 1))
        return ZStack(alignment: .topLeading) {
            edgeGroup(.top, tilt: tilt)
            edgeGroup(.bottom, tilt: tilt)
            edgeGroup(.left, tilt: tilt)
            edgeGroup(.right, tilt: tilt)
            ForEach(Spec.shines.filter { $0.edge == .corner }) { corner($0, tilt: tilt) }
            if tune.showEdges { tracks }
        }
        .frame(width: Spec.canvas.width, height: Spec.canvas.height, alignment: .topLeading)
        .scaleEffect(s, anchor: .topLeading)
        .frame(width: Spec.canvas.width * s, height: Spec.canvas.height * s, alignment: .topLeading)
        .allowsHitTesting(false)
    }

    // MARK: edges

    private func edgeGroup(_ edge: Spec.Edge, tilt: CGPoint) -> some View {
        let shines = Spec.shines.enumerated().filter { $0.element.edge == edge }
        return ZStack(alignment: .topLeading) {
            ForEach(shines, id: \.element.id) { i, shine in
                edgeShine(shine, index: i, tilt: tilt)
            }
        }
        .frame(width: Spec.canvas.width, height: Spec.canvas.height, alignment: .topLeading)
        .mask { rimMask(edge) }
        .blendMode(tune.additive ? .plusLighter : .normal)
    }

    /// The edge's straight run, a little past it (the resting streaks already
    /// reach 20px into the corners) and gone within 80px — times the rim's
    /// band across it.
    private func rimMask(_ edge: Spec.Edge) -> some View {
        let horizontal = edge == .top || edge == .bottom
        let run = horizontal ? Spec.spanX : Spec.spanY
        let along = horizontal ? Spec.canvas.width : Spec.canvas.height
        let across = horizontal ? Spec.canvas.height : Spec.canvas.width
        let band = Spec.band(edge)
        let lead: CGFloat = 30, fade: CGFloat = 80
        func at(_ v: CGFloat, _ n: CGFloat) -> CGFloat { max(0, min(1, v / n)) }
        let alongStops: [Gradient.Stop] = [
            .init(color: .clear, location: at(run.lowerBound - lead - fade, along)),
            .init(color: .black, location: at(run.lowerBound - lead, along)),
            .init(color: .black, location: at(run.upperBound + lead, along)),
            .init(color: .clear, location: at(run.upperBound + lead + fade, along)),
        ]
        let acrossStops: [Gradient.Stop] = [
            .init(color: .clear, location: at(band.solid.lowerBound - band.fade, across)),
            .init(color: .black, location: at(band.solid.lowerBound, across)),
            .init(color: .black, location: at(band.solid.upperBound, across)),
            .init(color: .clear, location: at(band.solid.upperBound + band.fade, across)),
        ]
        // A band that starts at the canvas edge has nothing to fade in from.
        let acrossFixed = band.solid.lowerBound <= 0
            ? [Gradient.Stop(color: .black, location: 0)] + acrossStops.dropFirst(2)
            : (band.solid.upperBound >= across
               ? Array(acrossStops.prefix(2)) + [Gradient.Stop(color: .black, location: 1)]
               : acrossStops)
        return LinearGradient(stops: alongStops,
                              startPoint: horizontal ? .leading : .top,
                              endPoint: horizontal ? .trailing : .bottom)
            .mask {
                LinearGradient(stops: acrossFixed,
                               startPoint: horizontal ? .top : .leading,
                               endPoint: horizontal ? .bottom : .trailing)
            }
            .frame(width: Spec.canvas.width, height: Spec.canvas.height)
            .mask { silhouette }
    }

    /// The base's own alpha. Folded into each group's mask rather than
    /// wrapped round the whole rim: a mask makes its content a group of its
    /// own, and an additive group inside it would blend against nothing
    /// instead of against the card.
    private var silhouette: some View {
        Image("slab_base").resizable().interpolation(.high)
            .frame(width: Spec.canvas.width, height: Spec.canvas.height)
    }

    private func edgeShine(_ shine: Spec.Shine, index: Int, tilt: CGPoint) -> some View {
        let horizontal = shine.edge == .top || shine.edge == .bottom
        // Screen y runs down and the tilt's y runs up, hence the sign.
        var drive = horizontal ? tilt.x : -tilt.y
        if tune.orbit, shine.edge == .bottom || shine.edge == .left { drive = -drive }
        // A touch of difference between shines, so a side's stars do not move
        // as one rigid piece.
        let gain = 1 + 0.12 * sin(Double(index) * 1.7)
        let want = CGFloat(drive * tune.travel * gain)
        let run = horizontal ? Spec.spanX : Spec.spanY
        let core = horizontal ? shine.core.x : shine.core.y
        let lo = run.lowerBound + Spec.coreMargin, hi = run.upperBound - Spec.coreMargin
        let along = min(hi, max(lo, core + want)) - core
        // Onto its bevel line: the cut left each star where it was drawn,
        // between the two.
        let across = Spec.line(shine.edge, shine.track) - (horizontal ? shine.core.y : shine.core.x)
        let energy = min(1, abs(drive))
        let grow = 1 + CGFloat(tune.stretch * energy)
        let anchor = UnitPoint(x: (shine.core.x - shine.frame.minX) / shine.frame.width,
                               y: (shine.core.y - shine.frame.minY) / shine.frame.height)
        return Image(shine.image).resizable().interpolation(.high)
            .frame(width: shine.frame.width, height: shine.frame.height)
            .scaleEffect(x: horizontal ? grow : 1, y: horizontal ? 1 : grow, anchor: anchor)
            .opacity(tune.restGlow + (1 - tune.restGlow) * energy)
            .offset(x: shine.frame.minX + (horizontal ? along : across),
                    y: shine.frame.minY + (horizontal ? across : along))
    }

    /// The corner star: on the inner arc, brightest with the card tipped
    /// toward its corner (−x, +y in tilt space).
    private func corner(_ shine: Spec.Shine, tilt: CGPoint) -> some View {
        let toward = max(0, min(1, (-tilt.x + tilt.y) / 2.0.squareRoot()))
        let anchor = UnitPoint(x: (shine.core.x - shine.frame.minX) / shine.frame.width,
                               y: (shine.core.y - shine.frame.minY) / shine.frame.height)
        let dx = Spec.cornerCore.x - shine.core.x, dy = Spec.cornerCore.y - shine.core.y
        return Image(shine.image).resizable().interpolation(.high)
            .frame(width: shine.frame.width, height: shine.frame.height)
            .scaleEffect(0.9 + 0.3 * toward, anchor: anchor)
            .opacity(tune.restGlow * 0.8 + (1 - tune.restGlow * 0.8) * toward)
            .offset(x: shine.frame.minX + dx, y: shine.frame.minY + dy)
            .frame(width: Spec.canvas.width, height: Spec.canvas.height, alignment: .topLeading)
            .mask { silhouette }
            .blendMode(tune.additive ? .plusLighter : .normal)
    }

    /// Debug: both bevel lines on every side, over the stretch a core may use.
    private var tracks: some View {
        let m = Spec.coreMargin
        let x = Spec.spanX, y = Spec.spanY
        return Path { p in
            for e in [Spec.Edge.top, .bottom] {
                for t in [Spec.Track.outer, .inner] {
                    let yy = Spec.line(e, t)
                    p.move(to: CGPoint(x: x.lowerBound + m, y: yy)); p.addLine(to: CGPoint(x: x.upperBound - m, y: yy))
                }
            }
            for e in [Spec.Edge.left, .right] {
                for t in [Spec.Track.outer, .inner] {
                    let xx = Spec.line(e, t)
                    p.move(to: CGPoint(x: xx, y: y.lowerBound + m)); p.addLine(to: CGPoint(x: xx, y: y.upperBound - m))
                }
            }
        }
        .stroke(Color.red.opacity(0.7), style: StrokeStyle(lineWidth: 3, dash: [12, 10]))
    }
}
