import SwiftUI
import CoreText

/// noon's brand face, Noontree.
///
/// The supplied folder is a webfont-style export: each weight ships as its own
/// *family* (`Noontree SemiBold`, `Noontree ExtraBold`, …) rather than as one
/// family with seven styles. Only Regular and Bold share the `Noontree` family
/// name. That means asking for a weight — `.custom("Noontree", size:).weight(.semibold)`
/// — silently renders Regular, and the mistake is easy to miss because the text
/// still looks like Noontree. Every weight is therefore addressed by its
/// PostScript name instead.
enum NoonFont {

    enum Weight: String, CaseIterable {
        case light     = "Noontree-Light"
        case regular   = "Noontree-Regular"
        case medium    = "Noontree-Medium"
        case semibold  = "Noontree-SemiBold"
        case bold      = "Noontree-Bold"
        case extrabold = "Noontree-ExtraBold"
        case black     = "Noontree-Black"
    }

    /// Registered at launch rather than declared in `UIAppFonts`, because the
    /// Info.plist here is generated (`GENERATE_INFOPLIST_FILE = YES`) and an
    /// array key has no `INFOPLIST_KEY_*` equivalent.
    ///
    /// Fonts that fail to register do not raise anything — `Font.custom` just
    /// falls through to the system face — so the count is logged and asserted.
    @discardableResult
    static func register() -> Int {
        var loaded = 0
        for weight in Weight.allCases {
            guard let url = Bundle.main.url(forResource: weight.rawValue, withExtension: "otf") else {
                print("NoonFont: \(weight.rawValue).otf missing from the bundle")
                continue
            }
            if CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil) {
                loaded += 1
            } else {
                print("NoonFont: \(weight.rawValue) failed to register")
            }
        }
        assert(loaded == Weight.allCases.count, "Noontree did not fully register")
        return loaded
    }

    /// `fixedSize`, not `size`: the design specifies exact point sizes and this
    /// is a motion prototype being compared against Figma frames, so Dynamic
    /// Type scaling would only make the comparison lie.
    static func f(_ weight: Weight, _ size: CGFloat) -> Font {
        .custom(weight.rawValue, fixedSize: size)
    }

    /// Prints what CoreText actually has, for when type looks like the system
    /// face and you need to know whether registration or naming is at fault.
    static func audit() {
        for weight in Weight.allCases {
            let f = UIFont(name: weight.rawValue, size: 17)
            print("NoonFont \(weight.rawValue) -> \(f?.fontName ?? "MISSING (system fallback)")")
        }
    }
}
