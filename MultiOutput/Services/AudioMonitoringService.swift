import Foundation
import Observation

@Observable
final class AudioMonitoringService {
    private static let historyLength = 48
    private static let eventLimit = 200

    private(set) var level = LevelReading.silent
    private(set) var history = [Float](repeating: 0, count: historyLength)
    private(set) var events: [DiagnosticEvent] = []
    private(set) var interruptionCount = 0
    /// Engine clock against the system host clock. This says nothing about drift between two outputs.
    private(set) var clockDriftPPM: Double?

    @ObservationIgnored private var firstTiming: (samples: Double, host: Double)?

    var routeHistory: [DiagnosticEvent] { events.filter { $0.kind == .route } }
    var errors: [DiagnosticEvent] { events.filter { $0.kind == .error } }

    func ingest(_ reading: LevelReading) {
        level = reading
        history.removeFirst()
        history.append(max(reading.left, reading.right))
    }

    func log(_ kind: DiagnosticEvent.Kind, _ message: String) {
        events.insert(DiagnosticEvent(date: .now, kind: kind, message: message), at: 0)
        if events.count > Self.eventLimit { events.removeLast() }
        if kind == .interruption, message.contains("began") { interruptionCount += 1 }
    }

    func recordTiming(samples: Double, host: Double) {
        guard let first = firstTiming else {
            firstTiming = (samples, host)
            return
        }
        clockDriftPPM = Self.driftPPM(sampleElapsed: samples - first.samples, hostElapsed: host - first.host)
    }

    func resetTiming() {
        firstTiming = nil
        clockDriftPPM = nil
    }

    /// Needs a couple of seconds of data, because short windows mostly measure scheduling jitter.
    nonisolated static func driftPPM(sampleElapsed: Double, hostElapsed: Double) -> Double? {
        guard hostElapsed >= 2 else { return nil }
        return (sampleElapsed - hostElapsed) / hostElapsed * 1_000_000
    }
}
