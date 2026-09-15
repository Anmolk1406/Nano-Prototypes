import SwiftUI

/// Geometry lifted 1:1 from the Figma node `779:22089` ("QR" card, 351 × 450).
///
/// Positions are card-local points measured from the card's outer edge. Note
/// that `get_design_context` reports CSS offsets against the *padding* box —
/// inside the 4pt white border — so every node position here is its Figma
/// offset plus (4, 4).
enum CardSpec {
    static let size = CGSize(width: 351, height: 450)
    static let corner: CGFloat = 32
    static let border: CGFloat = 4

    /// One parallax plane of the card.
    struct Layer: Identifiable {
        let id: String
        var image: String
        /// Card-local frame, points.
        var frame: CGRect
        /// Height above the card surface, in points. This is the whole depth
        /// model: a layer at elevation `h` shifts by `h · tan(tilt)` when the
        /// card turns, which is exactly what makes it read as floating.
        var elevation: CGFloat
        /// Drawn outside the card's clip, so it can overhang the edge.
        var floats = false
        /// Gaussian blur baked into the Figma layer, in points. Driven by the
        /// left/right tilt at runtime rather than applied statically — at this
        /// size a constant blur just turns the mascots to mush.
        var blur: CGFloat = 0
        var opacity: Double = 1
        /// Static rotation from Figma, degrees clockwise.
        var rotation: Double = 0
        /// Extra degrees of counter-rotation per unit of tilt.
        var wobble: Double = 0
        /// Contact shadow cast onto whatever is beneath.
        var shadowOpacity: Double = 0
        var shadowRadius: CGFloat = 0
        var shadowRest: CGFloat = 0      // resting downward offset
        /// Static oversize, so a layer that drifts never exposes its own edge.
        var scale: CGFloat = 1
        var anchor: UnitPoint = .center
        var debugTint: Color = .green
    }

    /// The caption panel (Figma 779:22701) is a sibling of the card on the
    /// screen, but it sits visually *on* the card — so it belongs to the card's
    /// transform, or it stays bolt upright while the card turns under it.
    /// Card-local frame = screen frame minus the card's origin.
    ///
    /// Elevation 0: it is printed on the card surface, so it shares the card's
    /// plane exactly and shows no parallax against it.
    static let captionFrame = CGRect(x: 30, y: 343.026, width: 297, height: 70)
    static let captionElevation: CGFloat = 0

    /// Back to front. Elevation is the thing worth playing with.
    ///
    /// Values are calibrated against the reference clip, where the floating QR
    /// panel travels ±17pt horizontally and ±21pt vertically against its card
    /// at roughly 25° of tilt — about 5% of the card on each axis. Elevations
    /// here were then fitted by measuring this app's own output with the same
    /// segmentation and matching those amplitudes; perspective projection
    /// amplifies the raw `h·tan θ` shift, so the fitted numbers land lower than
    /// the naive calculation suggests.
    static let layers: [Layer] = [
        // Background plate: the whole card art with the moving pieces
        // inpainted out. Sits *below* the surface so it drifts against the
        // tilt. Oversized so that drift never reveals an edge.
        Layer(id: "plate", image: "plate",
              frame: CGRect(x: 0, y: 0, width: 351, height: 450),
              elevation: -8, scale: 1.10, debugTint: .gray),

        // The magenta wash in the top-right corner.
        Layer(id: "blob", image: "blob",
              frame: CGRect(x: 0, y: 0, width: 351, height: 450),
              elevation: -3, scale: 1.08, anchor: .topTrailing, debugTint: .pink),

        // Figma 779:22209 — blur 5.583, opacity 30%.
        Layer(id: "grin", image: "mascot_grin",
              frame: CGRect(x: 305.77, y: 270.91, width: 72.369, height: 72.369),
              elevation: 7, blur: 5.583, opacity: 0.30, wobble: 1.0, debugTint: .purple),

        // Figma 779:22207 — 35.049pt square, rotated -43.54°, centred in a
        // 49.551pt box. Bleeds off the left edge by design, so it stays clipped.
        Layer(id: "fuzzy", image: "mascot_fuzzy",
              frame: CGRect(x: -10.529, y: 281.631, width: 35.049, height: 35.049),
              elevation: 9, rotation: -43.54, wobble: 1.4, debugTint: .indigo),

        // Figma 779:22208 — blur 4.254.
        Layer(id: "baseball", image: "mascot_baseball",
              frame: CGRect(x: 30.27, y: 61.26, width: 38.446, height: 37.959),
              elevation: 11, blur: 4.254, wobble: 1.8, debugTint: .yellow),

        // Figma 779:22213 — "Kiaan Khalid", extracted as an alpha matte so the
        // original Noontree Bold shapes survive.
        // Tight ink bounds, reported by Tools/build_layers.py.
        Layer(id: "name", image: "name",
              frame: CGRect(x: 106.667, y: 84.333, width: 138.333, height: 26),
              elevation: 13, floats: true, wobble: 0.15, debugTint: .orange),

        // Figma 779:22216 — the QR panel, 16.85pt corner radius. The hero: the
        // highest plane, unclipped, and the only layer with a real shadow.
        Layer(id: "qr", image: "qr_panel",
              frame: CGRect(x: 77.21, y: 125, width: 196.577, height: 196.577),
              elevation: 20, floats: true, wobble: 0.28,
              shadowOpacity: 0.26, shadowRadius: 14, shadowRest: 7, debugTint: .blue),

        // Figma 779:22688 — the profile picture. A screen-level sibling in the
        // design, but it reads as floating off the card, so it rides the card's
        // transform at the QR panel's elevation. Its card-local frame puts it
        // above the card's top edge — hence `floats`, so it is drawn outside
        // the clip and overhangs as designed.
        Layer(id: "avatar", image: "avatar",
              frame: CGRect(x: 119.253, y: -57.475, width: 112.4956, height: 112.4956),
              elevation: 20, floats: true, wobble: 0.28,
              shadowOpacity: 0.20, shadowRadius: 12, shadowRest: 6, debugTint: .teal),
    ]
}
