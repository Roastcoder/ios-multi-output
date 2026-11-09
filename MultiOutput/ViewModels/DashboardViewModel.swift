import Observation

@Observable
final class DashboardViewModel {
    let stack: AudioStack

    init(stack: AudioStack) {
        self.stack = stack
    }

    var route: AudioRoute { stack.devices.route }
    var routeTitle: String { route.summary }
    var connectedCount: Int { Set((route.outputs + route.inputs).map(\.uid)).count }
    var playbackTitle: String { stack.engine.playback.title }
    var engineTitle: String { stack.engine.status.title }
    var modeTitle: String { stack.routing.mode.title }
}
