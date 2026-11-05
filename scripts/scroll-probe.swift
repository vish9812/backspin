import CoreGraphics
import Foundation

// Prints the scroll fields backspin's device detection relies on. A listen-only tap never alters
// events, but the terminal running it needs Input Monitoring or Accessibility access.
let start = Date()
let callback: CGEventTapCallBack = { _, type, event, _ in
    guard type == .scrollWheel else { return Unmanaged.passUnretained(event) }
    let field = { (name: CGEventField) in event.getIntegerValueField(name) }
    print(String(format: "t=%5.1fs continuous=%lld phase=%lld momentum=%lld delta=%lld fixed=%.2f point=%lld",
                 Date().timeIntervalSince(start), field(.scrollWheelEventIsContinuous),
                 field(.scrollWheelEventScrollPhase), field(.scrollWheelEventMomentumPhase),
                 field(.scrollWheelEventDeltaAxis1), event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1),
                 field(.scrollWheelEventPointDeltaAxis1)))
    fflush(stdout)
    return Unmanaged.passUnretained(event)
}

guard let tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .listenOnly,
    eventsOfInterest: CGEventMask(1) << CGEventType.scrollWheel.rawValue, callback: callback, userInfo: nil) else {
    FileHandle.standardError.write(Data("Could not tap scroll events; grant this terminal Input Monitoring access.\n".utf8))
    exit(1)
}
CFRunLoopAddSource(CFRunLoopGetMain(), CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0), .commonModes)
CGEvent.tapEnable(tap: tap, enable: true)
print("""
    Scroll each device in turn; press Control-C to stop.
    backspin reverses events with continuous=0. Trackpads and the Magic Mouse report continuous=1 with
    a nonzero phase or momentum; continuous=1 with both zero suggests driver-emulated smooth scrolling.
    """)
fflush(stdout)
CFRunLoopRun()
