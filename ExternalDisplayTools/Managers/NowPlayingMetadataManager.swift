import AppKit
import Combine
import Foundation

@MainActor
final class NowPlayingMetadataManager: ObservableObject {
    static let shared = NowPlayingMetadataManager()
    
    @Published var title: String = ""
    @Published var artist: String = ""
    @Published var album: String = ""
    @Published var bundleId: String = ""
    @Published var artworkImage: NSImage?
    @Published var isPlaying: Bool = false
    @Published var duration: TimeInterval = 0
    @Published var elapsedTime: TimeInterval = 0
    @Published var isAvailable: Bool = false
    @Published var error: String?
    
    private var process: Process?
    private var pipeHandler: JSONLinesPipeHandler?
    private var streamTask: Task<Void, Never>?
    private var healthCheckTimer: Timer?
    private var pauseStartTime: Date?
    
    private let pauseThresholdSeconds: TimeInterval = 30
    
    private let mediaRemoteBundle: CFBundle?
    private var MRMediaRemoteSendCommandFunction: (@convention(c) (Int, AnyObject?) -> Void)?
    
    private init() {
        mediaRemoteBundle = CFBundleCreate(
            kCFAllocatorDefault,
            NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework"))
        
        if let bundle = mediaRemoteBundle,
           let ptr = CFBundleGetFunctionPointerForName(
            bundle, "MRMediaRemoteSendCommand" as CFString) {
            MRMediaRemoteSendCommandFunction = unsafeBitCast(
                ptr, to: (@convention(c) (Int, AnyObject?) -> Void).self)
        }
        
        Task { await setupNowPlayingObserver() }
    }
    
    deinit {
        streamTask?.cancel()
        healthCheckTimer?.invalidate()
        
        if let pipeHandler = self.pipeHandler {
            Task { await pipeHandler.close() }
        }
        
        if let process = self.process {
            if process.isRunning {
                process.terminate()
                process.waitUntilExit()
            }
        }
        
        self.process = nil
        self.pipeHandler = nil
    }
    
    func togglePlayPause() {
        MRMediaRemoteSendCommandFunction?(2, nil)
    }
    
    func play() {
        MRMediaRemoteSendCommandFunction?(0, nil)
    }
    
    func pause() {
        MRMediaRemoteSendCommandFunction?(1, nil)
    }
    
    func nextTrack() {
        MRMediaRemoteSendCommandFunction?(4, nil)
    }
    
    func previousTrack() {
        MRMediaRemoteSendCommandFunction?(5, nil)
    }
    
    private func setupNowPlayingObserver() async {
        let process = Process()
        guard
            let scriptURL = Bundle.main.url(forResource: "mediaremote-adapter", withExtension: "pl")
        else {
            await MainActor.run {
                self.error = "mediaremote-adapter.pl not found in bundle"
                self.isAvailable = false
            }
            return
        }
        
        let frameworkPath = Bundle.main.bundlePath.appending("/Contents/Frameworks/MediaRemoteAdapter.framework")
        
        process.executableURL = URL(fileURLWithPath: "/usr/bin/perl")
        process.arguments = [scriptURL.path, frameworkPath, "stream", "--debounce=100"]
        
        let pipeHandler = JSONLinesPipeHandler()
        process.standardOutput = await pipeHandler.getPipe()
        process.standardError = FileHandle.standardError
        
        self.process = process
        self.pipeHandler = pipeHandler
        
        do {
            try process.run()
            await MainActor.run {
                self.isAvailable = true
            }
            streamTask = Task { [weak self] in
                await self?.processJSONStream()
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to launch adapter: \(error.localizedDescription)"
                self.isAvailable = false
            }
        }
    }
    
    private func processJSONStream() async {
        guard let pipeHandler = self.pipeHandler else { return }
        
        await pipeHandler.readJSONLines(as: NowPlayingUpdate.self) { [weak self] update in
            await self?.handleUpdate(update)
        }
    }
    
    private func handleUpdate(_ update: NowPlayingUpdate) async {
        let payload = update.payload
        
        await MainActor.run {
            if let title = payload.title, !title.isEmpty {
                self.title = title
            }
            
            if let artist = payload.artist, !artist.isEmpty {
                self.artist = artist
            }
            
            if let album = payload.album, !album.isEmpty {
                self.album = album
            }
            
            if let duration = payload.duration {
                self.duration = duration
            }
            
            if let elapsedTime = payload.elapsedTime {
                self.elapsedTime = elapsedTime
            }
            
            if let playing = payload.playing {
                self.isPlaying = playing
                
                if !playing {
                    if self.pauseStartTime == nil {
                        self.pauseStartTime = Date()
                    }
                    self.startHealthCheck()
                } else {
                    self.pauseStartTime = nil
                    self.stopHealthCheck()
                }
            }
            
            let bundleId = payload.parentApplicationBundleIdentifier ?? payload.bundleIdentifier ?? ""
            if !bundleId.isEmpty {
                self.bundleId = bundleId
            }
            
            if let artworkDataString = payload.artworkData,
               let artworkData = Data(base64Encoded: artworkDataString.trimmingCharacters(in: .whitespacesAndNewlines)) {
                self.artworkImage = NSImage(data: artworkData)
            }
            
            self.error = nil
        }
    }
    
    private func startHealthCheck() {
        stopHealthCheck()
        
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkMediaPlayerHealth()
        }
    }
    
    private func stopHealthCheck() {
        healthCheckTimer?.invalidate()
        healthCheckTimer = nil
    }
    
    private func checkMediaPlayerHealth() {
        let isNotchAppActive = NSWorkspace.shared.frontmostApplication?.bundleIdentifier == "dev.masterbros.ExternalDisplayTools"
        
        if let pauseStart = pauseStartTime, Date().timeIntervalSince(pauseStart) >= pauseThresholdSeconds {
            if !isNotchAppActive {
                clearMediaInfo()
            }
            return
        }
        
        guard !bundleId.isEmpty else { return }
        
        let isRunning = NSWorkspace.shared.runningApplications.contains { app in
            app.bundleIdentifier == bundleId
        }
        
        if !isRunning {
            clearMediaInfo()
        }
    }
    
    private func clearMediaInfo() {
        pauseStartTime = nil
        title = ""
        artist = ""
        album = ""
        bundleId = ""
        artworkImage = nil
        duration = 0
        elapsedTime = 0
        isPlaying = false
        stopHealthCheck()
    }
}

struct NowPlayingUpdate: Codable {
    let payload: NowPlayingPayload
    let diff: Bool?
}

struct NowPlayingPayload: Codable {
    let title: String?
    let artist: String?
    let album: String?
    let duration: Double?
    let elapsedTime: Double?
    let artworkData: String?
    let playing: Bool?
    let parentApplicationBundleIdentifier: String?
    let bundleIdentifier: String?
}

actor JSONLinesPipeHandler {
    private let pipe: Pipe
    private let fileHandle: FileHandle
    private var buffer = ""
    
    init() {
        self.pipe = Pipe()
        self.fileHandle = pipe.fileHandleForReading
    }
    
    func getPipe() -> Pipe {
        return pipe
    }
    
    func readJSONLines<T: Decodable>(as type: T.Type, onLine: @escaping (T) async -> Void) async {
        do {
            try await self.processLines(as: type) { decodedObject in
                await onLine(decodedObject)
            }
        } catch {
            // Silent error handling
        }
    }
    
    private func processLines<T: Decodable>(as type: T.Type, onLine: @escaping (T) async -> Void) async throws {
        while true {
            let data = try await readData()
            guard !data.isEmpty else { break }
            
            if let chunk = String(data: data, encoding: .utf8) {
                buffer.append(chunk)
                
                while let range = buffer.range(of: "\n") {
                    let line = String(buffer[..<range.lowerBound])
                    buffer = String(buffer[range.upperBound...])
                    
                    if !line.isEmpty {
                        await processJSONLine(line, as: type, onLine: onLine)
                    }
                }
            }
        }
    }
    
    private func processJSONLine<T: Decodable>(_ line: String, as type: T.Type, onLine: @escaping (T) async -> Void) async {
        guard let data = line.data(using: .utf8) else { return }
        do {
            let decodedObject = try JSONDecoder().decode(T.self, from: data)
            await onLine(decodedObject)
        } catch {
            // Silently ignore lines that can't be decoded
        }
    }
    
    private func readData() async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            fileHandle.readabilityHandler = { handle in
                let data = handle.availableData
                handle.readabilityHandler = nil
                continuation.resume(returning: data)
            }
        }
    }
    
    func close() async {
        do {
            fileHandle.readabilityHandler = nil
            try fileHandle.close()
            try pipe.fileHandleForWriting.close()
        } catch {
            // Silent error handling
        }
    }
}
