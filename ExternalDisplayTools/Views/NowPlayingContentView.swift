import SwiftUI

struct NowPlayingContentView: View {
    @StateObject private var nowPlayingManager = NowPlayingMetadataManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            if !nowPlayingManager.isAvailable {
                unavailableView
            } else if nowPlayingManager.title.isEmpty {
                emptyStateView
            } else {
                nowPlayingView
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var unavailableView: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 32))
                .foregroundColor(.orange)
            
            Text("Media Access Unavailable")
                .font(.caption)
            
            Text(nowPlayingManager.error ?? "Unable to access system now playing info")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note")
                .font(.system(size: 32))
                .foregroundColor(.gray)
            
            Text("No Media Playing")
                .font(.caption)
            
            Text("Play something to see details here")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private var nowPlayingView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                if let artwork = nowPlayingManager.artworkImage {
                    Image(nsImage: artwork)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .cornerRadius(6)
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 24))
                                .foregroundColor(.gray)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(nowPlayingManager.title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    Text(nowPlayingManager.artist)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Text(nowPlayingManager.bundleId)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
            }
            
            if nowPlayingManager.duration > 0 {
                VStack(spacing: 6) {
                    ProgressView(value: nowPlayingManager.elapsedTime / nowPlayingManager.duration)
                        .tint(.accentColor)
                    
                    HStack {
                        Text(formatTime(nowPlayingManager.elapsedTime))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(formatTime(nowPlayingManager.duration))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            HStack(spacing: 12) {
                Button(action: { nowPlayingManager.previousTrack() }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                
                Button(action: { nowPlayingManager.togglePlayPause() }) {
                    Image(systemName: nowPlayingManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 22))
                }
                .buttonStyle(.plain)
                
                Button(action: { nowPlayingManager.nextTrack() }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    NowPlayingContentView()
}
