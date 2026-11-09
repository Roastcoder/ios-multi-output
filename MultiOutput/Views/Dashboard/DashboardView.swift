import SwiftUI

struct DashboardView: View {
    let model: DashboardViewModel
    let playback: PlaybackViewModel

    var body: some View {
        Screen(title: "Multi-Output") {
            Card(title: "Current Route", symbol: "point.3.connected.trianglepath.dotted") {
                Text(model.routeTitle)
                    .font(.title3.weight(.semibold))
                HStack {
                    StatusPill(text: model.modeTitle, tint: Theme.sky)
                    StatusPill(
                        text: model.route.outputChannelCount > 0 ? "\(model.route.outputChannelCount) output channels" : "Channels not reported",
                        tint: Theme.lavender
                    )
                }
            }

            Card(title: "Live Level", symbol: "waveform", tint: Theme.sky) {
                LevelVisualizer(history: model.stack.monitor.history)
            }

            HStack(spacing: 14) {
                Card(title: "Playback", symbol: "play.circle", tint: Theme.mint) {
                    Text(model.playbackTitle).font(.headline)
                }
                Card(title: "Engine", symbol: "cpu", tint: Theme.peach) {
                    Text(model.engineTitle).font(.headline)
                }
            }

            Card(title: "Connected Devices", symbol: "hifispeaker.2", tint: Theme.mint) {
                MetricRow(label: "Ports reported by iOS", value: "\(model.connectedCount)")
                ForEach(model.route.outputs) { device in
                    Label(device.name, systemImage: device.kind.symbol).font(.subheadline)
                }
            }

            Card(title: "Quick Audio Test", symbol: "speaker.wave.2", tint: Theme.peach) {
                Button {
                    if model.stack.engine.playback == .stopped { playback.play(signal: .stereo) } else { playback.stop() }
                } label: {
                    Text(model.stack.engine.playback == .stopped ? "Play Stereo Test Tone" : "Stop")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.route.outputs.isEmpty)
            }
        }
    }
}
