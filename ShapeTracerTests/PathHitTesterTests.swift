import XCTest
@testable import ShapeTracer
import SwiftUI

final class PathHitTesterTests: XCTestCase {
    func testDistanceAndHit_OnAndOffPath() {
        // square outline in a known rect
        let rect = CGRect(x: 100, y: 100, width: 200, height: 200)
        let path = ShapeType.square.path(in: rect)
        let band: CGFloat = 16

        // on-path: mid-point of the top edge
        let onPoint  = CGPoint(x: rect.midX, y: rect.minY)
        // off-path: 30 pt inside the square
        let offPoint = CGPoint(x: rect.midX, y: rect.minY + 30)

        let (distOn,  _, hitOn)  = PathHitTester.distanceAndHit(point: onPoint,  path: path, tolerance: band, for: .square, in: rect)
        let (distOff, _, hitOff) = PathHitTester.distanceAndHit(point: offPoint, path: path, tolerance: band, for: .square, in: rect)

        XCTAssertTrue(hitOn, "Expected on-point to be on-path")
        XCTAssertLessThan(distOn, 1.0, "On-path distance should be near 0")

        XCTAssertFalse(hitOff, "Expected off-point to be off-path")
        XCTAssertGreaterThan(distOff, 10.0, "Off-path distance should be clearly larger")
    }
}
