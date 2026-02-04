import Foundation
import Supabase

@Observable
@MainActor
final class ChatViewModel {
    var messages: [ChatMessage] = []
    var inputText = ""
    var isStreaming = false
    var streamingText = ""
    var errorMessage: String?
    var pendingMessageIds: Set<UUID> = []
    
    let session: ChatSession
    private let supabase = SupabaseService.shared
    private let streamingService = StreamingService()
    private let network = NetworkMonitor.shared
    private let queue = MessageQueue.shared
    
    init(session: ChatSession) {
        self.session = session
        setupNetworkObserver()
    }
    
    private func setupNetworkObserver() {
        NotificationCenter.default.addObserver(
            forName: .networkDidBecomeAvailable,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.flushQueue()
            }
        }
    }
    
    func loadMessages() async {
        do {
            let fetchedMessages = try await supabase.fetchMessages(sessionId: session.id)
            print("[ChatViewModel] Loaded \(fetchedMessages.count) messages for session \(session.id)")
            messages = fetchedMessages
            
            // Load any pending messages from queue
            loadPendingMessages()
        } catch {
            print("[ChatViewModel] Error loading messages: \(error)")
            errorMessage = error.localizedDescription
            
            // Still show pending messages even if fetch fails
            loadPendingMessages()
        }
    }
    
    private func loadPendingMessages() {
        let pending = queue.messagesFor(sessionId: session.id)
        for pendingMsg in pending {
            if !messages.contains(where: { $0.id == pendingMsg.id }) {
                let msg = ChatMessage(
                    id: pendingMsg.id,
                    sessionId: pendingMsg.sessionId,
                    role: .user,
                    content: pendingMsg.content,
                    createdAt: pendingMsg.createdAt
                )
                messages.append(msg)
                pendingMessageIds.insert(pendingMsg.id)
            }
        }
    }
    
    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        // Clear input immediately
        let messageText = text
        inputText = ""
        errorMessage = nil
        
        // Check network status
        if !network.isConnected {
            print("[ChatViewModel] Offline - queueing message")
            let pending = queue.enqueue(sessionId: session.id, content: messageText)
            
            let userMessage = ChatMessage(
                id: pending.id,
                sessionId: session.id,
                role: .user,
                content: messageText,
                createdAt: Date()
            )
            messages.append(userMessage)
            pendingMessageIds.insert(pending.id)
            return
        }
        
        await sendMessageToServer(text: messageText, messageId: UUID())
    }
    
    private func sendMessageToServer(text: String, messageId: UUID, isPending: Bool = false) async {
        isStreaming = true
        streamingText = ""
        
        // Add optimistic user message if not already shown
        if !isPending {
            let userMessage = ChatMessage(
                id: messageId,
                sessionId: session.id,
                role: .user,
                content: text,
                createdAt: Date()
            )
            messages.append(userMessage)
        }
        
        do {
            let authSession = try await supabase.client.auth.session
            let accessToken = authSession.accessToken
            let sessionId = self.session.id
            
            await streamingService.streamChat(
                sessionId: sessionId,
                message: text,
                accessToken: accessToken,
                onChunk: { [weak self] chunk in
                    guard let self else { return }
                    Task { @MainActor [weak self] in
                        self?.streamingText += chunk
                    }
                },
                onComplete: { [weak self] in
                    guard let self else { return }
                    Task { @MainActor [weak self] in
                        self?.pendingMessageIds.remove(messageId)
                        self?.finalizeStream()
                    }
                },
                onError: { [weak self] error in
                    guard let self else { return }
                    Task { @MainActor [weak self] in
                        self?.handleStreamError(error)
                    }
                }
            )
        } catch {
            handleStreamError(error)
        }
    }
    
    func flushQueue() async {
        let pending = queue.messagesFor(sessionId: session.id)
        guard !pending.isEmpty else { return }
        
        print("[ChatViewModel] Flushing \(pending.count) queued messages")
        
        for pendingMsg in pending {
            queue.dequeue(pendingMsg.id)
            await sendMessageToServer(text: pendingMsg.content, messageId: pendingMsg.id, isPending: true)
        }
    }
    
    func cancelStream() {
        Task {
            await streamingService.cancel()
        }
        
        if !streamingText.isEmpty {
            finalizeStream()
        } else {
            isStreaming = false
        }
    }
    
    func summarizeSession() async -> Memory? {
        do {
            return try await supabase.summarizeSession(sessionId: session.id)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
    
    private func finalizeStream() {
        guard !streamingText.isEmpty else {
            isStreaming = false
            return
        }
        
        let assistantMessage = ChatMessage(
            id: UUID(),
            sessionId: session.id,
            role: .assistant,
            content: streamingText,
            createdAt: Date()
        )
        messages.append(assistantMessage)
        streamingText = ""
        isStreaming = false
    }
    
    private func handleStreamError(_ error: Error) {
        errorMessage = error.localizedDescription
        isStreaming = false
        streamingText = ""
    }
}
