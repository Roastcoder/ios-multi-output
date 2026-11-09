import Observation

@Observable
final class AudioRoutingManager {
    var mode: RoutingMode = .systemRoute
    /// Stores switched-off ports, so a newly connected output starts switched on.
    var mutedOutputUIDs: Set<String> = []

    func isSelected(_ device: AudioDevice) -> Bool {
        !mutedOutputUIDs.contains(device.uid)
    }

    func channelMap(for route: AudioRoute, totalChannels: Int) -> [Int32]? {
        // Without every port's channel list the positions are unknown, and a guessed map could silence all outputs.
        guard mode.usesChannelMap, route.outputs.allSatisfy({ !$0.channels.isEmpty }) else { return nil }
        return Self.channelMap(
            ports: route.outputs.map { (uid: $0.uid, channelCount: $0.channels.count) },
            selected: Set(route.outputs.filter(isSelected).map(\.uid)),
            totalChannels: totalChannels
        )
    }

    /// Builds Apple's flattened output map: each index is a destination channel, each value a source channel, -1 is silence.
    /// Ports take positions in route order. Stereo repeats across a port's channels; a mono port gets the left channel only.
    nonisolated static func channelMap(
        ports: [(uid: String, channelCount: Int)],
        selected: Set<String>,
        totalChannels: Int,
        sourceChannels: Int = 2
    ) -> [Int32] {
        let portChannels = ports.reduce(0) { $0 + $1.channelCount }
        var map = [Int32](repeating: -1, count: max(totalChannels, portChannels))
        guard sourceChannels > 0 else { return map }

        var offset = 0
        for port in ports {
            if selected.contains(port.uid) {
                for channel in 0..<port.channelCount {
                    map[offset + channel] = Int32(channel % sourceChannels)
                }
            }
            offset += port.channelCount
        }
        return map
    }
}
