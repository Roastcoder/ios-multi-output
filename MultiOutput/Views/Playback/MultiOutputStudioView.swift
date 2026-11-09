import SwiftUI
import UniformTypeIdentifiers

struct MultiOutputStudioView: View {
    let model: PlaybackViewModel
    @State private var isImporting = false

    private var stack: AudioStack { model.stack }

    var body: some View {
        @Bindable var engine = stack.engine

        Screen(title: "Studio") {
            Card(title: "Routing Mode", symbol: "arrow.triangle.branch", tint: Theme.sky) {
                Picker("Routing Mode", selection: Binding(get: { stack.routing.mode }, set: { stack.setMode($0) })) {
                    ForEach(RoutingMode.allCases.filter(\.isSupportedOnThisOS)) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                Text(stack.routing.mode.detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Card(title: "Destinations", symbol: "hifispeaker.2", tint: Theme.mint) {
                if model.destinations.isEmpty { Text("No active output").foregroundStyle(.secondary) }
                ForEach(model.destinations) { device in
                    Toggle(isOn: Binding(get: { model.isSelected(device) }, set: { model.setSelected(device, $0) })) {
                        VStack(alignment: .leading) {
                            Text(device.name)
                            Text(device.channels.isEmpty ? device.kind.title : "\(device.kind.title) · \(device.channels.count) ch")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .disabled(!stack.routing.mode.usesChannelMap)
                }
                if !stack.routing.mode.usesChannelMap {
                    Text("Switch to Multi-Route to control destinations separately.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Card(title: "Audio Source", symbol: "music.note", tint: Theme.peach) {
                Text(stack.source?.title ?? "Nothing selected").font(.headline)
                HStack {
                    Button("Choose File") { isImporting = true }
                    Menu("Test Signal") {
                        ForEach(TestSignal.allCases) { signal in
                            Button(signal.title) { stack.source = .signal(signal) }
                        }
                    }
                }
                .buttonStyle(.bordered)
            }

            Card(title: "Playback", symbol: "play.circle", tint: Theme.lavender) {
                LevelVisualizer(history: stack.monitor.history)
                HStack {
                    Text(AudioFormatHelper.clock(model.position))
                    Spacer()
                    Text(AudioFormatHelper.clock(stack.engine.duration))
                }
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Button(stack.engine.playback == .playing ? "Pause" : "Play") { model.playOrPause() }
                        .buttonStyle(.borderedProminent)
                        .disabled(!model.canPlay)
                    Button("Stop") { model.stop() }
                        .buttonStyle(.bordered)
                        .disabled(stack.engine.playback == .stopped)
                    Spacer()
                    Toggle("Mute", isOn: $engine.isMuted).labelsHidden().accessibilityLabel("Mute app audio")
                    Image(systemName: stack.engine.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading) {
                    Text("App Volume").font(.caption).foregroundStyle(.secondary)
                    Slider(value: $engine.masterVolume).accessibilityLabel("App volume")
                    Text("System Volume").font(.caption).foregroundStyle(.secondary)
                    SystemVolumeSlider().frame(height: 34)
                }
            }

            Card(title: "Synchronization", symbol: "metronome", tint: Theme.sky) {
                Text(model.syncStatus).font(.subheadline)
                MetricRow(label: "Output latency", value: AudioFormatHelper.milliseconds(stack.session.snapshot.outputLatency))
                MetricRow(label: "I/O buffer", value: AudioFormatHelper.milliseconds(stack.session.snapshot.ioBufferDuration))
                MetricRow(label: "Engine clock vs system", value: stack.monitor.clockDriftPPM.map { "\($0.formatted(.number.precision(.fractionLength(1)))) ppm" } ?? "Measuring needs playback")
            }

            Card(title: "Route Combinations", symbol: "tablecells", tint: Theme.peach) {
                ForEach(RouteCombination.reference) { combination in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(combination.name).font(.subheadline.weight(.medium))
                            Spacer()
                            StatusPill(text: combination.mode, tint: Theme.sky)
                        }
                        Text("\(combination.support.rawValue). \(combination.note)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.audio]) { result in
            switch result {
            case .success(let url): model.useFile(url)
            case .failure(let error): stack.report(error)
            }
        }
    }
}
