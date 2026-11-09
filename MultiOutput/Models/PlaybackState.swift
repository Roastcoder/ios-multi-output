import Foundation

enum PlaybackState: Equatable {
    case stopped, playing, paused

    var title: String {
        switch self {
        case .stopped: "Stopped"
        case .playing: "Playing"
        case .paused: "Paused"
        }
    }
}

enum EngineStatus: Equatable {
    case idle, running, failed(String)

    var title: String {
        switch self {
        case .idle: "Idle"
        case .running: "Running"
        case .failed: "Failed"
        }
    }
}

enum AudioSource: Equatable {
    case file(URL, name: String)
    case signal(TestSignal)

    var title: String {
        switch self {
        case .file(_, let name): name
        case .signal(let signal): signal.title
        }
    }
}

nonisolated struct LevelReading: Sendable, Equatable {
    var left: Float
    var right: Float
    static let silent = LevelReading(left: 0, right: 0)
}

struct DiagnosticEvent: Identifiable, Equatable {
    enum Kind: String {
        case route = "Route"
        case interruption = "Interruption"
        case engine = "Engine"
        case error = "Error"
    }

    let id = UUID()
    let date: Date
    let kind: Kind
    let message: String
}

struct CompatibilityRecord: Identifiable, Codable, Equatable {
    enum Outcome: String, Codable {
        case works = "Works"
        case fails = "Fails"
        case restricted = "Restricted by iOS"

        static func from(engineStarted: Bool, requested: Int, heard: Int) -> Outcome {
            guard engineStarted, heard > 0 else { return engineStarted ? .fails : .restricted }
            return heard >= requested ? .works : .restricted
        }
    }

    var id = UUID()
    let date: Date
    let deviceModel: String
    let systemVersion: String
    let mode: String
    let outputs: [String]
    let heardOutputs: [String]
    let outcome: Outcome
}
