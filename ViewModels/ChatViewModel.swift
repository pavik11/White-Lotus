import Foundation
import Combine

@MainActor
final class ChatViewModel: ObservableObject {
    let persona: Persona
    @Published var draft = ""
    @Published private(set) var messages: [ChatMessage] = []
    @Published private(set) var isLoading = false
    @Published var showCrisisIntervention = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var storageWarning: String?
    @Published private(set) var supportTopic: SupportTopic?

    private let service: GeminiServicing
    private let loadMindfulness: () throws -> String
    private let store: ChatStoring
    private let safety = SafetyInterceptor()
    private var task: Task<Void, Never>?
    private var sessionID = UUID()
    private var failedMessageID: UUID?
    private(set) var mindfulnessData: String?

    // Injection keeps network, bundle failures, and cancellation independently testable.
    init(persona: Persona, service: GeminiServicing = GeminiService(),
         store: ChatStoring = LocalChatStore(),
         loadMindfulness: @escaping () throws -> String = { try MindfulnessDataLoader().load() }) {
        self.persona = persona
        self.service = service
        self.store = store
        self.loadMindfulness = loadMindfulness
    }

    var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading && failedMessageID == nil
    }

    func send() {
        guard canSend else { return }
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            // Run before history mutation, disk writes, RAG loading, or a Task/network call.
            try safety.validate(text)
            let prompt = try preparePrompt()
            let message = ChatMessage(role: .user, content: text)
            messages.append(message)
            supportTopic = persona == .teacup ? SupportTopic.suggested(for: text) : nil
            draft = ""
            requestReply(prompt: prompt, pendingMessageID: message.id)
        } catch SafetyError.crisisDetected {
            presentCrisisIntervention()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func retry() {
        guard !isLoading, let pendingID = failedMessageID else { return }
        do {
            for message in messages where message.role == .user { try safety.validate(message.content) }
            let prompt = try preparePrompt()
            requestReply(prompt: prompt, pendingMessageID: pendingID)
        } catch SafetyError.crisisDetected {
            presentCrisisIntervention()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func editFailedMessage() {
        guard !isLoading, let id = failedMessageID, let last = messages.last, last.id == id else { return }
        draft = last.content
        messages.removeLast()
        supportTopic = persona == .teacup ? messages.last(where: { $0.role == .user }).flatMap { SupportTopic.suggested(for: $0.content) } : nil
        failedMessageID = nil
        errorMessage = nil
        persist()
    }

    var hasFailedMessage: Bool { failedMessageID != nil }

    func clearError() { errorMessage = nil }

    func presentCrisisIntervention() {
        resetSession()
        showCrisisIntervention = true
    }

    func resetSession() {
        task?.cancel()
        task = nil
        // Rotate the token so an uncooperative late response cannot repopulate a cleared chat.
        sessionID = UUID()
        messages = []
        draft = ""
        isLoading = false
        failedMessageID = nil
        errorMessage = nil
        storageWarning = nil
        mindfulnessData = nil
        supportTopic = nil
    }

    private func preparePrompt() throws -> String {
        if persona == .teacup, mindfulnessData == nil { mindfulnessData = try loadMindfulness() }
        return try persona.systemPrompt(mindfulnessData: mindfulnessData)
    }

    private func requestReply(prompt: String, pendingMessageID: UUID) {
        isLoading = true
        errorMessage = nil
        failedMessageID = nil
        persist()
        let requestSessionID = sessionID
        let history = messages
        task = Task { [weak self, service] in
            do {
                let reply = try await service.generateReply(messages: history, systemPrompt: prompt)
                guard let self = self, !Task.isCancelled, self.sessionID == requestSessionID else { return }
                self.messages.append(ChatMessage(role: .assistant, content: reply))
                self.persist()
                self.isLoading = false
                self.task = nil
            } catch {
                guard let self = self, !Task.isCancelled, self.sessionID == requestSessionID else { return }
                self.isLoading = false
                self.task = nil
                if error as? SafetyError == .crisisDetected {
                    self.presentCrisisIntervention()
                } else {
                    self.failedMessageID = pendingMessageID
                    if let networkError = error as? URLError {
                        self.errorMessage = networkError.code == .notConnectedToInternet
                            ? "You're offline. Connect to the internet and try again. Help now is still available."
                            : "The connection didn't finish. Please try again when you're ready."
                    } else {
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }

    private func persist() {
        do {
            try store.save(ChatSession(id: sessionID, persona: persona, messages: messages, updatedAt: Date()))
            storageWarning = nil
        } catch {
            storageWarning = "This conversation couldn't be saved on your device. You can continue, but it may not be kept."
        }
    }
}
