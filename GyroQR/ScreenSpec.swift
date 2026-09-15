import SwiftUI

/// The full share screen, Figma node `779:22071` — 375 × 812.
///
/// The design is laid out at its native size and scaled to fit the device, so
/// every number here is the Figma value verbatim.
enum ScreenSpec {
    static let size = CGSize(width: 375, height: 812)

    // Frames, screen-local points.
    static let closeButton = CGRect(x: 12, y: 55, width: 40, height: 40)        // 779:22685
    static let avatar      = CGRect(x: 131.25, y: 81.525,
                                    width: 112.4956, height: 112.4956)          // 779:22688
    static let card        = CGRect(x: 12, y: 139, width: 351, height: 450)     // 779:22089
    static let caption     = CGRect(x: 42, y: 482.026, width: 297, height: 70)  // 779:22701
    static let sheet       = CGRect(x: 0, y: 590, width: 375, height: 222)      // 779:22703

    // Colours, from the design's variables.
    enum Palette {
        static let textPrimary   = Color(red: 0x1d/255, green: 0x25/255, blue: 0x39/255) // #1D2539
        static let textSecondary = Color(red: 0x5d/255, green: 0x5d/255, blue: 0x5d/255) // #5D5D5D
        static let textMuted     = Color(red: 0x98/255, green: 0x9f/255, blue: 0xb3/255) // #989FB3
        static let borderSubtle  = Color(red: 0xf2/255, green: 0xf3/255, blue: 0xf7/255) // #F2F3F7
        static let borderHairline = Color(red: 0xf1/255, green: 0xf0/255, blue: 0xf0/255) // #F1F0F0
        static let borderAction  = Color(red: 0xd6/255, green: 0xe9/255, blue: 0xff/255) // #D6E9FF
        static let inverted      = Color(red: 0x10/255, green: 0x16/255, blue: 0x28/255) // #101628
        static let homeBar       = Color(red: 0x26/255, green: 0x2a/255, blue: 0x33/255) // #262A33
        static let separator     = Color(red: 0xe8/255, green: 0xea/255, blue: 0xf0/255)
    }

    // Type. The design uses Noontree, which is not on the device — the system
    // font at the same size, weight, line height and tracking is the stand-in.
    enum TypeScale {
        /// Body/B16/Medium
        static let b16 = (size: 16.0, line: 22.0, tracking: -0.15, weight: Font.Weight.medium)
        /// Body/B14/SemiBold
        static let b14 = (size: 14.0, line: 20.0, tracking: -0.1, weight: Font.Weight.semibold)
        /// Body/B12/Bold
        static let b12 = (size: 12.0, line: 18.0, tracking: -0.1, weight: Font.Weight.bold)
        /// Action/A16/SemiBold
        static let a16 = (size: 16.0, line: 24.0, tracking: 0.0, weight: Font.Weight.semibold)
    }

    static let inviteLink = "invite.noon.com/Faraz"
    static let captionLine1 = "Ask Kiaan to download the app"
    static let captionLine2 = "& scan this code on their phone"
}

extension View {
    /// Applies one of the design's type styles, matching Figma's line height by
    /// pinning the line spacing rather than letting the system pick.
    func figmaText(_ style: (size: Double, line: Double, tracking: Double, weight: Font.Weight)) -> some View {
        self.font(.system(size: style.size, weight: style.weight))
            .tracking(style.tracking)
            .lineSpacing(style.line - style.size * 1.2)
    }
}
