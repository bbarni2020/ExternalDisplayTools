import Foundation
import Combine
import AppKit

class ScreenStateManager: ObservableObject {
    @Published var isScreenLocked: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupObservers()
    }
    
    private func setupObservers() {
        DistributedNotificationCenter.default()
            .publisher(for: Notification.Name("com.apple.screenIsLocked"))
            .map { _ in true }
            .assign(to: \.isScreenLocked, on: self)
            .store(in: &cancellables)
            
        DistributedNotificationCenter.default()
            .publisher(for: Notification.Name("com.apple.screenIsUnlocked"))
            .map { _ in false }
            .assign(to: \.isScreenLocked, on: self)
            .store(in: &cancellables)
    }
}
