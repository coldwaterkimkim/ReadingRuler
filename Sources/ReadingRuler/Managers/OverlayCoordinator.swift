import AppKit
import Combine
import SwiftUI

@MainActor
final class OverlayCoordinator {
    private unowned let appState: AppState

    private var rulerWindows: [String: NSWindow] = [:]

    private var observers: [NSObjectProtocol] = []
    private var cancellables: Set<AnyCancellable> = []
    private var effectiveRulerVisible = false

    init(appState: AppState) {
        self.appState = appState
        setupNotifications()
        setupBindings()
        rebuildWindows()
        updateEffectiveRulerVisibility(appState.holdActive || appState.settings.stickyEnabled)
    }

    private func setupNotifications() {
        observers.append(
            NotificationCenter.default.addObserver(
                forName: NSApplication.didChangeScreenParametersNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.rebuildWindows()
                    self?.updateWindowVisibility()
                }
            }
        )

        observers.append(
            NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.activeSpaceDidChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.updateWindowVisibility()
                }
            }
        )
    }

    private func setupBindings() {
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

        appState.$settings
            .sink { [weak self] _ in
                self?.updateWindowVisibility()
            }
            .store(in: &cancellables)

        appState.$sizeSelectionArmed
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.updateWindowVisibility()
            }
            .store(in: &cancellables)
    }

    private func rebuildWindows() {
        closeRulerWindows()

        for screen in NSScreen.screens {
            let key = screenFrameKey(for: screen.frame)
            rulerWindows[key] = makeRulerWindow(frame: screen.frame)
        }
    }

    private func closeRulerWindows() {
        for window in rulerWindows.values {
            window.close()
        }
        rulerWindows.removeAll()
    }

    private func makeRulerWindow(frame: CGRect) -> NSWindow {
        let window = NSWindow(
            contentRect: frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false,
            screen: NSScreen.screens.first(where: { $0.frame.equalTo(frame) })
        )

        configureOverlayWindow(
            window,
            level: .statusBar,
            ignoresMouseEvents: true
        )

        window.contentView = NSHostingView(
            rootView: RulerOverlayView(
                appState: appState,
                overlayFrame: frame
            )
        )

        return window
    }

    private func configureOverlayWindow(
        _ window: NSWindow,
        level: NSWindow.Level,
        ignoresMouseEvents: Bool
    ) {
        window.level = level
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = ignoresMouseEvents
        window.hidesOnDeactivate = false
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .ignoresCycle,
            .stationary
        ]
    }

    private func updateWindowVisibility() {
        if rulerWindows.isEmpty {
            rebuildWindows()
        }

        let interceptMouseInput = effectiveRulerVisible && appState.sizeSelectionArmed
        for window in rulerWindows.values {
            window.ignoresMouseEvents = !interceptMouseInput
            if effectiveRulerVisible {
                window.orderFrontRegardless()
            } else {
                window.orderOut(nil)
            }
        }
    }

    func forceClickThrough() {
        for window in rulerWindows.values {
            window.ignoresMouseEvents = true
        }
    }

    private func screenFrameKey(for frame: CGRect) -> String {
        "\(frame.origin.x),\(frame.origin.y),\(frame.size.width),\(frame.size.height)"
    }

    private func updateEffectiveRulerVisibility(_ visible: Bool) {
        effectiveRulerVisible = visible
        updateWindowVisibility()
    }
}
