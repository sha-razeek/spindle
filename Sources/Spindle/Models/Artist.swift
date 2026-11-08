import Foundation

public struct Artist: Identifiable, Hashable, Sendable {
    public var id: String { name }
    public let name: String
    public let albums: [Album]
    public let songs: [Song]

    public var songCount: Int {
        songs.count
    }

    public var albumCount: Int {
        albums.count
    }

    public var representativeSong: Song? {
        songs.first(where: { $0.hasArtwork }) ?? songs.first
    }

    public init(name: String, albums: [Album], songs: [Song]) {
        self.name = name
        self.albums = albums.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        self.songs = songs.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }
}
