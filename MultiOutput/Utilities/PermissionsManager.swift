import AVFoundation

enum PermissionsManager {
    static func ensureMicrophone() async throws {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            return
        case .undetermined:
            guard await AVAudioApplication.requestRecordPermission() else { throw AppAudioError.microphoneDenied }
        default:
            throw AppAudioError.microphoneDenied
        }
    }
}
