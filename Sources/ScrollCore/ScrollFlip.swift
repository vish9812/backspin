import CoreGraphics
import CoreFoundation

public enum ScrollFlip {
    private static let axes: [(delta: CGEventField, fixed: CGEventField, point: CGEventField)] = [
        (.scrollWheelEventDeltaAxis1, .scrollWheelEventFixedPtDeltaAxis1, .scrollWheelEventPointDeltaAxis1),
        (.scrollWheelEventDeltaAxis2, .scrollWheelEventFixedPtDeltaAxis2, .scrollWheelEventPointDeltaAxis2),
    ]

    /// Trackpads and the Magic Mouse report continuous scrolling; notched mouse wheels don't.
    public static func isMouseWheel(_ event: CGEvent) -> Bool {
        event.getIntegerValueField(.scrollWheelEventIsContinuous) == 0
    }

    /// The system applies one direction to every device, so with natural scrolling on, flipping
    /// wheel events gives the mouse traditional scrolling while the trackpad stays natural.
    public static func shouldInvert(_ event: CGEvent, naturalScrolling: Bool) -> Bool {
        naturalScrolling && isMouseWheel(event)
    }

    public static func invert(_ event: CGEvent) {
        // Read every field before writing any: setting the line delta can make CoreGraphics
        // recompute the fixed-point and pixel deltas, which would then be negated twice.
        let values = axes.map { axis in
            (event.getIntegerValueField(axis.delta),
             event.getDoubleValueField(axis.fixed),
             event.getIntegerValueField(axis.point))
        }
        for (axis, value) in zip(axes, values) {
            event.setIntegerValueField(axis.delta, value: -value.0)
            event.setDoubleValueField(axis.fixed, value: -value.1)
            event.setIntegerValueField(axis.point, value: -value.2)
        }
    }

    /// The key is absent until the user first changes the setting, and macOS defaults it to on.
    public static func systemNaturalScrolling() -> Bool {
        let key = "com.apple.swipescrolldirection" as CFString
        CFPreferencesAppSynchronize(kCFPreferencesAnyApplication)
        return CFPreferencesCopyAppValue(key, kCFPreferencesAnyApplication) as? Bool ?? true
    }
}
