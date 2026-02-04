import SwiftUI

struct ChatView: View {
    let session: ChatSession
    @State private var viewModel: ChatViewModel?
    
    var body: some View {
        Group {
            if let viewModel {
                ChatContentView(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .task {
            if viewModel == nil {
                viewModel = ChatViewModel(session: session)
            }
        }
    }
}

struct ChatContentView: View {
    @Bindable var viewModel: ChatViewModel
    @FocusState private var isInputFocused: Bool
    private let network = NetworkMonitor.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Offline banner
            if !network.isConnected {
                HStack {
                    Image(systemName: "wifi.slash")
                    Text("Offline - messages will be sent when connected")
                        .font(.caption)
                }
                .foregroundStyle(.white)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color.orange)
            }
            
            ScrollViewReader { proxy in
                ScrollView {
                    // VStack preferred over LazyVStack, LazyVStack has re-render issues with async data
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(
                                message: message,
                                isPending: viewModel.pendingMessageIds.contains(message.id)
                            )
                            .id(message.id)
                        }
                        
                        if viewModel.isStreaming && !viewModel.streamingText.isEmpty {
                            StreamingBubble(text: viewModel.streamingText)
                                .id("streaming")
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) {
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: viewModel.streamingText) {
                    scrollToBottom(proxy: proxy)
                }
            }
            
            Divider()
            
            inputArea
        }
        .navigationTitle(viewModel.session.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                // Save Memory - easy way to demo
                Menu {
                    Button {
                        Task {
                            if let memory = await viewModel.summarizeSession() {
                                print("Memory created: \(memory.summary)")
                            }
                        }
                    } label: {
                        Label("Save Memory", systemImage: "brain")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .task {
            await viewModel.loadMessages()
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    private var inputArea: some View {
        HStack(spacing: 12) {
            TextField("Message", text: $viewModel.inputText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...5)
                .focused($isInputFocused)
            
            if viewModel.isStreaming {
                Button {
                    viewModel.cancelStream()
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.red)
                }
            } else {
                Button {
                    isInputFocused = false
                    Task {
                        await viewModel.sendMessage()
                    }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .background(.bar)
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation {
            if viewModel.isStreaming {
                proxy.scrollTo("streaming", anchor: .bottom)
            } else if let lastMessage = viewModel.messages.last {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    var isPending: Bool = false
    
    private var isUser: Bool { message.role == .user }
    
    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(isUser ? (isPending ? Color.blue.opacity(0.6) : Color.blue) : Color(.systemGray5))
                    .foregroundStyle(isUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                if isPending {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text("Queued")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            
            if !isUser { Spacer(minLength: 60) }
        }
    }
}

struct StreamingBubble: View {
    let text: String
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                Text(text)
                
                Circle()
                    .fill(.primary)
                    .frame(width: 8, height: 8)
                    .opacity(0.5)
            }
            .padding(12)
            .background(Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            Spacer(minLength: 60)
        }
    }
}
