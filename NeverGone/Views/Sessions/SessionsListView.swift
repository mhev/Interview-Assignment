import SwiftUI

struct SessionsListView: View {
    @Bindable var viewModel: SessionsViewModel
    let authViewModel: AuthViewModel
    @State private var selectedSession: ChatSession?
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.sessions.isEmpty {
                    ProgressView("Loading...")
                } else if viewModel.sessions.isEmpty {
                    ContentUnavailableView(
                        "No Chats",
                        systemImage: "bubble.left.and.bubble.right",
                        description: Text("Start a new conversation")
                    )
                } else {
                    List {
                        ForEach(viewModel.sessions) { session in
                            SessionRowView(session: session)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedSession = session
                                }
                        }
                        .onDelete { indexSet in
                            Task {
                                for index in indexSet {
                                    await viewModel.deleteSession(viewModel.sessions[index])
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Sign Out") {
                        Task {
                            await authViewModel.signOut()
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            if let session = await viewModel.createSession() {
                                selectedSession = session
                            }
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .navigationDestination(item: $selectedSession) { session in
                ChatView(session: session)
            }
            .task {
                await viewModel.loadSessions()
            }
            .refreshable {
                await viewModel.loadSessions()
            }
        }
    }
}

struct SessionRowView: View {
    let session: ChatSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.title)
                .font(.headline)
            
            Text(session.createdAt, style: .relative)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
