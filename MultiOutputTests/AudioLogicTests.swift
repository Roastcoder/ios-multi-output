import Foundation
import Testing
@testable import MultiOutput

struct ChannelMapTests {
    private let ports: [(uid: String, channelCount: Int)] = [("a", 2), ("b", 2)]

    @Test func `both ports receive stereo`() {
        #expect(AudioRoutingManager.channelMap(ports: ports, selected: ["a", "b"], totalChannels: 4) == [0, 1, 0, 1])
    }

    @Test func `an unselected port is silent`() {
        #expect(AudioRoutingManager.channelMap(ports: ports, selected: ["b"], totalChannels: 4) == [-1, -1, 0, 1])
    }

    @Test func `a mono port takes the left channel`() {
        let map = AudioRoutingManager.channelMap(ports: [("m", 1), ("s", 2)], selected: ["m", "s"], totalChannels: 3)
        #expect(map == [0, 0, 1])
    }

    @Test func `the map fills every hardware channel`() {
        #expect(AudioRoutingManager.channelMap(ports: [("a", 2)], selected: ["a"], totalChannels: 4) == [0, 1, -1, -1])
    }

    @Test func `a stale channel total cannot overflow the map`() {
        #expect(AudioRoutingManager.channelMap(ports: ports, selected: ["a", "b"], totalChannels: 2).count == 4)
    }

    @Test func `no ports gives silence`() {
        #expect(AudioRoutingManager.channelMap(ports: [], selected: [], totalChannels: 2) == [-1, -1])
    }
}

struct RouteMapTests {
    private func output(_ uid: String, channels: Int) -> AudioDevice {
        AudioDevice(
            uid: uid, name: uid, kind: .usb, direction: .output, isActive: true,
            channels: (0..<channels).map { AudioChannel(name: "\($0)", number: $0 + 1) }
        )
    }

    @Test func `system route uses no channel map`() {
        let routing = AudioRoutingManager()
        #expect(routing.channelMap(for: AudioRoute(outputs: [output("a", channels: 2)]), totalChannels: 2) == nil)
    }

    @Test func `multi-route maps reported channels and honours mutes`() {
        let routing = AudioRoutingManager()
        routing.mode = .multiRoute
        routing.mutedOutputUIDs = ["a"]
        let route = AudioRoute(outputs: [output("a", channels: 2), output("b", channels: 2)])
        #expect(routing.channelMap(for: route, totalChannels: 4) == [-1, -1, 0, 1])
    }

    @Test func `an unreported channel list falls back to default routing`() {
        let routing = AudioRoutingManager()
        routing.mode = .multiRoute
        let route = AudioRoute(outputs: [output("a", channels: 0), output("b", channels: 2)])
        #expect(routing.channelMap(for: route, totalChannels: 4) == nil)
    }
}

struct EligibilityTests {
    @Test(arguments: [AudioDeviceKind.usb, .lineOut, .headphones, .hdmi])
    func `documented wired outputs combine in multi-route`(kind: AudioDeviceKind) {
        #expect(OutputEligibility.of(kind, in: .multiRoute) == .eligible)
    }

    @Test(arguments: [AudioDeviceKind.bluetoothA2DP, .airPlay, .bluetoothLE, .bluetoothHFP])
    func `wireless outputs do not combine in multi-route`(kind: AudioDeviceKind) {
        #expect(OutputEligibility.of(kind, in: .multiRoute) == .notEligible)
    }

    @Test func `the speaker is alone in multi-route`() {
        #expect(OutputEligibility.of(.builtInSpeaker, in: .multiRoute) == .eligibleOnlyWhenAlone)
    }

    @Test func `dual route accepts the speaker and hands-free but not A2DP`() {
        #expect(OutputEligibility.of(.builtInSpeaker, in: .dualRoute) == .eligible)
        #expect(OutputEligibility.of(.bluetoothHFP, in: .dualRoute) == .eligible)
        #expect(OutputEligibility.of(.bluetoothA2DP, in: .dualRoute) == .notEligible)
    }
}

struct TestSignalTests {
    private let parameters = SignalParameters(frequency: 1_000, level: 0.25, duration: 0.1, sampleRate: 48_000)

    @Test func `left signal leaves the right channel silent`() {
        let (left, right) = TestSignalGenerator.samples(.left, parameters)
        #expect(left.contains { $0 != 0 })
        #expect(right.allSatisfy { $0 == 0 })
    }

    @Test func `right signal leaves the left channel silent`() {
        let (left, right) = TestSignalGenerator.samples(.right, parameters)
        #expect(left.allSatisfy { $0 == 0 })
        #expect(right.contains { $0 != 0 })
    }

    @Test(arguments: TestSignal.allCases)
    func `signals have the right length, level and faded start`(signal: TestSignal) {
        let (left, right) = TestSignalGenerator.samples(signal, parameters)
        #expect(left.count == 4_800)
        #expect(right.count == 4_800)
        #expect((left + right).allSatisfy { abs($0) <= parameters.level })
        #expect(left[0] == 0)
        #expect(right[0] == 0)
    }

    @Test func `a zero-length signal is empty`() {
        var empty = parameters
        empty.duration = 0
        #expect(TestSignalGenerator.samples(.sweep, empty).left.isEmpty)
    }

    @Test func `a buffer holds the generated frames`() throws {
        let buffer = try #require(TestSignalGenerator.buffer(.stereo, parameters))
        #expect(buffer.frameLength == 4_800)
        #expect(buffer.format.channelCount == 2)
    }
}

struct MeasurementTests {
    @Test func `onset is found after the noise window`() {
        let samples: [Float] = [0.001, -0.002, 0.001, 0.0, 0.5, 0.4]
        #expect(LatencyAnalyzer.onsetIndex(samples, noiseWindow: 3) == 4)
    }

    @Test func `silence has no onset`() {
        #expect(LatencyAnalyzer.onsetIndex([Float](repeating: 0.001, count: 100), noiseWindow: 10) == nil)
    }

    @Test func `an out-of-range window has no onset`() {
        #expect(LatencyAnalyzer.onsetIndex([0.5], noiseWindow: 1) == nil)
        #expect(LatencyAnalyzer.onsetIndex([0.5], noiseWindow: -1) == nil)
    }

    @Test func `drift needs at least two seconds`() {
        #expect(AudioMonitoringService.driftPPM(sampleElapsed: 1, hostElapsed: 1) == nil)
    }

    @Test func `drift is reported in parts per million`() throws {
        let ppm = try #require(AudioMonitoringService.driftPPM(sampleElapsed: 10.001, hostElapsed: 10))
        #expect(abs(ppm - 100) < 0.001)
    }

    @Test func `the level meter measures RMS`() {
        let samples: [Float] = [0.5, -0.5, 0.5, -0.5]
        samples.withUnsafeBufferPointer { #expect(abs(LevelMeter.rms($0) - 0.5) < 0.0001) }
    }
}

struct OutcomeTests {
    @Test func `all outputs heard works`() {
        #expect(CompatibilityRecord.Outcome.from(engineStarted: true, requested: 2, heard: 2) == .works)
    }

    @Test func `some outputs heard is restricted`() {
        #expect(CompatibilityRecord.Outcome.from(engineStarted: true, requested: 2, heard: 1) == .restricted)
    }

    @Test func `nothing heard fails`() {
        #expect(CompatibilityRecord.Outcome.from(engineStarted: true, requested: 2, heard: 0) == .fails)
    }

    @Test func `an engine that never started is restricted`() {
        #expect(CompatibilityRecord.Outcome.from(engineStarted: false, requested: 2, heard: 0) == .restricted)
    }
}

struct SupportTests {
    @Test func `four-character statuses are readable`() {
        #expect(AudioErrorHandler.statusText(1_718_449_215) == "'fmt?'")
    }

    @Test func `numeric statuses stay numeric`() {
        #expect(AudioErrorHandler.statusText(-50) == "-50")
    }

    @Test func `configuration survives saving`() throws {
        let suite = "tests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var configuration = AudioConfiguration()
        configuration.preferredSampleRate = 48_000
        configuration.mixWithOthers = true
        configuration.save(to: defaults)
        #expect(AudioConfiguration.load(from: defaults) == configuration)
    }

    @Test func `the log writes a markdown row and reloads`() throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let log = CompatibilityLog(fileURL: url)
        log.add(CompatibilityRecord(date: .now, deviceModel: "iPhone15,4", systemVersion: "26.5", mode: "Multi-Route", outputs: ["USB Audio"], heardOutputs: ["USB Audio"], outcome: .works))
        #expect(log.markdown.contains("| iPhone15,4 | 26.5 | Multi-Route | USB Audio | USB Audio | Works |"))
        #expect(CompatibilityLog(fileURL: url).records.count == 1)
    }
}
