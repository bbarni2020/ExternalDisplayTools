//
//  ExternalDisplayToolsApp.swift
//  ExternalDisplayTools
//
//  Created by Balogh Barnabás on 2026. 02. 01..
//

import SwiftUI

class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

@main
struct ExternalDisplayToolsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        
        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    private var musicManager: MusicManager?
    private var bluetoothManager: BluetoothManager?
    private var screenLockObserver: Any?
    private var mouseMonitor: Any?

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        return false
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            ExternalNotchRequestManager.shared.handle(url: url)
        }
        closeExtraWindows()
    }

    private func closeExtraWindows() {
        let windows = NSApplication.shared.windows
        guard let primaryWindow = window ?? windows.first else { return }
        for existingWindow in windows where existingWindow != primaryWindow {
            existingWindow.close()
        }
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let window = NSApplication.shared.windows.first {
            self.window = window
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = false
            window.styleMask = [.borderless, .fullSizeContentView]
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.hidesOnDeactivate = false
            window.level = .screenSaver
            
            if let screen = NSScreen.main {
                window.setFrame(screen.frame, display: true)
            }
            
            setupMouseTracking()
        }
        
        initializeManagers()
        setupScreenLockObserver()
    }
    
    private func initializeManagers() {
        musicManager = MusicManager.shared
        bluetoothManager = BluetoothManager.shared
        
        bluetoothManager?.onDeviceConnected = { deviceName in
            let coordinator = NotchViewCoordinator.shared
            coordinator.showSneakPeek(
                type: .battery,
                value: 1.0,
                icon: "bluetooth"
            )
        }
    }
    
    private func setupScreenLockObserver() {
        screenLockObserver = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                NotchViewCoordinator.shared.closeNotch()
            }
        }
    }
    
    private func setupMouseTracking() {
        guard let window = self.window else { return }
        
        mouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .leftMouseUp]) { [weak self] event in
            guard let self = self,
                  let window = self.window,
                  let contentView = window.contentView else { return event }
            
            let mouseLocation = event.locationInWindow
            let coordinator = NotchViewCoordinator.shared
            
            let interactionFrame: CGRect
            if coordinator.notchState == .open {
                interactionFrame = CGRect(
                    x: 0,
                    y: 0,
                    width: contentView.bounds.width,
                    height: contentView.bounds.height
                )
            } else {
                interactionFrame = CGRect(
                    x: (contentView.bounds.width - coordinator.notchSize.width) / 2 - 50,
                    y: contentView.bounds.height - coordinator.notchSize.height - 100,
                    width: coordinator.notchSize.width + 100,
                    height: coordinator.notchSize.height + 150
                )
            }
            
            if interactionFrame.contains(mouseLocation) {
                return event
            } else {
                return nil
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        if let observer = screenLockObserver {
            DistributedNotificationCenter.default().removeObserver(observer)
        }
        if let monitor = mouseMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
