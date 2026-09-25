import SwiftUI
import UIKit

/// The natural shape of a skin's artwork.
///
/// There is no single card aspect, which is the thing that kept the drop
/// outline from fitting. Figma draws the card 248.7 × 163.2 — 1.524 : 1 — and
/// that number is right for the *layout*, but the 22 renders are trimmed tight
/// to their own content and they are not all the same shape: they run from
/// 1.444 (skin_01, whose charm hangs off the corner) to 1.637 (skin_12). A
/// 235pt-wide outline built on 1.524 is 8.6pt too short for skin_01 and 10.6pt
/// too tall for skin_12, which is visible as a gap along one edge however
/// carefully the width is matched.
///
/// `.scaledToFit()` inside a width-only frame already renders each card at its
/// own aspect, so the outline is what has to follow.
enum SkinArt {
    private static var cache = [String: CGFloat]()

    /// Width ÷ height of the trimmed artwork. Falls back to the design's
    /// nominal aspect if the asset is missing.
    static func aspect(_ name: String) -> CGFloat {
        if let hit = cache[name] { return hit }
        let size = UIImage(named: name)?.size ?? .zero
        let a = size.height > 0 ? size.width / size.height : SkinSelectSpec.cardAspect
        cache[name] = a
        return a
    }

    /// Height of `name` rendered at `width`.
    static func height(_ name: String, at width: CGFloat) -> CGFloat {
        width / aspect(name)
    }

    /// Corner radius of a skin's card, at a given rendered width.
    ///
    /// Measured, for the same reason the aspect is: the 22 renders do not share
    /// a corner. They run from 20.4pt to 33.6pt at the seated width, and the
    /// outline was drawn at a flat 22 — under almost every one of them, and
    /// barely two thirds of the lego card's.
    static func cornerRadius(_ name: String, at width: CGFloat) -> CGFloat {
        cornerFraction(name) * width
    }

    /// Radius as a fraction of the artwork's width, so it scales with however
    /// the card is being drawn.
    private static var radii = [String: CGFloat]()

    /// The median of the 22, for a missing asset.
    private static let fallbackFraction: CGFloat = 0.1055

    private static func cornerFraction(_ name: String) -> CGFloat {
        if let hit = radii[name] { return hit }
        let f = measureCorner(name) ?? fallbackFraction
        radii[name] = f
        return f
    }

    /// The inset from the corner along the 45° diagonal, converted to a radius.
    ///
    /// Robust where reading the top edge's profile is not. The first rows of
    /// these renders are specular highlights and soft shadow rather than the
    /// card — skin_03's very first row is 46 stray pixels of glare — and the
    /// plush and lego cards have no crisp edge at all. The diagonal ignores all
    /// of it and needs one number: for a circular corner of radius r the
    /// diagonal inset is exactly r(1 − 1/√2).
    ///
    /// Fitting a superellipse to the full profile offline agrees on the shape —
    /// these corners come out at n ≈ 1.8…2.0, which is circular, not a
    /// squircle — and that is why the outline is drawn `.circular`. It
    /// disagrees wildly on the radius for the soft-edged cards (18…42pt against
    /// this 20…34pt), which is the fit chasing fuzz.
    private static func measureCorner(_ name: String) -> CGFloat? {
        guard let cg = UIImage(named: name)?.cgImage else { return nil }
        let w = cg.width, h = cg.height
        guard w > 8, h > 8 else { return nil }

        // Alpha only: a quarter the memory of RGBA, and alpha is all this needs.
        var buf = [UInt8](repeating: 0, count: w * h)
        let drawn = buf.withUnsafeMutableBytes { raw -> Bool in
            guard let ctx = CGContext(data: raw.baseAddress, width: w, height: h,
                                      bitsPerComponent: 8, bytesPerRow: w,
                                      space: CGColorSpaceCreateDeviceGray(),
                                      bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue)
            else { return false }
            ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
            return true
        }
        guard drawn else { return nil }

        func solid(_ x: Int, _ y: Int) -> Bool { buf[y * w + x] > 128 }

        // The card body's own edges, read from the middle of each side so a
        // corner feature cannot move them. CoreGraphics draws bottom-up, so
        // this is the render's bottom-left corner rather than its top-left —
        // which is the one to want anyway: the charm on skin_01 and the sparkle
        // on skin_03 both sit at a top corner.
        var x0 = w, y0 = h
        for y in (h * 2 / 5)..<(h * 3 / 5) {
            if let x = (0..<(w / 2)).first(where: { solid($0, y) }) { x0 = min(x0, x) }
        }
        for x in (w * 2 / 5)..<(w * 3 / 5) {
            if let y = (0..<(h / 2)).first(where: { solid(x, $0) }) { y0 = min(y0, y) }
        }
        guard x0 < w, y0 < h else { return nil }

        let limit = min(w, h) / 3
        guard let d = (0..<limit).first(where: { solid(x0 + $0, y0 + $0) }) else { return nil }
        let r = CGFloat(d) / (1 - 1 / 2.squareRoot())
        return r / CGFloat(w)
    }

    /// Prints every skin's aspect and the outline it implies.
    ///     xcrun simctl launch --console-pty <udid> com.noon.gyroqr -artAudit
    static func audit() {
        for i in 1...SkinSelectSpec.skinCount {
            let name = String(format: "skin_%02d", i)
            let h = height(name, at: SkinSelectSpec.dropTargetWidth)
            let r = cornerRadius(name, at: SkinSelectSpec.dropTargetWidth)
            print(String(format: "ART %@ aspect %.3f  outline %.0f x %.1f  radius %.1f",
                         name, aspect(name), SkinSelectSpec.dropTargetWidth, h, r))
        }
    }
}
