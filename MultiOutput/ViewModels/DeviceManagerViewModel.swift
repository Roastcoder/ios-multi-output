import Observation

@Observable
final class DeviceManagerViewModel {
    let stack: AudioStack

    init(stack: AudioStack) {
        self.stack = stack
    }

    var outputs: [AudioDevice] { stack.devices.route.outputs }
    var inputs: [AudioDevice] { stack.devices.route.inputs }
    var mode: RoutingMode { stack.routing.mode }

    func eligibility(of device: AudioDevice) -> OutputEligibility {
        OutputEligibility.of(device.kind, in: mode)
    }

    func refresh() {
        stack.devices.refresh()
    }
}
