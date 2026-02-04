import SwiftUI

struct AuthView: View {
    @State private var isSignUp = false
    @State private var isCheckingNetwork = true
    @Bindable var viewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                Text("NeverGone")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(isSignUp ? "Create an account" : "Welcome back")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                VStack(spacing: 16) {
                    TextField("Email", text: $viewModel.email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    SecureField("Password", text: $viewModel.password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(isSignUp ? .newPassword : .password)
                }
                .padding(.horizontal)
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Button {
                    Task {
                        if isSignUp {
                            await viewModel.signUp()
                        } else {
                            await viewModel.signIn()
                        }
                    }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(isSignUp ? "Sign Up" : "Sign In")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)
                .padding(.horizontal)
                
                Button {
                    withAnimation {
                        isSignUp.toggle()
                        viewModel.errorMessage = nil
                    }
                } label: {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .font(.footnote)
                }
                
                Spacer()
            }
            .padding()
            .task {
                // Trigger local network permission prompt early
                await warmupNetworkConnection()
            }
        }
    }
    
    // Network warmup triggers iOS Local Network Permission dialog early so users don't fail on first sign in
    private func warmupNetworkConnection() async {
        print("[Auth] Warming up network connection...")
        do {
            var request = URLRequest(url: Config.supabaseURL.appendingPathComponent("rest/v1/"))
            request.httpMethod = "HEAD"
            request.timeoutInterval = 5
            let _ = try await URLSession.shared.data(for: request)
            print("[Auth] Network warmup successful")
        } catch {
            print("[Auth] Network warmup: \(error.localizedDescription)")
            // This is expected to fail or trigger permission - that's fine
        }
        isCheckingNetwork = false
    }
}
