import AppKit
import Combine

@MainActor
class NotchViewCoordinator: ObservableObject {
    static let shared = NotchViewCoordinator()
    
    @Published var currentView: NotchViews = .home
    @Published var notchState: NotchState = .closed
    @Published var sneakPeek: SneakPeek = SneakPeek()
    @Published var notchSize: NotchSize = NotchSize(width: 189, height: 33)
    @Published var expandedNotchSize: NotchSize = NotchSize(width: 420, height: 110)
    @Published var shouldHideNotch: Bool = false
    
    private var sneakPeekDispatch: DispatchWorkItem?
    
    private let batteryManager = BatteryActivityManager.shared
    private let screenStateManager = ScreenStateManager.shared
    private let callManager = CallManager()
    private let bluetoothManager = BluetoothManager.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        batteryManager.$isLowPowerMode
            .sink { [weak self] isLowPower in
                self?.handleLowPowerModeChange(isLowPower)
            }
            .store(in: &cancellables)
            
        screenStateManager.$isScreenLocked
            .sink { [weak self] isLocked in
                if !isLocked {
                    self?.triggerUnlockAnimation()
                }
            }
            .store(in: &cancellables)
            
        screenStateManager.$isFullScreenAppActive
            .sink { [weak self] isFullScreen in
                self?.handleFullScreenChange(isFullScreen)
            }
            .store(in: &cancellables)
            
        callManager.$isRinging
            .sink { [weak self] isRinging in
                self?.handleCallStateChange(isRinging)
            }
            .store(in: &cancellables)
            
        bluetoothManager.$isConnected
            .sink { [weak self] isConnected in
                self?.triggerBluetoothAnimation(connected: isConnected)
            }
            .store(in: &cancellables)
    }
    
    private func handleFullScreenChange(_ isFullScreen: Bool) {
        shouldHideNotch = isFullScreen
        if isFullScreen && notchState == .open {
            notchState = .closed
        }
    }
    
    private func handleLowPowerModeChange(_ : Bool) {}
    
    private func handleCallStateChange(_ isRinging: Bool) {
        if isRinging {
            self.currentView = .call
            self.notchState = .open
        } else {
            self.currentView = .home
            self.notchState = .closed
        }
    }
    
    func triggerUnlockAnimation() {
        showSneakPeek(type: .unlock, icon: "lock.open.fill")
    }
    
    func triggerBluetoothAnimation(connected: Bool) {
        showSneakPeek(type: .bluetooth, icon: connected ? "bolt.horizontal.fill" : "bolt.horizontal")
    }
    
    func openNotch() {
        notchState = .open
    }
    
    func closeNotch() {
        notchState = .closed
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
        sneakPeek = SneakPeek(show: true, type: type, value: value, icon: icon)
        
        let workItem = DispatchWorkItem { [weak self] in
            self?.sneakPeek.show = false
        }
        
        sneakPeekDispatch = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: workItem)
    }
    
    func hideSneakPeek() {
        sneakPeekDispatch?.cancel()
        sneakPeek.show = false
    }
}
