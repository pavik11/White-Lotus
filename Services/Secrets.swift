import Foundation

enum Secrets {
    // The key comes from an ignored local xcconfig via the generated Info.plist.
    // GEMINI_API_KEY in the Run scheme still takes precedence in .live below.
    static var geminiAPIKey: String {
        let value = (Bundle.main.object(forInfoDictionaryKey: "GeminiAPIKey") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return value.hasPrefix("$(") ? "" : value
    }
}

struct GeminiConfiguration {
    // One source of truth for both explicit configuration and the live app.
    static let defaultModel = "gemini-3.6-flash"

    let apiKey: String
    let model: String

    init(apiKey: String, model: String = GeminiConfiguration.defaultModel) {
        self.apiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedModel = model.trimmingCharacters(in: .whitespacesAndNewlines)
        // models.list returns resource names; accept those as well as bare model IDs.
        let modelID = trimmedModel.hasPrefix("models/") ? String(trimmedModel.dropFirst(7)) : trimmedModel
        self.model = modelID.isEmpty ? Self.defaultModel : modelID
    }

    static var live: GeminiConfiguration {
        let environment = ProcessInfo.processInfo.environment
        return GeminiConfiguration(
            apiKey: environment["GEMINI_API_KEY"] ?? Secrets.geminiAPIKey,
            model: environment["GEMINI_MODEL"] ?? defaultModel
        )
    }
}
