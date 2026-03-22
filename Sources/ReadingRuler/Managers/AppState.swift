import AppKit
import ApplicationServices
import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var settings: AppSettings {
        didSet {
            persistSettings()
            refreshDerivedState()
        }
    }

    @Published var mouseLocation: CGPoint = .zero
    @Published private(set) var holdActive: Bool = false
    @Published private(set) var rulerVisible: Bool = false
    @Published private(set) var barCenter: CGPoint?
    @Published private(set) var highlightCenter: CGPoint?
    @Published private(set) var spotlightCenter: CGPoint?
    @Published private(set) var accessibilityGranted: Bool = false
    @Published private(set) var sizeSelectionArmed: Bool = false
    @Published private(set) var sizeSelectionRect: CGRect?

    private let defaultsKey = "ReadingRuler.AppSettings"
    private var lastControlPointByMode: [RulerMode: CGPoint] = [:]
    private var cameraRectByMode: [RulerMode: CGRect] = [:]
    private var sizeSelectionStart: CGPoint?
    private static let spotlightDebugLogsEnabled = ProcessInfo.processInfo.environment["READINGRULER_DEBUG_SPOTLIGHT_EDGEPAN"] == "1"

    init() {
        settings = AppState.loadSettings(defaultsKey: defaultsKey).sanitized()
        refreshAccessibilityStatus()
        refreshDerivedState()
    }

    func refreshAccessibilityStatus(promptIfNeeded: Bool = false) {
        if promptIfNeeded {
            let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
            accessibilityGranted = AXIsProcessTrustedWithOptions(options)
            return
        }
        accessibilityGranted = AXIsProcessTrusted()
    }

    func setMouseLocation(_ location: CGPoint) {
        mouseLocation = location
        guard !sizeSelectionArmed else { return }
        updateCameraTracking(for: location)
    }

    func setHoldActive(_ active: Bool) {
        guard holdActive != active else { return }
        holdActive = active
        refreshDerivedState()
    }

    func toggleStickyRuler() {
        mutateSettings { settings in
            settings.stickyEnabled.toggle()
        }
    }

    func setMode(_ mode: RulerMode) {
        mutateSettings { settings in
            settings.mode = mode
        }
        lastControlPointByMode[mode] = nil
        updateCameraTracking(for: mouseLocation)
    }

    func beginSizeSelectionDrag(at point: CGPoint) {
        guard rulerVisible, sizeSelectionArmed else { return }
        guard sizeSelectionStart == nil else { return }
        sizeSelectionStart = point
        sizeSelectionRect = normalizedRect(from: point, to: point)
    }

    func updateSizeSelectionDrag(to point: CGPoint) {
        guard rulerVisible, sizeSelectionArmed, let start = sizeSelectionStart else { return }
        sizeSelectionRect = normalizedRect(from: start, to: point)
    }

    func endSizeSelectionDrag(at point: CGPoint) {
        guard sizeSelectionArmed else { return }

        if rulerVisible, let start = sizeSelectionStart {
            let rect = normalizedRect(from: start, to: point)
            applySizeSelection(rect: rect, cursor: point)
        }

        clearSizeSelection(keepArmed: false)
        updateCameraTracking(for: mouseLocation)
    }

    func cancelSizeSelection() {
        guard sizeSelectionArmed else { return }
        clearSizeSelection(keepArmed: false)
        updateCameraTracking(for: mouseLocation)
    }

    func resetCurrentModeSizeAndOffset() {
        mutateSettings { settings in
            settings.resetCurrentModeSizeAndOffset()
        }
    }

    func applyHandleDrag(deltaX: CGFloat, deltaY: CGFloat, adjustOffset: Bool) {
        let deltaWidth = Double(deltaX)
        let deltaHeight = Double(deltaY)

        mutateSettings { settings in
            switch settings.mode {
            case .bar:
                if adjustOffset {
                    settings.bar.offsetX += deltaWidth
                    settings.bar.offsetY += deltaHeight
                } else {
                    settings.bar.width = clamped(settings.bar.width + deltaWidth, min: 40, max: 2400)
                    settings.bar.height = clamped(settings.bar.height + deltaHeight, min: 2, max: 280)
                }
            case .highlight:
                if adjustOffset {
                    settings.highlight.offsetX += deltaWidth
                    settings.highlight.offsetY += deltaHeight
                } else {
                    settings.highlight.width = clamped(settings.highlight.width + deltaWidth, min: 40, max: 2600)
                    settings.highlight.height = clamped(settings.highlight.height + deltaHeight, min: 10, max: 500)
                }
            case .spotlight:
                if adjustOffset {
                    settings.spotlight.offsetX += deltaWidth
                    settings.spotlight.offsetY += deltaHeight
                } else {
                    settings.spotlight.width = clamped(settings.spotlight.width + deltaWidth, min: 40, max: 2600)
                    settings.spotlight.height = clamped(settings.spotlight.height + deltaHeight, min: 40, max: 1800)
                }
            }
        }

        updateCameraTracking(for: mouseLocation)
    }

    func overlayGlobalCenter(for mode: RulerMode, cursor: CGPoint? = nil) -> CGPoint {
        if let stored = storedCenter(for: mode) {
            return stored
        }

        let source = cursor ?? mouseLocation
        return edgePanControlPoint(for: mode, cursor: source)
    }

    private func refreshDerivedState() {
        let wasVisible = rulerVisible
        rulerVisible = holdActive || settings.stickyEnabled
        if !rulerVisible {
            lastControlPointByMode.removeAll()
            clearSizeSelection(keepArmed: false)
        } else {
            if !wasVisible {
                armSizeSelection()
            }
            guard !sizeSelectionArmed else { return }
            updateCameraTracking(for: mouseLocation)
        }
    }

    private func mutateSettings(_ mutate: (inout AppSettings) -> Void) {
        var next = settings
        mutate(&next)
        settings = next
    }

    private func updateCameraTracking(for location: CGPoint) {
        guard rulerVisible else {
            lastControlPointByMode.removeAll()
            return
        }
        guard !sizeSelectionArmed else { return }

        let mode = settings.mode
        let controlPoint = edgePanControlPoint(for: mode, cursor: location)

        guard let bounds = activeDisplayBounds(for: controlPoint) else {
            lastControlPointByMode[mode] = controlPoint
            return
        }

        let size = overlaySize(for: mode)
        let threshold = edgePanThreshold(for: size)

        let baseRect: CGRect = {
            if let existingRect = cameraRectByMode[mode] {
                return CGRect(
                    x: existingRect.midX - size.width / 2,
                    y: existingRect.midY - size.height / 2,
                    width: size.width,
                    height: size.height
                )
            }

            let initialCenter = storedCenter(for: mode) ?? controlPoint
            return CGRect(
                x: initialCenter.x - size.width / 2,
                y: initialCenter.y - size.height / 2,
                width: size.width,
                height: size.height
            )
        }()

        var rect = clampedOverlayRect(baseRect, within: bounds)
        let innerRect = rect.insetBy(dx: threshold, dy: threshold)

        let lastControlPoint = lastControlPointByMode[mode] ?? controlPoint
        let dx = controlPoint.x - lastControlPoint.x
        let dy = controlPoint.y - lastControlPoint.y

        let leftPan = controlPoint.x <= innerRect.minX && dx < 0
        let rightPan = controlPoint.x >= innerRect.maxX && dx > 0
        let bottomPan = controlPoint.y <= innerRect.minY && dy < 0
        let topPan = controlPoint.y >= innerRect.maxY && dy > 0

        // Edge-pan uses overflow distance so the cursor is pushed back toward
        // the inner safe zone boundary instead of moving by raw cursor delta.
        if leftPan {
            rect.origin.x += controlPoint.x - innerRect.minX
        } else if rightPan {
            rect.origin.x += controlPoint.x - innerRect.maxX
        }

        if bottomPan {
            rect.origin.y += controlPoint.y - innerRect.minY
        } else if topPan {
            rect.origin.y += controlPoint.y - innerRect.maxY
        }

        rect = clampedOverlayRect(rect, within: bounds)
        cameraRectByMode[mode] = rect
        setStoredCenter(CGPoint(x: rect.midX, y: rect.midY), for: mode)
        lastControlPointByMode[mode] = controlPoint

        debugSpotlight(
            mode: mode,
            cursorPos: controlPoint,
            lastCursorPos: lastControlPoint,
            dx: dx,
            dy: dy,
            spotlightRect: rect,
            innerRect: innerRect,
            leftPan: leftPan,
            rightPan: rightPan,
            topPan: topPan,
            bottomPan: bottomPan
        )
    }

    private func edgePanControlPoint(for mode: RulerMode, cursor: CGPoint) -> CGPoint {
        switch mode {
        case .bar:
            return CGPoint(x: cursor.x + settings.bar.offsetX, y: cursor.y + settings.bar.offsetY)
        case .highlight:
            return CGPoint(x: cursor.x + settings.highlight.offsetX, y: cursor.y + settings.highlight.offsetY)
        case .spotlight:
            return CGPoint(x: cursor.x + settings.spotlight.offsetX, y: cursor.y + settings.spotlight.offsetY)
        }
    }

    private func overlaySize(for mode: RulerMode) -> CGSize {
        switch mode {
        case .bar:
            return CGSize(width: settings.bar.width, height: settings.bar.height)
        case .highlight:
            return CGSize(width: settings.highlight.width, height: settings.highlight.height)
        case .spotlight:
            if settings.spotlight.shape == .circle {
                let side = max(settings.spotlight.width, settings.spotlight.height)
                return CGSize(width: side, height: side)
            }
            return CGSize(width: settings.spotlight.width, height: settings.spotlight.height)
        }
    }

    private func storedCenter(for mode: RulerMode) -> CGPoint? {
        switch mode {
        case .bar:
            return barCenter
        case .highlight:
            return highlightCenter
        case .spotlight:
            return spotlightCenter
        }
    }

    private func setStoredCenter(_ center: CGPoint, for mode: RulerMode) {
        switch mode {
        case .bar:
            barCenter = center
        case .highlight:
            highlightCenter = center
        case .spotlight:
            spotlightCenter = center
        }
    }

    private func activeDisplayBounds(for location: CGPoint) -> CGRect? {
        if let containing = NSScreen.screens.first(where: { $0.frame.contains(location) }) {
            return containing.visibleFrame
        }
        return NSScreen.screens.first?.visibleFrame
    }

    private func edgePanThreshold(for size: CGSize) -> CGFloat {
        let envValue = ProcessInfo.processInfo.environment["READINGRULER_SPOTLIGHT_EDGE_THRESHOLD"]
            .flatMap { Double($0) }
            .map { CGFloat($0) }
        let requested = envValue ?? 16
        let maxInset = max(1, (min(size.width, size.height) / 2) - 1)
        return min(maxInset, max(1, requested))
    }

    private func clampedOverlayRect(_ rect: CGRect, within bounds: CGRect) -> CGRect {
        let width = min(rect.width, bounds.width)
        let height = min(rect.height, bounds.height)
        var clampedRect = CGRect(x: rect.origin.x, y: rect.origin.y, width: width, height: height)

        let maxX = bounds.maxX - clampedRect.width
        let maxY = bounds.maxY - clampedRect.height
        clampedRect.origin.x = min(maxX, max(bounds.minX, clampedRect.origin.x))
        clampedRect.origin.y = min(maxY, max(bounds.minY, clampedRect.origin.y))
        return clampedRect
    }

    private func armSizeSelection() {
        clearSizeSelection(keepArmed: true)
    }

    private func clearSizeSelection(keepArmed: Bool) {
        sizeSelectionArmed = keepArmed
        sizeSelectionStart = nil
        sizeSelectionRect = nil
    }

    private func normalizedRect(from start: CGPoint, to end: CGPoint) -> CGRect {
        let minX = min(start.x, end.x)
        let maxX = max(start.x, end.x)
        let minY = min(start.y, end.y)
        let maxY = max(start.y, end.y)
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    private func applySizeSelection(rect: CGRect, cursor: CGPoint) {
        let mode = settings.mode
        guard rect.width >= 4 || rect.height >= 4 else { return }

        mutateSettings { settings in
            switch mode {
            case .bar:
                settings.bar.width = clamped(Double(rect.width), min: 40, max: 2400)
                settings.bar.height = clamped(Double(rect.height), min: 2, max: 280)
            case .highlight:
                settings.highlight.width = clamped(Double(rect.width), min: 40, max: 2600)
                settings.highlight.height = clamped(Double(rect.height), min: 10, max: 500)
            case .spotlight:
                if settings.spotlight.shape == .circle {
                    let side = clamped(Double(max(rect.width, rect.height)), min: 40, max: 2600)
                    settings.spotlight.width = side
                    settings.spotlight.height = side
                } else {
                    settings.spotlight.width = clamped(Double(rect.width), min: 40, max: 2600)
                    settings.spotlight.height = clamped(Double(rect.height), min: 40, max: 1800)
                }
            }
        }

        let selectionCenter = CGPoint(x: rect.midX, y: rect.midY)
        let size = overlaySize(for: mode)
        var targetRect = CGRect(
            x: selectionCenter.x - size.width / 2,
            y: selectionCenter.y - size.height / 2,
            width: size.width,
            height: size.height
        )

        if let bounds = activeDisplayBounds(for: selectionCenter) {
            targetRect = clampedOverlayRect(targetRect, within: bounds)
        }

        cameraRectByMode[mode] = targetRect
        setStoredCenter(CGPoint(x: targetRect.midX, y: targetRect.midY), for: mode)
        lastControlPointByMode[mode] = edgePanControlPoint(for: mode, cursor: cursor)
    }

    private func debugSpotlight(
        mode: RulerMode,
        cursorPos: CGPoint,
        lastCursorPos: CGPoint,
        dx: CGFloat,
        dy: CGFloat,
        spotlightRect: CGRect,
        innerRect: CGRect,
        leftPan: Bool,
        rightPan: Bool,
        topPan: Bool,
        bottomPan: Bool
    ) {
        guard Self.spotlightDebugLogsEnabled else { return }

        func f(_ value: CGFloat) -> String { String(format: "%.1f", value) }
        print(
            "[SpotlightEdgePan] mode=\(mode.rawValue) " +
            "cursor=(\(f(cursorPos.x)),\(f(cursorPos.y))) " +
            "last=(\(f(lastCursorPos.x)),\(f(lastCursorPos.y))) " +
            "dx=\(f(dx)) dy=\(f(dy)) " +
            "rect=(x:\(f(spotlightRect.origin.x)),y:\(f(spotlightRect.origin.y)),w:\(f(spotlightRect.width)),h:\(f(spotlightRect.height))) " +
            "inner=(x:\(f(innerRect.origin.x)),y:\(f(innerRect.origin.y)),w:\(f(innerRect.width)),h:\(f(innerRect.height))) " +
            "edges=L:\(leftPan ? 1 : 0),R:\(rightPan ? 1 : 0),T:\(topPan ? 1 : 0),B:\(bottomPan ? 1 : 0)"
        )
    }

    private func persistSettings() {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    private static func loadSettings(defaultsKey: String) -> AppSettings {
        let decoder = JSONDecoder()
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let decoded = try? decoder.decode(AppSettings.self, from: data) else {
            return .default
        }
        return decoded
    }
}
