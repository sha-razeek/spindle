import SwiftUI

public struct SearchView: View {
    @ObservedObject var library: LibraryManager
    @ObservedObject var player: AudioPlayer

    @State private var hoveredSongId: String? = nil
    @State private var hoveredAlbumId: String? = nil
    @State private var selectedAlbum: Album? = nil

    public init(library: LibraryManager, player: AudioPlayer) {
        self.library = library
        self.player = player
    }

    public var body: some View {
        if let album = selectedAlbum {
            AlbumDetailView(album: album, player: player) {
                selectedAlbum = nil
            }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // MARK: - Search Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Search")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)

                        // Apple Music Style Search Bar
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.secondary)

                            TextField("Search songs, artists, albums...", text: $library.searchQuery)
                                .textFieldStyle(.plain)
                                .font(.system(size: 14))

                            if !library.searchQuery.isEmpty {
                                Button {
                                    library.searchQuery = ""
                                    library.rebuildCollections()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.primary.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
                        )
                        .frame(maxWidth: 480)
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 24)

                    if library.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        // MARK: - Empty Query Suggestions / Recent Albums
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Recently Added")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 180), spacing: 20)], spacing: 20) {
                                ForEach(library.recentlyAddedAlbums.prefix(8)) { album in
                                    albumCard(album: album)
                                }
                            }
                        }
                        .padding(.horizontal, 32)
                    } else {
                        // MARK: - Search Results

                        // Matching Songs
                        if !library.songs.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Songs (\(library.songs.count))")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.primary)

                                VStack(spacing: 2) {
                                    ForEach(library.songs.prefix(8)) { song in
                                        searchSongRow(song: song)
                                    }
                                }
                            }
                            .padding(.horizontal, 32)
                        }

                        // Matching Albums
                        if !library.albums.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Albums (\(library.albums.count))")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.primary)

                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 180), spacing: 20)], spacing: 20) {
                                    ForEach(library.albums.prefix(12)) { album in
                                        albumCard(album: album)
                                    }
                                }
                            }
                            .padding(.horizontal, 32)
                        }

                        // Matching Artists
                        if !library.artists.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Artists (\(library.artists.count))")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.primary)

                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120, maximum: 150), spacing: 16)], spacing: 16) {
                                    ForEach(library.artists.prefix(6)) { artist in
                                        VStack(spacing: 8) {
                                            Circle()
                                                .fill(Color.primary.opacity(0.08))
                                                .frame(width: 80, height: 80)
                                                .overlay(
                                                    Image(systemName: "music.mic")
                                                        .font(.system(size: 28))
                                                        .foregroundColor(.secondary)
                                                )
                                            Text(artist.name)
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(.primary)
                                                .lineLimit(1)
                                            Text("\(artist.albums.count) albums")
                                                .font(.system(size: 11))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 32)
                        }

                        if library.songs.isEmpty && library.albums.isEmpty && library.artists.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                Text("No Results Found")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Try searching for a different song title, artist, or album name.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                        }
                    }
                }
                .padding(.bottom, 90) // space for bottom floating bar
            }
        }
    }

    @ViewBuilder
    private func albumCard(album: Album) -> some View {
        let isHovered = hoveredAlbumId == album.id

        Button {
            selectedAlbum = album
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    ArtworkView(song: album.representativeSong, cornerRadius: 8, size: 160)
                        .shadow(color: .black.opacity(isHovered ? 0.25 : 0.1), radius: isHovered ? 8 : 4, x: 0, y: isHovered ? 4 : 2)

                    if isHovered {
                        Button {
                            if let first = album.songs.first {
                                player.play(song: first, inContext: album.songs)
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 36, height: 36)
                                Image(systemName: "play.fill")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white)
                                    .offset(x: 1)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(8)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: 160, height: 160)

                VStack(alignment: .leading, spacing: 2) {
                    Text(album.title)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                        .foregroundColor(.primary)

                    Text(album.artistName)
                        .font(.system(size: 12))
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                }
                .frame(width: 160, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
        .onHover { h in
            hoveredAlbumId = h ? album.id : nil
        }
    }

    @ViewBuilder
    private func searchSongRow(song: Song) -> some View {
        let isCurrent = player.currentSong?.id == song.id
        let isHovered = hoveredSongId == song.id

        Button {
            player.play(song: song, inContext: library.songs)
        } label: {
            HStack(spacing: 12) {
                ArtworkView(song: song, cornerRadius: 4, size: 36)
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(song.title)
                        .font(.system(size: 13, weight: isCurrent ? .bold : .medium))
                        .foregroundColor(isCurrent ? .accentColor : .primary)
                        .lineLimit(1)

                    Text(song.artistName)
                        .font(.system(size: 11.5))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text(song.formattedDuration)
                    .font(.system(size: 11.5, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isHovered ? Color.primary.opacity(0.06) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { h in
            hoveredSongId = h ? song.id : nil
        }
    }
}
