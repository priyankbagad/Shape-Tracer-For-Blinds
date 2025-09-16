import SwiftUI

enum CoverageEstimator {
    static func estimate(points: [CGPoint], path: Path, shape: ShapeType, rect: CGRect) -> Double {
        guard !points.isEmpty else { return 0 }
        let samples = shape.perimeterSamples(in: rect, count: 180)
        var covered = 0
        for s in samples {
            if points.contains(where: { hypot($0.x - s.x, $0.y - s.y) < 18 }) {
                covered += 1
            }
        }
        return Double(covered) / Double(samples.count)
    }
}
