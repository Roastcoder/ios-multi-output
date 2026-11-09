import Observation

/// iOS has no API that lists idle outputs, so this shows the current route's outputs plus available inputs.
@Observable
final class AudioDeviceManager {
    private(set) var route = AudioRoute()

    @ObservationIgnored private let session: AudioSessionManager

    init(session: AudioSessionManager) {
        self.session = session
    }

    /// Returns true when the set of output ports changed.
    @discardableResult
    func refresh() -> Bool {
        let updated = session.currentRoute()
        let changed = Set(updated.outputs.map(\.uid)) != Set(route.outputs.map(\.uid))
        route = updated
        session.refreshSnapshot()
        return changed
    }
}
