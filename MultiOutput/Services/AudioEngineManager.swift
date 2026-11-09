import AVFoundation
import AudioToolbox
import Observation

/// One AVAudioEngine feeds every destination from one render callback, so destinations share the same samples.
/// iOS doesn't expose per-port hardware clocks, so nothing here can correct drift between ports.
@Observable
final class AudioEngineManager {
    private(set) var playback: PlaybackState = .stopped
    private(set) var status: EngineStatus = .idle
    private(set) var duration = 0.0
    var masterVolume: Float = 1 {
        didSet { applyVolume() }
    }
    var isMuted = false {
        didSet { applyVolume() }
    }

    @ObservationIgnored var onLevels: ((LevelReading) -> Void)?
    @ObservationIgnored var onFinished: (() -> Void)?
    @ObservationIgnored var onConfigurationChange: (() -> Void)?

    @ObservationIgnored private let engine = AVAudioEngine()
    @ObservationIgnored private let player = AVAudioPlayerNode()
    @ObservationIgnored private var generation = 0
    @ObservationIgnored private var tapInstalled = false
    @ObservationIgnored private var configurationObserver: NSObjectProtocol?

    init() {
        engine.attach(player)
        configurationObserver = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.onConfigurationChange?() }
        }
    }

    var hardwareSampleRate: Double {
        engine.outputNode.outputFormat(forBus: 0).sampleRate
    }

    var presentationLatency: Double {
        engine.outputNode.presentationLatency
    }

    /// Playback position, and the paired sample and host clocks used for drift measurement.
    var timing: (position: Double, samples: Double, host: Double)? {
        guard playback == .playing,
              let node = player.lastRenderTime, node.isSampleTimeValid, node.isHostTimeValid,
              let time = player.playerTime(forNodeTime: node), time.sampleRate > 0
        else { return nil }
        return (
            Double(time.sampleTime) / time.sampleRate,
            Double(node.sampleTime) / node.sampleRate,
            AVAudioTime.seconds(forHostTime: node.hostTime)
        )
    }

    func play(_ source: AudioSource, channelMap: [Int32]?, parameters: SignalParameters) throws {
        stop()
        let rate = hardwareSampleRate
        guard rate > 0, let outputFormat = AudioFormatHelper.stereo(sampleRate: rate) else { throw AppAudioError.noOutput }

        do {
            engine.connect(engine.mainMixerNode, to: engine.outputNode, format: outputFormat)
            if let channelMap { try apply(channelMap) }

            generation += 1
            let done = Self.completion(generation) { [weak self] finished in
                Task { @MainActor in self?.playbackEnded(generation: finished) }
            }

            switch source {
            case .file(let url, _):
                let file = try AVAudioFile(forReading: url)
                engine.connect(player, to: engine.mainMixerNode, format: file.processingFormat)
                duration = Double(file.length) / file.processingFormat.sampleRate
                player.scheduleFile(file, at: nil, completionCallbackType: .dataPlayedBack, completionHandler: done)
            case .signal(let signal):
                var parameters = parameters
                parameters.sampleRate = rate
                guard let buffer = TestSignalGenerator.buffer(signal, parameters) else { throw AppAudioError.signalUnavailable }
                engine.connect(player, to: engine.mainMixerNode, format: buffer.format)
                duration = parameters.duration
                player.scheduleBuffer(buffer, at: nil, options: [], completionCallbackType: .dataPlayedBack, completionHandler: done)
            }

            installLevelTap()
            applyVolume()
            engine.prepare()
            try engine.start()
            player.play()
            playback = .playing
            status = .running
        } catch {
            stop()
            status = .failed(AudioErrorHandler.message(for: error))
            throw error
        }
    }

    func pause() {
        guard playback == .playing else { return }
        player.pause()
        playback = .paused
    }

    func resume() throws {
        guard playback == .paused else { return }
        if !engine.isRunning { try engine.start() }
        player.play()
        playback = .playing
    }

    func stop() {
        generation += 1
        player.stop()
        engine.stop()
        if tapInstalled {
            engine.mainMixerNode.removeTap(onBus: 0)
            tapInstalled = false
        }
        playback = .stopped
        status = .idle
        duration = 0
        onLevels?(.silent)
    }

    func updateChannelMap(_ map: [Int32]) throws {
        try apply(map)
    }

    private func apply(_ map: [Int32]) throws {
        guard let unit = engine.outputNode.audioUnit else { throw AppAudioError.outputUnitUnavailable }
        let status = AudioUnitSetProperty(
            unit, kAudioOutputUnitProperty_ChannelMap, kAudioUnitScope_Output, 0,
            map, UInt32(map.count * MemoryLayout<Int32>.size)
        )
        guard status == noErr else { throw AppAudioError.channelMapRejected(status) }
    }

    private func applyVolume() {
        engine.mainMixerNode.outputVolume = isMuted ? 0 : masterVolume
    }

    private func playbackEnded(generation finished: Int) {
        guard finished == generation else { return }
        stop()
        onFinished?()
    }

    private func installLevelTap() {
        guard !tapInstalled else { return }
        let block = Self.levelTap { [weak self] reading in
            Task { @MainActor in self?.onLevels?(reading) }
        }
        engine.mainMixerNode.installTap(onBus: 0, bufferSize: 1_024, format: nil, block: block)
        tapInstalled = true
    }

    // These two are nonisolated because AVFoundation calls the closures off the main thread.
    nonisolated private static func completion(
        _ generation: Int, _ handler: @escaping @Sendable (Int) -> Void
    ) -> AVAudioPlayerNodeCompletionHandler {
        { _ in handler(generation) }
    }

    nonisolated private static func levelTap(_ handler: @escaping @Sendable (LevelReading) -> Void) -> AVAudioNodeTapBlock {
        { buffer, _ in handler(LevelMeter.measure(buffer)) }
    }
}

enum LevelMeter {
    nonisolated static func measure(_ buffer: AVAudioPCMBuffer) -> LevelReading {
        guard let channels = buffer.floatChannelData, buffer.frameLength > 0 else { return .silent }
        let frames = Int(buffer.frameLength)
        let left = rms(UnsafeBufferPointer(start: channels[0], count: frames))
        let right = buffer.format.channelCount > 1 ? rms(UnsafeBufferPointer(start: channels[1], count: frames)) : left
        return LevelReading(left: left, right: right)
    }

    nonisolated static func rms(_ samples: UnsafeBufferPointer<Float>) -> Float {
        guard !samples.isEmpty else { return 0 }
        return (samples.reduce(0) { $0 + $1 * $1 } / Float(samples.count)).squareRoot()
    }
}
