import CoreGraphics
import XCTest
@testable import ScrollCore

final class ScrollFlipTests: XCTestCase {
    private func makeEvent(units: CGScrollEventUnit, vertical: Int32, horizontal: Int32) throws -> CGEvent {
        try XCTUnwrap(CGEvent(scrollWheelEvent2Source: nil, units: units, wheelCount: 2,
                              wheel1: vertical, wheel2: horizontal, wheel3: 0))
    }

    private func snapshot(_ event: CGEvent) -> [Double] {
        [event.getIntegerValueField(.scrollWheelEventDeltaAxis1),
         event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1),
         event.getIntegerValueField(.scrollWheelEventDeltaAxis2),
         event.getIntegerValueField(.scrollWheelEventPointDeltaAxis2)].map(Double.init)
        + [event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1),
           event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2)]
    }

    func testLineEventsAreMouseWheelAndPixelEventsAreNot() throws {
        XCTAssertTrue(ScrollFlip.isMouseWheel(try makeEvent(units: .line, vertical: 3, horizontal: 0)))
        let trackpadLike = try makeEvent(units: .pixel, vertical: 3, horizontal: 0)
        trackpadLike.setIntegerValueField(.scrollWheelEventIsContinuous, value: 1)
        XCTAssertFalse(ScrollFlip.isMouseWheel(trackpadLike))
    }

    func testInvertNegatesEveryDeltaOnBothAxes() throws {
        let event = try makeEvent(units: .line, vertical: 3, horizontal: -2)
        let before = snapshot(event)
        XCTAssertTrue(before.allSatisfy { $0 != 0 }, "fixture must populate every delta field: \(before)")

        ScrollFlip.invert(event)

        XCTAssertEqual(snapshot(event), before.map { -$0 })
    }

    func testOnlyMouseWheelIsInvertedAndOnlyWithNaturalScrolling() throws {
        let wheel = try makeEvent(units: .line, vertical: 1, horizontal: 0)
        let trackpadLike = try makeEvent(units: .pixel, vertical: 10, horizontal: 0)
        trackpadLike.setIntegerValueField(.scrollWheelEventIsContinuous, value: 1)

        XCTAssertTrue(ScrollFlip.shouldInvert(wheel, naturalScrolling: true))
        XCTAssertFalse(ScrollFlip.shouldInvert(wheel, naturalScrolling: false),
                       "with natural scrolling off the wheel already scrolls traditionally")
        XCTAssertFalse(ScrollFlip.shouldInvert(trackpadLike, naturalScrolling: true))
    }
}
