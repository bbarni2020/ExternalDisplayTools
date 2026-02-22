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
    private var leftCornerWindow: NSWindow?
    private var rightCornerWindow: NSWindow?
    private var musicManager: MusicManager?
    private var bluetoothManager: BluetoothManager?
    private var keyboardRemapManager: KeyboardRemapManager?
    private var screenLockObserver: Any?
    private let cornerSize: CGFloat = 12
    private let notchHostSize = CGSize(width: 520, height: 140)

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
            configureOverlayWindow(window)
            positionNotchHostWindow(window, in: NSScreen.main)
            createCornerWindows(in: NSScreen.main)
        }
        
        initializeManagers()
        setupScreenLockObserver()
    }
    
    private func initializeManagers() {
        musicManager = MusicManager.shared
        bluetoothManager = BluetoothManager.shared
        keyboardRemapManager = KeyboardRemapManager.shared
        _ = AppSettings.shared
        
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

    private func configureOverlayWindow(_ window: NSWindow) {
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.styleMask = [.borderless, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.hidesOnDeactivate = false
        window.level = .screenSaver
    }

    private func positionNotchHostWindow(_ window: NSWindow, in screen: NSScreen?) {
        guard let screen else { return }

        let frame = CGRect(
            x: screen.frame.midX - notchHostSize.width / 2,
            y: screen.frame.maxY - notchHostSize.height,
            width: notchHostSize.width,
            height: notchHostSize.height
        )

        window.setFrame(frame, display: false, animate: false)
        window.orderFrontRegardless()
    }

    private func createCornerWindows(in screen: NSScreen?) {
        guard let screen else { return }

        let leftFrame = CGRect(
            x: screen.frame.minX,
            y: screen.frame.maxY - cornerSize,
            width: cornerSize,
            height: cornerSize
        )

        let rightFrame = CGRect(
            x: screen.frame.maxX - cornerSize,
            y: screen.frame.maxY - cornerSize,
            width: cornerSize,
            height: cornerSize
        )

        leftCornerWindow = makeCornerWindow(frame: leftFrame, position: .topLeft)
        rightCornerWindow = makeCornerWindow(frame: rightFrame, position: .topRight)
    }

    private func makeCornerWindow(frame: CGRect, position: CornerPosition) -> NSWindow {
        let cornerWindow = OverlayWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        configureOverlayWindow(cornerWindow)
        cornerWindow.contentView = NSHostingView(rootView: CornerOverlayView(position: position, cornerSize: cornerSize))
        cornerWindow.orderFrontRegardless()
        return cornerWindow
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        if let observer = screenLockObserver {
            DistributedNotificationCenter.default().removeObserver(observer)
        }
    }
}

private struct CornerOverlayView: View {
    let position: CornerPosition
    let cornerSize: CGFloat

    var body: some View {
        Canvas { context, size in
            var path = Path()

            switch position {
            case .topLeft:
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: cornerSize, y: 0))
                path.addArc(
                    center: CGPoint(x: cornerSize, y: cornerSize),
                    radius: cornerSize,
                    startAngle: .degrees(270),
                    endAngle: .degrees(180),
                    clockwise: true
                )
                path.addLine(to: CGPoint(x: 0, y: 0))

            case .topRight:
                let x = size.width
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: cornerSize))
                path.addArc(
                    center: CGPoint(x: x - cornerSize, y: cornerSize),
                    radius: cornerSize,
                    startAngle: .degrees(0),
                    endAngle: .degrees(270),
                    clockwise: true
                )
                path.addLine(to: CGPoint(x: x, y: 0))
            }

            context.fill(path, with: .color(.black))
        }
        .frame(width: cornerSize, height: cornerSize)
    }
}

private enum CornerPosition {
    case topLeft
    case topRight
}
