import SwiftUI
import UIKit

struct LandingView: View {
    @State private var selected: ShapeType?
    @StateObject private var speaker = SpeechGuide.shared

    private let shapes: [ShapeType] = [.square, .circle, .triangle, .star]

    private var guidanceScript: String {
        "Choose a shape. For Square tap top left. For Circle tap top right. For Triangle tap bottom left. For Star tap bottom right."
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                GeometryReader { geo in
                    let halfW = geo.size.width / 2
                    let halfH = geo.size.height / 2
                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            quadrantButton(shapes[0], pos: "Top left",  w: halfW, h: halfH, sort: 4)
                            quadrantButton(shapes[1], pos: "Top right", w: halfW, h: halfH, sort: 3)
                        }
                        HStack(spacing: 0) {
                            quadrantButton(shapes[2], pos: "Bottom left",  w: halfW, h: halfH, sort: 2)
                            quadrantButton(shapes[3], pos: "Bottom right", w: halfW, h: halfH, sort: 1)
                        }
                    }
                    .overlay { Rectangle().fill(.separator).frame(width: 1) }
                    .overlay { Rectangle().fill(.separator).frame(height: 1) }
                }
            }
            .navigationDestination(item: $selected) { shape in
                TraceView(shape: shape)
            }
        }
        .onAppear { SpeechGuide.shared.startGuidance(script: guidanceScript) }
        .onDisappear { SpeechGuide.shared.stopGuidance() }
    }

    private func quadrantButton(_ shape: ShapeType, pos: String, w: CGFloat, h: CGFloat, sort: Double) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            SpeechGuide.shared.stopGuidance()
            selected = shape
        } label: {
            ZStack {
                Color(.secondarySystemGroupedBackground)
                VStack(spacing: 12) {
                    GeometryReader { g in
                        let side = min(g.size.width, g.size.height) * 0.52
                        let rect = CGRect(x: (g.size.width - side)/2,
                                          y: (g.size.height - side)/2,
                                          width: side, height: side)
                        shape.path(in: rect)
                            .strokedPath(.init(lineWidth: max(3, side * 0.05), lineCap: .round, lineJoin: .round))
                            .foregroundStyle(Color.primary)
                    }
                    .frame(height: min(w, h) * 0.48)
                    Text(shape.title).font(.title3.weight(.medium)).foregroundStyle(.primary)
                }
                .padding(20)
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .frame(width: w, height: h)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(shape.title)
        .accessibilityHint("\(pos) quadrant. Double-tap to choose \(shape.title) for tracing.")
        .accessibilitySortPriority(sort)
    }
}
