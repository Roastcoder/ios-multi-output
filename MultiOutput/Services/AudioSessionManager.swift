import AVFoundation
import Observation

@Observable
final class AudioSessionManager {
    private(set) var snapshot = SessionSnapshot()

    @ObservationIgnored var onRouteChange: ((String) -> Void)?
    @ObservationIgnored var onInterruption: ((String, Bool) -> Void)?
    @ObservationIgnored var onMediaServicesReset: (() -> Void)?

    @ObservationIgnored private let session = AVAudioSession.sharedInstance()
    @ObservationIgnored private var observers: [NSObjectProtocol] = []

    func startObserving() {
        guard observers.isEmpty else { return }
        let center = NotificationCenter.default

        observers.append(center.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { [weak self] note in
            let reason = (note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt)
                .flatMap(AVAudioSession.RouteChangeReason.init(rawValue:)) ?? .unknown
            let text = Self.describe(reason)
            Task { @MainActor in self?.onRouteChange?(text) }
        })

        observers.append(center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
            let began = (note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt) == AVAudioSession.InterruptionType.began.rawValue
            Task { @MainActor in
                self?.onInterruption?(began ? "Interruption began" : "Interruption ended", began)
            }
        })

        observers.append(center.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.onMediaServicesReset?() }
        })
    }

    func apply(mode: RoutingMode, configuration: AudioConfiguration) throws {
        let mix: AVAudioSession.CategoryOptions = configuration.mixWithOthers ? [.mixWithOthers] : []
        switch mode {
        case .systemRoute:
            try session.setCategory(.playback, mode: .default, options: mix)
        case .multiRoute:
            try session.setCategory(.multiRoute, mode: .default, options: mix)
        case .dualRoute:
            guard #available(iOS 26.2, *) else { throw AppAudioError.modeUnavailable(mode.title) }
            try session.setCategory(.multiRoute, mode: .dualRoute, options: [.allowBluetoothHFP])
        }
        if let rate = configuration.preferredSampleRate { try session.setPreferredSampleRate(rate) }
        if let milliseconds = configuration.preferredBufferMilliseconds {
            try session.setPreferredIOBufferDuration(milliseconds / 1_000)
        }
        try session.setActive(true)
        if mode.usesChannelMap, session.maximumOutputNumberOfChannels > session.outputNumberOfChannels {
            // Multi-route needs every port's channels open before a channel map can address them.
            try session.setPreferredOutputNumberOfChannels(session.maximumOutputNumberOfChannels)
        }
        refreshSnapshot()
    }

    func applyLatencyMeasurementRoute() throws {
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker])
        try session.setActive(true)
    }

    func currentRoute() -> AudioRoute {
        let route = session.currentRoute
        let activeInputs = Set(route.inputs.map(\.uid))
        var inputs = route.inputs.map { AudioDevice(port: $0, direction: .input, isActive: true) }
        inputs += (session.availableInputs ?? [])
            .filter { !activeInputs.contains($0.uid) }
            .map { AudioDevice(port: $0, direction: .input, isActive: false) }
        return AudioRoute(
            outputs: route.outputs.map { AudioDevice(port: $0, direction: .output, isActive: true) },
            inputs: inputs
        )
    }

    func refreshSnapshot() {
        snapshot = SessionSnapshot(
            category: session.category.rawValue.replacingOccurrences(of: "AVAudioSessionCategory", with: ""),
            mode: session.mode.rawValue.replacingOccurrences(of: "AVAudioSessionMode", with: ""),
            sampleRate: session.sampleRate,
            preferredSampleRate: session.preferredSampleRate,
            ioBufferDuration: session.ioBufferDuration,
            preferredIOBufferDuration: session.preferredIOBufferDuration,
            outputLatency: session.outputLatency,
            inputLatency: session.inputLatency,
            outputChannels: session.outputNumberOfChannels,
            maximumOutputChannels: session.maximumOutputNumberOfChannels,
            systemOutputVolume: session.outputVolume,
            isOtherAudioPlaying: session.isOtherAudioPlaying
        )
    }

    nonisolated private static func describe(_ reason: AVAudioSession.RouteChangeReason) -> String {
        switch reason {
        case .newDeviceAvailable: "New device connected"
        case .oldDeviceUnavailable: "Device disconnected"
        case .categoryChange: "Session category changed"
        case .override: "Route overridden"
        case .wakeFromSleep: "Woke from sleep"
        case .noSuitableRouteForCategory: "No suitable route for this category"
        case .routeConfigurationChange: "Route configuration changed"
        default: "Route changed"
        }
    }
}
