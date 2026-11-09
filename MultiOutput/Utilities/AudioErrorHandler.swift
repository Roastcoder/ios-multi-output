import Foundation

enum AppAudioError: LocalizedError, Equatable {
    case noOutput
    case modeUnavailable(String)
    case channelMapRejected(Int32)
    case outputUnitUnavailable
    case signalUnavailable
    case microphoneDenied
    case noClickDetected

    var errorDescription: String? {
        switch self {
        case .noOutput: "No audio output is available."
        case .modeUnavailable(let mode): "\(mode) isn't available on this version of iOS."
        case .channelMapRejected(let status): "iOS rejected the output routing (\(AudioErrorHandler.statusText(status)))."
        case .outputUnitUnavailable: "The audio engine's output unit isn't available."
        case .signalUnavailable: "The test signal couldn't be created."
        case .microphoneDenied: "Microphone access is off. Turn it on in Settings to measure latency."
        case .noClickDetected: "The microphone didn't pick up the test click. Raise the volume and try again."
        }
    }
}

enum AudioErrorHandler {
    static func message(for error: Error) -> String {
        if let error = error as? LocalizedError, let description = error.errorDescription { return description }
        let error = error as NSError
        return error.domain == NSOSStatusErrorDomain
            ? "Audio error \(statusText(Int32(error.code)))"
            : error.localizedDescription
    }

    /// Core Audio statuses are usually four printable characters.
    nonisolated static func statusText(_ status: Int32) -> String {
        let bytes = withUnsafeBytes(of: status.bigEndian, Array.init)
        guard bytes.allSatisfy({ (32...126).contains($0) }) else { return String(status) }
        return "'" + String(decoding: bytes, as: UTF8.self) + "'"
    }
}
