// Views/TraceCanvas.swift
import SwiftUI
import AVFoundation

struct TraceCanvas: View {
    // Inputs
    let shape: ShapeType
    let tolerance: ToleranceLevel
    let eyesFree: Bool

    // Callbacks
    var onCoverage: (Double) -> Void
    var onComplete: () -> Void
    var onLog: (SessionRow) -> Void
    var onEvent: (SessionEvent) -> Void = { _ in }   // <-- NEW: events hook (default no-op)
    var onResetRequested: () -> Void = {}
    var onBackRequested: () -> Void = {}

    // State
    @State private var points: [CGPoint] = []
    @State private var lastAnnounced: Int = 0
    @State private var lastVertexHit: Int? = nil
    @State private var startTime = CACurrentMediaTime()
    @State private var coverageNow: Double = 0

    enum Phase { case waitingForStart, tracing }
    @State private var phase: Phase = .waitingForStart

    // Thresholds
    private let completionThreshold: Double = 0.75
    private let minStrokeFraction: CGFloat = 0.40
    @State private var lastOffPathSpeak: TimeInterval = 0

    var body: some View {
        GeometryReader { geo in
            // Keep circle true & square crisp by fitting to a centered square rect
            let rawRect = geo.frame(in: .local).insetBy(dx: 20, dy: 20)
            let drawRect = squareAspectFit(in: rawRect)
            let outlinePath = shape.path(in: drawRect)

            // Crisp corners for square; round for others
            let outlineStyle: StrokeStyle = {
                switch shape {
                case .square: return .init(lineWidth: 10, lineCap: .butt, lineJoin: .miter, miterLimit: 10)
                default:      return .init(lineWidth: 10, lineCap: .round, lineJoin: .round)
                }
            }()

            ZStack {
                // Ideal outline
                outlinePath
                    .stroke(style: outlineStyle)
                    .foregroundStyle(.secondary.opacity(0.28))

                // User trace
                Path { p in
                    guard let first = points.first else { return }
                    p.move(to: first)
                    for pt in points.dropFirst() { p.addLine(to: pt) }
                }
                .stroke(style: .init(lineWidth: 12, lineCap: .round, lineJoin: .round))
                .foregroundStyle(.tint)
            }
            .contentShape(Rectangle())

            // ===== Gestures =====

            // Triple-tap: reset attempt
            .simultaneousGesture(
                TapGesture(count: 3).onEnded {
                    onEvent(SessionEvent(timestampMS: relMS(), type: .reset, value: nil))
                    resetAttempt()
                    onResetRequested()
                }
            )

            // Five-tap: back to landing
            .simultaneousGesture(
                TapGesture(count: 5).onEnded {
                    onEvent(SessionEvent(timestampMS: relMS(), type: .back, value: nil))
                    FeedbackManager.shared.stopAll()
                    onBackRequested()
                }
            )

            // Drag: start (tap-on-outline) + tracing
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let pt = value.location

                        // ===== Phase 1: choose start ANYWHERE on the outline =====
                        if phase == .waitingForStart {
                            let (dist, nearest, onPath) = PathHitTester.distanceAndHit(
                                point: pt, path: outlinePath, tolerance: tolerance.band, for: shape, in: drawRect
                            )

                            // gentle cue while near outline to help discovery
                            if dist < tolerance.band * 2 {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }

                            // Lock start if on/very near outline → snap & begin tracing
                            if onPath || dist < max(12, tolerance.band * 0.8) {
                                phase = .tracing
                                points = [nearest]
                                onEvent(SessionEvent(timestampMS: relMS(), type: .start, value: nil))
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                if eyesFree { Speaker.shared.say("Starting point. Begin tracing.", priority: .high) }
                                FeedbackManager.shared.prepareAudio()
                                startTime = CACurrentMediaTime()
                            } else {
                                if eyesFree {
                                    let now = CACurrentMediaTime()
                                    if now - lastOffPathSpeak > 1.2 {
                                        lastOffPathSpeak = now
                                        Speaker.shared.say("Tap on the outline to start.", priority: .low)
                                        onEvent(SessionEvent(timestampMS: relMS(), type: .offpath_prompt, value: "prestart"))
                                    }
                                }
                            }
                            return
                        }

                        // ===== Phase 2: tracing =====
                        points.append(pt)

                        // Distance + onPath using the same fitted rect
                        let (dist, _, onPath) = PathHitTester.distanceAndHit(
                            point: pt, path: outlinePath, tolerance: tolerance.band, for: shape, in: drawRect
                        )

                        // Pitch maps to distance; tick when on-path
                        FeedbackManager.shared.updateContinuousTone(distance: dist, band: tolerance.band)
                        if onPath { FeedbackManager.shared.lightTick() }

                        // Corner earcons
                        if let idx = shape.vertexIndex(near: pt, in: drawRect, threshold: 24),
                           idx != lastVertexHit {
                            lastVertexHit = idx
                            FeedbackManager.shared.vertexDing()
                            onEvent(SessionEvent(timestampMS: relMS(), type: .vertex, value: "v=\(idx)"))
                        }

                        // Coverage against true outline
                        let cov = CoverageEstimator.estimate(points: points, path: outlinePath, shape: shape, rect: drawRect)
                        coverageNow = cov
                        onCoverage(cov)

                        // Progress buckets with events
                        if eyesFree {
                            let bucket = (Int(cov * 100) / 25) * 25
                            if bucket > lastAnnounced && [25,50,75,100].contains(bucket) {
                                lastAnnounced = bucket
                                Speaker.shared.say("\(bucket) percent", priority: .low)
                                onEvent(SessionEvent(timestampMS: relMS(), type: .progress, value: "\(bucket)"))
                            }
                        }

                        // Coaching when off-path (throttled)
                        if eyesFree && !onPath {
                            let now = CACurrentMediaTime()
                            if now - lastOffPathSpeak > 1.2 {
                                lastOffPathSpeak = now
                                Speaker.shared.say("Try to find the outline.", priority: .low)
                                onEvent(SessionEvent(timestampMS: relMS(), type: .offpath_prompt, value: "trace"))
                            }
                        }

                        // Sample row for CSV
                        onLog(SessionRow(
                            timestampMS: relMS(),
                            x: Double(pt.x), y: Double(pt.y),
                            onPath: onPath,
                            distance: Double(dist),
                            vertexHit: lastVertexHit != nil,
                            coverage: cov
                        ))
                    }
                    .onEnded { _ in
                        if phase == .waitingForStart {
                            if eyesFree { Speaker.shared.say("Tap on the outline to start.", priority: .medium) }
                            return
                        }

                        // Require decent stroke length + coverage for completion
                        let strokeOK = strokeLength(points) >= minStrokeFraction * rectPerimeter(drawRect)
                        let finished = (coverageNow >= completionThreshold) && strokeOK
                        if finished {
                            FeedbackManager.shared.finishSuccess()
                            if eyesFree { Speaker.shared.say("Complete", priority: .high) }
                            onEvent(SessionEvent(timestampMS: relMS(), type: .complete, value: "success"))
                            onComplete()
                        } else {
                            FeedbackManager.shared.stopAll()
                            if eyesFree { Speaker.shared.say("Not quite. You can reset with three taps, or try again.", priority: .high) }
                            onEvent(SessionEvent(timestampMS: relMS(), type: .complete, value: "incomplete"))
                        }
                    }
            )
            .onAppear {
                resetAttempt(announce: true)
            }
            .onDisappear {
                FeedbackManager.shared.stopAll()
            }
            .accessibilityLabel("Tracing area for \(shape.title)")
            .accessibilityHint("Tap three times to reset. Tap five times to go back. Tap on the outline to start, then trace the shape.")
        }
    }

    // MARK: - Helpers

    /// Centered square that fits within the given rect
    private func squareAspectFit(in r: CGRect) -> CGRect {
        let side = min(r.width, r.height)
        return CGRect(x: r.midX - side/2, y: r.midY - side/2, width: side, height: side)
    }

    private func rectPerimeter(_ r: CGRect) -> CGFloat { 2 * (r.width + r.height) }

    private func strokeLength(_ pts: [CGPoint]) -> CGFloat {
        guard pts.count > 1 else { return 0 }
        return (1..<pts.count).reduce(0) { sum, i in
            sum + hypot(pts[i].x - pts[i-1].x, pts[i].y - pts[i-1].y)
        }
    }

    private func relMS() -> Int {
        Int((CACurrentMediaTime()) * 1000) // relative ms is fine for deltas
    }

    private func resetAttempt(announce: Bool = false) {
        FeedbackManager.shared.stopAll()
        points.removeAll()
        coverageNow = 0
        lastAnnounced = 0
        lastVertexHit = nil
        phase = .waitingForStart
        if announce && eyesFree {
            Speaker.shared.say("Tap three times anywhere to reset. Tap five times to go back. Tap on the outline to start.", priority: .medium)
        }
        onCoverage(0)
    }
}
