import AppKit

func combinedScreenFrame() -> CGRect {
    NSScreen.screens.reduce(CGRect.null) { partial, screen in
        partial.union(screen.frame)
    }
}

func clamped(_ value: Double, min minValue: Double, max maxValue: Double) -> Double {
    Swift.min(maxValue, Swift.max(minValue, value))
}
