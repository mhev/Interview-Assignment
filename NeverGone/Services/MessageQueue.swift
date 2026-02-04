import Foundation

struct PendingMessage: Codable, Identifiable {
    let id: UUID
    let sessionId: UUID
    let content: String
    let createdAt: Date
}

// UserDefaults for offline queue
@MainActor
final class MessageQueue {
    static let shared = MessageQueue()
    
    private let storageKey = "pendingMessages"
    
    private init() {}
    
    var pendingMessages: [PendingMessage] {
        get {
            guard let data = UserDefaults.standard.data(forKey: storageKey),
                  let messages = try? JSONDecoder().decode([PendingMessage].self, from: data) else {
                return []
            }
            return messages
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: storageKey)
            }
        }
    }
    
    func enqueue(sessionId: UUID, content: String) -> PendingMessage {
        let message = PendingMessage(
            id: UUID(),
            sessionId: sessionId,
            content: content,
            createdAt: Date()
        )
        var messages = pendingMessages
        messages.append(message)
        pendingMessages = messages
        print("[Queue] Enqueued message: \(content.prefix(30))... (Queue size: \(messages.count))")
        return message
    }
    
    func dequeue(_ id: UUID) {
        var messages = pendingMessages
        messages.removeAll { $0.id == id }
        pendingMessages = messages
        print("[Queue] Dequeued message. Remaining: \(messages.count)")
    }
    
    func messagesFor(sessionId: UUID) -> [PendingMessage] {
        pendingMessages.filter { $0.sessionId == sessionId }
    }
    
    func clearAll() {
        pendingMessages = []
        print("[Queue] Cleared all pending messages")
    }
}
