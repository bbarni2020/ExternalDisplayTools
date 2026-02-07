import AppKit
import Combine
import SwiftUI

class MusicManager: ObservableObject {
    static let shared = MusicManager()
    
    private var cancellables = Set<AnyCancellable>()
    private var controllerCancellables = Set<AnyCancellable>()
    private var debounceIdleTask: Task<Void, Never>?

    private var activeController: (any MediaControllerProtocol)?

    @Published var songTitle: String = ""
    @Published var artistName: String = ""
    @Published var albumArt: NSImage = NSImage(systemSymbolName: "music.note", accessibilityDescription: "Music")!
    @Published var isPlaying = false
    @Published var album: String = ""
    @Published var isPlayerIdle: Bool = true
    @Published var bundleIdentifier: String? = nil
    @Published var songDuration: TimeInterval = 0
    @Published var elapsedTime: TimeInterval = 0
    @Published var timestampDate: Date = .init()
    @Published var playbackRate: Double = 1
    @Published var isShuffled: Bool = false
    @Published var repeatMode: NotchRepeatMode = .off
    @Published var volume: Double = 0.5
    @Published var volumeControlSupported: Bool = true
    @Published var isFavoriteTrack: Bool = false
    @Published var canFavoriteTrack: Bool = false
    
    private var artworkData: Data? = nil
    
    init() {
        setupController()
    }
    
    deinit {
        debounceIdleTask?.cancel()
        cancellables.removeAll()
        controllerCancellables.removeAll()
        activeController = nil
    }
    
    private func setupController() {
        detectActivePlayer()
    }
    
    private func detectActivePlayer() {
        if NSWorkspace.shared.runningApplications.contains(where: { $0.bundleIdentifier == "com.spotify.client" }) {
            setActiveController(type: MediaControllerType.spotify)
        } else {
            setActiveController(type: MediaControllerType.appleMusic)
        }
    }
    
    private func createController(for type: MediaControllerType) -> (any MediaControllerProtocol)? {
        controllerCancellables.removeAll()
        
        let newController: (any MediaControllerProtocol)?
        
        switch type {
        case .nowPlaying:
            return nil
        case .appleMusic:
            newController = AppleMusicController()
        case .spotify:
            newController = SpotifyController()
        }
        
        if let controller = newController {
            controller.playbackStatePublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] state in
                    guard let self = self else { return }
                    self.updateFromPlaybackState(state)
                }
                .store(in: &controllerCancellables)
        }
        
        return newController
    }

    private func setActiveController(type: MediaControllerType) {
        guard let controller = createController(for: type) else { return }
        activeController = controller
        canFavoriteTrack = controller.supportsFavorite
        volumeControlSupported = controller.supportsVolumeControl
        forceUpdate()
    }

    func switchController(to type: MediaControllerType) {
        setActiveController(type: type)
    }

    @MainActor
    private func updateFromPlaybackState(_ state: PlaybackState) {
        if state.isPlaying != isPlaying {
            withAnimation(.smooth) {
                isPlaying = state.isPlaying
                updateIdleState(isPlaying: state.isPlaying)
            }
        }

        let artworkChanged = state.artwork != nil && state.artwork != artworkData
        
        if artworkChanged, let artworkData = state.artwork, let image = NSImage(data: artworkData) {
            albumArt = image
        }
        
        artworkData = state.artwork
        songTitle = state.title
        artistName = state.artist
        album = state.album
        elapsedTime = state.currentTime
        songDuration = state.duration
        playbackRate = state.playbackRate
        isShuffled = state.isShuffled
        bundleIdentifier = state.bundleIdentifier
        repeatMode = state.repeatMode
        isFavoriteTrack = state.isFavorite
        volume = state.volume
        timestampDate = state.lastUpdated
    }

    private func updateIdleState(isPlaying: Bool) {
        if isPlaying {
            isPlayerIdle = false
            debounceIdleTask?.cancel()
        } else {
            debounceIdleTask?.cancel()
            debounceIdleTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(5))
                withAnimation {
                    self?.isPlayerIdle = !(self?.isPlaying ?? false)
                }
            }
        }
    }

    func forceUpdate() {
        Task {
            await activeController?.updatePlaybackInfo()
        }
    }

    func togglePlayPause() {
        Task {
            await activeController?.togglePlay()
        }
    }

    func nextTrack() {
        Task {
            await activeController?.nextTrack()
        }
    }

    func previousTrack() {
        Task {
            await activeController?.previousTrack()
        }
    }

    func seek(to time: Double) {
        Task {
            await activeController?.seek(to: time)
        }
    }

    func toggleShuffle() {
        Task {
            await activeController?.toggleShuffle()
        }
    }

    func toggleRepeat() {
        Task {
            await activeController?.toggleRepeat()
        }
    }

    func setVolume(_ level: Double) {
        Task {
            await activeController?.setVolume(level)
        }
    }

    func toggleFavorite() {
        guard canFavoriteTrack else { return }
        Task {
            await activeController?.setFavorite(!isFavoriteTrack)
        }
    }
}
