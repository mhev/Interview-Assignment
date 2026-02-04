import Foundation
import Network

@Observable
@MainActor
final class NetworkMonitor {
    static let shared = NetworkMonitor()
    
    var isConnected = true
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                let wasConnected = self?.isConnected ?? true
                self?.isConnected = path.status == .satisfied
                
                print("[Network] Status: \(path.status == .satisfied ? "Online" : "Offline")")
                
                // Notify when coming back online
                if self?.isConnected == true && !wasConnected {
                    NotificationCenter.default.post(name: .networkDidBecomeAvailable, object: nil)
                }
            }
        }
        monitor.start(queue: queue)
    }
}

extension Notification.Name {
    static let networkDidBecomeAvailable = Notification.Name("networkDidBecomeAvailable")
}
