import AVFoundation

enum AudioFormatHelper {
    nonisolated static func stereo(sampleRate: Double) -> AVAudioFormat? {
        AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)
    }

    static func hertz(_ value: Double) -> String {
        value > 0 ? value.formatted(.number.precision(.fractionLength(0))) + " Hz" : "Not reported"
    }

    static func milliseconds(_ seconds: Double) -> String {
        (seconds * 1_000).formatted(.number.precision(.fractionLength(1))) + " ms"
    }

    static func clock(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let whole = Int(seconds)
        return String(format: "%d:%02d", whole / 60, whole % 60)
    }

    /// A hardware identifier such as iPhone15,4.
    static var deviceModelIdentifier: String {
        #if targetEnvironment(simulator)
        return "Simulator"
        #else
        var info = utsname()
        uname(&info)
        return withUnsafeBytes(of: &info.machine) { String(cString: $0.bindMemory(to: CChar.self).baseAddress!) }
        #endif
    }
}
