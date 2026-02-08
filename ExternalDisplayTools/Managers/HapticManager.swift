import AppKit
import Foundation

class HapticManager {
    static let shared = HapticManager()
    
    private let feedbackPerformer = NSHapticFeedbackManager.defaultPerformer
    
    private init() {}
    
    func trigger(_ pattern: NSHapticFeedbackManager.FeedbackPattern = .generic) {
        feedbackPerformer.perform(pattern, performanceTime: .default)
    }
    
    func triggerAlignment() {
        feedbackPerformer.perform(.alignment, performanceTime: .default)
    }
    
    func triggerLevelChange() {
        feedbackPerformer.perform(.levelChange, performanceTime: .default)
    }
}
