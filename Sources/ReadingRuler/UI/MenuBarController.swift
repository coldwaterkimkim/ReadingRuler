import AppKit
import Combine

@MainActor
final class MenuBarController: NSObject {
    private unowned let appState: AppState

    var onOpenSettings: (() -> Void)?

    private var statusItem: NSStatusItem?
    private var cancellables: Set<AnyCancellable> = []

    init(appState: AppState) {
        self.appState = appState
        super.init()

        bindState()
        syncStatusItemVisibility()
    }

    private func bindState() {
        appState.$settings
            .sink { [weak self] _ in
                self?.syncStatusItemVisibility()
                self?.refreshMenuAndIcon()
            }
            .store(in: &cancellables)

        appState.$rulerVisible
            .sink { [weak self] _ in self?.refreshMenuAndIcon() }
            .store(in: &cancellables)
    }

    private func syncStatusItemVisibility() {
        if appState.settings.hideMenuBarIcon {
            if let statusItem {
                NSStatusBar.system.removeStatusItem(statusItem)
                self.statusItem = nil
            }
            return
        }

        if statusItem == nil {
            let newItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            statusItem = newItem
        }

        refreshMenuAndIcon()
    }

    private func refreshMenuAndIcon() {
        guard let statusItem else { return }
        statusItem.menu = buildMenu()

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: iconName(), accessibilityDescription: AppLabels.combinedName)
            button.image?.isTemplate = true
            button.toolTip = "\(AppLabels.combinedName): \(appState.rulerVisible ? "Ruler On" : "Ruler Off")"
        }
    }

    private func iconName() -> String {
        if appState.rulerVisible {
            return "text.alignleft"
        }
        return "line.3.horizontal.decrease.circle"
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let rulerTitle = appState.settings.stickyEnabled ? "Turn Ruler Sticky Off" : "Turn Ruler Sticky On"
        let rulerItem = NSMenuItem(title: rulerTitle, action: #selector(toggleStickyRuler), keyEquivalent: "")
        rulerItem.target = self
        menu.addItem(rulerItem)

        menu.addItem(.separator())

        let modeMenu = NSMenu()
        for mode in RulerMode.allCases {
            let item = NSMenuItem(title: mode.title, action: #selector(selectMode(_:)), keyEquivalent: "")
            item.target = self
            item.tag = modeTag(for: mode)
            item.state = (appState.settings.mode == mode) ? .on : .off
            modeMenu.addItem(item)
        }

        let modeItem = NSMenuItem(title: "Mode", action: nil, keyEquivalent: "")
        modeItem.submenu = modeMenu
        menu.addItem(modeItem)

        let resetItem = NSMenuItem(title: "Reset Size / Offset", action: #selector(resetModeSizeAndOffset), keyEquivalent: "")
        resetItem.target = self
        menu.addItem(resetItem)

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(title: "Open Settings", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let hideIconItem = NSMenuItem(title: "Hide Menu Bar Icon", action: #selector(toggleMenuBarIconVisibility), keyEquivalent: "")
        hideIconItem.target = self
        hideIconItem.state = appState.settings.hideMenuBarIcon ? .on : .off
        menu.addItem(hideIconItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit \(AppLabels.combinedName)", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    private func modeTag(for mode: RulerMode) -> Int {
        switch mode {
        case .bar: return 0
        case .highlight: return 1
        case .spotlight: return 2
        }
    }

    private func modeFromTag(_ tag: Int) -> RulerMode {
        switch tag {
        case 0: return .bar
        case 1: return .highlight
        default: return .spotlight
        }
    }

    @objc private func toggleStickyRuler() {
        appState.toggleStickyRuler()
    }

    @objc private func selectMode(_ sender: NSMenuItem) {
        appState.setMode(modeFromTag(sender.tag))
    }

    @objc private func resetModeSizeAndOffset() {
        appState.resetCurrentModeSizeAndOffset()
    }

    @objc private func openSettings() {
        onOpenSettings?()
    }

    @objc private func toggleMenuBarIconVisibility() {
        appState.settings.hideMenuBarIcon.toggle()
        syncStatusItemVisibility()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
