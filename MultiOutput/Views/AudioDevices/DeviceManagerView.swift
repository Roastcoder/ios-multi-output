import SwiftUI

struct DeviceManagerView: View {
    let model: DeviceManagerViewModel

    var body: some View {
        Screen(title: "Devices") {
            Card(title: "Choose a Route", symbol: "airplayaudio", tint: Theme.sky) {
                HStack {
                    Text("Open Apple's picker for AirPlay and Bluetooth destinations.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    RoutePickerButton().frame(width: 44, height: 44)
                }
            }

            Card(title: "Active Outputs", symbol: "speaker.wave.2", tint: Theme.mint) {
                if model.outputs.isEmpty { Text("No active output").foregroundStyle(.secondary) }
                ForEach(model.outputs) { DeviceRow(device: $0, model: model) }
                Text("iOS only lists outputs in the current route, so idle devices can't be shown here.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Card(title: "Inputs", symbol: "mic", tint: Theme.lavender) {
                if model.inputs.isEmpty { Text("No inputs reported").foregroundStyle(.secondary) }
                ForEach(model.inputs) { DeviceRow(device: $0, model: model) }
            }
        }
        .onAppear { model.refresh() }
        .refreshable { model.refresh() }
    }
}

private struct DeviceRow: View {
    let device: AudioDevice
    let model: DeviceManagerViewModel

    var body: some View {
        NavigationLink {
            DeviceDetailView(device: device, model: model)
        } label: {
            HStack {
                Image(systemName: device.kind.symbol)
                    .frame(width: 32, height: 32)
                    .foregroundStyle(Theme.lavender)
                    .background(Theme.lavender.opacity(0.12), in: Circle())
                VStack(alignment: .leading) {
                    Text(device.name).font(.subheadline.weight(.medium))
                    Text(device.kind.title).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                StatusPill(text: device.isActive ? "Active" : "Available", tint: device.isActive ? Theme.mint : Theme.sky)
            }
            .foregroundStyle(.primary)
        }
    }
}

struct DeviceDetailView: View {
    let device: AudioDevice
    let model: DeviceManagerViewModel

    var body: some View {
        Screen(title: device.name) {
            Card(title: "Device", symbol: device.kind.symbol) {
                MetricRow(label: "Type", value: device.kind.title)
                MetricRow(label: "Direction", value: device.direction.rawValue.capitalized)
                MetricRow(label: "Status", value: device.isActive ? "In current route" : "Available")
                MetricRow(label: "Spatial Audio", value: device.isSpatialAudioEnabled ? "On" : "Off")
                MetricRow(label: "Hardware call processing", value: device.hasHardwareVoiceCallProcessing ? "Yes" : "No")
                if device.direction == .output {
                    MetricRow(label: "\(model.mode.title) routing", value: model.eligibility(of: device).label)
                }
            }

            Card(title: "Channels", symbol: "square.split.2x1", tint: Theme.mint) {
                if device.channels.isEmpty { Text("Not reported by iOS").foregroundStyle(.secondary) }
                ForEach(device.channels, id: \.self) { MetricRow(label: "Channel \($0.number)", value: $0.name) }
            }

            if !device.dataSources.isEmpty {
                Card(title: "Data Sources", symbol: "list.bullet", tint: Theme.sky) {
                    ForEach(device.dataSources, id: \.self) { Text($0).font(.subheadline) }
                }
            }
        }
    }
}
