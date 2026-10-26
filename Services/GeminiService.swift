import Foundation

protocol GeminiServicing {
    func generateReply(messages: [ChatMessage], systemPrompt: String) async throws -> String
}

enum GeminiError: Error, LocalizedError, Equatable {
    case missingAPIKey, invalidConfiguration, invalidResponse, emptyResponse, responseBlocked, outputTruncated
    case httpStatus(Int)
    case modelUnavailable(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "Chat isn't configured yet. Set GEMINI_API_KEY in the Xcode Run scheme, or configure Config/Secrets.local.xcconfig."
        case .invalidConfiguration: return "The Gemini model configuration is invalid. Check GEMINI_MODEL in the Run scheme."
        case .invalidResponse: return "The service sent a response we couldn't read. Please try again."
        case .outputTruncated: return "The reply reached its length limit before finishing. Please try again; your message is still here."
        case .emptyResponse: return "No reply arrived. Please try again."
        case .responseBlocked: return "The service couldn't answer this message safely. You can edit it or open Help now for human support."
        case .modelUnavailable(let model):
            return "Gemini model \(model) isn't available for this API key. Remove any old GEMINI_MODEL override in the Xcode Run scheme to use \(GeminiConfiguration.defaultModel), then run the app again."
        case .httpStatus(let status):
            switch status {
            case 400: return "Gemini couldn't accept this request. Check that the configured model supports generateContent."
            case 401, 403: return "The API key wasn't accepted. Check its access and restrictions in Google AI Studio."
            case 404, 410: return "This Gemini model is unavailable or retired. Set GEMINI_MODEL to an available generateContent model in the Xcode Run scheme."
            case 503: return "Google’s AI service is temporarily busy (503). Your message is still here. Please try again in a moment."
            case 429: return "The service is busy or its quota is used up. Please wait before trying again."
            default: return "The service is temporarily unavailable (\(status)). Please try again later."
            }
        }
    }
}

final class GeminiService: GeminiServicing {
    private let configuration: GeminiConfiguration
    private let session: URLSession
    private let safety = SafetyInterceptor()
    private let sleep: (UInt64) async throws -> Void


    init(configuration: GeminiConfiguration = .live, session: URLSession? = nil,
         sleep: @escaping (UInt64) async throws -> Void = { try await Task.sleep(nanoseconds: $0) }) {
        self.configuration = configuration
        self.sleep = sleep
        if let session = session {
            self.session = session
        } else {
            let settings = URLSessionConfiguration.ephemeral
            settings.urlCache = nil
            settings.httpCookieStorage = nil
            settings.timeoutIntervalForRequest = 45
            settings.timeoutIntervalForResource = 60
            self.session = URLSession(configuration: settings)
        }
    }

    func generateReply(messages: [ChatMessage], systemPrompt: String) async throws -> String {
        // Defense in depth: all user turns are checked even if another caller bypasses the VM.
        // Safety takes precedence over key validation, connectivity, and any network activity.
        for message in messages where message.role == .user { try safety.validate(message.content) }
        try Task.checkCancellation()
        guard !configuration.apiKey.isEmpty else { throw GeminiError.missingAPIKey }
        let modelCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._")
        guard !configuration.model.isEmpty,
              configuration.model.unicodeScalars.allSatisfy({ modelCharacters.contains($0) }),
              let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(configuration.model):generateContent") else {
            throw GeminiError.invalidConfiguration
        }
        guard messages.last?.role == .user else { throw GeminiError.invalidResponse }

        // Coalesce consecutive user turns after an edited/failed reply to preserve Gemini roles.
        var contents: [Content] = []
        for message in messages {
            if contents.last?.role == message.role.rawValue {
                contents[contents.count - 1].parts.append(Part(text: message.content))
            } else {
                contents.append(Content(role: message.role.rawValue, parts: [Part(text: message.content)]))
            }
        }
        // Thinking shares the output allowance. Leave room for a full reply and, if
        // the provider still reports truncation, regenerate once with more headroom.
        for outputLimit in [4096, 8192] {
            let payload = RequestBody(
                systemInstruction: Instruction(parts: [Part(text: systemPrompt)]),
                contents: contents,
                generationConfig: GenerationConfig(temperature: 0.65, maxOutputTokens: outputLimit,
                    thinkingConfig: configuration.model == GeminiConfiguration.defaultModel
                        ? ThinkingConfig(thinkingLevel: "LOW") : nil)
            )
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(configuration.apiKey, forHTTPHeaderField: "x-goog-api-key")
            request.httpBody = try JSONEncoder().encode(payload)
            let (data, response) = try await dataWithRetry(for: request)
            try Task.checkCancellation()
            guard let http = response as? HTTPURLResponse else { throw GeminiError.invalidResponse }
            if http.statusCode == 404 || http.statusCode == 410 {
                throw GeminiError.modelUnavailable(configuration.model)
            }
            guard (200..<300).contains(http.statusCode) else { throw GeminiError.httpStatus(http.statusCode) }
            // Never expose the raw server body: it can contain submitted text or credential details.
            guard let result = try? JSONDecoder().decode(ResponseBody.self, from: data) else {
                throw GeminiError.invalidResponse
            }
            if result.promptFeedback?.blockReason != nil { throw GeminiError.responseBlocked }
            guard let candidate = result.candidates?.first else { throw GeminiError.emptyResponse }
            if candidate.finishReason == "MAX_TOKENS" {
                if outputLimit == 4096 { continue }
                throw GeminiError.outputTruncated
            }
            if let reason = candidate.finishReason, reason != "STOP" {
                throw GeminiError.responseBlocked
            }
            let reply = candidate.content?.parts?.compactMap { part in
                part.thought == true ? nil : part.text
            }.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !reply.isEmpty else { throw GeminiError.emptyResponse }
            return reply
        }
        throw GeminiError.outputTruncated
    }

    private func dataWithRetry(for request: URLRequest) async throws -> (Data, URLResponse) {
        // At most three requests for transient server failures. Credentials, quota, safety,
        // invalid requests, and decoding errors are not retried or sent to another model.
        for attempt in 0..<3 {
            try Task.checkCancellation()
            let result = try await session.data(for: request)
            try Task.checkCancellation()
            guard let response = result.1 as? HTTPURLResponse,
                  [500, 502, 503, 504].contains(response.statusCode), attempt < 2 else {
                return result
            }
            let delay: Double
            if let retryAfter = response.value(forHTTPHeaderField: "Retry-After") {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
                let seconds = Double(retryAfter) ?? formatter.date(from: retryAfter)?.timeIntervalSinceNow
                // Respect long server-directed cooldowns by leaving retry to the user.
                if let seconds = seconds, !seconds.isFinite || seconds > 10 { return result }
                delay = max(seconds ?? pow(2, Double(attempt)), 0)
            } else {
                delay = pow(2, Double(attempt)) + Double.random(in: 0...0.25)
            }
            try await sleep(UInt64(delay * 1_000_000_000))
        }
        throw GeminiError.invalidResponse
    }

    private struct Part: Encodable { let text: String }
    private struct Content: Encodable { let role: String; var parts: [Part] }
    private struct Instruction: Encodable { let parts: [Part] }
    private struct ThinkingConfig: Encodable { let thinkingLevel: String }
    private struct GenerationConfig: Encodable {
        let temperature: Double
        let maxOutputTokens: Int
        let thinkingConfig: ThinkingConfig?
    }
    private struct RequestBody: Encodable {
        let systemInstruction: Instruction
        let contents: [Content]
        let generationConfig: GenerationConfig
    }
    private struct ResponseBody: Decodable {
        let candidates: [Candidate]?
        let promptFeedback: PromptFeedback?
    }
    private struct PromptFeedback: Decodable { let blockReason: String? }
    private struct Candidate: Decodable { let content: ReplyContent?; let finishReason: String? }
    private struct ReplyContent: Decodable { let parts: [ReplyPart]? }
    private struct ReplyPart: Decodable { let text: String?; let thought: Bool? }
}
