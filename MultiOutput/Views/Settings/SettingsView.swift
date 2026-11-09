import SwiftUI

struct SettingsView: View {
    @Bindable var model: SettingsViewModel

    var body: some View {
        Form {
            Section {
                Picker("Sample Rate", selection: $model.configuration.preferredSampleRate) {
                    Text("System Default").tag(Double?.none)
                    ForEach(SettingsViewModel.sampleRates, id: \.self) { Text(AudioFormatHelper.hertz($0)).tag(Double?.some($0)) }
                }
                Picker("Buffer", selection: $model.configuration.preferredBufferMilliseconds) {
                    Text("System Default").tag(Double?.none)
                    ForEach(SettingsViewModel.bufferSizes, id: \.self) { Text("\(Int($0)) ms").tag(Double?.some($0)) }
                }
                LabeledContent("Current Rate", value: AudioFormatHelper.hertz(model.grantedSampleRate))
                LabeledContent("Current Buffer", value: AudioFormatHelper.milliseconds(model.grantedBuffer))
            } header: {
                Text("Audio Quality")
            } footer: {
                Text("These are requests. iOS decides the final values based on the hardware in use.")
            }

            Section {
                Toggle("Mix With Other Apps", isOn: $model.configuration.mixWithOthers)
            } header: {
                Text("Audio Session")
            } footer: {
                Text("Doesn't apply to Dual Route. Developers report that combining this with Multi-Route can stop the volume buttons working.")
            }

            Section("Test Tone") {
                LabeledContent("Frequency") {
                    Stepper("\(Int(model.configuration.toneFrequency)) Hz", value: $model.configuration.toneFrequency, in: 100...8_000, step: 100)
                }
                LabeledContent("Level") {
                    Slider(value: $model.configuration.toneLevel, in: 0.05...0.5).accessibilityLabel("Test tone level")
                }
                LabeledContent("Length") {
                    Stepper("\(Int(model.configuration.signalDuration)) s", value: $model.configuration.signalDuration, in: 1...30)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Settings")
    }
}
