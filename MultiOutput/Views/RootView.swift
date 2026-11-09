import SwiftUI

struct RootView: View {
    let stack: AudioStack
    @State private var dashboard: DashboardViewModel
    @State private var devices: DeviceManagerViewModel
    @State private var playback: PlaybackViewModel
    @State private var settings: SettingsViewModel

    init(stack: AudioStack) {
        self.stack = stack
        _dashboard = State(initialValue: DashboardViewModel(stack: stack))
        _devices = State(initialValue: DeviceManagerViewModel(stack: stack))
        _playback = State(initialValue: PlaybackViewModel(stack: stack))
        _settings = State(initialValue: SettingsViewModel(stack: stack))
    }

    var body: some View {
        TabView {
            NavigationStack { DashboardView(model: dashboard, playback: playback) }
                .tabItem { Label("Dashboard", systemImage: "gauge.with.dots.needle.33percent") }
            NavigationStack { DeviceManagerView(model: devices) }
                .tabItem { Label("Devices", systemImage: "hifispeaker.2") }
            NavigationStack { MultiOutputStudioView(model: playback) }
                .tabItem { Label("Studio", systemImage: "slider.horizontal.3") }
            NavigationStack { DiagnosticsView(stack: stack, playback: playback) }
                .tabItem { Label("Diagnostics", systemImage: "waveform.path.ecg") }
            NavigationStack { SettingsView(model: settings) }
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(Theme.lavender)
        .alert("Audio Problem", isPresented: Binding(
            get: { stack.errorMessage != nil },
            set: { if !$0 { stack.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(stack.errorMessage ?? "")
        }
        .task { stack.start() }
    }
}
