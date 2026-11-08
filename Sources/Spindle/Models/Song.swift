import Foundation
import iTunesLibrary

public struct Song: Identifiable, Hashable, Sendable {
    public let id: String
    public let persistentID: UInt64
    public let title: String
    public let artistName: String
    public let albumTitle: String
    public let albumArtistName: String
    public let genre: String
    public let trackNumber: Int
    public let discNumber: Int
    public let duration: TimeInterval
    public let year: Int
    public let location: URL?
    public let isCloud: Bool
    public let isDRMProtected: Bool
    public let hasArtwork: Bool
    public let playCount: Int
    public let rating: Int
    public let dateAdded: Date?

    public var isPlayableLocally: Bool {
        return location != nil && !isDRMProtected
    }

    public var formattedDuration: String {
        let totalSeconds = Int(duration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    public init(from item: ITLibMediaItem) {
        let pid = item.persistentID.uint64Value
        self.persistentID = pid
        self.id = String(pid)
        self.title = item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Unknown Title" : item.title
        self.artistName = item.artist?.name ?? "Unknown Artist"
        self.albumTitle = item.album.title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? (item.album.title ?? "Unknown Album") : "Unknown Album"
        self.albumArtistName = item.album.albumArtist?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? (item.album.albumArtist ?? item.artist?.name ?? "Unknown Artist") : (item.artist?.name ?? "Unknown Artist")
        self.genre = item.genre
        self.trackNumber = item.trackNumber
        self.discNumber = item.album.discNumber
        self.duration = TimeInterval(item.totalTime) / 1000.0
        self.year = item.year
        self.location = item.location
        self.isCloud = item.isCloud
        self.isDRMProtected = item.isDRMProtected
        self.hasArtwork = item.hasArtworkAvailable
        self.playCount = item.playCount
        self.rating = item.rating
        self.dateAdded = item.addedDate
    }

    // Hashable & Equatable conformance based on ID
    public func hash(into hasher: inout Hasher) {
        hasher.combine(persistentID)
    }

    public static func == (lhs: Song, rhs: Song) -> Bool {
        lhs.persistentID == rhs.persistentID
    }
}
