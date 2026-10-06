import SwiftUI

/// The header the kid's avatar and interests steps share — `Profile Pic`
/// (1113:27374) and `Interest Page` (1113:27168): a faint grid at the top, a
/// back button, the dark step rail and a two-line gradient headline.

/// `BG` (779:22753): white, with a 27.87pt grid of #EAECF0 hairlines that
/// fades out from a soft ellipse centred at the top. The design draws it as a
/// grid of SVG lines masked by a blurred ellipse; Xcode's SVG renderer drops
/// the blur, so it is drawn here — lines, then the same mask.
struct KidGridBackdrop: View {
    var body: some View {
        Canvas { ctx, size in
            let step: CGFloat = 27.872
            var path = Path()
            var x: CGFloat = 7.14
            while x < size.width { path.move(to: CGPoint(x: x, y: 0)); path.addLine(to: CGPoint(x: x, y: size.height)); x += step }
            var y: CGFloat = 14.85
            while y < size.height { path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: size.width, y: y)); y += step }
            ctx.stroke(path, with: .color(Color(hex: 0xEAECF0)), lineWidth: 0.755)
        }
        .frame(width: 375, height: 188)
        // The mask: #313131 at 48% in a 431 × 360 ellipse round (188.5, 8),
        // blurred by 50 — so the grid is strongest under the headline and
        // gone by the foot of the 188pt band.
        .mask {
            Ellipse()
                .fill(.black.opacity(0.48))
                .frame(width: 431, height: 360)
                .position(x: 188.5, y: 8)
                .blur(radius: 50)
                .frame(width: 375, height: 188)
        }
        .frame(width: 375, height: 188)
        .background(.white)
        .allowsHitTesting(false)
    }
}

/// `M-IconButton`, H40 default: white, a 1pt #F2F3F7 border, a 20pt chevron.
struct KidBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image("ic_chevron_left")
                .resizable()
                .frame(width: 20, height: 20)
                .frame(width: 40, height: 40)
                .background(.white, in: Circle())
                .overlay(Circle().strokeBorder(OnboardingSpec.C.borderSubtle, lineWidth: 1))
                .contentShape(Circle())
        }
        .buttonStyle(PressDip(scale: 0.96))
        .accessibilityLabel("Back")
    }
}

/// The three-step rail as these frames draw it: steps behind you are a
/// #343D54 disc with a white tick, the current one a 1pt ring round an 8pt
/// dot, the ones ahead #EAECF0; the 24 × 4 bars between are dark up to the
/// current step.
struct KidStepDots: View {
    let active: Int          // 0-based

    private let ink = Color(hex: 0x343D54)
    private let idle = Color(hex: 0xEAECF0)

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                dot(i)
                if i < 2 {
                    Capsule().fill(i < active ? ink : idle).frame(width: 24, height: 4)
                }
            }
        }
        .frame(width: 112, height: 16)
    }

    @ViewBuilder
    private func dot(_ i: Int) -> some View {
        if i < active {
            Circle().fill(ink)
                .overlay {
                    // Vector 20396 from the 16pt done dot.
                    Path { p in
                        p.move(to: CGPoint(x: 4.766, y: 8.427))
                        p.addLine(to: CGPoint(x: 7.014, y: 10.676))
                        p.addLine(to: CGPoint(x: 11.514, y: 6.176))
                    }
                    .stroke(.white, style: StrokeStyle(lineWidth: 1.23, lineCap: .round, lineJoin: .round))
                }
                .frame(width: 16, height: 16)
        } else if i == active {
            Circle().strokeBorder(ink, lineWidth: 1)
                .overlay(Circle().fill(ink).frame(width: 8, height: 8))
                .frame(width: 16, height: 16)
        } else {
            Circle().fill(idle).frame(width: 16, height: 16)
        }
    }
}

/// A headline line as these frames set it: 36pt ExtraBold on a 48pt line,
/// a black-to-purple gradient through the glyphs and the white sticker
/// outline — `ParentGradientTitle` at this size.
struct KidTitleLine {
    let text: String
    /// The text box, in stage points.
    let frame: CGRect
    /// The CSS gradient angle.
    let angle: Double
    var endColor = Color(hex: 0x6F21EA)
}

struct KidTitle: View {
    let lines: [KidTitleLine]
    /// White bars the design lays under the type, so the grid does not run
    /// through the counters.
    let bars: [CGRect]

    static let style = ParentSpec.TypeStyle(weight: .extrabold, size: 36, line: 48, tracking: -0.25)

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(bars.indices, id: \.self) { i in
                Rectangle().fill(.white)
                    .frame(width: bars[i].width, height: bars[i].height)
                    .offset(x: bars[i].minX, y: bars[i].minY)
            }
            ForEach(lines.indices, id: \.self) { i in
                let l = lines[i]
                ParentGradientTitle(text: l.text, style: Self.style, width: l.frame.width,
                                    angle: l.angle, outline: 4.3, endColor: l.endColor)
                    .offset(x: l.frame.minX, y: l.frame.minY)
            }
        }
        .frame(width: 375, alignment: .topLeading)
        .allowsHitTesting(false)
    }
}

/// Back button and step rail, where both frames put them: the button at
/// (16, 64), the rail centred at y 76.
struct KidHeaderBar: View {
    let active: Int
    let onBack: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            KidStepDots(active: active).offset(x: 132, y: 76)
            KidBackButton(action: onBack).offset(x: 16, y: 64)
        }
        .frame(width: 375, alignment: .topLeading)
    }
}
