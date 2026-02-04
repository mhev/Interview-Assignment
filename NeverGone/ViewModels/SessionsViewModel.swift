import Foundation

@Observable
@MainActor
final class SessionsViewModel {
    var sessions: [ChatSession] = []
    var isLoading = false
    var errorMessage: String?
    
    private let supabase = SupabaseService.shared
    
    func loadSessions() async {
        isLoading = true
        errorMessage = nil
        
        do {
            sessions = try await supabase.fetchSessions()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func createSession() async -> ChatSession? {
        isLoading = true
        errorMessage = nil
        
        do {
            let session = try await supabase.createSession(title: "New Chat")
            sessions.insert(session, at: 0)
            isLoading = false
            return session
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return nil
        }
    }
    
    func deleteSession(_ session: ChatSession) async {
        do {
            try await supabase.deleteSession(id: session.id)
            sessions.removeAll { $0.id == session.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
