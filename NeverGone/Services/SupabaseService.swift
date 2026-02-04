import Foundation
import Supabase

@MainActor
final class SupabaseService {
    static let shared = SupabaseService()
    
    let client: SupabaseClient
    
    private init() {
        client = SupabaseClient(
            supabaseURL: Config.supabaseURL,
            supabaseKey: Config.supabaseAnonKey
        )
    }
    
    // MARK: - Auth
    
    var currentUser: Supabase.User? {
        get async {
            try? await client.auth.session.user
        }
    }
    
    func signUp(email: String, password: String) async throws {
        try await client.auth.signUp(email: email, password: password)
    }
    
    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    // MARK: - Sessions
    
    func fetchSessions() async throws -> [ChatSession] {
        try await client
            .from("chat_sessions")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
    }
    
    func createSession(title: String) async throws -> ChatSession {
        guard let userId = await currentUser?.id else {
            throw SupabaseError.notAuthenticated
        }
        
        let request = CreateSessionRequest(userId: userId, title: title)
        return try await client
            .from("chat_sessions")
            .insert(request)
            .select()
            .single()
            .execute()
            .value
    }
    
    func deleteSession(id: UUID) async throws {
        try await client
            .from("chat_sessions")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    // MARK: - Messages
    
    func fetchMessages(sessionId: UUID) async throws -> [ChatMessage] {
        print("[SupabaseService] Fetching messages for session: \(sessionId)")
        
        // Check if user is authenticated
        if let user = await currentUser {
            print("[SupabaseService] Authenticated as user: \(user.id)")
        } else {
            print("[SupabaseService] WARNING: No authenticated user!")
        }
        
        do {
            let messages: [ChatMessage] = try await client
                .from("chat_messages")
                .select()
                .eq("session_id", value: sessionId.uuidString)
                .order("created_at", ascending: true)
                .execute()
                .value
            print("[SupabaseService] Fetched \(messages.count) messages")
            return messages
        } catch {
            print("[SupabaseService] Error fetching messages: \(error)")
            throw error
        }
    }
    
    // MARK: - Memories
    
    func summarizeSession(sessionId: UUID) async throws -> Memory {
        print("[SupabaseService] Summarizing session: \(sessionId)")
        
        // Encode request body
        let requestBody = try JSONEncoder().encode(SummarizeRequest(sessionId: sessionId.uuidString))
        
        // Call the edge function
        let url = Config.supabaseURL
            .appendingPathComponent("functions")
            .appendingPathComponent("v1")
            .appendingPathComponent(Config.summarizeMemoryFunction)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        
        let session = try await client.auth.session
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = requestBody
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("[SupabaseService] Summarize failed: \(errorMessage)")
            throw SupabaseError.invalidResponse
        }
        
        // Decode with custom decoder that handles ISO8601 dates
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            // Try without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateString)")
        }
        
        let summarizeResponse = try decoder.decode(SummarizeResponse.self, from: data)
        print("[SupabaseService] Memory created: \(summarizeResponse.memory.id)")
        return summarizeResponse.memory
    }
}

enum SupabaseError: LocalizedError {
    case notAuthenticated
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated"
        case .invalidResponse:
            return "Invalid response from server"
        }
    }
}
