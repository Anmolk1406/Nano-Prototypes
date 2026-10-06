import SwiftUI

// The flow's checkbox and radios, drawn rather than swapped between two SVG
// exports, so ticking one can animate. Geometry is the exports', to the point.
//
// Nothing here bumps the whole control. The box or ring crossfades between its
// off and on looks, and the tick is what moves: it draws itself in along its
// stroke, growing from 85% as it goes.

/// `M-Checkbox`: off, an 18pt grey outline in its 24pt box; on, a 15pt
/// purple square with the tick knocked out of it in white.
struct ParentCheckbox: View {
    let on: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5.4, style: .continuous)
                .strokeBorder(Color(hex: 0x989FB3), lineWidth: 1.5)
                .frame(width: 18.07, height: 18.07)
                .opacity(on ? 0 : 1)
            RoundedRectangle(cornerRadius: 4.5, style: .continuous)
                .fill(ParentSpec.C.selectedStroke)
                .frame(width: 15.06, height: 15.06)
                .opacity(on ? 1 : 0)
            ParentTick(on: on, points: [(7.08, 10.42), (8.75, 12.08), (12.92, 7.92)], width: 1.25)
                .frame(width: 20, height: 20)
        }
        .animation(.easeOut(duration: 0.16), value: on)
        .frame(width: 24, height: 24)
    }
}

/// `M-Radio` with a tick — the gender cards': a 20pt ring that fills purple,
/// the tick knocked out of it.
struct ParentTickRadio: View {
    let on: Bool

    var body: some View {
        ZStack {
            Circle().fill(.white)
            Circle().strokeBorder(Color(hex: 0xD0D4DD), lineWidth: 1).opacity(on ? 0 : 1)
            Circle().fill(ParentSpec.C.selectedStroke).opacity(on ? 1 : 0)
            ParentTick(on: on, points: [(6.92, 10.77), (9.08, 12.93), (13.09, 7.6)], width: 1.54)
        }
        .animation(.easeOut(duration: 0.16), value: on)
        .frame(width: 20, height: 20)
    }
}

/// `Radio`: a 20pt ring, grey off and purple on, with a 12pt dot that grows
/// in from the centre. The dot is the radio's tick.
struct ParentDotRadio: View {
    let on: Bool

    var body: some View {
        ZStack {
            Circle().fill(.white)
            Circle().strokeBorder(on ? ParentSpec.C.selectedStroke : Color(hex: 0xD0D4DD), lineWidth: 1)
                .animation(.easeOut(duration: 0.16), value: on)
            Circle().fill(ParentSpec.C.selectedStroke)
                .frame(width: 12, height: 12)
                .scaleEffect(on ? 1 : 0.4)
                .opacity(on ? 1 : 0)
                .animation(.interpolatingSpring(stiffness: 320, damping: 24), value: on)
        }
        .frame(width: 20, height: 20)
    }
}

/// The white tick, in its export's 20pt space: drawn in along its stroke
/// and grown from 85%, a beat after the box has started to fill; gone at once
/// when unticked, so it never undraws backwards.
private struct ParentTick: View {
    let on: Bool
    let points: [(CGFloat, CGFloat)]
    let width: CGFloat

    var body: some View {
        TickPath(points: points)
            .trim(from: 0, to: on ? 1 : 0)
            .stroke(.white, style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
            .animation(on ? .easeOut(duration: 0.22).delay(0.05) : nil, value: on)
            .scaleEffect(on ? 1 : 0.85)
            .animation(on ? .interpolatingSpring(stiffness: 320, damping: 22).delay(0.05)
                          : .easeOut(duration: 0.1), value: on)
            .frame(width: 20, height: 20)
    }

    private struct TickPath: Shape {
        let points: [(CGFloat, CGFloat)]
        func path(in r: CGRect) -> Path {
            let s = r.width / 20
            return Path { p in
                for (i, pt) in points.enumerated() {
                    let q = CGPoint(x: r.minX + pt.0 * s, y: r.minY + pt.1 * s)
                    if i == 0 { p.move(to: q) } else { p.addLine(to: q) }
                }
            }
        }
    }
}
