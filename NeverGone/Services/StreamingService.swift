import Foundation

actor StreamingService {
    private var currentTask: Task<Void, Never>?
    
    func streamChat(
        sessionId: UUID,
        message: String,
        accessToken: String,
        onChunk: @escaping @Sendable (String) -> Void,
        onComplete: @escaping @Sendable () -> Void,
        onError: @escaping @Sendable (Error) -> Void
    ) {
        currentTask?.cancel()
        
        currentTask = Task { [sessionId, message, accessToken] in
            do {
                let url = Config.supabaseURL
                    .appendingPathComponent("functions")
                    .appendingPathComponent("v1")
                    .appendingPathComponent(Config.chatStreamFunction)
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
                
                let body = ChatStreamRequest(sessionId: sessionId.uuidString, message: message)
                request.httpBody = try JSONEncoder().encode(body)
                
                let (bytes, response) = try await URLSession.shared.bytes(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw StreamError.invalidResponse
                }
                
                for try await line in bytes.lines {
                    if Task.isCancelled { break }
                    
                    guard line.hasPrefix("data: ") else { continue }
                    let jsonString = String(line.dropFirst(6))
                    
                    guard let data = jsonString.data(using: .utf8) else { continue }
                    
                    let chunk = try JSONDecoder().decode(StreamChunk.self, from: data)
                    
                    if let error = chunk.error {
                        await MainActor.run { onError(StreamError.serverError(error)) }
                        return
                    }
                    
                    if chunk.done {
                        await MainActor.run { onComplete() }
                        return
                    }
                    
                    if let text = chunk.chunk {
                        await MainActor.run { onChunk(text) }
                    }
                }
                
                if !Task.isCancelled {
                    await MainActor.run { onComplete() }
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run { onError(error) }
                }
            }
        }
    }
    
    func cancel() {
        currentTask?.cancel()
        currentTask = nil
    }
}

enum StreamError: LocalizedError {
    case invalidResponse
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let message):
            return message
        }
    }
}
