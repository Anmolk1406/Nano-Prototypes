import SwiftUI

@main
struct GyroQRApp: App {
    init() {
        NoonFont.register()
        if ProcessInfo.processInfo.arguments.contains("-fontAudit") { NoonFont.audit() }
        if ProcessInfo.processInfo.arguments.contains("-palAudit") { SkinPalette.audit() }
        if ProcessInfo.processInfo.arguments.contains("-artAudit") { SkinArt.audit() }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}
