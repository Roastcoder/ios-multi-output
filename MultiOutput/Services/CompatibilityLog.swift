import Foundation
import Observation

/// Results a person confirmed on a real device. This is the only source of "tested" entries in the matrix.
@Observable
final class CompatibilityLog {
    private(set) var records: [CompatibilityRecord] = []
    private(set) var lastSaveError: String?

    @ObservationIgnored private let fileURL: URL

    init(fileURL: URL = URL.documentsDirectory.appending(path: "compatibility.json")) {
        self.fileURL = fileURL
        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode([CompatibilityRecord].self, from: data) {
            records = saved
        }
    }

    func add(_ record: CompatibilityRecord) {
        records.insert(record, at: 0)
        do {
            try JSONEncoder().encode(records).write(to: fileURL, options: .atomic)
            lastSaveError = nil
        } catch {
            lastSaveError = AudioErrorHandler.message(for: error)
        }
    }

    var markdown: String {
        var lines = [
            "| Date | Device | iOS | Mode | Outputs | Heard | Result |",
            "|---|---|---|---|---|---|---|",
        ]
        for record in records {
            let cells = [
                record.date.formatted(date: .numeric, time: .shortened), record.deviceModel, record.systemVersion, record.mode,
                record.outputs.joined(separator: " + "), record.heardOutputs.joined(separator: " + "), record.outcome.rawValue,
            ]
            lines.append("| " + cells.joined(separator: " | ") + " |")
        }
        return lines.joined(separator: "\n")
    }
}
