import SwiftUI

/// Geometry and copy for the account page, Figma `Account` (978:15007) — laid
/// out at the design's native 375 × 812.
///
/// Only the header is taken apart; see `Tools/build_account_layers.py`. Below
/// y 379 the page is one flat export, because nothing down there moves.
///
/// Positions are summed through the parent frames. The header's art all lives
/// in `Frame 2147242732` (978:15075), which the design hangs at y = −197, so
/// every art position here is its Figma y minus 197 — the same trick the wallet
/// page's backdrop uses, and the reason these numbers do not look like the ones
/// in the layer panel.
enum AccountSpec {
    static let size = CGSize(width: 375, height: 812)

    /// The header's own box, 978:15074. Only the top 379 of it is ever seen —
    /// the body covers the rest — so that is where the page splits.
    static let headerHeight: CGFloat = 429
    static let headerBottom: CGFloat = 379
    /// Where the header starts before it expands: the status bar plus the
    /// page header, and nothing else. It is the height the page would have if
    /// it had no profile on it, which is what makes the expansion read as the
    /// profile *arriving* rather than as a panel being resized.
    static let headerCollapsed: CGFloat = 101

    // MARK: art

    /// The backdrop, rebuilt from its recipe with nothing ever in front of it
    /// — see `Tools/build_account_layers.py`.
    static let backdrop = CGRect(x: 0, y: 0, width: 375, height: 429)
    /// The rays entrance, a dotLottie authored in After Effects
    /// (`Tools/ae/build_account_rays.jsx`), 1.5s, ending on `acct_bg`.
    static let raysAnimation = "acct_rays"

    /// `Ellipse 24643` (978:15212).
    ///
    /// Measured, not taken from the frame. The layer panel reports this ellipse
    /// at 171.46 square, and its own export comes back 439px at 3× — 146.33pt.
    /// The export wins: template-matched against the finished header it lands
    /// at 8.6/255, and 171.46 is 17% too big for the hole in the render.
    static let avatar = CGRect(x: 114.33, y: 113.67, width: 146.33, height: 146.33)

    /// The three interest stickers — the *same nodes* as the profile QR card's
    /// badges, so the same three assets. Template-matched against this header
    /// at 1.11 / 1.66 / 1.44 out of 255, which is the check that they really
    /// are the same art and not just a similar set.
    static let stickers = [
        (image: "pq_badge1", frame: CGRect(x: 125.00, y: 232.00, width: 51.33, height: 42.33)),
        (image: "pq_badge2", frame: CGRect(x: 161.33, y: 226.67, width: 49.00, height: 55.33)),
        (image: "pq_badge3", frame: CGRect(x: 198.67, y: 226.00, width: 49.67, height: 49.33)),
    ]

    /// The three props that drift in, with the direction each comes from.
    ///
    /// The resting positions are the nodes' CSS boxes, header-local (Figma y
    /// minus 197). Each prop is its own upload at its CSS transform, and
    /// composited over the rebuilt backdrop it lands on the render to within
    /// a third of a point. An earlier cut searched these positions against a
    /// *patched* backdrop instead and put the ball 4pt low — the search was
    /// fitting the patch, not the ball.
    ///
    /// The entry offsets are chosen rather than measured — the design is a
    /// still, so there is no reference for where they come *from*. Each takes
    /// the shortest line to its own nearest edge, which is what makes the three
    /// read as one gesture instead of three: the ball and the star out to the
    /// right, the bolt out to the left.
    static let props = [
        (image: "acct_ball", frame: CGRect(x: 287.51, y: 92.76, width: 57.95, height: 57.95),
         from: CGSize(width: 96, height: -34)),
        (image: "acct_star", frame: CGRect(x: 288.23, y: 263.91, width: 82.18, height: 82.18),
         from: CGSize(width: 112, height: 26)),
        (image: "acct_bolt", frame: CGRect(x: 48.36, y: 263.79, width: 42.51, height: 41.97),
         from: CGSize(width: -104, height: 14)),
    ]

    // MARK: chrome

    /// `M-PageHeader` (978:15208) at (16, 45), 343 × 56, holding a 40pt icon
    /// button at each end. Measured off the render at 19 and 316 — symmetric,
    /// 19 in from each edge, which is 3 more than the header box's own inset.
    ///
    /// Drawn natively rather than exported: the buttons are a white ring and a
    /// glyph over the backdrop, and the node's export is 8pt of shadow bleed
    /// around two *transparent* rings matted onto the purple, which would
    /// arrive as a purple slab.
    static let buttonSize: CGFloat = 40
    static let buttonY: CGFloat = 53
    static let buttonLeftX: CGFloat = 19
    static let buttonRightX: CGFloat = 316

    // MARK: type

    /// 978:15225 — `H24/Bold`, white.
    static let name = "Alex Williams"
    static let nameBox = CGRect(x: 50.5, y: 300.76, width: 274, height: 32)
    /// 978:15227 — `B14/Regular` at `on-surface-subtle`.
    static let email = "alexwilliams@gmail.com"
    static let emailBox = CGRect(x: 50.5, y: 336.76, width: 274, height: 20)

    // MARK: the rest of the page

    /// 978:15228, flat, and positioned by the header's current height rather
    /// than by a constant — being pushed down is the point.
    static let bodyHeight: CGFloat = 452
    static let bodyWidth: CGFloat = 375
    /// The page colour behind the body's cards, sampled from the export's own
    /// corner. The body image is only 452 tall; while the header is short
    /// there is screen below it that the image does not reach, and a white
    /// band there would read as a bug.
    static let pageColour = Color(hex: 0xF2F3F7)
    /// 978:15387, the same `Nav` instance every other screen uses.
    static let nav = CGRect(x: 12, y: 720, width: 351, height: 80)

    // MARK: the entrance
    //
    // One spring for everything — `interpolatingSpring(stiffness: 320,
    // damping: 28)`, the same tension and friction the wallet's entrance uses,
    // so the two pages feel like the same app. The avatar is the exception: it
    // is the one element the brief asks to *pop*, so it takes the same
    // stiffness with the friction dropped to 18, which is a damping ratio of
    // 0.50 and a visible overshoot.

    static let spring = Animation.interpolatingSpring(stiffness: 320, damping: 28)
    static let pop = Animation.interpolatingSpring(stiffness: 320, damping: 18)

    /// The header opens first, on its own, and only then does anything appear
    /// in it. A little softer than the page's spring — friction 30 against 28
    /// — because this one moves 278pt and everything else moves ten, and the
    /// same damping ratio over that distance overshoots by a visible amount.
    static let expand = Animation.interpolatingSpring(stiffness: 320, damping: 30)
    /// How long the expansion is given before the sequence starts. The spring
    /// settles in about 0.31s; starting the avatar at 0.30 lets the last of
    /// the travel and the first of the pop overlap by a frame or two, which
    /// stops the page feeling like it has stalled.
    static let expandFor: Double = 0.30

    /// How small the avatar starts. 0.62 rather than 0 — from nothing it reads
    /// as a bubble inflating, and the disc has a photo in it that wants to be
    /// legible on the way up.
    static let avatarFrom: CGFloat = 0.62
    /// The stickers come from further down, because they are small and a pop
    /// from 0.62 barely registers at 50pt.
    static let stickerFrom: CGFloat = 0.3

    /// Seconds each element waits before it starts. Written out rather than
    /// derived from an index: the three groups do not want an even cadence —
    /// the stickers land almost together on the avatar, and the props are a
    /// separate beat behind them.
    static let delay = (
        avatar: 0.00,
        stickers: [0.10, 0.155, 0.21],
        props: [0.26, 0.30, 0.34],
        name: 0.20,
        email: 0.25
    )
}
