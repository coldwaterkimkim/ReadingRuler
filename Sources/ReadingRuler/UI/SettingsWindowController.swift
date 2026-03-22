import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController {
    private let appState: AppState
    private var window: NSWindow?

    init(appState: AppState) {
        self.appState = appState
    }

    func showWindow() {
        if window == nil {
            window = buildWindow()
        }

        guard let window else { return }

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    private func buildWindow() -> NSWindow {
        let contentView = SettingsView(appState: appState)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 860),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "\(AppLabels.combinedName) Settings"
        window.center()
        window.contentView = NSHostingView(rootView: contentView)
        window.isReleasedWhenClosed = false

        return window
    }
}
