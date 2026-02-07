//
//  ExternalDisplayToolsApp.swift
//  ExternalDisplayTools
//
//  Created by Balogh Barnabás on 2026. 02. 01..
//

import SwiftUI

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
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let window = NSApplication.shared.windows.first {
            self.window = window
            window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = false
            window.styleMask = [.borderless, .fullSizeContentView]
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden

            window.hidesOnDeactivate = false
            
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
        guard let window = window else { return }
        
        let trackingArea = NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect],
            owner: window,
            userInfo: nil
        )
        window.contentView?.addTrackingArea(trackingArea)
        
        mouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { event in
            guard let window = self.window,
                  let contentView = window.contentView else { return event }
            
            let mouseLocation = event.locationInWindow
            let notchFrame = CGRect(
                x: (contentView.bounds.width - NotchViewCoordinator.shared.notchSize.width) / 2,
                y: contentView.bounds.height - NotchViewCoordinator.shared.notchSize.height,
                width: NotchViewCoordinator.shared.notchSize.width + 100,
                height: NotchViewCoordinator.shared.notchSize.height + 50
            )
            
            if notchFrame.contains(mouseLocation) {
                window.ignoresMouseEvents = false
            } else {
                window.ignoresMouseEvents = true
            }
            
            return event
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
