import SwiftUI

struct NotchView: View {
    @StateObject private var coordinator = NotchViewCoordinator.shared
    @StateObject private var musicManager = MusicManager.shared
    @StateObject private var batteryManager = BatteryActivityManager.shared
    @State private var isHovering = false
    @State private var hoverTask: Task<Void, Never>?
    
    private let openAnimation = Animation.spring(response: 0.42, dampingFraction: 0.8)
    private let closeAnimation = Animation.spring(response: 0.45, dampingFraction: 1.0)
    
    var body: some View {
        VStack(spacing: 0) {
            notchContent
                .background(
                    NotchShape(
                        topCornerRadius: coordinator.notchState == .open ? 18 : 5,
                        bottomCornerRadius: coordinator.notchState == .open ? 35 : 15
                    )
                    .fill(Color(red: 0, green: 0, blue: 00))
                    .shadow(
                        color: (coordinator.notchState == .open || isHovering) ? Color.black.opacity(0.7) : .clear,
                        radius: coordinator.notchState == .open ? 6 : 4
                    )
                )
                .frame(
                    width: coordinator.notchState == .open ? (coordinator.currentView == .lowBattery ? 300 : coordinator.expandedNotchSize.width) : coordinator.notchSize.width,
                    height: coordinator.notchState == .open ? (coordinator.currentView == .lowBattery ? 32 : coordinator.expandedNotchSize.height) : coordinator.notchSize.height
                )
                .animation(coordinator.notchState == .open ? openAnimation : closeAnimation, value: coordinator.notchState)
                .contentShape(Rectangle())
                .onHover { hovering in
                    handleHover(hovering)
                }
                .onTapGesture {
                    doOpen()
                }
        }
        .allowsHitTesting(true)
    }
    
    private var notchContent: some View {
        VStack(spacing: 0) {
            if coordinator.notchState == .closed {
                closedNotchView
                    .frame(height: coordinator.notchSize.height)
            } else {
                expandedNotchView
                    .padding(.top, coordinator.notchSize.height + 8)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)
            }
        }
    }
    
    private var closedNotchView: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(height: coordinator.notchSize.height)
    }
    
    private var expandedNotchView: some View {
        Group {
            switch coordinator.currentView {
            case .music:
                musicView
            case .call:
                IncomingCallAnimation()
            case .lowBattery:
                LowBatteryAnimation()
            default:
                musicView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var musicView: some View {
        HStack(spacing: 12) {
            Image(nsImage: musicManager.albumArt)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 48, height: 48)
                .cornerRadius(6)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(musicManager.songTitle.isEmpty ? "No Media Playing" : musicManager.songTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(musicManager.artistName.isEmpty ? "Select a song" : musicManager.artistName)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: {
                    musicManager.previousTrack()
                }) {
                    Image(systemName: "backward.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    musicManager.togglePlayPause()
                }) {
                    Image(systemName: musicManager.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    musicManager.nextTrack()
                }) {
                    Image(systemName: "forward.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var idleNotchView: some View {
        HStack(spacing: 8) {
            Image(systemName: "apple.logo")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
            
            Text(currentTimeString())
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 12)
    }
    
    private var musicPreview: some View {
        HStack(spacing: 12) {
            Image(nsImage: musicManager.albumArt)
                .resizable()
                .frame(width: 24, height: 24)
                .cornerRadius(4)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(musicManager.songTitle)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(musicManager.artistName)
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: musicManager.isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 12)
    }
    
    private var sneakPeekContent: some View {
        HStack(spacing: 12) {
            if coordinator.sneakPeek.type == .bluetooth {
                BluetoothConnectionAnimation()
            } else if coordinator.sneakPeek.type == .unlock {
                HelloAnimation()
            } else {
                if !coordinator.sneakPeek.icon.isEmpty {
                    Image(systemName: coordinator.sneakPeek.icon)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                
                ProgressView(value: coordinator.sneakPeek.value, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .white))
                    .frame(height: 4)
                
                Text("\(Int(coordinator.sneakPeek.value * 100))%")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 40)
            }
        }
        .padding(.horizontal, 16)
    }
    
    private func currentTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }
    
    private func doOpen() {
        guard !musicManager.songTitle.isEmpty else { return }
        withAnimation(openAnimation) {
            coordinator.openNotch()
        }
    }
    
    private func handleHover(_ hovering: Bool) {
        hoverTask?.cancel()
        
        if hovering {
            withAnimation(openAnimation) {
                isHovering = true
            }
            
            guard coordinator.notchState == .closed,
                  !coordinator.sneakPeek.show,
                  !musicManager.songTitle.isEmpty else { return }
            
            hoverTask = Task {
                try? await Task.sleep(for: .seconds(0.3))
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    guard self.coordinator.notchState == .closed,
                          self.isHovering,
                          !self.coordinator.sneakPeek.show,
                          !self.musicManager.songTitle.isEmpty else { return }
                    
                    self.doOpen()
                }
            }
        } else {
            hoverTask = Task {
                try? await Task.sleep(for: .milliseconds(100))
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    withAnimation(self.closeAnimation) {
                        self.isHovering = false
                    }
                    
                    if self.coordinator.notchState == .open {
                        self.coordinator.closeNotch()
                    }
                }
            }
        }
    }
}

struct NotchShape: Shape {
    var topCornerRadius: CGFloat
    var bottomCornerRadius: CGFloat
    
    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { .init(topCornerRadius, bottomCornerRadius) }
        set {
            topCornerRadius = newValue.first
            bottomCornerRadius = newValue.second
        }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + topCornerRadius, y: rect.minY + topCornerRadius),
            control: CGPoint(x: rect.minX + topCornerRadius, y: rect.minY)
        )
        
        path.addLine(to: CGPoint(x: rect.minX + topCornerRadius, y: rect.maxY - bottomCornerRadius))
        
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + topCornerRadius + bottomCornerRadius, y: rect.maxY),
            control: CGPoint(x: rect.minX + topCornerRadius, y: rect.maxY)
        )
        
        path.addLine(to: CGPoint(x: rect.maxX - topCornerRadius - bottomCornerRadius, y: rect.maxY))
        
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - topCornerRadius, y: rect.maxY - bottomCornerRadius),
            control: CGPoint(x: rect.maxX - topCornerRadius, y: rect.maxY)
        )
        
        path.addLine(to: CGPoint(x: rect.maxX - topCornerRadius, y: rect.minY + topCornerRadius))
        
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.maxX - topCornerRadius, y: rect.minY)
        )
        
        path.closeSubpath()
        return path
    }
}

