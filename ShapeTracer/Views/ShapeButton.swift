// Views/ShapeButton.swift
import SwiftUI

struct ShapeButton: View {
    let shape: ShapeType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.08))
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: 2)

                GeometryReader { geo in
                    let rect = geo.frame(in: .local).insetBy(dx: 18, dy: 18)
                    shape.path(in: rect)
                        .strokedPath(.init(lineWidth: 6, lineCap: .round, lineJoin: .round))
                        .foregroundStyle(isSelected ? Color.accentColor : Color.primary.opacity(0.9))
                }
                .padding(10)
                .accessibilityHidden(true)

                VStack {
                    Spacer(minLength: 0)
                    Text(shape.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 8)
                }
            }
            .frame(minWidth: 120, minHeight: 120)   // large enough for accessibility
        }
        .accessibilityLabel(shape.title)
        .accessibilityHint("Double-tap to choose \(shape.title) for tracing.")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
