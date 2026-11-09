import Foundation
import iTunesLibrary
import Combine

@MainActor
public final class LibraryManager: ObservableObject {
    @Published public private(set) var rawLibrary: ITLibrary?
    @Published public private(set) var songs: [Song] = []
    @Published public private(set) var albums: [Album] = []
    @Published public private(set) var artists: [Artist] = []
    @Published public private(set) var playlists: [Playlist] = []
    @Published public private(set) var recentlyAddedAlbums: [Album] = []
    @Published public private(set) var recentlyAddedSongs: [Song] = []

    @Published public var searchQuery: String = ""
    @Published public var showOnlyLocalSongs: Bool = true
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var errorMessage: String?

    @Published public private(set) var totalAppleMusicItems: Int = 0
    @Published public private(set) var localItemsCount: Int = 0

    private var allLoadedSongs: [Song] = []

    public init() {
        Task {
            await loadLibrary()
        }
    }

    public func loadLibrary() async {
        isLoading = true
        errorMessage = nil

        do {
            let lib = try await Task.detached(priority: .userInitiated) { () -> ITLibrary in
                return try ITLibrary(apiVersion: "1.0")
            }.value

            self.rawLibrary = lib
            ArtworkLoader.shared.setLibrary(lib)

            var parsedSongs: [Song] = []
            var localCount = 0

            for item in lib.allMediaItems {
                // Keep only music items
                if item.mediaKind == .kindSong {
                    let song = Song(from: item)
                    parsedSongs.append(song)
                    if song.isPlayableLocally {
                        localCount += 1
                    }
                }
            }

            self.totalAppleMusicItems = lib.allMediaItems.count
            self.localItemsCount = localCount
            self.allLoadedSongs = parsedSongs

            self.rebuildCollections()

            self.isLoading = false
        } catch {
            self.isLoading = false
            self.errorMessage = "Could not open Apple Music library: \(error.localizedDescription)"
        }
    }

    public func rebuildCollections() {
        let baseSongs: [Song]
        if showOnlyLocalSongs {
            baseSongs = allLoadedSongs.filter { $0.isPlayableLocally }
        } else {
            baseSongs = allLoadedSongs
        }

        // Apply search query if present
        let filtered: [Song]
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            filtered = baseSongs
        } else {
            filtered = baseSongs.filter {
                $0.title.localizedCaseInsensitiveContains(query) ||
                $0.artistName.localizedCaseInsensitiveContains(query) ||
                $0.albumTitle.localizedCaseInsensitiveContains(query) ||
                $0.genre.localizedCaseInsensitiveContains(query)
            }
        }

        self.songs = filtered.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }

        // Group into Albums
        let albumGroups = Dictionary(grouping: filtered) { song in
            "\(song.albumArtistName) - \(song.albumTitle)"
        }

        var albumList: [Album] = []
        for (_, groupSongs) in albumGroups {
            if let first = groupSongs.first {
                let album = Album(title: first.albumTitle, artistName: first.albumArtistName, songs: groupSongs)
                albumList.append(album)
            }
        }
        self.albums = albumList.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }

        // Recently Added Albums (sorted by dateAdded descending)
        self.recentlyAddedAlbums = albumList.sorted { a1, a2 in
            let d1 = a1.dateAdded ?? .distantPast
            let d2 = a2.dateAdded ?? .distantPast
            if d1 != d2 {
                return d1 > d2
            }
            return a1.title.localizedCaseInsensitiveCompare(a2.title) == .orderedAscending
        }

        // Recently Added Songs (sorted by dateAdded descending)
        self.recentlyAddedSongs = filtered.sorted { s1, s2 in
            let d1 = s1.dateAdded ?? .distantPast
            let d2 = s2.dateAdded ?? .distantPast
            if d1 != d2 {
                return d1 > d2
            }
            return s1.title.localizedCaseInsensitiveCompare(s2.title) == .orderedAscending
        }

        // Group into Artists
        let artistGroups = Dictionary(grouping: filtered) { song in
            song.artistName
        }

        var artistList: [Artist] = []
        for (artistName, artistSongs) in artistGroups {
            // Find albums by this artist
            let artistAlbums = albumList.filter { $0.artistName.localizedCaseInsensitiveCompare(artistName) == .orderedSame }
            let artist = Artist(name: artistName, albums: artistAlbums, songs: artistSongs)
            artistList.append(artist)
        }
        self.artists = artistList.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
