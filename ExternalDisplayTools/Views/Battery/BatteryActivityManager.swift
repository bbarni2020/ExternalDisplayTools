import Foundation
import IOKit.ps
import Combine

@MainActor
final class BatteryActivityManager: ObservableObject {
    
    /// Shared singleton instance
    static let shared = BatteryActivityManager()
    
    /// Indicates if Low Power Mode is active (macOS does not provide direct API; default false)
    @Published var isLowPowerMode: Bool = false
    
    /// Current battery level percentage (0-100)
    @Published var currentBatteryLevel: Double = 100
    
    /// Indicates if the device is plugged into power
    @Published var isPluggedIn: Bool = false

    /// Indicates if the battery is currently charging
    @Published var isCharging: Bool = false

    /// Controls whether the charging animation should stay visible briefly
    @Published var showChargingAnimation: Bool = false
    
    /// Optional callback when power source changes; passes new isPluggedIn value
    var onPowerSourceChange: ((Bool) -> Void)?
    
    private var runLoopSource: CFRunLoopSource?
    private var chargingAnimationWorkItem: DispatchWorkItem?
    private let chargingAnimationDuration: TimeInterval = 3.0
    private let settings = AppSettings.shared
    
    /// Private initializer to setup initial values and observers
    private init() {
        updateBatteryInfo()
        subscribeToPowerSourceChanges()
    }
    
    deinit {
        unsubscribeFromPowerSourceChanges()
    }
    
    /// Updates battery info by querying IOKit power source info
    private func updateBatteryInfo() {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              !sources.isEmpty,
              let source = sources.first,
              let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
            // Defaults remain if system calls fail
            return
        }
        
        // Update battery level if available
        if let currentCapacity = description[kIOPSCurrentCapacityKey as String] as? Int,
           let maxCapacity = description[kIOPSMaxCapacityKey as String] as? Int,
           maxCapacity > 0 {
            let level = Double(currentCapacity) / Double(maxCapacity) * 100
            currentBatteryLevel = level
        } else {
            currentBatteryLevel = 100
        }
        
        // Update plugged-in status
        if let powerSourceState = description[kIOPSPowerSourceStateKey as String] as? String {
            let plugged = (powerSourceState == kIOPSACPowerValue)
            if isPluggedIn != plugged {
                isPluggedIn = plugged
                onPowerSourceChange?(plugged)
            }
        } else {
            isPluggedIn = false
        }

        let charging = (description[kIOPSIsChargingKey as String] as? Bool)
            ?? (description[kIOPSIsChargingKey as String] as? NSNumber)?.boolValue
            ?? false
        let chargingChanged = isCharging != charging
        if chargingChanged {
            isCharging = charging
            if charging {
                startChargingAnimationIfNeeded()
            } else {
                stopChargingAnimation()
            }
        }
    }
    
    /// Callback for power source change notifications
    private func powerSourceChanged(_ context: UnsafeMutableRawPointer?) {
        updateBatteryInfo()
    }
    
    /// Sets up run loop source and adds observer for power source changes
    private func subscribeToPowerSourceChanges() {
        let callback: IOPowerSourceCallbackType = { context in
            let unmanagedSelf = Unmanaged<BatteryActivityManager>.fromOpaque(context!)
            let manager = unmanagedSelf.takeUnretainedValue()
            Task { @MainActor in
                manager.powerSourceChanged(context)
            }
        }
        
        runLoopSource = IOPSNotificationCreateRunLoopSource(callback, Unmanaged.passUnretained(self).toOpaque())?.takeRetainedValue()
        
        if let runLoopSource = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)
        }
    }
    
    /// Removes observer from run loop source
    private func unsubscribeFromPowerSourceChanges() {
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)
            self.runLoopSource = nil
        }
    }

    private func startChargingAnimationIfNeeded() {
        guard settings.showChargingAnimation else {
            showChargingAnimation = false
            return
        }

        chargingAnimationWorkItem?.cancel()
        showChargingAnimation = true

        let workItem = DispatchWorkItem { [weak self] in
            self?.showChargingAnimation = false
        }

        chargingAnimationWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + chargingAnimationDuration, execute: workItem)
    }

    private func stopChargingAnimation() {
        chargingAnimationWorkItem?.cancel()
        chargingAnimationWorkItem = nil
        showChargingAnimation = false
    }
}
