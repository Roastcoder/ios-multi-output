import AVFoundation

enum TestSignal: String, CaseIterable, Identifiable, Codable {
    case left, right, stereo, sweep, whiteNoise

    var id: String { rawValue }

    var title: String {
        switch self {
        case .left: "Left Channel"
        case .right: "Right Channel"
        case .stereo: "Stereo"
        case .sweep: "Frequency Sweep"
        case .whiteNoise: "White Noise"
        }
    }

    var symbol: String {
        switch self {
        case .left: "l.circle.fill"
        case .right: "r.circle.fill"
        case .stereo: "circle.grid.2x1.fill"
        case .sweep: "waveform.path.ecg"
        case .whiteNoise: "aqi.medium"
        }
    }
}

struct SignalParameters: Equatable {
    var frequency = 1_000.0
    var level: Float = 0.25
    var duration = 3.0
    var sampleRate = 44_100.0
}

enum TestSignalGenerator {
    private static let sweepStart = 20.0
    private static let fadeSeconds = 0.005

    static func samples(_ signal: TestSignal, _ parameters: SignalParameters) -> (left: [Float], right: [Float]) {
        let count = max(Int(parameters.duration * parameters.sampleRate), 0)
        var mono = [Float](repeating: 0, count: count)

        switch signal {
        case .left, .right, .stereo:
            let step = 2 * Double.pi * parameters.frequency / parameters.sampleRate
            for index in mono.indices { mono[index] = Float(sin(step * Double(index))) }
        case .sweep:
            let end = min(20_000, parameters.sampleRate * 0.45)
            let ratio = log(end / sweepStart)
            var phase = 0.0
            for index in mono.indices {
                mono[index] = Float(sin(phase))
                let frequency = sweepStart * exp(ratio * Double(index) / Double(max(count - 1, 1)))
                phase += 2 * .pi * frequency / parameters.sampleRate
            }
        case .whiteNoise:
            for index in mono.indices { mono[index] = Float.random(in: -1...1) }
        }

        // A short fade at each end prevents an audible click.
        let fade = min(Int(fadeSeconds * parameters.sampleRate), count / 2)
        for index in 0..<fade {
            let gain = Float(index) / Float(max(fade, 1))
            mono[index] *= gain
            mono[count - 1 - index] *= gain
        }

        let shaped = mono.map { $0 * parameters.level }
        let silence = [Float](repeating: 0, count: count)
        return (signal == .right ? silence : shaped, signal == .left ? silence : shaped)
    }

    static func buffer(_ signal: TestSignal, _ parameters: SignalParameters) -> AVAudioPCMBuffer? {
        let (left, right) = samples(signal, parameters)
        return buffer(left: left, right: right, sampleRate: parameters.sampleRate)
    }

    static func buffer(left: [Float], right: [Float], sampleRate: Double) -> AVAudioPCMBuffer? {
        guard let format = AudioFormatHelper.stereo(sampleRate: sampleRate),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(left.count)),
              let channels = buffer.floatChannelData,
              left.count == right.count
        else { return nil }
        buffer.frameLength = AVAudioFrameCount(left.count)
        left.withUnsafeBufferPointer { channels[0].update(from: $0.baseAddress!, count: left.count) }
        right.withUnsafeBufferPointer { channels[1].update(from: $0.baseAddress!, count: right.count) }
        return buffer
    }
}
