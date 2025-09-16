import SwiftUI

enum PathHitTester {
    static func distanceAndHit(
        point: CGPoint,
        path: Path,
        tolerance: CGFloat,
        for shape: ShapeType,
        in rect: CGRect
    ) -> (distance: CGFloat, nearest: CGPoint, onPath: Bool) {
        let samples = shape.perimeterSamples(in: rect, count: 360)
        var best = CGFloat.greatestFiniteMagnitude
        var nearest = CGPoint.zero
        for s in samples {
            let d = hypot(point.x - s.x, point.y - s.y)
            if d < best { best = d; nearest = s }
        }
        return (best, nearest, best <= tolerance)
    }
}
