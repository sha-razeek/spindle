import Foundation

public struct Album: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let artistName: String
    public let year: Int
    public let songs: [Song]

    public var trackCount: Int {
        songs.count
    }

    public var representativeSong: Song? {
        songs.first(where: { $0.hasArtwork }) ?? songs.first
    }

    public var totalDuration: TimeInterval {
        songs.reduce(0) { $0 + $1.duration }
    }

    public var formattedDuration: String {
        let totalMinutes = Int(totalDuration) / 60
        if totalMinutes >= 60 {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            return "\(hours) hr \(minutes) min"
        } else {
            return "\(totalMinutes) min"
        }
    }

    public init(title: String, artistName: String, songs: [Song]) {
        self.title = title
        self.artistName = artistName
        // Sort songs by disc number, then track number, then title
        self.songs = songs.sorted {
            if $0.discNumber != $1.discNumber {
                return $0.discNumber < $1.discNumber
            }
            if $0.trackNumber != $1.trackNumber {
                return $0.trackNumber < $1.trackNumber
            }
            return $0.title < $1.title
        }
        self.year = songs.first(where: { $0.year > 0 })?.year ?? 0
        self.id = "\(artistName) - \(title)"
    }
}
