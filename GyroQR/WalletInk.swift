import SwiftUI
import UIKit

/// Which way round the wallet page's type goes, for the background it is on.
///
/// The page's copy was white, full stop, because the design's own background is
/// a mid purple. But the background follows the card skin now, and nine of the
/// 22 are light — `bg_15` is a pale sand that measures 0.76 relative luminance
/// under the text, where white type sits at a contrast ratio of **1.29**. That
/// is not a near miss; it is unreadable.
///
/// So the ink is chosen from the artwork rather than fixed, by the same rule a
/// person would use: work out the contrast ratio white would get and the ratio
/// the design's dark ink would get, and take whichever is higher. Measured at
/// first use and cached, like `SkinPalette` — hand-authoring 22 answers would
/// go stale the moment a background is re-exported.
///
/// Measured over the 22, the split is 13 white and 9 dark, and only two are
/// close: `bg_04` (3.68 vs 4.15) and `bg_05` (3.55 vs 4.30). Both clear WCAG's
/// 3.0 bar for large text either way, which is what the balance is; the rule
/// simply takes the better of the two.
enum WalletInk {

    struct Scheme {
        /// `on-surface-bold` — the headline and the balance's top stop.
        var bold: Color
        /// `on-surface-subtle` — the help line, the owner label.
        var subtle: Color
        /// The ramp an amount is filled with, in this direction.
        var money: LinearGradient
        /// True when the background is light and the type has gone dark.
        var light: Bool
    }

    private static let onDark = Scheme(bold: .white, subtle: .white.opacity(0.8),
                                       money: MoneyStyle.onSurface, light: false)
    private static let onLight = Scheme(bold: Color(hex: 0x1D2539),
                                        subtle: Color(hex: 0x475067),
                                        money: MoneyStyle.onPage, light: true)

    private static var cache = [String: Scheme]()

    static func scheme(for background: String) -> Scheme {
        if let hit = cache[background] { return hit }
        let s = measure(background) ?? onDark
        cache[background] = s
        return s
    }

    /// The band of the image the type actually lands on.
    ///
    /// Not the whole picture. These backgrounds are gradients and several have
    /// a bright top and a dark bottom, so an average over all of them answers
    /// a question nobody asked. Both layouts put their type at about 0.6 of
    /// the backdrop's height — the empty page's balance at 0.60…0.76, the
    /// filled page's at 0.60…0.67 — so one band covers both, and the sides
    /// are trimmed because the copy is centred.
    private static let band = (top: 0.55, bottom: 0.78, left: 0.2, right: 0.8)

    private static func measure(_ name: String) -> Scheme? {
        guard let cg = UIImage(named: name)?.cgImage else { return nil }
        let w = 48, h = 96
        var buf = [UInt8](repeating: 0, count: w * h * 4)
        let ok = buf.withUnsafeMutableBytes { raw -> Bool in
            guard let ctx = CGContext(data: raw.baseAddress, width: w, height: h,
                                      bitsPerComponent: 8, bytesPerRow: w * 4,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            else { return false }
            ctx.interpolationQuality = .medium
            ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
            return true
        }
        guard ok else { return nil }

        var sum = 0.0
        var n = 0
        // CoreGraphics draws bottom-up, so the band's rows are mirrored.
        let y0 = Int(Double(h) * (1 - band.bottom)), y1 = Int(Double(h) * (1 - band.top))
        let x0 = Int(Double(w) * band.left), x1 = Int(Double(w) * band.right)
        for y in y0..<y1 {
            for x in x0..<x1 {
                let i = (y * w + x) * 4
                let a = Double(buf[i + 3]) / 255
                guard a > 0.5 else { continue }
                sum += luminance(Double(buf[i]) / 255 / a,
                                 Double(buf[i + 1]) / 255 / a,
                                 Double(buf[i + 2]) / 255 / a)
                n += 1
            }
        }
        guard n > 0 else { return nil }
        let bg = sum / Double(n)
        return contrast(1.0, bg) >= contrast(inkLuminance, bg) ? onDark : onLight
    }

    /// sRGB relative luminance, WCAG's definition.
    private static func luminance(_ r: Double, _ g: Double, _ b: Double) -> Double {
        func lin(_ c: Double) -> Double {
            let c = min(max(c, 0), 1)
            return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)
    }

    private static let inkLuminance = luminance(0x1D / 255, 0x25 / 255, 0x39 / 255)

    private static func contrast(_ a: Double, _ b: Double) -> Double {
        (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }
}
