import SwiftUI

/// Where the chosen card settles — Figma `Grid` (1118:44289): a tray in the
/// card's own colour, a faint 18pt grid inside it, clipped to the card's
/// rounding.
///
/// | layer | design (on the green-leather card, #006B3B) |
/// |---|---|
/// | tray | fill 5%, 1pt stroke 50%, the whole layer at 50% |
/// | grid | 0.5pt lines at 50%, every 18pt both ways, the group at 25% |
///
/// The colour is the dragged skin's `SkinPalette.ink`, so it is drawn here
/// rather than exported — and the motion lives here too:
///
/// * **Reveal, scrubbed by the pull.** The grid is uncovered from the centre
///   out as the card comes down, by a soft disc that grows with `reveal`. It
///   is the finger's progress, so it runs backwards if the pull is undone.
/// * **Arm ripple.** Crossing the commit point — the `armed()` tick — sends
///   one bright ring through the grid from the centre to the edge (0.55s,
///   ease-out) and lifts the tray's edge for the same time: the slot saying
///   "yes, here".
/// * **Running strokes.** Trim-path runners: a bright 28% length of each
///   grid line slides along it — verticals top to bottom, horizontals left
///   to right — each line a beat behind its neighbour, so light washes
///   across the tray; and a 22% trim of the edge travels round it. One lap
///   is 1.6s (the edge 2.4s), looping while the tray is showing, at a
///   strength that follows `reveal`.
/// * **Absorb on settle.** When the card commits the tray swells 4% and fades
///   under it over 0.25s instead of switching off.
struct SkinDropGrid: View {
    let ink: Color
    let size: CGSize
    let radius: CGFloat
    /// 0…1 — how much of the grid is uncovered.
    var reveal: Double
    /// True once the pull is past the commit point.
    var armed: Bool
    /// True once the card has committed and is landing on the tray.
    var absorbed: Bool

    @State private var ripple: CGFloat = 0
    @State private var rippling = false
    @State private var edgeLift: Double = 0

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: radius, style: .circular)
    }
    /// A disc that covers the tray's corners from its centre.
    private var reach: CGFloat { (size.width * size.width + size.height * size.height).squareRoot() }

    var body: some View {
        ZStack {
            // The tray: 5% fill and a 50% edge, the layer at 50%.
            shape.fill(ink.opacity(0.05))
                .overlay(shape.strokeBorder(ink.opacity(0.5 + 0.5 * edgeLift), lineWidth: 1))
                .opacity(0.5)

            // The grid, uncovered from the centre.
            grid(alpha: 0.5 * 0.25)
                .mask {
                    Circle()
                        .frame(width: reach, height: reach)
                        .scaleEffect(0.15 + 0.95 * reveal)
                        .blur(radius: 18)
                }

            // The runners, under the same reveal as the grid.
            TimelineView(.animation(paused: absorbed || reveal <= 0.001)) { tl in
                let t = tl.date.timeIntervalSinceReferenceDate
                ZStack {
                    runners(t: t, alpha: 0.55 * reveal)
                    edgeRunner(t: t, alpha: 0.6 * reveal)
                }
            }
            .mask {
                Circle()
                    .frame(width: reach, height: reach)
                    .scaleEffect(0.15 + 0.95 * reveal)
                    .blur(radius: 18)
            }

            // The ripple: the same grid, much brighter, seen only through a
            // ring that runs outward.
            if rippling {
                grid(alpha: 0.75)
                    .mask {
                        Circle()
                            .strokeBorder(.white, lineWidth: 22)
                            .frame(width: reach, height: reach)
                            .scaleEffect(0.1 + 0.95 * ripple)
                            .blur(radius: 8)
                    }
                    .opacity(1 - Double(ripple))
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(shape)
        .scaleEffect(absorbed ? 1.04 : 1)
        .opacity(absorbed ? 0 : 1)
        .animation(.easeOut(duration: 0.25), value: absorbed)
        .onChange(of: armed) { _, now in
            guard now else { return }
            ripple = 0
            rippling = true
            withAnimation(.easeOut(duration: 0.55)) { ripple = 1 }
            withAnimation(.easeOut(duration: 0.12)) { edgeLift = 1 }
            withAnimation(.easeIn(duration: 0.43).delay(0.12)) { edgeLift = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.56) { rippling = false }
        }
    }

    /// The trimmed runs on the grid lines. Each is the trim window
    /// `[p − 0.28, p]` of its line, with a tail that fades to nothing, `p`
    /// sweeping past both ends so the run enters and leaves cleanly.
    private func runners(t: TimeInterval, alpha: Double) -> some View {
        Canvas { ctx, s in
            let lap = 1.6, length = 0.28, stagger = 0.07
            func run(_ a: CGPoint, _ b: CGPoint, _ i: Int) {
                let raw = (t / lap + Double(i) * stagger).truncatingRemainder(dividingBy: 1)
                let head = raw * (1 + length)          // 0 … 1.28
                let tail = head - length
                let h = min(1, head), tl = max(0, tail)
                guard h > tl else { return }
                func at(_ f: Double) -> CGPoint {
                    CGPoint(x: a.x + (b.x - a.x) * f, y: a.y + (b.y - a.y) * f)
                }
                var p = Path(); p.move(to: at(tl)); p.addLine(to: at(h))
                ctx.stroke(p, with: .linearGradient(
                    Gradient(colors: [ink.opacity(0), ink.opacity(alpha)]),
                    startPoint: at(tail), endPoint: at(head)), lineWidth: 0.75)
            }
            var i = 0
            var x: CGFloat = 0
            while x <= s.width { run(CGPoint(x: x, y: 0), CGPoint(x: x, y: s.height), i); x += 18; i += 1 }
            var y: CGFloat = 0.5625
            i = 0
            while y <= s.height { run(CGPoint(x: 0, y: y), CGPoint(x: s.width, y: y), i + 3); y += 18; i += 1 }
        }
        .frame(width: size.width, height: size.height)
    }

    /// A 22% trim of the tray's edge, travelling round it once every 2.4s.
    /// Drawn as two trims so it wraps past the path's start without a gap.
    private func edgeRunner(t: TimeInterval, alpha: Double) -> some View {
        let p = CGFloat((t / 2.4).truncatingRemainder(dividingBy: 1))
        let len: CGFloat = 0.22
        let style = StrokeStyle(lineWidth: 1.2, lineCap: .round)
        return ZStack {
            shape.inset(by: 0.6).trim(from: p, to: min(1, p + len))
                .stroke(ink.opacity(alpha), style: style)
            if p + len > 1 {
                shape.inset(by: 0.6).trim(from: 0, to: p + len - 1)
                    .stroke(ink.opacity(alpha), style: style)
            }
        }
        .frame(width: size.width, height: size.height)
    }

    /// 0.5pt lines every 18pt both ways, from the design's own origins:
    /// verticals from x 0, horizontals from y 0.56.
    private func grid(alpha: Double) -> some View {
        Canvas { ctx, s in
            var p = Path()
            var x: CGFloat = 0
            while x <= s.width { p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: s.height)); x += 18 }
            var y: CGFloat = 0.5625
            while y <= s.height { p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: s.width, y: y)); y += 18 }
            ctx.stroke(p, with: .color(ink.opacity(alpha)), lineWidth: 0.5)
        }
        .frame(width: size.width, height: size.height)
    }
}
