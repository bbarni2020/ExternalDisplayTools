import Foundation
import Combine
import ServiceManagement

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
            updateLaunchAtLoginRegistration(enabled: launchAtLogin)
        }
    }

    @Published var hapticFeedbackEnabled: Bool {
        didSet { defaults.set(hapticFeedbackEnabled, forKey: Keys.hapticFeedbackEnabled) }
    }

    @Published var showBatteryNotifications: Bool {
        didSet { defaults.set(showBatteryNotifications, forKey: Keys.showBatteryNotifications) }
    }

    @Published var showChargingAnimation: Bool {
        didSet { defaults.set(showChargingAnimation, forKey: Keys.showChargingAnimation) }
    }

    private let defaults: UserDefaults

    private enum Keys {
        static let launchAtLogin = "settings.launchAtLogin"
        static let hapticFeedbackEnabled = "settings.hapticFeedbackEnabled"
        static let showBatteryNotifications = "settings.showBatteryNotifications"
        static let showChargingAnimation = "settings.showChargingAnimation"
    }

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        launchAtLogin = defaults.object(forKey: Keys.launchAtLogin) as? Bool ?? false
        hapticFeedbackEnabled = defaults.object(forKey: Keys.hapticFeedbackEnabled) as? Bool ?? true
        showBatteryNotifications = defaults.object(forKey: Keys.showBatteryNotifications) as? Bool ?? true
        showChargingAnimation = defaults.object(forKey: Keys.showChargingAnimation) as? Bool ?? true

        updateLaunchAtLoginRegistration(enabled: launchAtLogin)
    }

    private func updateLaunchAtLoginRegistration(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("Launch at login update failed: %@", error.localizedDescription)
        }
    }
}
