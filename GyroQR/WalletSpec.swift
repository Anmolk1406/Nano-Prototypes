import SwiftUI

/// The wallet page, Figma `Wallet Page` (935:61643) and its receipt state
/// (935:61752) — laid out at the design's native 375 × 812.
///
/// Every art layer here is an export of one node, and the placements are the
/// frame's own numbers except where noted. The sparkle is the exception: the
/// frame reports its box at x 359, which is off the right edge of a 375 screen,
/// while the render clearly puts it at 304 — so that one is measured off the
/// rendered frame instead, which is the only ground truth that matters.
enum WalletSpec {
    static let size = CGSize(width: 375, height: 812)

    // MARK: art
    //
    // The card and the page behind it are *the same pair of assets the skin
    // picker uses*, not wallet-specific exports. The two exports this page
    // used to carry measured within 0.4/255 of `skin_17` and 0.3/255 of
    // `bg_17` — they were always that skin, and the design simply shipped the
    // one the mock happened to be wearing, so both have been deleted. Reading
    // them from the skin number instead means the wallet shows whichever card
    // the user has on, with its own background, which is the thing the
    // bloom's colours were always meant to be matched against.

    /// The design's own skin. Everything on this page defaults to it.
    static let defaultSkin = 17

    static func cardArt(_ skin: Int) -> String { String(format: "skin_%02d", skin) }
    static func backdropArt(_ skin: Int) -> String { String(format: "bg_%02d", skin) }

    /// 935:61644. Taller than the screen and hung above it, which is what the
    /// frame does — only y 0…506 of it is ever visible.
    static let backdrop = CGRect(x: 0, y: -117, width: 376, height: 623)
    /// 962:66754 — the same image, zoomed.
    ///
    /// The empty page needs purple a further 257pt down, because its pocket
    /// sits that much lower, and the design gets it by drawing the backdrop
    /// 1.394× larger from the same top edge rather than by stretching it:
    /// 524 / 376 and 869 / 623 are the same number. Keeping both rectangles
    /// means the fill transition is a slow zoom out of the background, which
    /// is what the design implies and cost nothing to honour.
    static let backdropEmpty = CGRect(x: -74, y: -117, width: 524, height: 869)
    /// 935:61645 — the `nano` wallet, as the frame boxes it.
    static let card = CGRect(x: 51, y: 66, width: 273, height: 182)
    /// Where the card's *artwork* lands inside that box.
    ///
    /// Not the same rectangle. The export carries about 5.5pt of shadow bleed
    /// on every side, and the frame squeezes it: 819 × 579 drawn into
    /// 273 × 182 is 0.333 across and 0.314 down, so the design's own card is
    /// 5.7% shorter than the artwork it is made of. Measured back out, the
    /// body sits here.
    ///
    /// The skins are drawn to this rectangle's *width* at their own aspect
    /// rather than stretched to fill it. The 22 renders run from 1.467 to
    /// 1.644 and the design's squashed box is 1.712, so filling it would take
    /// 16% out of the height of the widest ones — visible on the plush and
    /// lego cards in a way the 5.7% on this one never was.
    static let cardBody = CGRect(x: 54, y: 77.32, width: 266.33, height: 155.6)
    /// 935:61651.
    static let mascot = CGRect(x: 10, y: 150, width: 81, height: 81)
    /// 935:61650. Measured off the render, and deliberately not square: the
    /// design squeezes a square source to 44 × 66, so the art is stretched
    /// rather than fitted.
    static let sparkle = CGRect(x: 304, y: 42, width: 44, height: 66)

    // MARK: header

    static let owner = "KIAAN'S WALLET"
    /// `Savings summary` (935:61646) at y 260: the label's box, then the
    /// balance 22 below it.
    static let ownerY: CGFloat = 260
    static let balanceY: CGFloat = 282
    /// `font/body/b11`, and the tracking is the design's own 2.2 — not a
    /// guess at "a bit of letterspacing", which is what 1.6 was.
    static let ownerTracking: CGFloat = 2.2
    /// 935:61649 — `M-NeutralRoundButton`.
    static let requestButton = CGRect(x: 116.5, y: 342, width: 142, height: 40)
    static let requestTitle = "Request top up"

    // MARK: the cut
    //
    // The white shape is the *same* geometry as the wallet pocket the skin
    // picker drops a card into — Figma `Subtract` (915:61054), the same path
    // and the same shadow filter (dy -8, blur 12, black at 12%). So it is drawn
    // with `PocketShape` rather than traced twice.

    /// Where the shape's crest sits, measured off the render.
    static let cutCrest: CGFloat = 365
    /// And where it sits once the receipt has pushed in — the frame moves it up
    /// by 7 to make room.
    static let cutCrestWithReceipt: CGFloat = 358
    static let cutWidth: CGFloat = 376
    static let cutX: CGFloat = -0.5
    static let cutShadow = (color: Color.black.opacity(0.12), radius: 12.0, y: -8.0)

    // MARK: the list, and the receipt that pushes it down

    /// 935:61653, clipped to the frame — the list runs off the bottom.
    static let transactions = CGRect(x: 12, y: 422, width: 351, height: 390)
    /// 935:61763 — where the same list sits once the receipt is in.
    static let transactionsWithReceipt: CGFloat = 518

    /// 935:61862. The export carries the notch that points up at the button, so
    /// the image is 10pt taller than the 70pt card and hangs that much above it.
    static let receipt = CGRect(x: 12, y: 413, width: 351, height: 80)
    static let receiptNotch: CGFloat = 10

    /// 935:61749.
    static let nav = CGRect(x: 12, y: 720, width: 351, height: 80)

    /// The balance the page opens on.
    ///
    /// Zero. The flow starts on the empty state now — there is nothing in the
    /// wallet and no history to show — and the first top-up is what fills
    /// both. 10.56 was the filled frame's own number and is kept as the
    /// *seed* of the list, below.
    static let openingBalance: Double = 0

    // MARK: the empty state
    //
    // `Wallet Page` 962:66753. Same page, nothing in it: the art drops 93pt to
    // make room for a headline and a line of help, the balance reads dhm 0,
    // the pocket is empty and sits 257pt lower, and the button moves down with
    // everything else.

    enum Empty {
        /// The whole art block — card, mascot, sparkle — moves down together.
        static let artDrop: CGFloat = 93
        static let balanceY: CGFloat = 405
        /// 962:66760, `H28/Bold`.
        static let titleY: CGFloat = 469
        static let title = "Your wallet is empty"
        /// 962:66761, `B14/Regular` at `on-surface-subtle`.
        static let subtitleY: CGFloat = 513
        static let subtitle = "Ask your parent to top up your wallet first."
        static let buttonY: CGFloat = 597
        /// The instance box is at 619; the crest sits 3 below it, the same
        /// offset the filled state's 362/365 pair has.
        static let cutCrest: CGFloat = 622
    }

    // MARK: the list
    //
    // The transaction list is one export of eight rows (935:61653). On the
    // empty state there is nothing to show, and the first top-up is what
    // brings it in — so the page has a third state between "empty" and
    // "filled": receipt in, list arriving under it.

    /// How far the list slides up into place as it arrives.
    static let listRise: CGFloat = 22

    // MARK: the entrance

    /// How hard the card is keystoned when it arrives.
    ///
    /// The fractional magnification at its top edge — the bottom is reduced
    /// by the same amount. Measured on the build rather than taken from the
    /// algebra, because SwiftUI's projection does not land where the matrix
    /// says: 0.087 renders a width ratio of 0.888, which is what the
    /// reference's first clean frames measure (0.890).
    static let entryKeystone: Double = 0.087
}
