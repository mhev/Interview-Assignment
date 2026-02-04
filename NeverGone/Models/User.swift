import Foundation

struct User: Identifiable, Codable, Sendable {
    let id: UUID
    let email: String
    var displayName: String?
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName = "display_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
