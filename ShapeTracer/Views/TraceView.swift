// Views/TraceView.swift
import SwiftUI

struct TraceView: View {
    let shape: ShapeType

    var body: some View {
        VStack(spacing: 16) {
            Text("Tracing: \(shape.title)")
                .font(.title3).bold()
                .frame(maxWidth: .infinity, alignment: .leading)

            GeometryReader { geo in
                let rect = geo.frame(in: .local).insetBy(dx: 24, dy: 24)
                shape.path(in: rect)
                    .strokedPath(.init(lineWidth: 8, lineCap: .round, lineJoin: .round))
                    .foregroundStyle(.blue.opacity(0.6))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(radius: 1, y: 1)

            Spacer(minLength: 0)
        }
        .padding(20)
        .navigationTitle(shape.title)
        .accessibilityLabel("Tracing screen for \(shape.title)")
        .accessibilityHint("Drag your finger along the outline to trace the shape.")
    }
}
