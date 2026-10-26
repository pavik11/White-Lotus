import Foundation

enum SafetyError: Error, LocalizedError, Equatable {
    case crisisDetected

    var errorDescription: String? { "Let's connect you with human support right now." }
}

struct SafetyInterceptor {
    // The exact six triggers from AGENTS.md. Deliberate substring matching follows its rule,
    // including conservative matches such as "substance abuse". This is not clinical triage.
    static let triggerWords = ["suicide", "kill myself", "harm myself", "abuse", "end it all", "want to die"]

    func validate(_ input: String) throws {
        let lowercased = input.lowercased()
        let normalized = input.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
                                       locale: Locale(identifier: "en_US_POSIX"))
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        if Self.triggerWords.contains(where: { lowercased.contains($0) || normalized.contains($0) }) {
            throw SafetyError.crisisDetected
        }
    }
}
