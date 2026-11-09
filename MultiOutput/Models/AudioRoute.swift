import Foundation

enum RoutingMode: String, Codable, CaseIterable, Identifiable {
    case systemRoute, multiRoute, dualRoute

    var id: String { rawValue }

    var title: String {
        switch self {
        case .systemRoute: "System Route"
        case .multiRoute: "Multi-Route"
        case .dualRoute: "Dual Route"
        }
    }

    var detail: String {
        switch self {
        case .systemRoute: "One destination chosen by iOS. Works with the speaker, Bluetooth and AirPlay."
        case .multiRoute: "Drives eligible wired outputs at the same time: USB, line out, headphones and HDMI."
        case .dualRoute: "Built-in speaker plus one input/output headset. Bluetooth uses call-quality audio. Needs iOS 26.2."
        }
    }

    var usesChannelMap: Bool { self != .systemRoute }

    var isSupportedOnThisOS: Bool {
        guard self == .dualRoute else { return true }
        if #available(iOS 26.2, *) { return true }
        return false
    }
}

/// Whether a port type may join a mode, taken from the rules in AVAudioSessionTypes.h (iOS 26.5 SDK).
enum OutputEligibility: Equatable {
    case eligible
    case eligibleOnlyWhenAlone
    case notEligible

    static func of(_ kind: AudioDeviceKind, in mode: RoutingMode) -> OutputEligibility {
        switch mode {
        case .systemRoute:
            return .eligibleOnlyWhenAlone
        case .multiRoute:
            switch kind {
            case .usb, .lineOut, .headphones, .hdmi: return .eligible
            case .builtInSpeaker: return .eligibleOnlyWhenAlone
            default: return .notEligible
            }
        case .dualRoute:
            switch kind {
            case .builtInSpeaker, .headphones, .bluetoothLE, .bluetoothHFP: return .eligible
            default: return .notEligible
            }
        }
    }

    var label: String {
        switch self {
        case .eligible: "Can combine"
        case .eligibleOnlyWhenAlone: "Single output only"
        case .notEligible: "Can't combine in this mode"
        }
    }
}

struct AudioRoute: Equatable {
    var outputs: [AudioDevice] = []
    var inputs: [AudioDevice] = []

    var outputChannelCount: Int { outputs.reduce(0) { $0 + $1.channels.count } }
    var summary: String { outputs.isEmpty ? "No active output" : outputs.map(\.name).joined(separator: " + ") }
}

struct SessionSnapshot: Equatable {
    var category = "–"
    var mode = "–"
    var sampleRate = 0.0
    var preferredSampleRate = 0.0
    var ioBufferDuration = 0.0
    var preferredIOBufferDuration = 0.0
    var outputLatency = 0.0
    var inputLatency = 0.0
    var outputChannels = 0
    var maximumOutputChannels = 0
    var systemOutputVolume: Float = 0
    var isOtherAudioPlaying = false
}

/// A pairing from Apple's documentation. `tested` stays nil until a device run is recorded.
struct RouteCombination: Identifiable {
    enum Support: String {
        case documented = "Documented as supported"
        case restricted = "Restricted by iOS"
        case notDocumented = "Not documented"
    }

    var id: String { name }
    let name: String
    let mode: String
    let support: Support
    let note: String

    static let reference: [RouteCombination] = [
        .init(name: "USB + wired headphones", mode: "Multi-Route", support: .documented, note: "Apple's own example for the category."),
        .init(name: "USB + HDMI", mode: "Multi-Route", support: .documented, note: "Both are listed as eligible outputs."),
        .init(name: "Line out + headphones", mode: "Multi-Route", support: .documented, note: "Both are listed as eligible outputs."),
        .init(name: "Speaker + wired output", mode: "Multi-Route", support: .restricted, note: "The speaker is only used when no other eligible output is connected."),
        .init(name: "Speaker + wired headset", mode: "Dual Route", support: .documented, note: "iOS 26.2 or later. The speaker is the primary route."),
        .init(name: "Speaker + Bluetooth headset", mode: "Dual Route", support: .documented, note: "iOS 26.2 or later. Hands-free or LE audio only."),
        .init(name: "Bluetooth A2DP + anything", mode: "Multi-Route", support: .restricted, note: "The A2DP option can't be enabled in this category."),
        .init(name: "AirPlay + local output", mode: "Multi-Route", support: .notDocumented, note: "AirPlay isn't on the eligible output list."),
    ]
}
