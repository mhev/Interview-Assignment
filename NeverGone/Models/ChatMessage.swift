import Foundation

enum MessageRole: String, Codable, Sendable {
    case user
    case assistant
}

struct ChatMessage: Identifiable, Codable, Sendable {
    let id: UUID
    let sessionId: UUID
    let role: MessageRole
    var content: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case role
        case content
        case createdAt = "created_at"
    }
}

struct ChatStreamRequest: Codable, Sendable {
    let sessionId: String
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case message
    }
}

struct StreamChunk: Codable, Sendable {
    let chunk: String?
    let done: Bool
    let error: String?
}
