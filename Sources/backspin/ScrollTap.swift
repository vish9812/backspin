import CoreGraphics
import ScrollCore

private func scrollCallback(_ proxy: CGEventTapProxy, _ type: CGEventType, _ event: CGEvent,
                            _ context: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    guard let context else { return Unmanaged.passUnretained(event) }
    return Unmanaged<ScrollTap>.fromOpaque(context).takeUnretainedValue().receive(type, event)
}

final class ScrollTap {
    /// Read on every scroll event; the delegate refreshes it rather than the callback querying preferences.
    var naturalScrolling = true
    private var port: CFMachPort?
    private var source: CFRunLoopSource?
    var isRunning: Bool { port.map { CGEvent.tapIsEnabled(tap: $0) } ?? false }

    func start() -> Bool {
        if let port {
            if isRunning { return true }
            CGEvent.tapEnable(tap: port, enable: true)
            if isRunning { return true }
            stop()
        }
        let mask = CGEventMask(1) << CGEventType.scrollWheel.rawValue
        guard let port = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap,
            options: .defaultTap, eventsOfInterest: mask, callback: scrollCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()) else { return false }
        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0) else {
            CFMachPortInvalidate(port)
            return false
        }
        self.port = port
        self.source = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: port, enable: true)
        return isRunning
    }

    func stop() {
        if let port { CGEvent.tapEnable(tap: port, enable: false) }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        if let port { CFMachPortInvalidate(port) }
        source = nil
        port = nil
    }

    fileprivate func receive(_ type: CGEventType, _ event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let port { CGEvent.tapEnable(tap: port, enable: true) }
        } else if type == .scrollWheel, ScrollFlip.shouldInvert(event, naturalScrolling: naturalScrolling) {
            ScrollFlip.invert(event)
        }
        return Unmanaged.passUnretained(event)
    }

    deinit { stop() }
}
