import AppKit
import Carbon.HIToolbox

struct Shortcut: Codable, Hashable {
    var keyCode: UInt16
    var modifiers: UInt32
    var isModifierOnly: Bool

    init(keyCode: UInt16, modifiers: UInt32, isModifierOnly: Bool = false) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.isModifierOnly = isModifierOnly
    }

    var displayString: String {
        let keyText = Shortcut.keyName(for: keyCode)
        let modifierParts = Shortcut.modifierDisplayParts(for: modifiers)
        if modifierParts.isEmpty { return keyText }
        if isModifierOnly { return modifierParts.joined(separator: "+") }
        return (modifierParts + [keyText]).joined(separator: "+")
    }

    static let holdDefault = Shortcut(keyCode: 49, modifiers: UInt32(optionKey))
    static let toggleDefault = Shortcut(keyCode: 15, modifiers: UInt32(cmdKey | controlKey))
    static let modeBarDefault = Shortcut(keyCode: 18, modifiers: UInt32(cmdKey | controlKey))
    static let modeHighlightDefault = Shortcut(keyCode: 19, modifiers: UInt32(cmdKey | controlKey))
    static let modeSpotlightDefault = Shortcut(keyCode: 20, modifiers: UInt32(cmdKey | controlKey))

    static func from(event: NSEvent) -> Shortcut? {
        guard event.type == .keyDown else { return nil }
        guard !Shortcut.isModifierKeyCode(event.keyCode) else { return nil }
        guard Shortcut.optionalKeyName(for: event.keyCode) != nil else { return nil }

        let carbonModifiers = Shortcut.carbonModifiers(from: event.modifierFlags)
        guard carbonModifiers != 0 else { return nil }
        return Shortcut(keyCode: event.keyCode, modifiers: carbonModifiers, isModifierOnly: false)
    }

    static func previewText(for modifiers: UInt32) -> String {
        let parts = modifierDisplayParts(for: modifiers)
        if parts.isEmpty { return "Press shortcut" }
        return parts.joined(separator: "+")
    }

    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var value: UInt32 = 0
        if flags.contains(.command) { value |= UInt32(cmdKey) }
        if flags.contains(.option) { value |= UInt32(optionKey) }
        if flags.contains(.control) { value |= UInt32(controlKey) }
        if flags.contains(.shift) { value |= UInt32(shiftKey) }
        return value
    }

    static func isModifierKeyCode(_ keyCode: UInt16) -> Bool {
        modifierKeyCodes.contains(keyCode)
    }

    static func sanitized(_ shortcut: Shortcut, fallback: Shortcut) -> Shortcut {
        if shortcut.isModifierOnly { return fallback }
        if Shortcut.isModifierKeyCode(shortcut.keyCode) { return fallback }
        if Shortcut.optionalKeyName(for: shortcut.keyCode) == nil { return fallback }
        if shortcut.modifiers == 0 { return fallback }
        return Shortcut(keyCode: shortcut.keyCode, modifiers: shortcut.modifiers, isModifierOnly: false)
    }

    static func modifierDisplayParts(for modifiers: UInt32) -> [String] {
        var parts: [String] = []
        if modifiers & UInt32(controlKey) != 0 { parts.append("Ctrl") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("Option") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("Shift") }
        if modifiers & UInt32(cmdKey) != 0 { parts.append("Cmd") }
        return parts
    }

    static func optionalKeyName(for keyCode: UInt16) -> String? {
        Shortcut.keyNameMap[keyCode]
    }

    static func keyName(for keyCode: UInt16) -> String {
        Shortcut.keyNameMap[keyCode] ?? "Key \(keyCode)"
    }

    private static let keyNameMap: [UInt16: String] = [
        0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C", 9: "V",
        11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y", 17: "T", 18: "1", 19: "2",
        20: "3", 21: "4", 22: "6", 23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8",
        29: "0", 30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 37: "L", 38: "J",
        39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/", 45: "N", 46: "M", 47: ".",
        49: "Space", 50: "`", 53: "Esc", 54: "Right Cmd", 55: "Left Cmd", 56: "Left Shift",
        58: "Left Option", 59: "Left Control", 60: "Right Shift", 61: "Right Option", 62: "Right Control",
        123: "Left Arrow", 124: "Right Arrow", 125: "Down Arrow", 126: "Up Arrow"
    ]

    private static let modifierKeyCodes: Set<UInt16> = [54, 55, 56, 58, 59, 60, 61, 62]
}

struct ShortcutSet: Codable, Hashable {
    var holdToShow: Shortcut
    var toggleSticky: Shortcut
    var selectBarMode: Shortcut
    var selectHighlightMode: Shortcut
    var selectSpotlightMode: Shortcut

    init(
        holdToShow: Shortcut,
        toggleSticky: Shortcut,
        selectBarMode: Shortcut,
        selectHighlightMode: Shortcut,
        selectSpotlightMode: Shortcut
    ) {
        self.holdToShow = holdToShow
        self.toggleSticky = toggleSticky
        self.selectBarMode = selectBarMode
        self.selectHighlightMode = selectHighlightMode
        self.selectSpotlightMode = selectSpotlightMode
    }

    private enum CodingKeys: String, CodingKey {
        case holdToShow
        case toggleSticky
        case selectBarMode
        case selectHighlightMode
        case selectSpotlightMode
    }

    static let `default` = ShortcutSet(
        holdToShow: .holdDefault,
        toggleSticky: .toggleDefault,
        selectBarMode: .modeBarDefault,
        selectHighlightMode: .modeHighlightDefault,
        selectSpotlightMode: .modeSpotlightDefault
    )

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        holdToShow = (try? container.decode(Shortcut.self, forKey: .holdToShow)) ?? .holdDefault
        toggleSticky = (try? container.decode(Shortcut.self, forKey: .toggleSticky)) ?? .toggleDefault
        selectBarMode = (try? container.decode(Shortcut.self, forKey: .selectBarMode)) ?? .modeBarDefault
        selectHighlightMode = (try? container.decode(Shortcut.self, forKey: .selectHighlightMode)) ?? .modeHighlightDefault
        selectSpotlightMode = (try? container.decode(Shortcut.self, forKey: .selectSpotlightMode)) ?? .modeSpotlightDefault
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(holdToShow, forKey: .holdToShow)
        try container.encode(toggleSticky, forKey: .toggleSticky)
        try container.encode(selectBarMode, forKey: .selectBarMode)
        try container.encode(selectHighlightMode, forKey: .selectHighlightMode)
        try container.encode(selectSpotlightMode, forKey: .selectSpotlightMode)
    }

    func sanitized() -> ShortcutSet {
        ShortcutSet(
            holdToShow: Shortcut.sanitized(holdToShow, fallback: .holdDefault),
            toggleSticky: Shortcut.sanitized(toggleSticky, fallback: .toggleDefault),
            selectBarMode: Shortcut.sanitized(selectBarMode, fallback: .modeBarDefault),
            selectHighlightMode: Shortcut.sanitized(selectHighlightMode, fallback: .modeHighlightDefault),
            selectSpotlightMode: Shortcut.sanitized(selectSpotlightMode, fallback: .modeSpotlightDefault)
        )
    }
}
