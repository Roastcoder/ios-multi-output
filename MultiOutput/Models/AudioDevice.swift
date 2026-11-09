import AVFoundation

enum AudioDeviceKind: String, Codable, CaseIterable {
    case builtInSpeaker, builtInReceiver, builtInMic, headphones, headsetMic, lineOut, lineIn
    case usb, hdmi, displayPort, airPlay, bluetoothA2DP, bluetoothHFP, bluetoothLE, carAudio
    case continuityMic, virtual, pci, fireWire, avb, thunderbolt, other

    init(port: AVAudioSession.Port) {
        switch port {
        case .builtInSpeaker: self = .builtInSpeaker
        case .builtInReceiver: self = .builtInReceiver
        case .builtInMic: self = .builtInMic
        case .headphones: self = .headphones
        case .headsetMic: self = .headsetMic
        case .lineOut: self = .lineOut
        case .lineIn: self = .lineIn
        case .usbAudio: self = .usb
        case .HDMI: self = .hdmi
        case .displayPort: self = .displayPort
        case .airPlay: self = .airPlay
        case .bluetoothA2DP: self = .bluetoothA2DP
        case .bluetoothHFP: self = .bluetoothHFP
        case .bluetoothLE: self = .bluetoothLE
        case .carAudio: self = .carAudio
        case .continuityMicrophone: self = .continuityMic
        case .virtual: self = .virtual
        case .PCI: self = .pci
        case .fireWire: self = .fireWire
        case .AVB: self = .avb
        case .thunderbolt: self = .thunderbolt
        default: self = .other
        }
    }

    var title: String {
        switch self {
        case .builtInSpeaker: "Built-in Speaker"
        case .builtInReceiver: "Earpiece"
        case .builtInMic: "Built-in Microphone"
        case .headphones: "Wired Headphones"
        case .headsetMic: "Wired Headset Mic"
        case .lineOut: "Line Out"
        case .lineIn: "Line In"
        case .usb: "USB Audio"
        case .hdmi: "HDMI"
        case .displayPort: "DisplayPort"
        case .airPlay: "AirPlay"
        case .bluetoothA2DP: "Bluetooth (A2DP)"
        case .bluetoothHFP: "Bluetooth (Hands-Free)"
        case .bluetoothLE: "Bluetooth LE"
        case .carAudio: "CarPlay Audio"
        case .continuityMic: "Continuity Microphone"
        case .virtual: "Virtual"
        case .pci: "PCI"
        case .fireWire: "FireWire"
        case .avb: "AVB"
        case .thunderbolt: "Thunderbolt"
        case .other: "Other"
        }
    }

    var symbol: String {
        switch self {
        case .builtInSpeaker: "speaker.wave.2.fill"
        case .builtInReceiver: "iphone"
        case .builtInMic, .continuityMic, .headsetMic: "mic.fill"
        case .headphones: "headphones"
        case .lineOut, .lineIn: "cable.connector"
        case .usb, .thunderbolt, .fireWire, .pci: "cable.connector.horizontal"
        case .hdmi, .displayPort: "tv"
        case .airPlay: "airplayaudio"
        case .bluetoothA2DP, .bluetoothHFP, .bluetoothLE: "wave.3.right"
        case .carAudio: "car.fill"
        case .virtual, .avb, .other: "waveform"
        }
    }
}

struct AudioChannel: Hashable, Codable {
    let name: String
    let number: Int
}

enum AudioDirection: String, Codable {
    case output, input
}

/// One port exactly as AVAudioSession reports it. Fields iOS doesn't expose per port, such as sample rate, are deliberately absent.
struct AudioDevice: Identifiable, Hashable {
    var id: String { "\(direction.rawValue):\(uid)" }
    let uid: String
    let name: String
    let kind: AudioDeviceKind
    let direction: AudioDirection
    let isActive: Bool
    let channels: [AudioChannel]
    let dataSources: [String]
    let isSpatialAudioEnabled: Bool
    let hasHardwareVoiceCallProcessing: Bool

    init(
        uid: String, name: String, kind: AudioDeviceKind, direction: AudioDirection, isActive: Bool,
        channels: [AudioChannel] = [], dataSources: [String] = [],
        isSpatialAudioEnabled: Bool = false, hasHardwareVoiceCallProcessing: Bool = false
    ) {
        self.uid = uid
        self.name = name
        self.kind = kind
        self.direction = direction
        self.isActive = isActive
        self.channels = channels
        self.dataSources = dataSources
        self.isSpatialAudioEnabled = isSpatialAudioEnabled
        self.hasHardwareVoiceCallProcessing = hasHardwareVoiceCallProcessing
    }

    init(port: AVAudioSessionPortDescription, direction: AudioDirection, isActive: Bool) {
        self.init(
            uid: port.uid,
            name: port.portName,
            kind: AudioDeviceKind(port: port.portType),
            direction: direction,
            isActive: isActive,
            channels: (port.channels ?? []).map { AudioChannel(name: $0.channelName, number: $0.channelNumber) },
            dataSources: (port.dataSources ?? []).map(\.dataSourceName),
            isSpatialAudioEnabled: port.isSpatialAudioEnabled,
            hasHardwareVoiceCallProcessing: port.hasHardwareVoiceCallProcessing
        )
    }
}
