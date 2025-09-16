import SwiftUI

enum ShapeType: String, CaseIterable, Identifiable {
    case square, circle, triangle, star
    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    func path(in rect: CGRect) -> Path {
        switch self {
        case .square:
            return Path { $0.addRect(rect) }
        case .circle:
            return Path(ellipseIn: rect)
        case .triangle:
            let top = CGPoint(x: rect.midX, y: rect.minY)
            let left = CGPoint(x: rect.minX, y: rect.maxY)
            let right = CGPoint(x: rect.maxX, y: rect.maxY)
            return Path { p in
                p.move(to: top); p.addLine(to: left); p.addLine(to: right); p.closeSubpath()
            }
        case .star:
            return Path { p in
                let c = CGPoint(x: rect.midX, y: rect.midY)
                let R = min(rect.width, rect.height) * 0.5
                let r = R * 0.38
                let pts = (0..<10).map { i -> CGPoint in
                    let ang = (Double(i) * 36.0 - 90.0) * .pi/180
                    let rad = (i % 2 == 0) ? R : r
                    return CGPoint(x: c.x + CGFloat(cos(ang))*rad,
                                   y: c.y + CGFloat(sin(ang))*rad)
                }
                guard let first = pts.first else { return }
                p.move(to: first)
                pts.dropFirst().forEach { p.addLine(to: $0) }
                p.closeSubpath()
            }
        }
    }
}

// MARK: - Vertices for corner earcons
extension ShapeType {
    func vertices(in rect: CGRect) -> [CGPoint] {
        switch self {
        case .square:
            return [
                rect.origin,
                CGPoint(x: rect.maxX, y: rect.minY),
                CGPoint(x: rect.maxX, y: rect.maxY),
                CGPoint(x: rect.minX, y: rect.maxY)
            ]
        case .triangle:
            return [
                CGPoint(x: rect.midX, y: rect.minY),
                CGPoint(x: rect.maxX, y: rect.maxY),
                CGPoint(x: rect.minX, y: rect.maxY)
            ]
        case .star:
            var tips: [CGPoint] = []
            let c = CGPoint(x: rect.midX, y: rect.midY)
            let R = min(rect.width, rect.height) * 0.5
            for i in stride(from: 0, to: 360, by: 72) {
                let a = (Double(i) - 90) * .pi/180
                tips.append(CGPoint(x: c.x + CGFloat(cos(a))*R,
                                    y: c.y + CGFloat(sin(a))*R))
            }
            return tips
        case .circle:
            return []
        }
    }

    func vertexIndex(near p: CGPoint, in rect: CGRect, threshold: CGFloat) -> Int? {
        let vs = vertices(in: rect)
        for (i, v) in vs.enumerated() {
            if hypot(p.x - v.x, p.y - v.y) < threshold { return i }
        }
        return nil
    }
}

// MARK: - True-outline sampling for coverage/hit testing
extension ShapeType {
    func perimeterSamples(in rect: CGRect, count N: Int) -> [CGPoint] {
        switch self {
        case .circle:
            let cx = rect.midX, cy = rect.midY
            let rx = rect.width * 0.5, ry = rect.height * 0.5
            return (0..<N).map { i in
                let t = Double(i) / Double(N) * 2.0 * .pi
                return CGPoint(x: cx + CGFloat(cos(t))*rx,
                               y: cy + CGFloat(sin(t))*ry)
            }
        case .square:
            return perimeterSamplesOfRect(rect, count: N)
        case .triangle:
            let pts = [
                CGPoint(x: rect.midX, y: rect.minY),
                CGPoint(x: rect.maxX, y: rect.maxY),
                CGPoint(x: rect.minX, y: rect.maxY)
            ]
            return sampleEvenlyAlongPolyline(points: pts + [pts[0]], count: N)
        case .star:
            let c = CGPoint(x: rect.midX, y: rect.midY)
            let R = min(rect.width, rect.height) * 0.5
            let r = R * 0.38
            let poly: [CGPoint] = (0..<10).map { i in
                let ang = (Double(i) * 36.0 - 90.0) * .pi/180
                let rad = (i % 2 == 0) ? R : r
                return CGPoint(x: c.x + CGFloat(cos(ang))*rad,
                               y: c.y + CGFloat(sin(ang))*rad)
            }
            return sampleEvenlyAlongPolyline(points: poly + [poly[0]], count: N)
        }
    }

    private func perimeterSamplesOfRect(_ r: CGRect, count N: Int) -> [CGPoint] {
        var pts: [CGPoint] = []
        let per = 2*(r.width + r.height)
        for i in 0..<N {
            let d = CGFloat(i)/CGFloat(N) * per
            switch d {
            case 0..<r.width:
                pts.append(CGPoint(x: r.minX + d, y: r.minY))
            case r.width..<(r.width + r.height):
                pts.append(CGPoint(x: r.maxX, y: r.minY + (d - r.width)))
            case (r.width + r.height)..<(2*r.width + r.height):
                pts.append(CGPoint(x: r.maxX - (d - (r.width + r.height)), y: r.maxY))
            default:
                pts.append(CGPoint(x: r.minX, y: r.maxY - (d - (2*r.width + r.height))))
            }
        }
        return pts
    }
}

private func sampleEvenlyAlongPolyline(points: [CGPoint], count: Int) -> [CGPoint] {
    guard points.count >= 2, count > 0 else { return [] }
    var segLens: [CGFloat] = []
    var total: CGFloat = 0
    for i in 0..<(points.count - 1) {
        let L = hypot(points[i+1].x - points[i].x, points[i+1].y - points[i].y)
        segLens.append(L); total += L
    }
    func pointAt(distance t: CGFloat) -> CGPoint {
        var d = t
        for i in 0..<segLens.count {
            if d <= segLens[i] || i == segLens.count - 1 {
                let a = points[i], b = points[i+1]
                let u = segLens[i] == 0 ? 0 : d/segLens[i]
                return CGPoint(x: a.x + (b.x - a.x)*u,
                               y: a.y + (b.y - a.y)*u)
            }
            d -= segLens[i]
        }
        return points.last!
    }
    return (0..<count).map { i in
        let t = CGFloat(i) / CGFloat(count) * total
        return pointAt(distance: t)
    }
}
// MARK: - Start anchor (where the user begins)
extension ShapeType {
    /// A consistent starting anchor on the outline, plus a short description (for speech)
    func startAnchor(in rect: CGRect) -> (point: CGPoint, description: String) {
        switch self {
        case .circle:
            // Top center of the circle
            return (CGPoint(x: rect.midX, y: rect.minY), "top center")
        case .square:
            // Top-left corner
            return (CGPoint(x: rect.minX, y: rect.minY), "top left corner")
        case .triangle:
            // Top vertex
            return (CGPoint(x: rect.midX, y: rect.minY), "top vertex")
        case .star:
            // Top tip
            return (CGPoint(x: rect.midX, y: rect.minY), "top tip")
        }
    }
}
