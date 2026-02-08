import Foundation
import Combine

class CallManager: ObservableObject {
    @Published var isRinging: Bool = false
    @Published var callerName: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupObservers()
    }
    
    private func setupObservers() {
        NotificationCenter.default.publisher(for: Notification.Name("com.externaldisplaytools.simulatedCall"))
            .sink { [weak self] notification in
                guard let self = self else { return }
                if let name = notification.userInfo?["callerName"] as? String {
                    self.callerName = name
                    self.isRinging = true
                } else {
                    self.isRinging = false
                }
            }
            .store(in: &cancellables)
            
        NotificationCenter.default.publisher(for: Notification.Name("com.externaldisplaytools.endCall"))
            .sink { [weak self] _ in
                self?.isRinging = false
            }
            .store(in: &cancellables)
    }
    
    func simulateCall(from name: String) {
        NotificationCenter.default.post(name: Notification.Name("com.externaldisplaytools.simulatedCall"), object: nil, userInfo: ["callerName": name])
    }
    
    func endCall() {
        NotificationCenter.default.post(name: Notification.Name("com.externaldisplaytools.endCall"), object: nil)
    }
}
