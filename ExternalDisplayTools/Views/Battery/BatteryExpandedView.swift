import SwiftUI

struct BatteryExpandedView: View {
    @StateObject private var batteryManager = BatteryActivityManager.shared
    @StateObject private var coordinator = NotchViewCoordinator.shared
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            Spacer()
            
            batteryIndicator
            
            Spacer()
            
            batteryDetails
            
            Spacer()
        }
        .padding(24)
    }
    
    private var header: some View {
        HStack {
            Button(action: {
                coordinator.currentView = .home
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            Text("Battery")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Button(action: {
                coordinator.closeNotch()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var batteryIndicator: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 12)
                    .frame(width: 160, height: 160)
                
                Circle()
                    .trim(from: 0, to: CGFloat(batteryManager.currentBatteryLevel / 100))
                    .stroke(
                        batteryColor,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 4) {
                    Text("\(Int(batteryManager.currentBatteryLevel))%")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                    
                    if batteryManager.isPluggedIn {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.yellow)
                    }
                }
            }
        }
    }
    
    private var batteryDetails: some View {
        VStack(spacing: 12) {
            detailRow(icon: "powerplug", title: "Power Source", value: batteryManager.isPluggedIn ? "AC Power" : "Battery")
            
            detailRow(icon: "battery.100", title: "Status", value: batteryStatusText)
        }
        .padding(.horizontal)
    }
    
    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    private var batteryColor: Color {
        if batteryManager.currentBatteryLevel > 50 {
            return .green
        } else if batteryManager.currentBatteryLevel > 20 {
            return .yellow
        } else {
            return .red
        }
    }
    
    private var batteryStatusText: String {
        if batteryManager.isPluggedIn {
            return "Charging"
        } else {
            return "Discharging"
        }
    }
}
