import AppKit
import CoreVideo
import Foundation

final class CursorTracker: @unchecked Sendable {
    typealias UpdateHandler = (CGPoint) -> Void

    private var updateHandler: UpdateHandler?

    private var timer: DispatchSourceTimer?
    private var displayLink: CVDisplayLink?

    private let stateQueue = DispatchQueue(label: "ReadingRuler.CursorTracker.State", qos: .userInteractive)
    private var mainDispatchQueued = false

    private let useTimerFallback = ProcessInfo.processInfo.environment["READINGRULER_USE_TIMER_TRACKER"] == "1"

    deinit {
        stop()
    }

    func start(update: @escaping UpdateHandler) {
        stop()
        updateHandler = update

        if !useTimerFallback, startDisplayLinkedUpdates() {
            return
        }

        startTimerUpdates()
    }

    func stop() {
        if let displayLink {
            CVDisplayLinkStop(displayLink)
            self.displayLink = nil
        }

        timer?.cancel()
        timer = nil

        updateHandler = nil

        stateQueue.sync {
            mainDispatchQueued = false
        }
    }

    private func startDisplayLinkedUpdates() -> Bool {
        var newLink: CVDisplayLink?
        let createStatus = CVDisplayLinkCreateWithActiveCGDisplays(&newLink)
        guard createStatus == kCVReturnSuccess, let newLink else {
            return false
        }

        let callback: CVDisplayLinkOutputCallback = { _, _, _, _, _, context in
            guard let context else { return kCVReturnError }
            let tracker = Unmanaged<CursorTracker>.fromOpaque(context).takeUnretainedValue()
            tracker.handleDisplayTick()
            return kCVReturnSuccess
        }

        let callbackStatus = CVDisplayLinkSetOutputCallback(
            newLink,
            callback,
            Unmanaged.passUnretained(self).toOpaque()
        )
        guard callbackStatus == kCVReturnSuccess else {
            return false
        }

        let startStatus = CVDisplayLinkStart(newLink)
        guard startStatus == kCVReturnSuccess else {
            return false
        }

        displayLink = newLink
        return true
    }

    private func startTimerUpdates() {
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: .milliseconds(16), leeway: .milliseconds(2))
        timer.setEventHandler { [weak self] in
            guard let self, let updateHandler = self.updateHandler else { return }
            updateHandler(self.appKitMouseLocation())
        }
        timer.resume()
        self.timer = timer
    }

    private func handleDisplayTick() {
        queueMainUpdate()
    }

    private func queueMainUpdate() {
        stateQueue.async { [weak self] in
            guard let self else { return }

            guard !mainDispatchQueued else { return }
            mainDispatchQueued = true

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }

                stateQueue.sync {
                    mainDispatchQueued = false
                }

                guard let updateHandler = updateHandler else { return }
                updateHandler(appKitMouseLocation())
            }
        }
    }

    private func appKitMouseLocation() -> CGPoint {
        return NSEvent.mouseLocation
    }
}
