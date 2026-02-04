import Foundation

enum Config {
    // Default: 127.0.0.1 for simulator
    // For real device: use your Mac's IP (run: ipconfig getifaddr en0)
    static let supabaseURL = URL(string: "http://127.0.0.1:54321")!
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
    
    static let chatStreamFunction = "chat_stream"
    static let summarizeMemoryFunction = "summarize_memory"
}
