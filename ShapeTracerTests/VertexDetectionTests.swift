import XCTest
@testable import ShapeTracer
import SwiftUI

final class VertexDetectionTests: XCTestCase {
    func testVertexDetection_ReturnsCorrectCorner() {
        let rect = CGRect(x: 50, y: 50, width: 120, height: 120)

        // Near top-left and bottom-right corners
        let nearTL = CGPoint(x: rect.minX + 5, y: rect.minY + 5)
        let nearBR = CGPoint(x: rect.maxX - 5, y: rect.maxY - 5)

        let idxTL = ShapeType.square.vertexIndex(near: nearTL, in: rect, threshold: 24)
        let idxBR = ShapeType.square.vertexIndex(near: nearBR, in: rect, threshold: 24)

        // our order: [top-left, top-right, bottom-right, bottom-left]
        XCTAssertEqual(idxTL, 0)
        XCTAssertEqual(idxBR, 2)
    }
}
