import Foundation

enum NotchState {
    case closed
    case open
}

enum NotchViews: String, CaseIterable, Equatable {
    case home
    case music
    case battery
    case call
    case lowBattery
}

enum SneakContentType: Equatable {
    case brightness
    case volume
    case backlight
    case music
    case mic
    case battery
    case download
    case bluetooth
    case unlock
}

enum MediaControllerType: String, CaseIterable {
    case nowPlaying = "System (Now Playing)"
    case appleMusic = "Apple Music"
    case spotify = "Spotify"
}

enum RepeatMode: Int, Codable {
    case off = 1
    case one = 2
    case all = 3
}
