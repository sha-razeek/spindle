import Foundation
import AVFoundation
import MediaPlayer
import AppKit
import Combine

public enum RepeatMode: String, CaseIterable, Identifiable {
    case off = "Off"
    case all = "Repeat All"
    case one = "Repeat One"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .off: return "repeat"
        case .all: return "repeat"
        case .one: return "repeat.1"
        }
    }
}

@MainActor
public final class AudioPlayer: ObservableObject {
    public static let shared = AudioPlayer()

    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var endObserverToken: Any?

    @Published public private(set) var currentSong: Song?
    @Published public private(set) var isPlaying: Bool = false
    @Published public var currentTime: TimeInterval = 0
    @Published public var duration: TimeInterval = 0
    @Published public var volume: Float = 1.0 {
        didSet {
            player?.volume = isMuted ? 0 : volume
        }
    }
    @Published public var isMuted: Bool = false {
        didSet {
            player?.volume = isMuted ? 0 : volume
        }
    }

    @Published public var isShuffleEnabled: Bool = false {
        didSet {
            if isShuffleEnabled {
                shuffleQueue()
            } else {
                restoreOriginalQueue()
            }
        }
    }

    @Published public var repeatMode: RepeatMode = .off
    @Published public private(set) var queue: [Song] = []
    @Published public private(set) var queueIndex: Int = 0

    private var originalQueue: [Song] = []

    public var hasNext: Bool {
        if repeatMode == .all || repeatMode == .one { return !queue.isEmpty }
        return queueIndex + 1 < queue.count
    }

    public var hasPrevious: Bool {
        if currentTime > 3.0 { return true }
        if repeatMode == .all || repeatMode == .one { return !queue.isEmpty }
        return queueIndex > 0
    }

    public var formattedCurrentTime: String {
        formatTime(currentTime)
    }

    public var formattedRemainingTime: String {
        let remaining = max(0, duration - currentTime)
        return "-" + formatTime(remaining)
    }

    private init() {
        setupRemoteCommands()
    }

    deinit {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
        }
        if let token = endObserverToken {
            NotificationCenter.default.removeObserver(token)
        }
    }

    // MARK: - Playback Controls

    public func play(song: Song, inContext contextSongs: [Song]? = nil) {
        guard let location = song.location else {
            print("Cannot play song without location: \(song.title)")
            return
        }

        if let context = contextSongs, !context.isEmpty {
            originalQueue = context
            if isShuffleEnabled {
                var shuffled = context.filter { $0.id != song.id }
                shuffled.shuffle()
                queue = [song] + shuffled
                queueIndex = 0
            } else {
                queue = context
                queueIndex = queue.firstIndex(of: song) ?? 0
            }
        } else if queue.isEmpty || !queue.contains(song) {
            queue = [song]
            originalQueue = [song]
            queueIndex = 0
        } else {
            queueIndex = queue.firstIndex(of: song) ?? 0
        }

        startPlayback(song: song, url: location)
    }

    private func startPlayback(song: Song, url: URL) {
        cleanUpCurrentPlayer()

        currentSong = song
        duration = song.duration

        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.volume = isMuted ? 0 : volume

        // Observe progress
        let interval = CMTime(seconds: 0.25, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.currentTime = time.seconds
                self.updateNowPlayingProgress()
            }
        }

        // Observe song end
        endObserverToken = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleTrackEnded()
            }
        }

        player?.play()
        isPlaying = true

        updateNowPlayingInfo(song: song)
    }

    public func togglePlayPause() {
        guard let player = player else {
            if let song = queue.first {
                play(song: song)
            }
            return
        }

        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
        updateNowPlayingPlaybackRate()
    }

    public func nextTrack() {
        if repeatMode == .one, let song = currentSong, let loc = song.location {
            startPlayback(song: song, url: loc)
            return
        }

        guard !queue.isEmpty else { return }

        if queueIndex + 1 < queue.count {
            queueIndex += 1
            let nextSong = queue[queueIndex]
            if let loc = nextSong.location {
                startPlayback(song: nextSong, url: loc)
            }
        } else if repeatMode == .all {
            queueIndex = 0
            let nextSong = queue[0]
            if let loc = nextSong.location {
                startPlayback(song: nextSong, url: loc)
            }
        } else {
            // End of queue
            player?.pause()
            isPlaying = false
            currentTime = 0
        }
    }

    public func previousTrack() {
        if currentTime > 3.0 {
            seek(to: 0)
            return
        }

        guard !queue.isEmpty else { return }

        if queueIndex > 0 {
            queueIndex -= 1
            let prevSong = queue[queueIndex]
            if let loc = prevSong.location {
                startPlayback(song: prevSong, url: loc)
            }
        } else if repeatMode == .all {
            queueIndex = queue.count - 1
            let prevSong = queue[queueIndex]
            if let loc = prevSong.location {
                startPlayback(song: prevSong, url: loc)
            }
        } else {
            seek(to: 0)
        }
    }

    public func seek(to time: TimeInterval) {
        currentTime = time
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
        updateNowPlayingProgress()
    }

    public func addToQueue(song: Song) {
        queue.append(song)
        originalQueue.append(song)
    }

    public func playNext(song: Song) {
        if queue.isEmpty {
            play(song: song)
        } else {
            let insertIndex = min(queueIndex + 1, queue.count)
            queue.insert(song, at: insertIndex)
            originalQueue.insert(song, at: insertIndex)
        }
    }

    public func cycleRepeatMode() {
        switch repeatMode {
        case .off: repeatMode = .all
        case .all: repeatMode = .one
        case .one: repeatMode = .off
        }
    }

    private func handleTrackEnded() {
        if repeatMode == .one {
            seek(to: 0)
            player?.play()
            isPlaying = true
        } else {
            nextTrack()
        }
    }

    private func shuffleQueue() {
        guard !queue.isEmpty else { return }
        guard let current = currentSong else { return }
        var remainder = queue.filter { $0.id != current.id }
        remainder.shuffle()
        queue = [current] + remainder
        queueIndex = 0
    }

    private func restoreOriginalQueue() {
        guard !originalQueue.isEmpty else { return }
        queue = originalQueue
        if let current = currentSong {
            queueIndex = queue.firstIndex(of: current) ?? 0
        }
    }

    private func cleanUpCurrentPlayer() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        if let token = endObserverToken {
            NotificationCenter.default.removeObserver(token)
            endObserverToken = nil
        }
        player?.pause()
        player = nil
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }

    // MARK: - Now Playing & Remote Commands

    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if !self.isPlaying {
                    self.togglePlayPause()
                }
            }
            return .success
        }

        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if self.isPlaying {
                    self.togglePlayPause()
                }
            }
            return .success
        }

        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.togglePlayPause()
            }
            return .success
        }

        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.nextTrack()
            }
            return .success
        }

        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.previousTrack()
            }
            return .success
        }

        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            Task { @MainActor [weak self] in
                self?.seek(to: event.positionTime)
            }
            return .success
        }
    }

    private func updateNowPlayingInfo(song: Song) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: song.title,
            MPMediaItemPropertyArtist: song.artistName,
            MPMediaItemPropertyAlbumTitle: song.albumTitle,
            MPMediaItemPropertyPlaybackDuration: song.duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info

        // Asynchronously load and attach artwork
        Task {
            if let image = await ArtworkLoader.shared.loadArtwork(for: song) {
                let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                info[MPMediaItemPropertyArtwork] = artwork
                MPNowPlayingInfoCenter.default().nowPlayingInfo = info
            }
        }
    }

    private func updateNowPlayingProgress() {
        guard var info = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func updateNowPlayingPlaybackRate() {
        guard var info = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}
