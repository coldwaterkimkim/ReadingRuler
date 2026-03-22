import SwiftUI

struct RulerOverlayView: View {
    @ObservedObject var appState: AppState
    let overlayFrame: CGRect

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if appState.rulerVisible {
                    if appState.sizeSelectionArmed {
                        sizeSelectionView(size: proxy.size)
                    } else {
                        let mouse = appState.mouseLocation
                        if overlayFrame.contains(mouse) {
                            switch appState.settings.mode {
                            case .bar:
                                barView(size: proxy.size, mouse: mouse)
                            case .highlight:
                                highlightView(size: proxy.size, mouse: mouse)
                            case .spotlight:
                                spotlightView(size: proxy.size, mouse: mouse)
                            }
                        }
                    }
                }

                if appState.rulerVisible, appState.sizeSelectionArmed {
                    Color.clear
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .contentShape(Rectangle())
                        .gesture(sizeSelectionGesture(in: proxy.size))
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
        }
        .allowsHitTesting(appState.sizeSelectionArmed)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }

    private func barView(size: CGSize, mouse: CGPoint) -> some View {
        let settings = appState.settings.bar
        let globalCenter = appState.overlayGlobalCenter(for: .bar, cursor: mouse)
        let center = overlayCenterPoint(in: size, globalPoint: globalCenter)
        let color = settings.color.swiftUIColor.opacity(settings.opacity)

        return RoundedRectangle(cornerRadius: settings.cornerRadius)
            .fill(color)
            .frame(width: settings.width, height: settings.height)
            .position(center)
    }

    private func highlightView(size: CGSize, mouse: CGPoint) -> some View {
        let settings = appState.settings.highlight
        let globalCenter = appState.overlayGlobalCenter(for: .highlight, cursor: mouse)
        let center = overlayCenterPoint(in: size, globalPoint: globalCenter)
        let color = settings.color.swiftUIColor.opacity(settings.opacity)

        return RoundedRectangle(cornerRadius: settings.cornerRadius)
            .fill(color)
            .frame(width: settings.width, height: settings.height)
            .position(center)
    }

    @ViewBuilder
    private func spotlightHole(settings: SpotlightModeSettings, center: CGPoint, holeWidth: Double, holeHeight: Double) -> some View {
        switch settings.shape {
        case .circle:
            Circle()
                .frame(width: holeWidth, height: holeWidth)
                .position(center)
        case .roundedRect:
            RoundedRectangle(cornerRadius: settings.cornerRadius, style: .continuous)
                .frame(width: holeWidth, height: holeHeight)
                .position(center)
        }
    }

    private func spotlightView(size: CGSize, mouse: CGPoint) -> some View {
        let settings = appState.settings.spotlight
        let globalCenter = appState.overlayGlobalCenter(for: .spotlight, cursor: mouse)
        let center = overlayCenterPoint(in: size, globalPoint: globalCenter)
        let holeWidth = settings.shape == .circle ? max(settings.width, settings.height) : settings.width
        let holeHeight = settings.shape == .circle ? max(settings.width, settings.height) : settings.height

        return ZStack {
            Color.black.opacity(settings.dimOpacity)

            spotlightHole(settings: settings, center: center, holeWidth: holeWidth, holeHeight: holeHeight)
                .blur(radius: settings.feather)
                .blendMode(.destinationOut)
        }
        .compositingGroup()
    }

    @ViewBuilder
    private func sizeSelectionView(size: CGSize) -> some View {
        if let globalRect = appState.sizeSelectionRect {
            let rect = selectionRectInOverlay(size: size, globalRect: globalRect)
            let center = CGPoint(x: rect.midX, y: rect.midY)

            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(width: rect.width, height: rect.height)
                .position(center)
                .overlay(
                    Rectangle()
                        .stroke(Color.white.opacity(0.95), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                        .frame(width: rect.width, height: rect.height)
                        .position(center)
                )
        } else {
            EmptyView()
        }
    }

    private func overlayCenterPoint(in size: CGSize, globalPoint: CGPoint) -> CGPoint {
        let localX = globalPoint.x - overlayFrame.minX
        let localYFromBottom = globalPoint.y - overlayFrame.minY
        let localY = size.height - localYFromBottom
        return CGPoint(x: localX, y: localY)
    }

    private func selectionRectInOverlay(size: CGSize, globalRect: CGRect) -> CGRect {
        let localX = globalRect.minX - overlayFrame.minX
        let localYFromBottom = globalRect.minY - overlayFrame.minY
        let localY = size.height - localYFromBottom - globalRect.height
        return CGRect(x: localX, y: localY, width: globalRect.width, height: globalRect.height)
    }

    private func globalPoint(from localPoint: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: overlayFrame.minX + localPoint.x,
            y: overlayFrame.maxY - localPoint.y
        )
    }

    private func sizeSelectionGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let start = globalPoint(from: value.startLocation, in: size)
                let current = globalPoint(from: value.location, in: size)
                appState.beginSizeSelectionDrag(at: start)
                appState.updateSizeSelectionDrag(to: current)
            }
            .onEnded { value in
                let end = globalPoint(from: value.location, in: size)
                appState.endSizeSelectionDrag(at: end)
            }
    }
}
