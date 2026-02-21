import SwiftUI
import AppKit

@main
struct MouserinoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var eventManager = MouseEventManager()

    init() {
        // SPM App executable workaround to force .lproj bundle resolution
        if let languageCode = Locale.current.language.languageCode?.identifier {
            UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(eventManager)
                .frame(minWidth: 760, minHeight: 640)
        }
        .defaultSize(width: 860, height: 700)
        .windowResizability(.contentSize)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApplication.shared.windows.first?.makeKeyAndOrderFront(nil)
        }
    }
}
