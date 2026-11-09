import Foundation
import Observation

/// Owns the audio services and connects their events. View models read from this.
@Observable
final class AudioStack {
    let session = AudioSessionManager()
    let devices: AudioDeviceManager
    let engine = AudioEngineManager()
    let routing = AudioRoutingManager()
    let monitor = AudioMonitoringService()
    let log = CompatibilityLog()

    var source: AudioSource?
    var errorMessage: String?
    var configuration = AudioConfiguration.load() {
        didSet { configuration.save() }
    }

    var signalParameters: SignalParameters {
        SignalParameters(
            frequency: configuration.toneFrequency,
            level: configuration.toneLevel,
            duration: configuration.signalDuration
        )
    }

    init() {
        devices = AudioDeviceManager(session: session)
        engine.onLevels = { [monitor] in monitor.ingest($0) }
        engine.onFinished = { [monitor] in monitor.log(.engine, "Playback finished") }
        engine.onConfigurationChange = { [weak self] in self?.handleEngineConfigurationChange() }

        session.onRouteChange = { [weak self] reason in self?.handleRouteChange(reason) }
        session.onInterruption = { [weak self] message, began in
            guard let self else { return }
            monitor.log(.interruption, message)
            // shortcut: playback stops instead of resuming from the same position, add resume if interrupted sessions matter.
            if began { engine.stop() }
        }
        session.onMediaServicesReset = { [weak self] in
            guard let self else { return }
            monitor.log(.error, "iOS reset its media services")
            engine.stop()
            applySession()
        }
    }

    func start() {
        session.startObserving()
        applySession()
    }

    func applySession() {
        do {
            try session.apply(mode: routing.mode, configuration: configuration)
            monitor.log(.engine, "Session set to \(routing.mode.title)")
        } catch {
            report(error)
        }
        devices.refresh()
    }

    func setMode(_ mode: RoutingMode) {
        guard mode != routing.mode else { return }
        engine.stop()
        routing.mode = mode
        applySession()
    }

    func report(_ error: Error) {
        let message = AudioErrorHandler.message(for: error)
        errorMessage = message
        monitor.log(.error, message)
    }

    private func handleRouteChange(_ reason: String) {
        let outputsChanged = devices.refresh()
        monitor.log(.route, "\(reason): \(devices.route.summary)")
        // Channel positions depend on the exact port order, so a changed route invalidates the running map.
        if outputsChanged, engine.playback != .stopped {
            engine.stop()
            monitor.log(.engine, "Stopped because the outputs changed")
        }
    }

    private func handleEngineConfigurationChange() {
        monitor.log(.engine, "Audio hardware configuration changed")
        session.refreshSnapshot()
        if engine.playback != .stopped { engine.stop() }
    }
}
