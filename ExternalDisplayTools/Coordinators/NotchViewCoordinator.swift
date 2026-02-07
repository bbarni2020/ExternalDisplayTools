import AppKit
import Combine
import SwiftUI

@MainActor
class NotchViewCoordinator: ObservableObject {
    static let shared = NotchViewCoordinator()
    
    @Published var currentView: NotchViews = .home
    @Published var notchState: NotchState = .closed
    @Published var sneakPeek: SneakPeek = SneakPeek()
    @Published var notchSize: NotchSize = NotchSize(width: 189, height: 32)
    @Published var expandedNotchSize: NotchSize = NotchSize(width: 420, height: 110)
    
    private var sneakPeekDispatch: DispatchWorkItem?
    
    private let batteryManager = BatteryActivityManager.shared
    private let screenStateManager = ScreenStateManager()
    private let callManager = CallManager()
    private let bluetoothManager = BluetoothManager.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        // Battery Low Power Mode
        batteryManager.$isLowPowerMode
            .sink { [weak self] isLowPower in
                self?.handleLowPowerModeChange(isLowPower)
            }
            .store(in: &cancellables)
            
        // Screen Lock
        screenStateManager.$isScreenLocked
            .sink { [weak self] isLocked in
                if !isLocked {
                    self?.triggerUnlockAnimation()
                }
            }
            .store(in: &cancellables)
            
        // Call
        callManager.$isRinging
            .sink { [weak self] isRinging in
                self?.handleCallStateChange(isRinging)
            }
            .store(in: &cancellables)
            
        // Bluetooth
        bluetoothManager.$isConnected
            .sink { [weak self] isConnected in
                self?.triggerBluetoothAnimation(connected: isConnected)
            }
            .store(in: &cancellables)
    }
    
    private func handleLowPowerModeChange(_ isLowPower: Bool) {
        if isLowPower {
            if notchState == .closed {
                // If closed, we might want to show a sneak peek or change state
                // For now, let's just update the view if we are open, or handle it in NotchView
            }
        }
    }
    
    private func handleCallStateChange(_ isRinging: Bool) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if isRinging {
                self.currentView = .call
                self.notchState = .open
            } else {
                self.currentView = .home
                self.notchState = .closed
            }
        }
    }
    
    func triggerUnlockAnimation() {
        showSneakPeek(type: .unlock, icon: "lock.open.fill")
    }
    
    func triggerBluetoothAnimation(connected: Bool) {
        showSneakPeek(type: .bluetooth, icon: connected ? "bolt.horizontal.fill" : "bolt.horizontal")
    }
    
    func openNotch() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            notchState = .open
        }
    }
    
    func closeNotch() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
            notchState = .closed
        }
    }
    
    func toggleNotch() {
        if notchState == .open {
            closeNotch()
        } else {
            openNotch()
        }
    }
    
    func showSneakPeek(type: SneakContentType, value: CGFloat = 0, icon: String = "") {
        sneakPeekDispatch?.cancel()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            sneakPeek = SneakPeek(show: true, type: type, value: value, icon: icon)
        }
        
        let workItem = DispatchWorkItem { [weak self] in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                self?.sneakPeek.show = false
            }
        }
        
        sneakPeekDispatch = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: workItem)
    }
    
    func hideSneakPeek() {
        sneakPeekDispatch?.cancel()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            sneakPeek.show = false
        }
    }
}
