import SwiftUI

/// The QR shine lab — experimental, not in any flow.
///
/// Everything here is in the artwork's own pixels: the base and the shines
/// are two 1055 × 1491 layers that line up, so a shine's place on the base
/// is simply where it was drawn. The view scales the lot to the card's width.
enum ShineLabSpec {
    static let canvas = CGSize(width: 1055, height: 1491)

    /// The base's straight edges, between its rounded corners (outer radius
    /// ~130px): the stretch each shine is allowed to run along.
    static let spanX: ClosedRange<CGFloat> = 184...870
    static let spanY: ClosedRange<CGFloat> = 190...1280
    /// How close a shine's core may come to the end of its edge.
    static let coreMargin: CGFloat = 24

    enum Edge { case top, bottom, left, right, corner }

    /// The rim's two bevel highlights — the bright lines a shine rides. Found
    /// as the two brightness ridges across each side of the base, averaged
    /// over its straight run: the outer one just in from the silhouette, the
    /// inner one just outside the dark line round the panel.
    enum Track { case outer, inner }

    static func line(_ edge: Edge, _ track: Track) -> CGFloat {
        switch (edge, track) {
        case (.left, .outer):   62
        case (.left, .inner):   101
        case (.right, .outer):  992
        case (.right, .inner):  953
        case (.top, .outer):    65
        case (.top, .inner):    104
        case (.bottom, .outer): 1403
        case (.bottom, .inner): 1358
        case (.corner, _):      0
        }
    }

    /// The corner star, set on the inner bevel's arc at 45°: its corner's
    /// centre is (180, 186) and the inner line runs 79px out from it.
    static let cornerCore = CGPoint(x: 124, y: 130)

    /// The rim's band on each side, where light may fall: out past the
    /// silhouette for the outer halo, and in only as far as the panel's edge
    /// (112px) plus a 60px fade, so no shine glows out over the panel.
    static func band(_ edge: Edge) -> (solid: ClosedRange<CGFloat>, fade: CGFloat) {
        switch edge {
        case .left, .top:     (0...118, 60)
        case .right:          (937...canvas.width, 60)
        case .bottom:         (1344...canvas.height, 60)
        case .corner:         (0...0, 0)
        }
    }

    struct Shine: Identifiable {
        let image: String
        let edge: Edge
        var track: Track = .outer
        /// The bright centre, which is what is kept on the edge.
        let core: CGPoint
        /// Where the cut-out sprite sits on the canvas.
        let frame: CGRect
        var id: String { image }
    }

    /// Tracks alternate inner, outer along each side, so every side carries
    /// both bevels and no two neighbours share a line.
    ///
    /// Cut out of the designer's shines layer. Each pixel is shared between
    /// the cores by a soft partition, measured 2.5× shorter along a star's
    /// edge than across it so the long streaks stay with their star; then
    /// each sprite is faded out on a cosine window — along its edge by the
    /// time it is most of the way to its neighbour, across it 55–105px from
    /// its core, and to nothing round every other star's core.
    ///
    /// The windows are what keep the stars clean in motion. A partition alone
    /// rebuilds the layer exactly at rest, but its boundaries are edges in
    /// each sprite's glow; slide two neighbours apart, or onto different
    /// bevels, and those edges stop meeting and show as a hard band. Windowed,
    /// every sprite reaches zero before its own border, so there is no edge
    /// to show — at the cost of the faintest streak tails between stars.
    static let shines: [Shine] = [
        Shine(image: "slab_shine_01", edge: .top, track: .outer, core: CGPoint(x: 327, y: 83),
              frame: CGRect(x: 162, y: 0, width: 369, height: 170)),
        Shine(image: "slab_shine_02", edge: .top, track: .inner, core: CGPoint(x: 773, y: 84),
              frame: CGRect(x: 579, y: 0, width: 382, height: 170)),
        Shine(image: "slab_shine_03", edge: .corner, track: .inner, core: CGPoint(x: 117, y: 116),
              frame: CGRect(x: 52, y: 52, width: 142, height: 142)),
        Shine(image: "slab_shine_04", edge: .left, track: .outer, core: CGPoint(x: 84, y: 304),
              frame: CGRect(x: 7, y: 162, width: 155, height: 309)),
        Shine(image: "slab_shine_05", edge: .left, track: .inner, core: CGPoint(x: 65, y: 541),
              frame: CGRect(x: 0, y: 380, width: 136, height: 312)),
        Shine(image: "slab_shine_06", edge: .left, track: .outer, core: CGPoint(x: 79, y: 748),
              frame: CGRect(x: 11, y: 598, width: 137, height: 303)),
        Shine(image: "slab_shine_07", edge: .left, track: .inner, core: CGPoint(x: 83, y: 1068),
              frame: CGRect(x: 3, y: 877, width: 159, height: 384)),
        Shine(image: "slab_shine_08", edge: .right, track: .inner, core: CGPoint(x: 971, y: 340),
              frame: CGRect(x: 896, y: 166, width: 149, height: 384)),
        Shine(image: "slab_shine_09", edge: .right, track: .outer, core: CGPoint(x: 974, y: 662),
              frame: CGRect(x: 894, y: 460, width: 161, height: 413)),
        Shine(image: "slab_shine_10", edge: .right, track: .inner, core: CGPoint(x: 981, y: 968),
              frame: CGRect(x: 908, y: 758, width: 147, height: 416)),
        Shine(image: "slab_shine_11", edge: .bottom, track: .inner, core: CGPoint(x: 338, y: 1400),
              frame: CGRect(x: 141, y: 1309, width: 400, height: 180)),
        Shine(image: "slab_shine_12", edge: .bottom, track: .outer, core: CGPoint(x: 742, y: 1400),
              frame: CGRect(x: 540, y: 1316, width: 403, height: 170)),
    ]
}
