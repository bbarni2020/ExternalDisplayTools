import Foundation
import SwiftUI

struct SneakPeek {
    var show: Bool = false
    var type: SneakContentType = .music
    var value: CGFloat = 0
    var icon: String = ""
}

struct BatteryInfo {
    var isPluggedIn: Bool
    var isCharging: Bool
    var currentCapacity: Float
    var maxCapacity: Float
    var isInLowPowerMode: Bool
    var timeToFullCharge: Int
}

struct PlaybackState: Equatable {
    var bundleIdentifier: String = ""
    var isPlaying: Bool = false
    var title: String = ""
    var artist: String = ""
    var album: String = ""
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    var playbackRate: Double = 1.0
    var isShuffled: Bool = false
    var repeatMode: NotchRepeatMode = .off
    var lastUpdated: Date = .distantPast
    var artwork: Data?
    var volume: Double = 0.5
    var isFavorite: Bool = false
}

enum NotchRepeatMode: Int, Equatable {
    case off = 1
    case one = 2
    case all = 3
}

struct NotchSize {
    var width: CGFloat
    var height: CGFloat
}
