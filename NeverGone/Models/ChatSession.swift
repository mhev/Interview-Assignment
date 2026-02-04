import Foundation

struct ChatSession: Identifiable, Codable, Sendable, Hashable {
    let id: UUID
    let userId: UUID
    var title: String
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct CreateSessionRequest: Codable, Sendable {
    let userId: UUID
    let title: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case title
    }
}
