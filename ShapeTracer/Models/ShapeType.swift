// Models/ShapeType.swift
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
                    let ang = (Double(i) * 36.0 - 90.0) * .pi / 180
                    let rad = (i % 2 == 0) ? R : r
                    return CGPoint(x: c.x + CGFloat(cos(ang)) * rad,
                                   y: c.y + CGFloat(sin(ang)) * rad)
                }
                guard let first = pts.first else { return }
                p.move(to: first)
                pts.dropFirst().forEach { p.addLine(to: $0) }
                p.closeSubpath()
            }
        }
    }
}
