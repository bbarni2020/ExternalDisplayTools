import SwiftUI

struct NotchHomeView: View {
    @StateObject private var coordinator = NotchViewCoordinator.shared
    @StateObject private var musicManager = MusicManager.shared
    @StateObject private var batteryManager = BatteryActivityManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            header
            
            Spacer()
            
            quickActions
            
            Spacer()
        }
        .padding(24)
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Digital Notch")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Text(currentDateString())
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Button(action: {
                coordinator.closeNotch()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var quickActions: some View {
        HStack(spacing: 20) {
            if !musicManager.isPlayerIdle {
                actionCard(
                    icon: "music.note",
                    title: "Music",
                    subtitle: musicManager.songTitle,
                    action: {
                        coordinator.currentView = .music
                    }
                )
            }
            
            actionCard(
                icon: "battery.100",
                title: "Battery",
                subtitle: "\(Int(batteryManager.currentBatteryLevel))%",
                action: {
                    coordinator.currentView = .battery
                }
            )
        }
    }
    
    private func actionCard(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func currentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
}
