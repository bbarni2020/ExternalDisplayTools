import SwiftUI

struct NotchView: View {
    @StateObject private var coordinator = NotchViewCoordinator.shared
    @StateObject private var musicManager = MusicManager.shared
    @StateObject private var batteryManager = BatteryActivityManager.shared
    @StateObject private var nowPlayingManager = NowPlayingMetadataManager.shared
    @StateObject private var externalRequestManager = ExternalNotchRequestManager.shared
    @State private var isHovering = false
    @State private var previousHover = false
    @State private var playPauseHover = false
    @State private var nextHover = false
    @State private var isClickedOpen = false
    @State private var openHoverWorkItem: DispatchWorkItem?
    @State private var closeHoverWorkItem: DispatchWorkItem?
    @State private var hoverReopenLockUntil: Date = .distantPast
    @State private var contentOpacity: Double = 1.0
    @State private var contentScale: CGFloat = 1.0
    @State private var contentBlur: CGFloat = 0
    @Namespace private var nowPlayingArtworkNamespace

    private let notchMorphAnimation = Animation.spring(response: 0.36, dampingFraction: 0.94, blendDuration: 0.12)
    private let notchVisibilityAnimation = Animation.easeInOut(duration: 0.22)
    private let contentSwapAnimation = Animation.timingCurve(0.2, 0.0, 0.16, 1.0, duration: 0.2)
    private let hoverAnimation = Animation.easeOut(duration: 0.14)
    
    var body: some View {
        VStack(spacing: 0) {
            notchContent
                .background(
                    NotchShape(
                        topCornerRadius: coordinator.notchState == .open ? 18 : 5,
                        bottomCornerRadius: coordinator.notchState == .open ? 35 : 15
                    )
                    .fill(
                        LinearGradient(
                            colors: [Color.black.opacity(0.98), Color.black],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        NotchShape(
                            topCornerRadius: coordinator.notchState == .open ? 18 : 5,
                            bottomCornerRadius: coordinator.notchState == .open ? 35 : 15
                        )
                        .stroke(
                            Color.white.opacity(coordinator.notchState == .open ? 0.08 : 0.05),
                            lineWidth: 0.7
                        )
                    )
                    .shadow(
                        color: (coordinator.notchState == .open || isHovering) ? Color.black.opacity(0.62) : .clear,
                        radius: coordinator.notchState == .open ? 16 : 8,
                        y: coordinator.notchState == .open ? 8 : 4
                    )
                )
                .clipShape(NotchShape(
                    topCornerRadius: coordinator.notchState == .open ? 18 : 5,
                    bottomCornerRadius: coordinator.notchState == .open ? 35 : 15
                ))
                .frame(
                    width: targetNotchSize.width,
                    height: targetNotchSize.height,
                    alignment: .top
                )
                .fixedSize()
                .scaleEffect(coordinator.shouldHideNotch ? 0.62 : 1.0, anchor: .top)
                .offset(y: coordinator.shouldHideNotch ? -36 : 0)
                .opacity(coordinator.shouldHideNotch ? 0 : 1)
                .animation(notchVisibilityAnimation, value: coordinator.shouldHideNotch)
                .animation(notchMorphAnimation, value: targetNotchSize)
                .onHover { hovering in
                    if !coordinator.shouldHideNotch {
                        handleHover(hovering)
                    } else {
                        isHovering = false
                    }
                }
                .onTapGesture {
                    if coordinator.notchState == .closed && !coordinator.shouldHideNotch {
                        closeHoverWorkItem?.cancel()
                        isClickedOpen = true
                        doOpen()
                    } else if coordinator.notchState == .open && isClickedOpen && !coordinator.shouldHideNotch {
                        openHoverWorkItem?.cancel()
                        isClickedOpen = false
                        withAnimation(notchMorphAnimation) {
                            coordinator.closeNotch()
                        }
                    }
                }
                .contextMenu {
                    SettingsLink {
                        Text("Settings")
                    }

                    Divider()

                    Button("Quit") {
                        NSApplication.shared.terminate(nil)
                    }
                }
        }
        .onChange(of: coordinator.notchState) { _ in
            animateContentTransition()
        }
        .onChange(of: coordinator.currentView) { _ in
            animateContentTransition()
        }
        .onChange(of: externalRequestManager.activeRequest) { _ in
            animateContentTransition()
        }
        .allowsHitTesting(true)
    }
    
    private var notchContent: some View {
        ZStack(alignment: .top) {
            if coordinator.notchState == .closed {
                closedNotchView
                    .frame(height: coordinator.notchSize.height)
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.985, anchor: .top)),
                            removal: .opacity
                        )
                    )
            } else {
                expandedNotchView
                    .padding(.top, coordinator.notchSize.height + 8)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)
                    .allowsHitTesting(true)
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.985, anchor: .top)),
                            removal: .opacity
                        )
                    )
            }
        }
        .opacity(contentOpacity)
        .scaleEffect(contentScale, anchor: .top)
        .blur(radius: contentBlur)
        .animation(contentSwapAnimation, value: coordinator.notchState)
    }
    
    private var closedNotchView: some View {
        Group {
            if !nowPlayingManager.title.isEmpty {
                HStack(spacing: 0) {
                    nowPlayingArtwork(size: 18, cornerRadius: 5, iconSize: 10)
                    .padding(.leading, 12)
                    .offset(y: -1)
                    
                    Spacer()
                    
                    MusicBarsAnimation(isPlaying: nowPlayingManager.isPlaying)
                        .frame(height: 12)
                        .padding(.trailing, 12)
                        .transition(.opacity)
                }
                .frame(height: coordinator.notchSize.height)
                .frame(maxHeight: .infinity, alignment: .center)
                .transition(.opacity)
            } else {
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: coordinator.notchSize.height)
                    .transition(.opacity)
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
            nowPlayingArtwork(size: 48, cornerRadius: 6, iconSize: 20)
            
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
                 
                        .scaleEffect(previousHover ? 1.08 : 1.0)
                        .opacity(previousHover ? 1 : 0.9)
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Rectangle())
                .onHover { hovering in
                    withAnimation(hoverAnimation) {
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
                        .contentTransition(.symbolEffect(.replace))
                        .scaleEffect(playPauseHover ? 1.08 : 1.0)
                        .scaleEffect(nowPlayingManager.isPlaying ? 1.01 : 0.99)
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Rectangle())
                .onHover { hovering in
                    withAnimation(hoverAnimation) {
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
                        .scaleEffect(nextHover ? 1.08 : 1.0)
                        .opacity(nextHover ? 1 : 0.9)
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Rectangle())
                .onHover { hovering in
                    withAnimation(hoverAnimation) {
                        nextHover = hovering
                    }
                }
            }
        }
    }

    private func nowPlayingArtwork(size: CGFloat, cornerRadius: CGFloat, iconSize: CGFloat) -> some View {
        ZStack {
            if let artwork = nowPlayingManager.artworkImage {
                Image(nsImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: iconSize))
                            .foregroundColor(.gray)
                    )
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .matchedGeometryEffect(id: "nowPlayingArtwork", in: nowPlayingArtworkNamespace)
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
        withAnimation(notchMorphAnimation) {
            coordinator.openNotch()
        }
    }

    private func handleHover(_ hovering: Bool) {
        openHoverWorkItem?.cancel()
        closeHoverWorkItem?.cancel()

        if hovering {
            isHovering = true

            guard Date() >= hoverReopenLockUntil else { return }

            let workItem = DispatchWorkItem {
                guard isHovering,
                      !isClickedOpen,
                      coordinator.notchState == .closed,
                      !coordinator.sneakPeek.show,
                      !nowPlayingManager.title.isEmpty else { return }

                doOpen()
            }

            openHoverWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: workItem)
            return
        }

        isHovering = false

        let workItem = DispatchWorkItem {
            guard !isHovering,
                  !isClickedOpen,
                  coordinator.notchState == .open else { return }

            hoverReopenLockUntil = Date().addingTimeInterval(0.28)
            withAnimation(notchMorphAnimation) {
                coordinator.closeNotch()
            }
        }

        closeHoverWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42, execute: workItem)
    }

    private var targetNotchSize: CGSize {
        if coordinator.notchState == .open {
            let width = coordinator.currentView == .lowBattery ? 300 : coordinator.expandedNotchSize.width
            let height = coordinator.currentView == .lowBattery ? 32 : coordinator.expandedNotchSize.height + 1
            return CGSize(width: width, height: height)
        }

        let width = nowPlayingManager.title.isEmpty ? coordinator.notchSize.width : 270
        return CGSize(width: width, height: coordinator.notchSize.height)
    }

    private func animateContentTransition() {
        DispatchQueue.main.async {
            contentOpacity = 0.0
            contentScale = 0.992
            contentBlur = 2

            withAnimation(contentSwapAnimation.delay(0.02)) {
                contentOpacity = 1.0
                contentScale = 1.0
                contentBlur = 0
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

