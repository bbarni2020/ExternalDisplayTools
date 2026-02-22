import AppKit
import Foundation

class HapticManager {
    static let shared = HapticManager()
    
    private let feedbackPerformer = NSHapticFeedbackManager.defaultPerformer
    
    private init() {}
    
    func trigger(_ pattern: NSHapticFeedbackManager.FeedbackPattern = .generic) {
        guard AppSettings.shared.hapticFeedbackEnabled else { return }
        feedbackPerformer.perform(pattern, performanceTime: .default)
    }
    
    func triggerAlignment() {
        guard AppSettings.shared.hapticFeedbackEnabled else { return }
        feedbackPerformer.perform(.alignment, performanceTime: .default)
    }
    
    func triggerLevelChange() {
        guard AppSettings.shared.hapticFeedbackEnabled else { return }
        feedbackPerformer.perform(.levelChange, performanceTime: .default)
    }
}
