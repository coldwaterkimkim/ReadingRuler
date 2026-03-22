import AppKit
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let appState = AppState()
    private let cursorTracker = CursorTracker()
    private let hotKeyCenter = GlobalHotKeyCenter()

    private var overlayCoordinator: OverlayCoordinator?
    private var menuBarController: MenuBarController?
    private var settingsWindowController: SettingsWindowController?

    private var cancellables: Set<AnyCancellable> = []
    private var shortcutRecordingCount = 0
    private var cursorTrackingActive = false
    private var effectiveRulerVisible = false
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        applyActivationPolicy()

        settingsWindowController = SettingsWindowController(appState: appState)
        overlayCoordinator = OverlayCoordinator(appState: appState)

        let menuBarController = MenuBarController(appState: appState)
        menuBarController.onOpenSettings = { [weak self] in
            self?.openSettings()
        }
        self.menuBarController = menuBarController

        configureHotkeys()
        bindState()
        installSizeSelectionMonitors()
        updateEffectiveRulerVisibility(appState.holdActive || appState.settings.stickyEnabled)
    }

    func applicationWillTerminate(_ notification: Notification) {
        cursorTracker.stop()
        hotKeyCenter.unregisterAll()
        removeSizeSelectionMonitors()
    }

    func openSettings() {
        settingsWindowController?.showWindow()
    }

    private func bindState() {
        appState.$settings
            .map(\.shortcuts)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.configureHotkeys()
            }
            .store(in: &cancellables)

        appState.$settings
            .map(\.hideMenuBarIcon)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.applyActivationPolicy()
            }
            .store(in: &cancellables)

        Publishers.CombineLatest(
            appState.$holdActive.removeDuplicates(),
            appState.$settings.map(\.stickyEnabled).removeDuplicates()
        )
        .map { holdActive, stickyEnabled in
            holdActive || stickyEnabled
        }
        .removeDuplicates()
        .sink { [weak self] visible in
            self?.updateEffectiveRulerVisibility(visible)
        }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .shortcutRecorderDidBegin)
            .sink { [weak self] _ in
                self?.beginShortcutRecording()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .shortcutRecorderDidEnd)
            .sink { [weak self] _ in
                self?.endShortcutRecording()
            }
            .store(in: &cancellables)

        appState.$sizeSelectionArmed
            .removeDuplicates()
            .sink { [weak self] armed in
                guard !armed else { return }
                self?.overlayCoordinator?.forceClickThrough()
            }
            .store(in: &cancellables)
    }

    private func configureHotkeys() {
        hotKeyCenter.unregisterAll()
        guard shortcutRecordingCount == 0 else { return }

        _ = hotKeyCenter.register(
            shortcut: appState.settings.shortcuts.holdToShow,
            onPressed: { [weak self] in
                self?.appState.setHoldActive(true)
            },
            onReleased: { [weak self] in
                self?.appState.setHoldActive(false)
            }
        )

        _ = hotKeyCenter.register(
            shortcut: appState.settings.shortcuts.toggleSticky,
            onPressed: { [weak self] in
                self?.appState.toggleStickyRuler()
            }
        )

        _ = hotKeyCenter.register(
            shortcut: appState.settings.shortcuts.selectBarMode,
            onPressed: { [weak self] in
                self?.appState.setMode(.bar)
            }
        )

        _ = hotKeyCenter.register(
            shortcut: appState.settings.shortcuts.selectHighlightMode,
            onPressed: { [weak self] in
                self?.appState.setMode(.highlight)
            }
        )

        _ = hotKeyCenter.register(
            shortcut: appState.settings.shortcuts.selectSpotlightMode,
            onPressed: { [weak self] in
                self?.appState.setMode(.spotlight)
            }
        )
    }

    private func applyActivationPolicy() {
        if appState.settings.hideMenuBarIcon {
            NSApp.setActivationPolicy(.regular)
        } else {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    private func beginShortcutRecording() {
        shortcutRecordingCount += 1
        configureHotkeys()
    }

    private func endShortcutRecording() {
        guard shortcutRecordingCount > 0 else { return }
        shortcutRecordingCount -= 1
        if shortcutRecordingCount == 0 {
            configureHotkeys()
        }
    }

    private func updateEffectiveRulerVisibility(_ visible: Bool) {
        effectiveRulerVisible = visible
        updateCursorTracking()
        if !visible {
            overlayCoordinator?.forceClickThrough()
        }
    }

    private func updateCursorTracking() {
        if effectiveRulerVisible {
            guard !cursorTrackingActive else { return }
            cursorTrackingActive = true
            appState.setMouseLocation(NSEvent.mouseLocation)
            cursorTracker.start { [weak self] point in
                self?.appState.setMouseLocation(point)
            }
        } else {
            guard cursorTrackingActive else { return }
            cursorTrackingActive = false
            cursorTracker.stop()
        }
    }

    private func installSizeSelectionMonitors() {
        let events: NSEvent.EventTypeMask = [.leftMouseDown, .leftMouseDragged, .leftMouseUp, .keyDown]

        if globalMouseMonitor == nil {
            globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: events) { [weak self] event in
                self?.handleSizeSelectionMouseEvent(event)
            }
        }

        if localMouseMonitor == nil {
            localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: events) { [weak self] event in
                self?.handleSizeSelectionMouseEvent(event)
                return event
            }
        }
    }

    private func removeSizeSelectionMonitors() {
        if let globalMouseMonitor {
            NSEvent.removeMonitor(globalMouseMonitor)
            self.globalMouseMonitor = nil
        }
        if let localMouseMonitor {
            NSEvent.removeMonitor(localMouseMonitor)
            self.localMouseMonitor = nil
        }
    }

    private func handleSizeSelectionMouseEvent(_ event: NSEvent) {
        guard appState.sizeSelectionArmed else { return }

        switch event.type {
        case .keyDown where event.keyCode == 53:
            appState.cancelSizeSelection()
            overlayCoordinator?.forceClickThrough()
        case .leftMouseDown:
            let point = screenPoint(for: event)
            appState.beginSizeSelectionDrag(at: point)
        case .leftMouseDragged:
            let point = screenPoint(for: event)
            appState.updateSizeSelectionDrag(to: point)
        case .leftMouseUp:
            let point = screenPoint(for: event)
            appState.endSizeSelectionDrag(at: point)
            overlayCoordinator?.forceClickThrough()
        default:
            break
        }
    }

    private func screenPoint(for event: NSEvent) -> CGPoint {
        if let window = event.window {
            return window.convertPoint(toScreen: event.locationInWindow)
        }
        return event.locationInWindow
    }
}
