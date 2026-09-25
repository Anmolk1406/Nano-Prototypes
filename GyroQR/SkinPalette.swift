import SwiftUI
import UIKit

/// Two or three colours taken from a skin's own artwork, for the pocket glow.
///
/// Hand-authoring 22 palettes would go stale the moment a skin is re-exported,
/// so they are read off the art at first use and cached. The image is drawn
/// into a 24 × 24 bitmap first — the glow only needs the card's broad colour
/// story, and averaging over ~570 pixels is both enough and cheap.
///
/// Half of these skins are metal or leather with no hue to speak of. Those fall
/// to `shades(of:)`, which is the brief's "if only one colour is there take
/// shades/tints": one hue, three saturations, so the glow still travels rather
/// than sitting there as a flat white band.
enum SkinPalette {

    struct Profile {
        /// Two or three bright colours, for additive layers over a dark page.
        var glow: [Color]
        /// One dark colour for line work on white — the drop target's stroke
        /// and fill. The glow colours are useless here: they are forced to full
        /// brightness, which on a white sheet reads as a pale wash.
        var ink: Color
    }

    private static var cache = [String: Profile]()

    static func colors(for name: String) -> [Color] { profile(for: name).glow }
    static func ink(for name: String) -> Color { profile(for: name).ink }

    static func profile(for name: String) -> Profile {
        if let hit = cache[name] { return hit }
        let result = extract(name) ?? fallback
        cache[name] = result
        return result
    }

    /// Used only if the asset is missing — a neutral cool triad.
    private static let fallback = Profile(
        glow: [
            Color(hue: 0.58, saturation: 0.50, brightness: 1),
            Color(hue: 0.72, saturation: 0.42, brightness: 1),
            Color(hue: 0.46, saturation: 0.38, brightness: 1),
        ],
        ink: Color(hue: 0.58, saturation: 0.55, brightness: 0.42))

    /// Number of hue buckets. 18 is a 20° bin: wide enough that a gradient
    /// isn't split across two bins, narrow enough to tell blue from cyan.
    private static let bins = 18

    /// The dark counterpart of a glow colour.
    ///
    /// Calibrated against the one value the designer specified by hand: the
    /// green-leather card's outline is 006B3B, which is h150 s1.00 b0.42. That
    /// card's dominant bin measures s 0.50, so a 1.6× boost and a fixed 0.42
    /// brightness lands on h150 s0.80 b0.42 — near enough the same green, and
    /// the same rule then gives every other card an outline in its own colour.
    private static func inkColor(hue: Double, saturation: Double) -> Color {
        Color(hue: hue, saturation: min(1, max(0.55, saturation * 1.6)), brightness: 0.42)
    }

    private static func extract(_ name: String) -> Profile? {
        guard let cg = UIImage(named: name)?.cgImage else { return nil }

        let n = 24
        var buf = [UInt8](repeating: 0, count: n * n * 4)
        let ok = buf.withUnsafeMutableBytes { raw -> Bool in
            guard let ctx = CGContext(data: raw.baseAddress, width: n, height: n,
                                      bitsPerComponent: 8, bytesPerRow: n * 4,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            else { return false }
            ctx.interpolationQuality = .medium
            ctx.draw(cg, in: CGRect(x: 0, y: 0, width: n, height: n))
            return true
        }
        guard ok else { return nil }

        var weight = [Double](repeating: 0, count: bins)
        var satSum = [Double](repeating: 0, count: bins)
        var briSum = [Double](repeating: 0, count: bins)
        var opaque = 0
        var briTotal = 0.0
        var satPeak = 0.0

        for i in stride(from: 0, to: buf.count, by: 4) {
            let a = Double(buf[i + 3]) / 255
            guard a > 0.5 else { continue }
            // Premultiplied, so undo the alpha before reading the colour.
            let r = Double(buf[i]) / 255 / a
            let g = Double(buf[i + 1]) / 255 / a
            let b = Double(buf[i + 2]) / 255 / a
            let (h, sat, bri) = hsb(min(r, 1), min(g, 1), min(b, 1))
            opaque += 1
            briTotal += bri
            satPeak = max(satPeak, sat)
            // Weighting by saturation *and* brightness keeps a card's accent
            // from being drowned out by the large dull area around it.
            let w = sat * bri
            let bin = min(bins - 1, Int(h * Double(bins)))
            weight[bin] += w
            satSum[bin] += sat * w
            briSum[bin] += bri * w
        }
        guard opaque > 0 else { return nil }

        let dominant = weight.indices.max { weight[$0] < weight[$1] } ?? 0
        let hue = (Double(dominant) + 0.5) / Double(bins)

        // Under this the card has no usable hue — metals, black leather, the
        // plain whites. A three-hue glow there would be inventing colour the
        // card does not have.
        if satPeak < 0.22 {
            // No hue worth using — the metals, the black leathers, the whites.
            // A saturated outline here would invent colour the card does not
            // have, so it gets a near-neutral dark instead.
            return Profile(glow: shades(of: hue, brightness: briTotal / Double(opaque)),
                           ink: Color(hue: hue, saturation: 0.17, brightness: 0.28))
        }

        // Pick up to three bins, each at least two bins off the ones already
        // taken, so the glow reads as distinct colours rather than one hue
        // sampled three times.
        var picked: [Int] = []
        for bin in weight.indices.sorted(by: { weight[$0] > weight[$1] }) {
            guard weight[bin] > 0 else { break }
            let apart = picked.allSatisfy { other in
                let d = abs(other - bin)
                return min(d, bins - d) >= 2
            }
            if apart { picked.append(bin) }
            if picked.count == 3 { break }
        }
        guard let first = picked.first else {
            return Profile(glow: shades(of: hue, brightness: briTotal / Double(opaque)),
                           ink: Color(hue: hue, saturation: 0.17, brightness: 0.28))
        }

        let leadHue = (Double(first) + 0.5) / Double(bins)
        let leadSat = satSum[first] / weight[first]
        let ink = inkColor(hue: leadHue, saturation: leadSat)

        if picked.count == 1 {
            return Profile(glow: shades(of: leadHue,
                                        brightness: briSum[first] / weight[first]),
                           ink: ink)
        }

        let glow = picked.map { bin -> Color in
            let s = satSum[bin] / weight[bin]
            // Forced bright and reined in on saturation: these are additive
            // layers over a dark page, and a fully saturated one clips to a
            // flat slab of colour instead of reading as light.
            return Color(hue: (Double(bin) + 0.5) / Double(bins),
                         saturation: min(0.82, max(0.34, s)),
                         brightness: 1)
        }
        return Profile(glow: glow, ink: ink)
    }

    /// One hue, three strengths — the monochrome case.
    ///
    /// The floor matters more than it looks. Black leather and brushed steel
    /// read at s 0.05–0.15, and a band of three shades that faint is a plain
    /// white glow with no travel in it at all. 0.28 is the point where the
    /// movement becomes visible while still being recognisably the card's own
    /// cast — pushed further, a silver card starts glowing lilac, which is
    /// colour it does not have.
    private static func shades(of hue: Double, brightness: Double) -> [Color] {
        let base = max(0.28, min(0.46, brightness * 0.5))
        return [
            Color(hue: hue,               saturation: base,        brightness: 1),
            Color(hue: wrap(hue + 0.055), saturation: base * 0.62, brightness: 1),
            Color(hue: wrap(hue - 0.055), saturation: base * 0.84, brightness: 1),
        ]
    }

    private static func wrap(_ h: Double) -> Double { h - floor(h) }

    private static func hsb(_ r: Double, _ g: Double, _ b: Double) -> (Double, Double, Double) {
        let mx = max(r, g, b), mn = min(r, g, b)
        let d = mx - mn
        guard d > 0.0001 else { return (0, 0, mx) }
        var h: Double
        if mx == r        { h = (g - b) / d / 6 }
        else if mx == g   { h = (2 + (b - r) / d) / 6 }
        else              { h = (4 + (r - g) / d) / 6 }
        if h < 0 { h += 1 }
        return (h, d / mx, mx)
    }

    /// Prints every skin's extracted palette, for when a glow comes out a
    /// colour the card does not obviously contain.
    ///     xcrun simctl launch --console-pty <udid> com.noon.gyroqr -palAudit
    static func audit() {
        for i in 1...SkinSelectSpec.skinCount {
            let name = String(format: "skin_%02d", i)
            func describe(_ c: Color) -> String {
                let ui = UIColor(c)
                var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
                return String(format: "h%.0f s%.2f b%.2f", h * 360, s, b)
            }
            let prof = profile(for: name)
            print("PALETTE \(name): \(prof.glow.map(describe).joined(separator: " | "))"
                  + "  ink \(describe(prof.ink))")
        }
    }
}
