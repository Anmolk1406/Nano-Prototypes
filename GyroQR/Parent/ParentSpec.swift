import SwiftUI

/// The parent flow's tokens — the design's variables, verbatim.
enum ParentSpec {
    static let size = CGSize(width: 375, height: 812)

    /// The flow's spring for everything that moves inside a page: tension
    /// 320, friction 28.
    static let spring = Animation.interpolatingSpring(stiffness: 320, damping: 28)
    /// Between pages: the push, on the same spring.
    static let page = spring
    /// Crossfades inside a page.
    static let fade = Animation.easeInOut(duration: 0.35)

    enum C {
        static let surface = Color.white
        static let textPrimary = Color(hex: 0x1D2539)      // text-n-icon/primary, blue-gray/900
        static let textSecondary = Color(hex: 0x475067)    // text-n-icon/secondary
        static let textTertiary = Color(hex: 0x666D85)     // text-n-icon/tertiary
        static let label = Color(hex: 0x343D54)            // blue-gray/800
        static let ink = Color(hex: 0x0E0E0E)              // neutral/black
        static let field = Color(hex: 0xF5F7FA)
        static let borderPrimary = Color(hex: 0xEAECF0)    // border/primary
        static let borderSubtle = Color(hex: 0xF2F3F7)     // blue-gray/200
        static let cardSubtle = Color(hex: 0xFCFCFD)       // blue-gray/50
        static let selectedFill = Color(hex: 0xF2E5FF)
        static let selectedStroke = Color(hex: 0x9B3DFF)
        static let homeBar = Color(hex: 0x262A33)

        static let headerTop = Color(hex: 0xB693FD)
        static let headerBottom = Color(hex: 0xF9F3FC)
    }

    /// Figma's type ramp: size, line height, tracking.
    struct TypeStyle {
        let weight: NoonFont.Weight
        let size: CGFloat
        let line: CGFloat
        let tracking: CGFloat
    }
    enum T {
        static let h40 = TypeStyle(weight: .extrabold, size: 40, line: 48, tracking: -0.25)
        static let b16s = TypeStyle(weight: .semibold, size: 16, line: 22, tracking: -0.15)
        static let b14m = TypeStyle(weight: .medium, size: 14, line: 20, tracking: -0.1)
        static let b14s = TypeStyle(weight: .semibold, size: 14, line: 20, tracking: -0.1)
        static let b14r = TypeStyle(weight: .regular, size: 14, line: 20, tracking: -0.1)
        static let b13r = TypeStyle(weight: .regular, size: 13, line: 20, tracking: -0.1)
        static let b12r = TypeStyle(weight: .regular, size: 12, line: 18, tracking: -0.1)
        static let label3 = TypeStyle(weight: .semibold, size: 14, line: 18, tracking: -0.14)
        static let label2 = TypeStyle(weight: .semibold, size: 14, line: 20, tracking: -0.16)
        static let a16 = TypeStyle(weight: .semibold, size: 16, line: 24, tracking: 0)
    }
}

extension View {
    /// One line of Figma type in a box exactly its line height tall, so its
    /// baseline sits where the design's does and stacked text keeps the
    /// design's rhythm.
    func parentType(_ s: ParentSpec.TypeStyle) -> some View {
        font(NoonFont.f(s.weight, s.size))
            .tracking(s.tracking)
            .lineLimit(1)
            .frame(height: s.line)
    }
}

/// Figma multi-line copy, one line to a box exactly its line height tall.
/// `lineSpacing` would have to guess the face's natural line height; boxes
/// put every baseline where the design's is.
struct ParentLines: View {
    let lines: [String]
    let style: ParentSpec.TypeStyle
    var colour: Color = ParentSpec.C.textPrimary
    var alignment: HorizontalAlignment = .center

    var body: some View {
        VStack(alignment: alignment, spacing: 0) {
            ForEach(lines.indices, id: \.self) { i in
                Text(lines[i]).parentType(style).foregroundStyle(colour)
            }
        }
    }
}
