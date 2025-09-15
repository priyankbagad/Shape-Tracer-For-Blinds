// Views/LandingView.swift
import SwiftUI
import UIKit

struct LandingView: View {
    @State private var selected: ShapeType?
    @StateObject private var speaker = SpeechGuide.shared

    // Fixed order to match spoken positions (TL, TR, BL, BR)
    private let shapes: [ShapeType] = [.square, .circle, .triangle, .star]

    private var guidanceScript: String {
        "Choose a shape. For Square tap top left. For Circle tap top right. For Triangle tap bottom left. For Star tap bottom right."
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Uniform background
                Color(.systemGroupedBackground).ignoresSafeArea()

                // Full-screen 2×2 quadrants
                GeometryReader { geo in
                    let halfW = geo.size.width / 2
                    let halfH = geo.size.height / 2

                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            quadrantButton(shape: shapes[0], position: "Top left",  width: halfW, height: halfH, sort: 4)
                            quadrantButton(shape: shapes[1], position: "Top right", width: halfW, height: halfH, sort: 3)
                        }
                        HStack(spacing: 0) {
                            quadrantButton(shape: shapes[2], position: "Bottom left",  width: halfW, height: halfH, sort: 2)
                            quadrantButton(shape: shapes[3], position: "Bottom right", width: halfW, height: halfH, sort: 1)
                        }
                    }
                    // Thin visual separators between quadrants
                    .overlay { Rectangle().fill(.separator).frame(width: 1) }   // vertical
                    .overlay { Rectangle().fill(.separator).frame(height: 1) }  // horizontal
                }
            }
            .navigationDestination(item: $selected) { shape in
                TraceView(shape: shape)
            }
        }
        .onAppear {
            // If you want speech only when VoiceOver is ON, wrap with:
            // if UIAccessibility.isVoiceOverRunning { ... }
            SpeechGuide.shared.startGuidance(script: guidanceScript)
        }
        .onDisappear { SpeechGuide.shared.stopGuidance() }
    }

    // MARK: - Quadrant Button

    private func quadrantButton(
        shape: ShapeType,
        position: String,
        width: CGFloat,
        height: CGFloat,
        sort: Double
    ) -> some View {
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
                        let rect = CGRect(
                            x: (g.size.width - side)/2,
                            y: (g.size.height - side)/2,
                            width: side,
                            height: side
                        )
                        shape.path(in: rect)
                            .strokedPath(.init(lineWidth: max(3, side * 0.05),
                                               lineCap: .round, lineJoin: .round))
                            .foregroundStyle(Color.primary)
                    }
                    .frame(height: min(width, height) * 0.48)

                    // Keep the text label for low-vision users; VoiceOver will read the accessibility label anyway.
                    Text(shape.title)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.primary)
                }
                .padding(20)
            }
        }
        .buttonStyle(.plain)           // full-rect tap area
        .contentShape(Rectangle())
        .frame(width: width, height: height)
        // VoiceOver
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(shape.title)
        .accessibilityHint("\(position) quadrant. Double-tap to choose \(shape.title) for tracing.")
        .accessibilitySortPriority(sort) // TL -> TR -> BL -> BR
    }
}
