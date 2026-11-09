import AVFoundation

enum LatencyAnalyzer {
    /// Finds the first sample after `noiseWindow` that clearly rises above the noise measured before it.
    nonisolated static func onsetIndex(_ samples: [Float], noiseWindow: Int, minimumLevel: Float = 0.01) -> Int? {
        guard noiseWindow >= 0, noiseWindow < samples.count else { return nil }
        let noise = samples[..<noiseWindow].reduce(Float(0)) { max($0, abs($1)) }
        let threshold = max(noise * 4, minimumLevel)
        return samples[noiseWindow...].firstIndex { abs($0) >= threshold }
    }
}

/// Plays a click and listens with the microphone. The result is an acoustic round-trip estimate through the speaker and mic only.
enum LatencyProbe {
    nonisolated private final class Capture: @unchecked Sendable {
        private let lock = NSLock()
        private var samples: [Float] = []
        private var firstHostTime: UInt64?

        func append(_ buffer: AVAudioPCMBuffer, at time: AVAudioTime) {
            guard let channel = buffer.floatChannelData?[0] else { return }
            lock.withLock {
                if firstHostTime == nil, time.isHostTimeValid { firstHostTime = time.hostTime }
                samples.append(contentsOf: UnsafeBufferPointer(start: channel, count: Int(buffer.frameLength)))
            }
        }

        func contents() -> (samples: [Float], firstHostTime: UInt64?) {
            lock.withLock { (samples, firstHostTime) }
        }
    }

    static func measure() async throws -> Double {
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        let input = engine.inputNode
        let inputFormat = input.outputFormat(forBus: 0)
        guard inputFormat.sampleRate > 0, inputFormat.channelCount > 0 else { throw AppAudioError.noOutput }

        let capture = Capture()
        input.installTap(onBus: 0, bufferSize: 1_024, format: inputFormat, block: makeTap(capture))
        defer {
            input.removeTap(onBus: 0)
            player.stop()
            engine.stop()
        }

        let clickFrames = Int(0.01 * inputFormat.sampleRate)
        let click = (0..<clickFrames).map { Float(sin(2 * .pi * 2_000 * Double($0) / inputFormat.sampleRate)) * 0.5 }
        guard let buffer = TestSignalGenerator.buffer(left: click, right: click, sampleRate: inputFormat.sampleRate) else {
            throw AppAudioError.signalUnavailable
        }

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: buffer.format)
        try engine.start()
        try await Task.sleep(for: .milliseconds(500))

        let clickHostTime = mach_absolute_time() + AVAudioTime.hostTime(forSeconds: 0.3)
        player.scheduleBuffer(buffer, at: AVAudioTime(hostTime: clickHostTime), options: [], completionHandler: nil)
        player.play()
        try await Task.sleep(for: .seconds(1.3))

        let (samples, firstHostTime) = capture.contents()
        guard let firstHostTime, clickHostTime > firstHostTime else { throw AppAudioError.noClickDetected }
        let secondsBeforeClick = AVAudioTime.seconds(forHostTime: clickHostTime - firstHostTime)
        let noiseWindow = Int(secondsBeforeClick * inputFormat.sampleRate)
        guard let onset = LatencyAnalyzer.onsetIndex(samples, noiseWindow: noiseWindow) else { throw AppAudioError.noClickDetected }
        return Double(onset - noiseWindow) / inputFormat.sampleRate
    }

    nonisolated private static func makeTap(_ capture: Capture) -> AVAudioNodeTapBlock {
        { buffer, time in capture.append(buffer, at: time) }
    }
}
