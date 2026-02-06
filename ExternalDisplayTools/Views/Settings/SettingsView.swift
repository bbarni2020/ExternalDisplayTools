import SwiftUI

struct SettingsView: View {
    @StateObject private var coordinator = NotchViewCoordinator.shared
    @StateObject private var musicManager = MusicManager.shared
    
    @State private var selectedTab: SettingsTab = .general
    
    enum SettingsTab: String, CaseIterable {
        case general = "General"
        case appearance = "Appearance"
        case media = "Media"
        case battery = "Battery"
    }
    
    var body: some View {
        HStack(spacing: 0) {
            sidebar
            
            Divider()
            
            contentView
        }
        .frame(width: 600, height: 400)
    }
    
    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(SettingsTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    HStack {
                        Image(systemName: iconForTab(tab))
                            .font(.system(size: 14))
                        
                        Text(tab.rawValue)
                            .font(.system(size: 13))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(selectedTab == tab ? Color.accentColor.opacity(0.2) : Color.clear)
                    )
                    .foregroundColor(selectedTab == tab ? .accentColor : .primary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
        }
        .padding(12)
        .frame(width: 180)
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                switch selectedTab {
                case .general:
                    GeneralSettingsView()
                case .appearance:
                    AppearanceSettingsView()
                case .media:
                    MediaSettingsView()
                case .battery:
                    BatterySettingsView()
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func iconForTab(_ tab: SettingsTab) -> String {
        switch tab {
        case .general:
            return "gearshape"
        case .appearance:
            return "paintbrush"
        case .media:
            return "music.note"
        case .battery:
            return "battery.100"
        }
    }
}

struct GeneralSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("General")
                .font(.system(size: 20, weight: .bold))
            
            Toggle("Launch at Login", isOn: .constant(false))
            
            Toggle("Enable Haptic Feedback", isOn: .constant(true))
            
            Divider()
            
            Text("About")
                .font(.system(size: 16, weight: .semibold))
            
            HStack {
                Text("Version:")
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct AppearanceSettingsView: View {
    @StateObject private var coordinator = NotchViewCoordinator.shared
    @State private var notchWidth: Double = 250
    @State private var notchHeight: Double = 30
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Appearance")
                .font(.system(size: 20, weight: .bold))
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Notch Width: \(Int(notchWidth))px")
                    .font(.system(size: 13))
                
                Slider(value: $notchWidth, in: 200...400, step: 10)
                    .onChange(of: notchWidth) { oldValue, newValue in
                        coordinator.notchSize.width = newValue
                    }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Notch Height: \(Int(notchHeight))px")
                    .font(.system(size: 13))
                
                Slider(value: $notchHeight, in: 25...50, step: 5)
                    .onChange(of: notchHeight) { oldValue, newValue in
                        coordinator.notchSize.height = newValue
                    }
            }
        }
        .onAppear {
            notchWidth = coordinator.notchSize.width
            notchHeight = coordinator.notchSize.height
        }
    }
}

struct MediaSettingsView: View {
    @StateObject private var musicManager = MusicManager.shared
    @State private var selectedController: MediaControllerType = .appleMusic
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Media Playback")
                .font(.system(size: 20, weight: .bold))
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Media Controller")
                    .font(.system(size: 13, weight: .medium))
                
                Picker("", selection: $selectedController) {
                    ForEach(MediaControllerType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(RadioGroupPickerStyle())
                .onChange(of: selectedController) { oldValue, newValue in
                    musicManager.switchController(to: newValue)
                }
            }
            
            Divider()
            
            Toggle("Show Music in Notch", isOn: .constant(true))
            
            Toggle("Auto-expand for Music", isOn: .constant(false))
        }
    }
}

struct BatterySettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Battery")
                .font(.system(size: 20, weight: .bold))
            
            Toggle("Show Battery Notifications", isOn: .constant(true))
            
            Toggle("Show Charging Animation", isOn: .constant(true))
            
            Divider()
            
            Text("Notifications will appear when:")
                .font(.system(size: 13, weight: .medium))
            
            VStack(alignment: .leading, spacing: 8) {
                Text("• Power adapter is connected/disconnected")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Text("• Battery reaches low power mode")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
    }
}
