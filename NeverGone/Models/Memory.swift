import Foundation

struct Memory: Identifiable, Codable, Sendable {
    let id: UUID
    let userId: UUID
    let sessionId: UUID?
    let summary: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case sessionId = "session_id"
        case summary
        case createdAt = "created_at"
    }
}

struct SummarizeRequest: Codable, Sendable {
    let sessionId: String
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
    }
}

struct SummarizeResponse: Codable, Sendable {
    let memory: Memory
}
