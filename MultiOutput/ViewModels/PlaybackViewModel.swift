import Foundation
import Observation
import UIKit

@Observable
final class PlaybackViewModel {
    let stack: AudioStack
    private(set) var position = 0.0
    private(set) var latencyResult: String?
    private(set) var isMeasuringLatency = false

    @ObservationIgnored private var timingTask: Task<Void, Never>?

    init(stack: AudioStack) {
        self.stack = stack
    }

    var destinations: [AudioDevice] { stack.devices.route.outputs }
    var canPlay: Bool { stack.source != nil && !destinations.isEmpty }

    var syncStatus: String {
        guard stack.routing.mode.usesChannelMap else {
            return "One destination. iOS handles output timing."
        }
        return "All destinations receive the same samples from one engine. iOS doesn't expose per-output clocks, so drift between outputs can't be measured or corrected."
    }

    func isSelected(_ device: AudioDevice) -> Bool {
        stack.routing.isSelected(device)
    }

    func setSelected(_ device: AudioDevice, _ selected: Bool) {
        let routing = stack.routing
        let wasMuted = routing.mutedOutputUIDs
        if selected { routing.mutedOutputUIDs.remove(device.uid) } else { routing.mutedOutputUIDs.insert(device.uid) }
        guard stack.engine.playback != .stopped, let map = currentMap() else { return }
        do {
            try stack.engine.updateChannelMap(map)
        } catch {
            routing.mutedOutputUIDs = wasMuted
            stack.report(error)
        }
    }

    func useFile(_ url: URL) {
        let isScoped = url.startAccessingSecurityScopedResource()
        defer { if isScoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let copy = URL.temporaryDirectory.appending(path: UUID().uuidString).appendingPathExtension(url.pathExtension)
            try FileManager.default.copyItem(at: url, to: copy)
            stack.engine.stop()
            if case .file(let old, _) = stack.source { try? FileManager.default.removeItem(at: old) }
            stack.source = .file(copy, name: url.lastPathComponent)
        } catch {
            stack.report(error)
        }
    }

    func playOrPause() {
        do {
            switch stack.engine.playback {
            case .playing: stack.engine.pause()
            case .paused: try stack.engine.resume()
            case .stopped:
                guard let source = stack.source else { return }
                try start(source)
            }
        } catch {
            stack.report(error)
        }
    }

    func play(signal: TestSignal) {
        stack.source = .signal(signal)
        do {
            try start(.signal(signal))
        } catch {
            stack.report(error)
        }
    }

    func stop() {
        stack.engine.stop()
    }

    func measureLatency() async {
        isMeasuringLatency = true
        defer {
            isMeasuringLatency = false
            stack.applySession()
        }
        stack.engine.stop()
        do {
            try await PermissionsManager.ensureMicrophone()
            try stack.session.applyLatencyMeasurementRoute()
            let seconds = try await LatencyProbe.measure()
            let text = AudioFormatHelper.milliseconds(seconds)
            latencyResult = text
            stack.monitor.log(.engine, "Measured round-trip latency: \(text)")
        } catch {
            latencyResult = nil
            stack.report(error)
        }
    }

    func saveVerification(heard: Set<String>, engineStarted: Bool) {
        let outputs = destinations.filter(isSelected)
        stack.log.add(CompatibilityRecord(
            date: .now,
            deviceModel: AudioFormatHelper.deviceModelIdentifier,
            systemVersion: UIDevice.current.systemVersion,
            mode: stack.routing.mode.title,
            outputs: outputs.map(\.kind.title),
            heardOutputs: outputs.filter { heard.contains($0.uid) }.map(\.kind.title),
            outcome: .from(engineStarted: engineStarted, requested: outputs.count, heard: outputs.filter { heard.contains($0.uid) }.count)
        ))
    }

    private func currentMap() -> [Int32]? {
        stack.routing.channelMap(for: stack.devices.route, totalChannels: stack.session.snapshot.maximumOutputChannels)
    }

    private func start(_ source: AudioSource) throws {
        stack.devices.refresh()
        try stack.engine.play(source, channelMap: currentMap(), parameters: stack.signalParameters)
        stack.monitor.resetTiming()
        stack.monitor.log(.engine, "Playing \(source.title) to \(stack.devices.route.summary)")
        startTimingUpdates()
    }

    private func startTimingUpdates() {
        timingTask?.cancel()
        timingTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self, stack.engine.playback != .stopped else { break }
                if let timing = stack.engine.timing {
                    position = timing.position
                    stack.monitor.recordTiming(samples: timing.samples, host: timing.host)
                }
                stack.session.refreshSnapshot()
                try? await Task.sleep(for: .milliseconds(250))
            }
            self?.position = 0
        }
    }
}
