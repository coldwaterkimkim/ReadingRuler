import Carbon.HIToolbox
import Foundation

@MainActor
final class GlobalHotKeyCenter {
    private struct Binding {
        var hotKeyRef: EventHotKeyRef?
        let onPressed: () -> Void
        let onReleased: (() -> Void)?
    }

    private static let signature: OSType = 0x5252756C // RRul

    private var bindings: [UInt32: Binding] = [:]
    private var nextID: UInt32 = 1

    private var eventHandlerRef: EventHandlerRef?
    private var eventHandlerUPP: EventHandlerUPP?

    init() {
        installEventHandlerIfNeeded()
    }

    @discardableResult
    func register(
        shortcut: Shortcut,
        onPressed: @escaping () -> Void,
        onReleased: (() -> Void)? = nil
    ) -> Bool {
        let hotKeyIDValue = nextID
        nextID += 1

        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: Self.signature, id: hotKeyIDValue)

        let status = RegisterEventHotKey(
            UInt32(shortcut.keyCode),
            shortcut.modifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )

        guard status == noErr else {
            return false
        }

        bindings[hotKeyIDValue] = Binding(
            hotKeyRef: hotKeyRef,
            onPressed: onPressed,
            onReleased: onReleased
        )

        return true
    }

    func unregisterAll() {
        for binding in bindings.values {
            if let hotKeyRef = binding.hotKeyRef {
                UnregisterEventHotKey(hotKeyRef)
            }
        }
        bindings.removeAll()
    }

    private func installEventHandlerIfNeeded() {
        guard eventHandlerRef == nil else { return }

        var eventTypes = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)),
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased))
        ]

        let handler: EventHandlerUPP = { _, eventRef, userData in
            guard let userData else { return noErr }
            let center = Unmanaged<GlobalHotKeyCenter>.fromOpaque(userData).takeUnretainedValue()
            return center.handle(eventRef: eventRef)
        }

        eventHandlerUPP = handler

        InstallEventHandler(
            GetEventDispatcherTarget(),
            handler,
            eventTypes.count,
            &eventTypes,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )
    }

    private func handle(eventRef: EventRef?) -> OSStatus {
        guard let eventRef else { return noErr }

        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            eventRef,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )

        guard status == noErr, let binding = bindings[hotKeyID.id] else {
            return noErr
        }

        switch GetEventKind(eventRef) {
        case UInt32(kEventHotKeyPressed):
            binding.onPressed()
        case UInt32(kEventHotKeyReleased):
            binding.onReleased?()
        default:
            break
        }

        return noErr
    }
}
