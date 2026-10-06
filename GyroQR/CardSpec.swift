import SwiftUI

/// One card design: its geometry, the colour behind it, and the parallax planes
/// it is built from.
///
/// This was a bag of statics for the single `779:22089` card. It is a value now
/// because there are two cards, and they want the *same* motion — the depth
/// model, the light, the shadows and the wobble all live in `GyroCardView` and
/// neither card knows anything about them. A card is only its planes and where
/// they sit.
struct CardSpec {
    /// For the controls sheet and for `-cardStyle`.
    let name: String
    var size: CGSize
    var corner: CGFloat
    var border: CGFloat
    /// Painted behind every plane, so the sliver the plate's drift exposes at
    /// the card's edge is the card's own colour and not the page.
    var base: Color
    var layers: [Layer]
    /// How dark a shadow the whole card casts. The invite card's chrome frame
    /// is drawn with its own glow and wants far less than a flat slab does.
    var shadowStrength: Double = 0.22
    /// An image whose alpha is the card's own coverage, used to clip the sheen
    /// and the iridescence to the card's *shape*.
    ///
    /// Only needed when the artwork does not fill its box. `corner` is enough
    /// for a card that is a rounded rectangle — the profile card's plate fills
    /// its 32pt-radius box, so the clip does the job. The invite card is a
    /// moulded object with rounded corners well inside its box, and there the
    /// light bands were painting onto nothing: a pale rectangle sitting at the
    /// card's rest position while the card itself rotated away from it.
    var lightMask: String? = nil
    /// Text kept native rather than rasterised, so it stays crisp — but
    /// parallaxed and shadowed like any other plane.
    var texts: [TextPlane] = []
    /// The new card's close button, drawn as its own plane.
    var closeDisc: Disc? = nil

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

    /// Native text on the card, at its own elevation.
    struct TextPlane: Identifiable {
        let id: String
        var frame: CGRect
        var elevation: CGFloat
        var lines: [String]
        var font: Font
        var color: Color
        /// Overrides `color` when the design fills the type with a gradient.
        var style: AnyShapeStyle? = nil
        var tracking: CGFloat = 0
        var lineSpacing: CGFloat = 0
        /// Draws the invite card's white panel behind the lines.
        var panel = false
        var wobble: Double = 0
        var shadowOpacity: Double = 0
        var shadowRadius: CGFloat = 0
    }

    /// A white disc with a dark glyph — the profile card's close button.
    struct Disc {
        var frame: CGRect
        var elevation: CGFloat
        var glyph: String
        var glyphSize: CGFloat
        var shadowOpacity: Double = 0.18
        var shadowRadius: CGFloat = 8
    }
}

// MARK: - the invite card, Figma 980:15528

extension CardSpec {
    /// The chrome-framed invite card from `1 Child details` (980:15528).
    ///
    /// A redesign, and a different *kind* of card from the one it replaces. The
    /// old invite card was a flat magenta panel with a QR floating over it and
    /// mascots bleeding off its edges; this one is a single moulded chrome
    /// object with the QR recessed into it. So the depth model inverts: the
    /// panel sits *below* the frame's surface rather than the QR sitting above
    /// the card, and the only plane with positive elevation is the ink.
    ///
    /// Every number here is card-local, the card being the frame's own box at
    /// screen (42.67, 197). The planes are cut by
    /// `Tools/build_invite_layers.py`.
    static let invite = CardSpec(
        name: "Invite",
        size: CGSize(width: 290, height: 409.19),
        // The chrome frame carries its own shape, its own rounding and its own
        // glow, so the card has no geometry of its own to draw: no corner, no
        // border, nothing behind. Setting a corner here would clip the glow.
        corner: 0,
        border: 0,
        base: .clear,
        layers: inviteLayers,
        // A tenth of what a flat card casts. The frame is already drawn with a
        // soft halo around it, and the usual 0.22 stacks a second, harder
        // shadow under the first.
        shadowStrength: 0.10,
        lightMask: "inv_card_mask",
        texts: [
            // 980:15976 — `H28/Bold`, filled with a horizontal ramp from black
            // to #4C17A0 starting at 15.4%. Native rather than part of the
            // frame's artwork so it stays crisp, and on its own plane so it
            // lifts off the chrome as the card turns.
            TextPlane(id: "name",
                      frame: CGRect(x: 20.53, y: 305.13, width: 246.6, height: 36),
                      elevation: 3,
                      lines: [ScreenSpec.inviteName],
                      font: NoonFont.f(.bold, 28),
                      color: .black,
                      style: AnyShapeStyle(
                          LinearGradient(stops: [.init(color: .black, location: 0.154),
                                                 .init(color: Color(hex: 0x4C17A0), location: 1)],
                                         startPoint: .leading, endPoint: .trailing)),
                      tracking: -0.25,
                      wobble: 0.1),
        ])

    /// Experimental, for the shine lab only: the same card with the holo base
    /// in place of the chrome frame. The base is its own coverage, so it is
    /// also the light mask; its 1055 × 1491 artwork is 409.85 tall at the
    /// card's width, 0.7pt more than the chrome frame's box.
    static let inviteHolo: CardSpec = {
        var c = CardSpec.invite
        c.layers[0].image = "slab_base"
        c.layers[0].frame.size.height = 290 * 1491 / 1055
        c.lightMask = "slab_base"
        // The chrome frame drew its own halo; the holo base has none, so the
        // card casts a little more of its own.
        c.shadowStrength = 0.16
        return c
    }()

    /// Back to front, and shallower than the old card's stack — this is one
    /// moulded object rather than a panel with things floating over it, so the
    /// whole range is 10pt instead of 28.
    private static let inviteLayers: [Layer] = [
        // 980:15537. The card itself: the chrome bezel and the plate it is
        // moulded from, with the name and the recessed panel absent.
        Layer(id: "frame", image: "inv_frame",
              frame: CGRect(x: 0, y: 0, width: 290, height: 409.19),
              elevation: 0, debugTint: .gray),

        // 980:15538. Recessed, so it drifts *against* the tilt — which is what
        // sells the frame as having depth rather than being printed on.
        Layer(id: "panel", image: "inv_panel",
              frame: CGRect(x: 39.33, y: 42.19, width: 212, height: 244),
              elevation: -3, debugTint: .indigo),

        // 980:15539. The modules and the nano badge, ink on the panel and the
        // only thing above the surface.
        Layer(id: "qr", image: "inv_qr",
              frame: CGRect(x: 61.50, y: 77.43, width: 172, height: 173),
              elevation: 7, wobble: 0.2,
              shadowOpacity: 0.12, shadowRadius: 6, shadowRest: 2, debugTint: .blue),
    ]
}

// MARK: - the profile card, Figma 940:63003

extension CardSpec {
    /// `Share QR` (940:62757), whose card is `940:63003` — 351 × 656.
    ///
    /// Same motion, different content: a starburst backdrop, a portrait at the
    /// star's origin, three interest stickers hanging off it, and a QR drawn as
    /// ink straight onto the card rather than on a white panel.
    ///
    /// Every plane is one Figma node, exported on its own and cut to its own
    /// alpha by `Tools/build_profile_layers.py`. That is not bookkeeping: a
    /// plane whose matte is a rectangle carries a slab of the backdrop with it,
    /// and the moment the card tilts that slab slides across the plate and
    /// draws a hard edge with nothing casting it. The badges used to live
    /// inside the portrait's rectangle for exactly that reason, and that
    /// rectangle is what showed.
    ///
    /// Positions come from `get_metadata`, summed through the parent frames —
    /// not measured off the render. The one number worth double-checking is the
    /// close button, where the frame reports the page header's 56pt height
    /// rather than the 40pt disc inside it.
    ///
    /// The elevations follow the invite card's fitted values so the two read as
    /// the same effect: the hero planes at 20, the name at 13, the backdrop
    /// below the surface at -8.
    static let profile = CardSpec(
        name: "Profile",
        size: CGSize(width: 351, height: 656),
        corner: 32,
        border: 4,
        // The gradient's own top colour, for the edge sliver.
        base: Color(red: 0.584, green: 0.365, blue: 1.0),
        layers: [
            // The starburst, whole. Figma renders `940:63004` — the backdrop
            // image — clipped to the card and with everything above it absent,
            // so this plane is the real artwork rather than a reconstruction
            // of one: the rays that show under the portrait and between the
            // QR's modules are the rays the design draws there.
            //
            // 8pt of baked bleed, not `scale`. A scale is anchored at the
            // card's centre, and on a 656pt card that displaces the top of the
            // plate by several points — which is what used to leave a pale
            // crescent above the avatar.
            Layer(id: "plate", image: "pq_plate",
                  frame: CGRect(x: -8, y: -8, width: 367, height: 672),
                  elevation: -8, debugTint: .gray),

            // `Ellipse 24643` (940:63104): 140pt across with a 2pt white
            // stroke outside it, so the plane is a 144pt disc and its matte is
            // that circle exactly. Nothing about this shape is measured off
            // the pixels — every attempt to find it there came back with the
            // pale halo attached, because the halo is artwork and no threshold
            // separates a soft ring from the soft backdrop behind it.
            //
            // Barely any shadow. The design draws none — the disc sits flush
            // on the starburst — and a shadow cast from a crisp circle, offset
            // by the parallax, reads as a hard crescent ringing the portrait
            // rather than as contact. The parallax carries the depth on its
            // own; Controls ▸ Contact shadow scales what is left.
            Layer(id: "portrait", image: "pq_portrait",
                  frame: CGRect(x: 103.5, y: 82, width: 144, height: 144),
                  elevation: 20, wobble: 0.28,
                  shadowOpacity: 0.09, shadowRadius: 7, shadowRest: 3,
                  debugTint: .teal),

            // The three interest stickers, `940:63587/63590/63593`, each its
            // own plane because each is its own node. They used to be inside
            // the portrait's rectangle, which is what drew a box-shaped edge
            // under them the moment the card turned.
            //
            // At the portrait's elevation, not above it: they hang off the
            // disc's lower edge and belong to it, and any difference in
            // elevation slides them off it as the card tilts. Their own drop
            // shadows are baked into the artwork, so they cast none at
            // runtime.
            Layer(id: "badge1", image: "pq_badge1",
                  frame: CGRect(x: 113.67, y: 202, width: 51.33, height: 42.33),
                  elevation: 20, wobble: 0.28, debugTint: .mint),
            Layer(id: "badge2", image: "pq_badge2",
                  frame: CGRect(x: 150, y: 196.67, width: 49, height: 55.33),
                  elevation: 20, wobble: 0.28, debugTint: .mint),
            Layer(id: "badge3", image: "pq_badge3",
                  frame: CGRect(x: 187.33, y: 196, width: 49.67, height: 49.33),
                  elevation: 20, wobble: 0.28, debugTint: .mint),

            // The QR, as a white matte of its own ink rather than a panel: on
            // this card the modules are printed straight on the backdrop and
            // the rays show between them. The frame is the module grid itself
            // (`Clip path group`, inset 24pt inside the 280pt node), which is
            // also what the builder measures back out of the pixels — the two
            // agreeing to the point is the check that the matte is aligned.
            //
            // Its shadow is per-module, which at the invite card's strength
            // pooled into a grey haze behind the whole code, so it is only
            // enough to lift the modules off the surface.
            Layer(id: "qr", image: "pq_qr",
                  frame: CGRect(x: 59.5, y: 311.67, width: 232.33, height: 232),
                  elevation: 20, wobble: 0.28,
                  shadowOpacity: 0.10, shadowRadius: 6, shadowRest: 3,
                  debugTint: .blue),
        ],
        texts: [
            TextPlane(id: "name",
                      frame: CGRect(x: 38.5, y: 248, width: 274, height: 32),
                      elevation: 13,
                      lines: ["Alex Williams"],
                      font: NoonFont.f(.bold, 24),
                      color: .white,
                      tracking: -0.3,
                      wobble: 0.15,
                      shadowOpacity: 0.22, shadowRadius: 8),
            TextPlane(id: "caption",
                      frame: CGRect(x: 47, y: 576, width: 257, height: 44),
                      elevation: 0,
                      lines: ["Share your profile QR, make friends,",
                              "shop together!"],
                      font: NoonFont.f(.medium, 14),
                      color: .white.opacity(0.95),
                      tracking: -0.1,
                      lineSpacing: 20 - 14 * 1.2),
        ],
        closeDisc: Disc(frame: CGRect(x: 283, y: 26, width: 40, height: 40),
                        elevation: 6,
                        glyph: "xmark",
                        glyphSize: 15))
}
