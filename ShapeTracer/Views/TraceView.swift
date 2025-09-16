// Views/TraceView.swift
import SwiftUI
import UIKit

struct TraceView: View {
    let shape: ShapeType

    @State private var eyesFree = true
    @State private var coverage: Double = 0
    @State private var completed = false
    @State private var logger = SessionLogger()

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 12) {
            // Eyes-Free toggle (leave on by default for blind users)
            Toggle("Eyes-Free announcements", isOn: $eyesFree)
                .toggleStyle(.switch)
                .padding(.horizontal)
                .accessibilityHint("Speaks guidance and progress milestones")

            GeometryReader { geo in
                TraceCanvas(
                    shape: shape,
                    tolerance: .medium,
                    eyesFree: eyesFree,
                    onCoverage: { coverage = $0 },
                    onComplete: { handleComplete(screenSize: geo.size) },
                    onLog: { logger.add(row: $0) },
                    onEvent: { logger.add(event: $0) },
                    onResetRequested: { /* already logged in canvas */ },
                    onBackRequested: { handleBack() }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(alignment: .topLeading) {
                    Text("Coverage: \(Int(coverage * 100))%")
                        .font(.caption)
                        .padding(8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(8)
                        .accessibilityLabel("Coverage \(Int(coverage*100)) percent")
                }
            }

            // Export CSV (Share Sheet) — easiest way to get the file off-device
            Button {
                exportCSV()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export CSV")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.horizontal)
            .accessibilityHint("Share the traces CSV via Files, Mail, or AirDrop.")
        }
        .padding(.top, 10)
        .navigationTitle("Trace \(shape.title)")
        .onAppear {
            Speaker.shared.say("Tap three times anywhere to reset. Tap five times to go back to shape selection. Tap on the outline to start.", priority: .medium)
        }
        .onDisappear { FeedbackManager.shared.stopAll() }
    }

    // MARK: - Handlers

    private func handleBack() {
        FeedbackManager.shared.stopAll()
        Speaker.shared.say("Returning to shape selection.", priority: .high)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { dismiss() }
    }

    private func handleComplete(screenSize: CGSize) {
        guard !completed else { return }
        completed = true

        // Attempt metadata for research CSV
        let meta = AttemptMeta(
            shape: shape,
            eyesFree: eyesFree,
            toleranceBand: Double(ToleranceLevel.medium.band),
            screenW: Int(screenSize.width.rounded()),
            screenH: Int(screenSize.height.rounded()),
            participantId: nil   // or set to an ID if you run a study
        )

        // Append full attempt (summary + events + samples) to a single CSV
        _ = logger.appendAttemptToSharedCSV(filename: "traces_study.csv", meta: meta)

        Speaker.shared.say("You have successfully traced the \(shape.title). Returning to shape selection.", priority: .high)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { dismiss() }
    }

    // MARK: - CSV Export (Share Sheet)

    private func exportCSV() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = docs.appendingPathComponent("traces_study.csv")

        guard FileManager.default.fileExists(atPath: url.path) else {
            Speaker.shared.say("No CSV file yet. Trace a shape first.", priority: .medium)
            return
        }

        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(activityVC, animated: true)
        }
    }
}
