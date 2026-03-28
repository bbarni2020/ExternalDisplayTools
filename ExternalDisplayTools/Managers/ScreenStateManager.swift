import Foundation
import Combine
import AppKit

class ScreenStateManager: ObservableObject {
    static let shared = ScreenStateManager()

    @Published var isScreenLocked: Bool = false
    @Published var isScreenSaverActive: Bool = false
    @Published var isFullScreenAppActive: Bool = false

    var isInteractionRestricted: Bool {
        isScreenLocked || isScreenSaverActive
    }
    
    private var cancellables = Set<AnyCancellable>()
    private var checkTimer: Timer?
    private var lastScreenSaverStartDate: Date?
    private var isScreenSaverLockSession: Bool = false
    
    private init() {
        setupObservers()
        startFullScreenMonitoring()
    }
    
    deinit {
        checkTimer?.invalidate()
    }
    
    private func setupObservers() {
        DistributedNotificationCenter.default()
            .publisher(for: Notification.Name("com.apple.screenIsLocked"))
            .sink { [weak self] _ in
                guard let self else { return }
                self.isScreenLocked = true
                if self.lastScreenSaverStartDate?.timeIntervalSinceNow ?? -.infinity > -4 {
                    self.isScreenSaverLockSession = true
                    self.isScreenSaverActive = true
                }
            }
            .store(in: &cancellables)
            
        DistributedNotificationCenter.default()
            .publisher(for: Notification.Name("com.apple.screenIsUnlocked"))
            .sink { [weak self] _ in
                guard let self else { return }
                self.isScreenLocked = false
                self.isScreenSaverLockSession = false
                self.checkScreenSaverStatus()
            }
            .store(in: &cancellables)

        DistributedNotificationCenter.default()
            .publisher(for: Notification.Name("com.apple.screensaver.didstart"))
            .sink { [weak self] _ in
                guard let self else { return }
                self.lastScreenSaverStartDate = Date()
                self.isScreenSaverActive = true
                if self.isScreenLocked {
                    self.isScreenSaverLockSession = true
                }
            }
            .store(in: &cancellables)

        DistributedNotificationCenter.default()
            .publisher(for: Notification.Name("com.apple.screensaver.didstop"))
            .sink { [weak self] _ in
                guard let self else { return }
                if self.isScreenLocked && self.isScreenSaverLockSession {
                    return
                }
                self.isScreenSaverActive = false
                self.lastScreenSaverStartDate = nil
                self.isScreenSaverLockSession = false
            }
            .store(in: &cancellables)
        
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.activeSpaceDidChangeNotification)
            .sink { [weak self] _ in
                self?.checkFullScreenStatus()
            }
            .store(in: &cancellables)
    }
    
    private func startFullScreenMonitoring() {
        checkTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkDynamicScreenState()
        }
        checkDynamicScreenState()
    }

    private func checkDynamicScreenState() {
        checkFullScreenStatus()
        checkScreenSaverStatus()
    }

    private func checkScreenSaverStatus() {
        if isScreenLocked && isScreenSaverLockSession {
            DispatchQueue.main.async {
                self.isScreenSaverActive = true
            }
            return
        }

        let runningApps = NSWorkspace.shared.runningApplications
        let isEngineRunning = runningApps.contains { app in
            let bundleId = (app.bundleIdentifier ?? "").lowercased()
            let executable = (app.executableURL?.lastPathComponent ?? "").lowercased()
            let name = (app.localizedName ?? "").lowercased()

            if bundleId.contains("screensaver") || bundleId.contains("legacyscreensaver") {
                return true
            }

            if executable.contains("screensaver") || executable.contains("legacyscreensaver") {
                return true
            }

            return name.contains("screensaver") || name.contains("legacyscreensaver")
        }

        let options = CGWindowListOption(arrayLiteral: .optionOnScreenOnly)
        let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: AnyObject]]
        let hasScreenSaverWindow = windowList?.contains { window in
            guard let owner = window[kCGWindowOwnerName as String] as? String else {
                return false
            }
            let ownerName = owner.lowercased()
            return ownerName.contains("screensaver") || ownerName.contains("legacyscreensaver")
        } ?? false

        let isScreenSaverActiveNow = isEngineRunning || hasScreenSaverWindow

        DispatchQueue.main.async {
            self.isScreenSaverActive = isScreenSaverActiveNow
            if !isScreenSaverActiveNow {
                self.lastScreenSaverStartDate = nil
            }
        }
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
