import Foundation
import Combine
import AppKit

class ScreenStateManager: ObservableObject {
    @Published var isScreenLocked: Bool = false
    @Published var isFullScreenAppActive: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private var checkTimer: Timer?
    
    init() {
        setupObservers()
        startFullScreenMonitoring()
    }
    
    deinit {
        checkTimer?.invalidate()
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
        
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.activeSpaceDidChangeNotification)
            .sink { [weak self] _ in
                self?.checkFullScreenStatus()
            }
            .store(in: &cancellables)
    }
    
    private func startFullScreenMonitoring() {
        checkTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkFullScreenStatus()
        }
        checkFullScreenStatus()
    }
    
    private func checkFullScreenStatus() {
        let workspace = NSWorkspace.shared
        guard let frontApp = workspace.frontmostApplication else {
            isFullScreenAppActive = false
            return
        }
        
        let options = CGWindowListOption(arrayLiteral: .excludeDesktopElements, .optionOnScreenOnly)
        let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: AnyObject]]
        
        var hasFullScreenWindow = false
        
        if let windows = windowList {
            for window in windows {
                guard let owner = window[kCGWindowOwnerName as String] as? String,
                      owner == frontApp.localizedName,
                      let bounds = window[kCGWindowBounds as String] as? [String: CGFloat],
                      let layer = window[kCGWindowLayer as String] as? Int else {
                    continue
                }
                
                if layer == 0 {
                    let windowWidth = bounds["Width"] ?? 0
                    let windowHeight = bounds["Height"] ?? 0
                    
                    if let screen = NSScreen.main {
                        let screenWidth = screen.frame.width
                        let screenHeight = screen.frame.height
                        
                        if abs(windowWidth - screenWidth) < 1 && abs(windowHeight - screenHeight) < 1 {
                            hasFullScreenWindow = true
                            break
                        }
                    }
                }
            }
        }
        
        DispatchQueue.main.async {
            self.isFullScreenAppActive = hasFullScreenWindow
        }
    }
}
