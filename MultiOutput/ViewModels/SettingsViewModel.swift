import Observation

@Observable
final class SettingsViewModel {
    let stack: AudioStack

    static let sampleRates: [Double] = [44_100, 48_000, 96_000]
    static let bufferSizes: [Double] = [5, 10, 20, 40]

    init(stack: AudioStack) {
        self.stack = stack
    }

    var configuration: AudioConfiguration {
        get { stack.configuration }
        set {
            let sessionChanged = newValue.preferredSampleRate != stack.configuration.preferredSampleRate
                || newValue.preferredBufferMilliseconds != stack.configuration.preferredBufferMilliseconds
                || newValue.mixWithOthers != stack.configuration.mixWithOthers
            stack.configuration = newValue
            if sessionChanged {
                stack.engine.stop()
                stack.applySession()
            }
        }
    }

    var grantedSampleRate: Double { stack.session.snapshot.sampleRate }
    var grantedBuffer: Double { stack.session.snapshot.ioBufferDuration }
}
