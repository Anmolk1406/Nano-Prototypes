import SwiftUI

@main
struct GyroQRApp: App {
    init() {
        NoonFont.register()
        if ProcessInfo.processInfo.arguments.contains("-fontAudit") { NoonFont.audit() }
        if ProcessInfo.processInfo.arguments.contains("-palAudit") { SkinPalette.audit() }
        if ProcessInfo.processInfo.arguments.contains("-artAudit") { SkinArt.audit() }
    }

    /// Set by a screen whose top is light, for a dark status bar.
    @State private var darkStatusBar = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onPreferenceChange(DarkStatusBar.self) { darkStatusBar = $0 }
                // The status bar follows the scheme, and only the root's
                // choice counts: a screen's own `preferredColorScheme` loses
                // to this one, so screens ask through `DarkStatusBar` instead.
                .preferredColorScheme(darkStatusBar ? .light : .dark)
        }
    }
}

/// True when the screen under the status bar is light, so its glyphs should
/// go dark. Any view in the tree can set it; the app's root applies it.
struct DarkStatusBar: PreferenceKey {
    static var defaultValue = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}
