import Foundation

struct AudioConfiguration: Codable, Equatable {
    var preferredSampleRate: Double?
    var preferredBufferMilliseconds: Double?
    var mixWithOthers = false
    var toneFrequency = 1_000.0
    var toneLevel: Float = 0.25
    var signalDuration = 3.0

    private static let key = "audioConfiguration"

    static func load(from defaults: UserDefaults = .standard) -> AudioConfiguration {
        guard let data = defaults.data(forKey: key),
              let saved = try? JSONDecoder().decode(AudioConfiguration.self, from: data)
        else { return AudioConfiguration() }
        return saved
    }

    func save(to defaults: UserDefaults = .standard) {
        if let data = try? JSONEncoder().encode(self) {
            defaults.set(data, forKey: Self.key)
        }
    }
}
