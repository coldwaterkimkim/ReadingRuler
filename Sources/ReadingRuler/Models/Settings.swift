import Foundation

enum RulerMode: String, Codable, CaseIterable, Identifiable {
    case bar
    case highlight
    case spotlight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bar: return "Bar"
        case .highlight: return "Highlight"
        case .spotlight: return "Spotlight"
        }
    }
}

enum SpotlightShape: String, Codable, CaseIterable, Identifiable {
    case circle
    case roundedRect

    var id: String { rawValue }

    var title: String {
        switch self {
        case .circle: return "Circle"
        case .roundedRect: return "Rounded Rect"
        }
    }
}

struct BarModeSettings: Codable, Hashable {
    var width: Double = 420
    var height: Double = 6
    var cornerRadius: Double = 3
    var color: CodableColor = CodableColor(red: 0.97, green: 0.83, blue: 0.17)
    var opacity: Double = 0.9
    var offsetX: Double = 0
    var offsetY: Double = 24

    static let `default` = BarModeSettings()
}

struct HighlightModeSettings: Codable, Hashable {
    var width: Double = 520
    var height: Double = 52
    var color: CodableColor = CodableColor(red: 0.98, green: 0.9, blue: 0.26)
    var opacity: Double = 0.28
    var cornerRadius: Double = 8
    var offsetX: Double = 0
    var offsetY: Double = 0

    static let `default` = HighlightModeSettings()
}

struct SpotlightModeSettings: Codable, Hashable {
    var width: Double = 320
    var height: Double = 160
    var dimOpacity: Double = 0.56
    var feather: Double = 18
    var shape: SpotlightShape = .roundedRect
    var cornerRadius: Double = 24
    var offsetX: Double = 0
    var offsetY: Double = 0

    static let `default` = SpotlightModeSettings()
}

struct AppSettings: Codable, Hashable {
    var mode: RulerMode = .bar
    var stickyEnabled: Bool = false
    var hideMenuBarIcon: Bool = false

    var shortcuts: ShortcutSet = .default

    var bar: BarModeSettings = .default
    var highlight: HighlightModeSettings = .default
    var spotlight: SpotlightModeSettings = .default

    static let `default` = AppSettings()

    mutating func resetCurrentModeSizeAndOffset() {
        switch mode {
        case .bar:
            bar.width = BarModeSettings.default.width
            bar.height = BarModeSettings.default.height
            bar.offsetX = BarModeSettings.default.offsetX
            bar.offsetY = BarModeSettings.default.offsetY
        case .highlight:
            highlight.width = HighlightModeSettings.default.width
            highlight.height = HighlightModeSettings.default.height
            highlight.offsetX = HighlightModeSettings.default.offsetX
            highlight.offsetY = HighlightModeSettings.default.offsetY
        case .spotlight:
            spotlight.width = SpotlightModeSettings.default.width
            spotlight.height = SpotlightModeSettings.default.height
            spotlight.offsetX = SpotlightModeSettings.default.offsetX
            spotlight.offsetY = SpotlightModeSettings.default.offsetY
        }
    }

    func sanitized() -> AppSettings {
        var copy = self
        copy.shortcuts = shortcuts.sanitized()
        return copy
    }
}
