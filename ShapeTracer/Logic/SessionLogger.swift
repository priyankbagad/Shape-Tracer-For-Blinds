// Logic/SessionLogger.swift
import Foundation
import UIKit

// Per-sample trace row
struct SessionRow {
    let timestampMS: Int   // time since attempt start (ms)
    let x: Double
    let y: Double
    let onPath: Bool
    let distance: Double
    let vertexHit: Bool
    let coverage: Double
}

// Interaction events to study behavior (e.g., resets, prompts, vertices)
enum SessionEventType: String {
    case start, progress, vertex, offpath_prompt, reset, back, complete
}

struct SessionEvent {
    let timestampMS: Int
    let type: SessionEventType
    let value: String? // e.g., "25", "v=3"
}

struct AttemptMeta {
    let shape: ShapeType
    let eyesFree: Bool
    let toleranceBand: Double
    let screenW: Int
    let screenH: Int
    let participantId: String? // optional ("anon" if nil)
}

struct SessionLogger {
    private(set) var rows: [SessionRow] = []
    private(set) var events: [SessionEvent] = []

    mutating func add(row: SessionRow) { rows.append(row) }
    mutating func add(event: SessionEvent) { events.append(event) }
    mutating func reset() { rows.removeAll(); events.removeAll() }

    /// Append a full attempt (summary + events + samples) to a single shared CSV.
    /// File lives in Documents/traces_study.csv and is created with header on first write.
    @discardableResult
    func appendAttemptToSharedCSV(filename: String = "traces_study.csv",
                                  meta: AttemptMeta) -> URL? {
        guard !rows.isEmpty else { return nil }

        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = docs.appendingPathComponent(filename)

        // ---- Derived metrics (attempt-level) ----
        let attemptId = Int(Date().timeIntervalSince1970) // unique-ish
        let durationMS = rows.last?.timestampMS ?? 0
        let coverageFinal = rows.last?.coverage ?? 0
        let samples = rows.count
        let (onPathMS, offPathMS) = accumulateOnOffPathDurations(rows: rows)
        let pathLen = estimatePathLength(rows: rows) // in points
        let verticesHit = events.filter { $0.type == .vertex }.count
        let resetsUsed = events.filter { $0.type == .reset }.count
        let backActions = events.filter { $0.type == .back }.count
        let success = events.contains { $0.type == .complete }

        // Device / environment
        let device = UIDevice.current.model
        let ios = UIDevice.current.systemVersion
        let participant = meta.participantId ?? "anon"

        // ---- CSV header (written once) ----
        let header =
            "row_type," +
            "attempt_id,participant_id,timestamp_iso," +
            "device,ios,screen_w,screen_h," +
            "shape,eyes_free,tolerance_band," +
            "success,duration_ms,samples,coverage_final," +
            "path_length_pts,onpath_time_ms,offpath_time_ms," +
            "event_type,event_value,t_rel_ms," +
            "x,y,onPath,distance,vertexHit,coverage\n"

        // ---- Summary row ----
        let tsISO = iso8601Now()
        let summary =
            "summary," +
            "\(attemptId),\(participant),\(tsISO)," +
            "\(csvEscape(device)),\(csvEscape(ios)),\(meta.screenW),\(meta.screenH)," +
            "\(meta.shape.title),\(meta.eyesFree),\(fmt(meta.toleranceBand))," +
            "\(success),\(durationMS),\(samples),\(fmt(coverageFinal))," +
            "\(fmt(pathLen)),\(onPathMS),\(offPathMS)," +
            ",,,," + // event/sample fields empty in summary
            ",,,\n"

        // ---- Event rows ----
        let eventRows = events.map { e in
            "event," +
            "\(attemptId),\(participant),\(tsISO)," +
            "\(csvEscape(device)),\(csvEscape(ios)),\(meta.screenW),\(meta.screenH)," +
            "\(meta.shape.title),\(meta.eyesFree),\(fmt(meta.toleranceBand))," +
            "\(success),\(durationMS),\(samples),\(fmt(coverageFinal))," +
            "\(fmt(pathLen)),\(onPathMS),\(offPathMS)," +
            "\(e.type.rawValue),\(csvEscape(e.value ?? "")),\(e.timestampMS)," +
            ",,,," + // sample-only fields empty in event rows
            ",\n"
        }.joined()

        // ---- Sample rows (time-series) ----
        let sampleRows = rows.map { r in
            "sample," +
            "\(attemptId),\(participant),\(tsISO)," +
            "\(csvEscape(device)),\(csvEscape(ios)),\(meta.screenW),\(meta.screenH)," +
            "\(meta.shape.title),\(meta.eyesFree),\(fmt(meta.toleranceBand))," +
            "\(success),\(durationMS),\(samples),\(fmt(coverageFinal))," +
            "\(fmt(pathLen)),\(onPathMS),\(offPathMS)," +
            ",,," + // event fields empty in sample rows
            "\(r.timestampMS)," +
            "\(fmt(r.x)),\(fmt(r.y)),\(r.onPath),\(fmt(r.distance)),\(r.vertexHit),\(fmt(r.coverage))\n"
        }.joined()

        let payload = summary + eventRows + sampleRows

        do {
            if FileManager.default.fileExists(atPath: url.path) == false {
                try (header + payload).write(to: url, atomically: true, encoding: .utf8)
            } else {
                let handle = try FileHandle(forWritingTo: url)
                try handle.seekToEnd()
                try handle.write(contentsOf: Data(payload.utf8))
                try handle.close()
            }
            return url
        } catch {
            print("CSV write/append error:", error)
            return nil
        }
    }

    // MARK: - Metrics helpers

    private func accumulateOnOffPathDurations(rows: [SessionRow]) -> (on: Int, off: Int) {
        guard rows.count > 1 else { return (0, 0) }
        var onMS = 0, offMS = 0
        for i in 1..<rows.count {
            let dt = max(0, rows[i].timestampMS - rows[i-1].timestampMS)
            if rows[i-1].onPath { onMS += dt } else { offMS += dt }
        }
        return (onMS, offMS)
    }

    private func estimatePathLength(rows: [SessionRow]) -> Double {
        guard rows.count > 1 else { return 0 }
        var total = 0.0
        for i in 1..<rows.count {
            let dx = rows[i].x - rows[i-1].x
            let dy = rows[i].y - rows[i-1].y
            total += sqrt(dx*dx + dy*dy)
        }
        return total
    }

    // MARK: - CSV helpers

    private func fmt(_ v: Double) -> String { String(format: "%.4f", v) }

    private func iso8601Now() -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.string(from: Date())
    }

    private func csvEscape(_ s: String) -> String {
        if s.contains(",") || s.contains("\"") || s.contains("\n") {
            return "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return s
    }
}
