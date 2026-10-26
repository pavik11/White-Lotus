import Foundation

enum MindfulnessDataError: Error, LocalizedError {
    case unavailable

    var errorDescription: String? {
        "Teacup's grounding guide couldn't be loaded. Please rebuild with mindfulness_data.txt in Copy Bundle Resources."
    }
}

struct MindfulnessDataLoader {
    let bundle: Bundle

    init(bundle: Bundle = .main) { self.bundle = bundle }

    func load() throws -> String {
        guard let url = bundle.url(forResource: "mindfulness_data", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw MindfulnessDataError.unavailable
        }
        return text
    }
}
