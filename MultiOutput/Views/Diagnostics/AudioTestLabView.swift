import SwiftUI

struct AudioTestLabView: View {
    let model: PlaybackViewModel
    @State private var heard: Set<String> = []
    @State private var verificationStarted = false

    private var stack: AudioStack { model.stack }

    var body: some View {
        Screen(title: "Test Lab") {
            Card(title: "Signals", symbol: "waveform", tint: Theme.lavender) {
                ForEach(TestSignal.allCases) { signal in
                    Button {
                        model.play(signal: signal)
                    } label: {
                        Label(signal.title, systemImage: signal.symbol).frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                }
                Button("Stop", role: .destructive) { model.stop() }
                    .disabled(stack.engine.playback == .stopped)
            }

            Card(title: "Latency Measurement", symbol: "stopwatch", tint: Theme.peach) {
                Text("Plays a click and listens with the microphone. Measures speaker-to-mic round trip only, and stops any playback.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                MetricRow(label: "Last result", value: model.latencyResult ?? "Not measured")
                Button(model.isMeasuringLatency ? "Measuring…" : "Measure Latency") {
                    Task { await model.measureLatency() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.isMeasuringLatency)
            }

            Card(title: "Route Verification", symbol: "checkmark.seal", tint: Theme.mint) {
                Text("Play the tone, then record which outputs you actually heard. Only your confirmation counts as a tested result.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("Play Verification Tone") {
                    heard = []
                    verificationStarted = true
                    model.play(signal: .stereo)
                }
                .buttonStyle(.bordered)

                ForEach(model.destinations.filter(model.isSelected)) { device in
                    Toggle("Heard on \(device.name)", isOn: Binding(
                        get: { heard.contains(device.uid) },
                        set: { if $0 { heard.insert(device.uid) } else { heard.remove(device.uid) } }
                    ))
                    .disabled(!verificationStarted)
                }

                Button("Save Result") {
                    model.saveVerification(heard: heard, engineStarted: stack.engine.status != .idle || !heard.isEmpty)
                    verificationStarted = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(!verificationStarted)
            }

            Card(title: "Compatibility Log", symbol: "tablecells", tint: Theme.sky) {
                if stack.log.records.isEmpty { Text("No device results yet").font(.subheadline).foregroundStyle(.secondary) }
                ForEach(stack.log.records.prefix(10)) { record in
                    VStack(alignment: .leading) {
                        Text("\(record.outputs.joined(separator: " + ")): \(record.outcome.rawValue)").font(.subheadline)
                        Text("\(record.deviceModel) · iOS \(record.systemVersion) · \(record.mode)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if let error = stack.log.lastSaveError {
                    Text(error).font(.caption).foregroundStyle(Theme.peach)
                }
                if !stack.log.records.isEmpty {
                    ShareLink("Export as Markdown", item: stack.log.markdown)
                }
            }
        }
    }
}
