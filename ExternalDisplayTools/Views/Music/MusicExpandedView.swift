import SwiftUI

struct MusicExpandedView: View {
    @StateObject private var musicManager = MusicManager.shared
    @StateObject private var coordinator = NotchViewCoordinator.shared
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            Spacer()
            
            albumArtwork
            
            Spacer()
            
            trackInfo
            
            progressBar
            
            controls
            
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
            
            Text("Now Playing")
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
    
    private var albumArtwork: some View {
        Image(nsImage: musicManager.albumArt)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 180, height: 180)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
    
    private var trackInfo: some View {
        VStack(spacing: 8) {
            Text(musicManager.songTitle)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
            
            Text(musicManager.artistName)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(1)
        }
        .padding(.bottom, 8)
    }
    
    private var progressBar: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white)
                        .frame(width: geometry.size.width * CGFloat(min(1.0, max(0.0, musicManager.elapsedTime / max(1.0, musicManager.songDuration)))), height: 4)
                }
            }
            .frame(height: 4)
            
            HStack {
                Text(formatTime(musicManager.elapsedTime))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
                
                Spacer()
                
                Text(formatTime(musicManager.songDuration))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.bottom, 16)
    }
    
    private var controls: some View {
        HStack(spacing: 32) {
            Button(action: {
                musicManager.toggleShuffle()
            }) {
                Image(systemName: musicManager.isShuffled ? "shuffle.circle.fill" : "shuffle")
                    .font(.system(size: 20))
                    .foregroundColor(musicManager.isShuffled ? .white : .white.opacity(0.6))
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: {
                musicManager.previousTrack()
            }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: {
                musicManager.togglePlayPause()
            }) {
                Image(systemName: musicManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.white)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: {
                musicManager.nextTrack()
            }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: {
                musicManager.toggleRepeat()
            }) {
                Image(systemName: musicManager.repeatMode != .off ? "repeat.circle.fill" : "repeat")
                    .font(.system(size: 20))
                    .foregroundColor(musicManager.repeatMode != .off ? .white : .white.opacity(0.6))
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
