import AppKit
import Foundation

enum ExternalNotchLeftContent: Equatable {
    case appBundleId(String)
}

enum ExternalNotchRightContent: Equatable {
    case text(String)
    case icon(String)
    case image(URL)
    case gif(URL)
}

enum ExternalNotchMainContent: Equatable {
    case text(String)
    case image(URL)
    case gif(URL)
}

struct ExternalNotchRequest: Equatable {
    let duration: TimeInterval
    let left: ExternalNotchLeftContent?
    let right: ExternalNotchRightContent?
    let content: ExternalNotchMainContent
}

struct ExternalNotchRequestParser {
    static let maxDuration: TimeInterval = 60

    static func parse(url: URL) -> ExternalNotchRequest? {
        guard url.scheme == "notch" else { return nil }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        let queryItems = components.queryItems ?? []

        let durationValue = value(for: "duration", in: queryItems)
        guard let durationString = durationValue, let durationInt = Int(durationString) else { return nil }
        let clampedDuration = min(maxDuration, max(1, TimeInterval(durationInt)))

        guard let contentRaw = value(for: "content", in: queryItems) else { return nil }
        guard let content = parseMainContent(from: contentRaw) else { return nil }

        let leftRaw = value(for: "left", in: queryItems)
        let rightRaw = value(for: "right", in: queryItems)

        let left = parseLeftContent(from: leftRaw)
        if leftRaw != nil && left == nil {
            return nil
        }

        let right = parseRightContent(from: rightRaw)
        if rightRaw != nil && right == nil {
            return nil
        }

        return ExternalNotchRequest(duration: clampedDuration, left: left, right: right, content: content)
    }

    private static func value(for key: String, in items: [URLQueryItem]) -> String? {
        items.first { $0.name == key }?.value
    }

    private static func parseLeftContent(from raw: String?) -> ExternalNotchLeftContent? {
        guard let raw = raw, !raw.isEmpty else { return nil }
        guard let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: raw) else { return nil }
        guard FileManager.default.fileExists(atPath: appUrl.path) else { return nil }
        return .appBundleId(raw)
    }

    private static func parseRightContent(from raw: String?) -> ExternalNotchRightContent? {
        guard let raw = raw, !raw.isEmpty else { return nil }
        let parts = raw.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return nil }
        let type = parts[0].lowercased()
        let value = parts[1]
        guard !value.isEmpty else { return nil }

        switch type {
        case "text":
            return .text(value)
        case "icon":
            return .icon(value)
        case "image":
            guard let url = URL(string: value) else { return nil }
            return .image(url)
        case "gif":
            guard let url = URL(string: value) else { return nil }
            return .gif(url)
        default:
            return nil
        }
    }

    private static func parseMainContent(from raw: String) -> ExternalNotchMainContent? {
        let parts = raw.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return nil }
        let type = parts[0].lowercased()
        let value = parts[1]
        guard !value.isEmpty else { return nil }

        switch type {
        case "text":
            return .text(value)
        case "image":
            guard let url = URL(string: value) else { return nil }
            return .image(url)
        case "gif":
            guard let url = URL(string: value) else { return nil }
            return .gif(url)
        default:
            return nil
        }
    }
}
