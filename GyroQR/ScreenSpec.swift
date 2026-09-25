import SwiftUI

/// The invite share screen, Figma node `1 Child details` (980:15528) — 375 × 812.
///
/// A redesign of `779:22071`, and a thorough one: the photographic backdrop is
/// gone for a lilac gradient with a ray pattern, the card is a moulded chrome
/// object instead of a flat magenta panel, the avatar and the three mascots
/// are gone, and a title has arrived above the card. What survives unchanged
/// is the bottom of the screen — the OR rule, the invite link and the share
/// button are the same component at the same numbers, which is why that code
/// is untouched.
///
/// The design is laid out at its native size and scaled to fit the device, so
/// every number here is the Figma value verbatim.
enum ScreenSpec {
    static let size = CGSize(width: 375, height: 812)

    // Frames, screen-local points.
    /// 980:15981 — the page header's leading slot, 12 in and 8 down from the
    /// 56pt header at y 47.
    static let closeButton = CGRect(x: 12, y: 55, width: 40, height: 40)
    /// 980:15984. The title block: an ExtraBold line and a Medium one under it.
    static let titleBox    = CGRect(x: 57, y: 112.31, width: 261, height: 48)
    static let subtitleBox = CGRect(x: 32, y: 162.31, width: 311.28, height: 20)
    /// 980:15537 — the chrome frame, which is the card's own box.
    static let card        = CGRect(x: 42.17, y: 196.57, width: 290, height: 409.19)
    /// 980:15987 and 980:16004. Both carry a rotation, and the right one is
    /// also drawn at 70% of the box its CSS reports — so these are built from
    /// their own uploads and then *sized and placed* against the render. See
    /// the builder; guessing either number is what went wrong twice.
    static let starLeft    = CGRect(x: -19.85, y: 459.20, width: 85, height: 89)
    static let starRight   = CGRect(x: 250.67, y: 256.79, width: 153, height: 182.33)
    /// 980:15988 — unchanged from the old design.
    static let sheet       = CGRect(x: 0, y: 590, width: 375, height: 222)

    // Colours, from the design's variables.
    enum Palette {
        static let textPrimary   = Color(red: 0x1d/255, green: 0x25/255, blue: 0x39/255) // #1D2539
        static let textSecondary = Color(red: 0x5d/255, green: 0x5d/255, blue: 0x5d/255) // #5D5D5D
        static let textMuted     = Color(red: 0x98/255, green: 0x9f/255, blue: 0xb3/255) // #989FB3
        static let borderSubtle  = Color(red: 0xf2/255, green: 0xf3/255, blue: 0xf7/255) // #F2F3F7
        static let borderHairline = Color(red: 0xf1/255, green: 0xf0/255, blue: 0xf0/255) // #F1F0F0
        static let borderAction  = Color(red: 0xd6/255, green: 0xe9/255, blue: 0xff/255) // #D6E9FF
        /// 980:15994's own border. The old design used the action blue here;
        /// this one uses the neutral.
        static let borderField   = Color(red: 0xea/255, green: 0xec/255, blue: 0xf0/255) // #EAECF0
        /// The `M-NeutralButton`'s fill — a vertical ramp, not the flat navy
        /// the old screen used.
        static let buttonTop     = Color(red: 0x21/255, green: 0x21/255, blue: 0x21/255) // #212121
        static let buttonBottom  = Color(red: 0x0d/255, green: 0x0d/255, blue: 0x0d/255) // #0D0D0D
        static let inverted      = Color(red: 0x10/255, green: 0x16/255, blue: 0x28/255) // #101628
        static let homeBar       = Color(red: 0x26/255, green: 0x2a/255, blue: 0x33/255) // #262A33
        static let separator     = Color(red: 0xe8/255, green: 0xea/255, blue: 0xf0/255)
    }

    // Type — Noontree, at the design's size, weight, line height and tracking.
    enum TypeScale {
        /// Body/B16/Medium
        static let b16 = (size: 16.0, line: 22.0, tracking: -0.15, weight: NoonFont.Weight.medium)
        /// Body/B14/SemiBold
        static let b14 = (size: 14.0, line: 20.0, tracking: -0.1, weight: NoonFont.Weight.semibold)
        /// Body/B12/Bold
        static let b12 = (size: 12.0, line: 18.0, tracking: -0.1, weight: NoonFont.Weight.bold)
        /// Action/A16/SemiBold
        static let a16 = (size: 16.0, line: 24.0, tracking: 0.0, weight: NoonFont.Weight.semibold)
    }

    static let inviteLink = "invite.noon.com/Faraz"
    static let inviteName = "Kiaan Khalid"
    static let title      = "Invite Kiaan"
    static let subtitle   = "Download the app, then scan to get started"

    /// 980:15985 — `linear-gradient(43.05deg, #000 52.835%, #7924FF 104.2%)`,
    /// clipped to the type. The CSS angle is measured from "to top" clockwise,
    /// so 43° points up and to the right; bottom-leading to top-trailing is
    /// that direction on a box this shape. The second stop runs past the end
    /// of the box, so it is clamped and the purple never fully arrives — which
    /// is what the render shows.
    /// The headline's white sticker outline. Not in the design context — a
    /// Figma text stroke does not come through it — so measured off the
    /// render: 4.67pt of white above the glyphs and 5 below.
    static let titleOutline: (colour: Color, width: CGFloat) = (.white, 4.8)

    static let titleFill = LinearGradient(
        stops: [.init(color: .black, location: 0.528),
                .init(color: Color(hex: 0x7924FF), location: 1)],
        startPoint: .bottomLeading, endPoint: .topTrailing)
}

extension View {
    /// Applies one of the design's type styles, matching Figma's line height by
    /// pinning the line spacing rather than letting the system pick.
    func figmaText(_ style: (size: Double, line: Double, tracking: Double, weight: NoonFont.Weight)) -> some View {
        self.font(NoonFont.f(style.weight, style.size))
            .tracking(style.tracking)
            .lineSpacing(style.line - style.size * 1.2)
    }
}
