import Foundation

struct ChatMessage: Identifiable, Codable, Equatable {
    enum Role: String, Codable {
        case user
        // Gemini's REST API calls assistant turns "model".
        case assistant = "model"
    }

    let id: UUID
    let role: Role
    let content: String
    let createdAt: Date

    init(id: UUID = UUID(), role: Role, content: String, createdAt: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.createdAt = createdAt
    }
}

struct ChatSession: Codable {
    let id: UUID
    let persona: Persona
    let messages: [ChatMessage]
    let updatedAt: Date
}
