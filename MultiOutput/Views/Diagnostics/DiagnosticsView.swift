import SwiftUI

struct DiagnosticsView: View {
    let stack: AudioStack
    let playback: PlaybackViewModel

    var body: some View {
        let snapshot = stack.session.snapshot

        Screen(title: "Diagnostics") {
            NavigationLink {
                AudioTestLabView(model: playback)
            } label: {
                Card(title: "Audio Test Lab", symbol: "tuningfork", tint: Theme.peach) {
                    Text("Channel tests, sweep, noise, latency and route verification.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)

            Card(title: "Audio Session", symbol: "slider.vertical.3", tint: Theme.sky) {
                MetricRow(label: "Category", value: snapshot.category)
                MetricRow(label: "Mode", value: snapshot.mode)
                MetricRow(label: "Sample rate", value: AudioFormatHelper.hertz(snapshot.sampleRate))
                MetricRow(label: "Output channels", value: "\(snapshot.outputChannels) of \(snapshot.maximumOutputChannels)")
                MetricRow(label: "I/O buffer", value: AudioFormatHelper.milliseconds(snapshot.ioBufferDuration))
                MetricRow(label: "Output latency", value: AudioFormatHelper.milliseconds(snapshot.outputLatency))
                MetricRow(label: "Input latency", value: AudioFormatHelper.milliseconds(snapshot.inputLatency))
                MetricRow(label: "Engine presentation latency", value: AudioFormatHelper.milliseconds(stack.engine.presentationLatency))
                MetricRow(label: "Interruptions", value: "\(stack.monitor.interruptionCount)")
                MetricRow(label: "Other audio playing", value: snapshot.isOtherAudioPlaying ? "Yes" : "No")
            }

            EventCard(title: "Route-Change History", symbol: "arrow.triangle.swap", tint: Theme.mint, events: stack.monitor.routeHistory)
            EventCard(title: "Error Log", symbol: "exclamationmark.triangle", tint: Theme.peach, events: stack.monitor.errors)
            EventCard(title: "All Events", symbol: "list.bullet.rectangle", tint: Theme.lavender, events: stack.monitor.events)
        }
        .onAppear { stack.session.refreshSnapshot() }
    }
}

private struct EventCard: View {
    let title: String
    let symbol: String
    let tint: Color
    let events: [DiagnosticEvent]

    var body: some View {
        Card(title: title, symbol: symbol, tint: tint) {
            if events.isEmpty { Text("Nothing recorded yet").font(.subheadline).foregroundStyle(.secondary) }
            ForEach(events.prefix(12)) { event in
                VStack(alignment: .leading) {
                    Text(event.message).font(.subheadline)
                    Text(event.date.formatted(date: .omitted, time: .standard))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
