import AppKit
import SwiftUI

extension Notification.Name {
    static let shortcutRecorderDidBegin = Notification.Name("ReadingRuler.ShortcutRecorderDidBegin")
    static let shortcutRecorderDidEnd = Notification.Name("ReadingRuler.ShortcutRecorderDidEnd")
}

struct ShortcutRecorder: NSViewRepresentable {
    @Binding var shortcut: Shortcut
    var allowsModifierOnly: Bool

    func makeNSView(context: Context) -> ShortcutRecorderField {
        let view = ShortcutRecorderField()
        view.shortcut = shortcut
        view.onShortcutChange = { newShortcut in
            DispatchQueue.main.async {
                shortcut = newShortcut
            }
        }
        return view
    }

    func updateNSView(_ nsView: ShortcutRecorderField, context: Context) {
        _ = allowsModifierOnly // Kept for API compatibility; recorder now always finalizes on non-modifier keys only.
        if !nsView.isRecording, nsView.shortcut != shortcut {
            nsView.shortcut = shortcut
        }
    }
}

final class ShortcutRecorderField: NSView {
    var shortcut: Shortcut = .holdDefault {
        didSet { needsDisplay = true }
    }

    var onShortcutChange: ((Shortcut) -> Void)?

    private(set) var isRecording = false {
        didSet { needsDisplay = true }
    }
    private var previewModifiers: UInt32 = 0 {
        didSet { needsDisplay = true }
    }

    private var eventMonitor: Any?

    override var acceptsFirstResponder: Bool {
        true
    }

    override var canBecomeKeyView: Bool {
        true
    }

    override func mouseDown(with event: NSEvent) {
        startRecording()
    }

    override func becomeFirstResponder() -> Bool {
        needsDisplay = true
        return true
    }

    override func resignFirstResponder() -> Bool {
        stopRecording(notify: true)
        return true
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            startRecording()
            return
        }
        _ = handleRecordingEvent(event)
    }

    override func flagsChanged(with event: NSEvent) {
        guard isRecording else { return }
        _ = handleRecordingEvent(event)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window == nil {
            stopRecording(notify: true)
        }
    }

    private func startRecording() {
        guard !isRecording else { return }

        isRecording = true
        previewModifiers = Shortcut.carbonModifiers(from: NSEvent.modifierFlags)
        window?.makeFirstResponder(self)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.window?.makeFirstResponder(self)
        }
        NotificationCenter.default.post(name: .shortcutRecorderDidBegin, object: self)
        installEventMonitor()
    }

    private func stopRecording(notify: Bool) {
        guard isRecording else { return }

        isRecording = false
        removeEventMonitor()

        if notify {
            NotificationCenter.default.post(name: .shortcutRecorderDidEnd, object: self)
        }
    }

    private func installEventMonitor() {
        removeEventMonitor()

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            guard let self else { return event }
            guard self.isRecording else { return event }

            if self.handleRecordingEvent(event) {
                return nil
            }
            return event
        }
    }

    private func removeEventMonitor() {
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }
    }

    @discardableResult
    private func handleRecordingEvent(_ event: NSEvent) -> Bool {
        if event.type == .keyDown, event.keyCode == 53 {
            stopRecording(notify: true)
            return true
        }

        if event.type == .flagsChanged {
            previewModifiers = Shortcut.carbonModifiers(from: event.modifierFlags)
            return true
        }

        guard event.type == .keyDown else { return false }
        previewModifiers = Shortcut.carbonModifiers(from: event.modifierFlags)

        if Shortcut.isModifierKeyCode(event.keyCode) {
            return true
        }

        guard let newShortcut = Shortcut.from(event: event) else {
            return true
        }

        applyShortcut(newShortcut)
        return true
    }

    private func applyShortcut(_ newShortcut: Shortcut) {
        shortcut = newShortcut
        onShortcutChange?(newShortcut)
        stopRecording(notify: true)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let backgroundRect = bounds.insetBy(dx: 0.5, dy: 0.5)
        let path = NSBezierPath(roundedRect: backgroundRect, xRadius: 8, yRadius: 8)
        NSColor.textBackgroundColor.setFill()
        path.fill()

        let strokeColor = isRecording ? NSColor.controlAccentColor : NSColor.separatorColor
        strokeColor.setStroke()
        path.lineWidth = isRecording ? 2 : 1
        path.stroke()

        let prompt: String
        if isRecording {
            let preview = Shortcut.previewText(for: previewModifiers)
            prompt = preview == "Press shortcut" ? preview : "\(preview)+..."
        } else {
            prompt = shortcut.displayString
        }
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.labelColor
        ]

        let textSize = (prompt as NSString).size(withAttributes: attributes)
        let textRect = NSRect(
            x: (bounds.width - textSize.width) / 2,
            y: (bounds.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )

        (prompt as NSString).draw(in: textRect, withAttributes: attributes)
    }
}
