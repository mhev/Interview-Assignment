import Foundation
import Supabase

@Observable
@MainActor
final class AuthViewModel {
    var email = ""
    var password = ""
    var isLoading = false
    var errorMessage: String?
    var isAuthenticated = false
    
    private let supabase = SupabaseService.shared
    
    init() {
        Task {
            await checkAuthStatus()
        }
    }
    
    func checkAuthStatus() async {
        print("[Auth] Checking authentication status...")
        let user = await supabase.currentUser
        isAuthenticated = user != nil
        if let user = user {
            print("[Auth] User is authenticated: \(user.id)")
        } else {
            print("[Auth] No authenticated user")
        }
    }
    
    func signUp() async {
        guard validateInput() else { return }
        
        isLoading = true
        errorMessage = nil
        
        print("[Auth] Attempting sign up for: \(email)")
        do {
            try await supabase.signUp(email: email, password: password)
            print("[Auth] Sign up successful, now signing in...")
            try await supabase.signIn(email: email, password: password)
            print("[Auth] Sign in after sign up successful")
            isAuthenticated = true
            clearForm()
        } catch {
            print("[Auth] Sign up failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signIn() async {
        guard validateInput() else { return }
        
        isLoading = true
        errorMessage = nil
        
        print("[Auth] Attempting sign in for: \(email)")
        do {
            try await supabase.signIn(email: email, password: password)
            print("[Auth] Sign in successful")
            if let user = await supabase.currentUser {
                print("[Auth] Authenticated user ID: \(user.id)")
            }
            isAuthenticated = true
            clearForm()
        } catch {
            print("[Auth] Sign in failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signOut() async {
        print("[Auth] Signing out...")
        do {
            try await supabase.signOut()
            print("[Auth] Sign out successful")
            isAuthenticated = false
        } catch {
            print("[Auth] Sign out failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
    
    private func validateInput() -> Bool {
        guard !email.isEmpty else {
            errorMessage = "Email is required"
            return false
        }
        guard !password.isEmpty else {
            errorMessage = "Password is required"
            return false
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return false
        }
        return true
    }
    
    private func clearForm() {
        email = ""
        password = ""
    }
}
