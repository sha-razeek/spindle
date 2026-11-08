import Foundation
import iTunesLibrary

public struct Playlist: Identifiable, Hashable, Sendable {
    public let id: String
    public let persistentID: UInt64
    public let name: String
    public let isFolder: Bool
    public let isMaster: Bool
    public let songs: [Song]

    public var songCount: Int {
        songs.count
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

    public init(from playlist: ITLibPlaylist, songLookup: [UInt64: Song]) {
        let pid = playlist.persistentID.uint64Value
        self.persistentID = pid
        self.id = String(pid)
        self.name = playlist.name
        self.isFolder = false
        self.isMaster = playlist.isMaster
        
        var resolvedSongs: [Song] = []
        for item in playlist.items {
            if let song = songLookup[item.persistentID.uint64Value] {
                resolvedSongs.append(song)
            }
        }
        self.songs = resolvedSongs
    }
}
