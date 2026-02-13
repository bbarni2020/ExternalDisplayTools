import SwiftUI

struct NotchView: View {
    @StateObject private var coordinator = NotchViewCoordinator.shared
    @StateObject private var musicManager = MusicManager.shared
    @StateObject private var batteryManager = BatteryActivityManager.shared
    @StateObject private var nowPlayingManager = NowPlayingMetadataManager.shared
    @StateObject private var externalRequestManager = ExternalNotchRequestManager.shared
    @State private var isHovering = false
    @State private var hoverTask: Task<Void, Never>?
    @State private var previousHover = false
    @State private var playPauseHover = false
    @State private var nextHover = false
    @State private var isClickedOpen = false
    
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
                .clipShape(NotchShape(
                    topCornerRadius: coordinator.notchState == .open ? 18 : 5,
                    bottomCornerRadius: coordinator.notchState == .open ? 35 : 15
                ))
                .frame(
                    width: coordinator.notchState == .open ? (coordinator.currentView == .lowBattery ? 300 : coordinator.expandedNotchSize.width) : (!nowPlayingManager.title.isEmpty ? 270 : coordinator.notchSize.width),
                    height: coordinator.notchState == .open ? (coordinator.currentView == .lowBattery ? 32 : coordinator.expandedNotchSize.height + 1) : coordinator.notchSize.height
                )
                .scaleEffect(
                    coordinator.shouldHideNotch ? 0.4 : 1.0,
                    anchor: .top
                )
                .offset(y: coordinator.shouldHideNotch ? -50 : 0)
                .opacity(coordinator.shouldHideNotch ? 0 : 1)
                .animation(.spring(response: 0.42, dampingFraction: 0.8), value: nowPlayingManager.title)
                .animation(coordinator.notchState == .open ? openAnimation : closeAnimation, value: coordinator.notchState)
                .animation(.spring(response: 0.5, dampingFraction: 0.75), value: coordinator.shouldHideNotch)
                .onHover { hovering in
                    if !coordinator.shouldHideNotch {
                        handleHover(hovering)
                    }
                }
                .onTapGesture {
                    if coordinator.notchState == .closed && !coordinator.shouldHideNotch {
                        isClickedOpen = true
                        doOpen()
                    } else if coordinator.notchState == .open && isClickedOpen && !coordinator.shouldHideNotch {
                        isClickedOpen = false
                        coordinator.closeNotch()
                    }
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
                    .allowsHitTesting(true)
            }
        }
    }
    
    private var closedNotchView: some View {
        Group {
            if !nowPlayingManager.title.isEmpty {
                HStack(spacing: 0) {
                    Group {
                        if let artwork = nowPlayingManager.artworkImage {
                            Image(nsImage: artwork)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 18, height: 18)
                                .cornerRadius(5)
                        } else {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 18, height: 18)
                                .overlay(
                                    Image(systemName: "music.note")
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                )
                        }
                    }
                    .padding(.leading, 12)
                    .offset(y: -1)
                    
                    Spacer()
                    
                    MusicBarsAnimation(isPlaying: nowPlayingManager.isPlaying)
                        .frame(height: 12)
                        .padding(.trailing, 12)
                }
                .frame(height: coordinator.notchSize.height)
                .frame(maxHeight: .infinity, alignment: .center)
            } else {
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: coordinator.notchSize.height)
            }
        }
    }
    
    private var expandedNotchView: some View {
        Group {
            if let request = externalRequestManager.activeRequest {
                externalRequestView(request)
            } else {
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(true)
    }

    private func externalRequestView(_ request: ExternalNotchRequest) -> some View {
        ExternalNotchContentView(request: request)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var musicView: some View {
        HStack(spacing: 12) {
            if let artwork = nowPlayingManager.artworkImage {
                Image(nsImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 48, height: 48)
                    .cornerRadius(6)
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(nowPlayingManager.title.isEmpty ? "No Media Playing" : nowPlayingManager.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(nowPlayingManager.artist.isEmpty ? "Select a song" : nowPlayingManager.artist)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: {
                    nowPlayingManager.previousTrack()
                }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                 
                        .scaleEffect(previousHover ? 1.2 : 1.0)
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Rectangle())
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        previousHover = hovering
                    }
                }
                
                Button(action: {
                    nowPlayingManager.togglePlayPause()
                }) {
                    Image(systemName: nowPlayingManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .scaleEffect(playPauseHover ? 1.2 : 1.0)
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Rectangle())
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        playPauseHover = hovering
                    }
                }
                
                Button(action: {
                    nowPlayingManager.nextTrack()
                }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .scaleEffect(nextHover ? 1.2 : 1.0)
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Rectangle())
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        nextHover = hovering
                    }
                }
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
        guard !nowPlayingManager.title.isEmpty else { return }
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
                  !nowPlayingManager.title.isEmpty else { return }
            
            hoverTask = Task {
                try? await Task.sleep(for: .seconds(0.3))
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    guard self.coordinator.notchState == .closed,
                          self.isHovering,
                          !self.coordinator.sneakPeek.show,
                          !self.nowPlayingManager.title.isEmpty else { return }
                    
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
                    
                    if self.coordinator.notchState == .open && !self.isClickedOpen {
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

