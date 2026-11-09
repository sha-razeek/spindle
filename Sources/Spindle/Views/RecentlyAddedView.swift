import SwiftUI
import AppKit

public enum RecentlyAddedDisplayMode: String, CaseIterable, Identifiable {
    case songs = "Songs"
    case grid = "Grid"
    case stack = "3D Stack"

    public var id: String { rawValue }
}

public typealias RecentlyAddedScope = RecentlyAddedDisplayMode

public struct RecentlyAddedView: View {
    let albums: [Album]
    let songs: [Song]
    @ObservedObject var player: AudioPlayer

    @State private var displayMode: RecentlyAddedDisplayMode = .grid
    @State private var selectedAlbum: Album?
    @State private var hoveredAlbumID: String?
    @State private var hoveredSongID: String?

    let albumColumns = [
        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 20)
    ]

    public init(albums: [Album], songs: [Song], player: AudioPlayer) {
        self.albums = albums
        self.songs = songs
        self.player = player
    }

    public var body: some View {
        if let album = selectedAlbum {
            AlbumDetailView(album: album, player: player, backTitle: "Recently Added") {
                selectedAlbum = nil
            }
        } else {
            VStack(spacing: 0) {
                switch displayMode {
                case .songs:
                    songsListView
                case .grid:
                    albumsGridView
                case .stack:
                    CoverStackView(albums: albums, player: player)
                }
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Picker("View Mode", selection: $displayMode) {
                        Image(systemName: "list.bullet").tag(RecentlyAddedDisplayMode.songs)
                        Image(systemName: "square.grid.2x2").tag(RecentlyAddedDisplayMode.grid)
                        Image(systemName: "square.stack.3d.up.fill").tag(RecentlyAddedDisplayMode.stack)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 110)
                    .help("Switch between Recently Added Songs, Album Grid, and 3D Stack")
                }
            }
        }
    }

    // MARK: - Albums Grid View
    private var albumsGridView: some View {
        Group {
            if albums.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock")
                        .font(.system(size: 44))
                        .foregroundColor(.secondary)
                    Text("No recently added albums")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: albumColumns, spacing: 24) {
                        ForEach(albums) { album in
                            let isHovered = (hoveredAlbumID == album.id)

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

                                    if let relativeDate = album.relativeDateAdded {
                                        HStack(spacing: 3) {
                                            Image(systemName: "clock")
                                                .font(.system(size: 8))
                                            Text(relativeDate)
                                                .font(.system(size: 10, weight: .medium))
                                        }
                                        .foregroundColor(.secondary.opacity(0.85))
                                        .lineLimit(1)
                                        .padding(.top, 1)
                                    }
                                }
                                .frame(width: 160, alignment: .leading)
                            }
                            .contentShape(Rectangle())
                            .onHover { hovering in
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    hoveredAlbumID = hovering ? album.id : nil
                                }
                            }
                            .onTapGesture {
                                selectedAlbum = album
                            }
                        }

                        // Bottom clearance for floating liquid glass panel
                        Color.clear.frame(height: 84)
                    }
                    .padding(24)
                }
            }
        }
    }

    // MARK: - Songs List View
    private var songsListView: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack(spacing: 12) {
                Text("#")
                    .frame(width: 36, alignment: .center)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("Title")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Artist")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 180, alignment: .leading)

                Text("Album")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 180, alignment: .leading)

                HStack(spacing: 3) {
                    Image(systemName: "clock")
                        .font(.system(size: 9))
                    Text("Added")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)

                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 50, alignment: .trailing)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)

            Divider()

            if songs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "music.note")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No recently added songs")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(Array(songs.enumerated()), id: \.element.id) { index, song in
                            let isPlayingThis = (player.currentSong?.id == song.id)
                            let isHovered = (hoveredSongID == song.id)

                            HStack(spacing: 12) {
                                // Index / play icon
                                ZStack {
                                    if isPlayingThis && player.isPlaying {
                                        Image(systemName: "speaker.wave.2.fill")
                                            .font(.system(size: 11))
                                            .foregroundColor(.accentColor)
                                    } else if isHovered {
                                        Image(systemName: "play.fill")
                                            .font(.system(size: 11))
                                            .foregroundColor(.accentColor)
                                    } else {
                                        Text("\(index + 1)")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .frame(width: 36, alignment: .center)

                                // Artwork + Title
                                HStack(spacing: 10) {
                                    ArtworkView(song: song, cornerRadius: 4, size: 32)
                                    Text(song.title)
                                        .font(.system(size: 13, weight: isPlayingThis ? .semibold : .regular))
                                        .foregroundColor(isPlayingThis ? .accentColor : .primary)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                // Artist
                                Text(song.artistName)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .frame(width: 180, alignment: .leading)
                                    .lineLimit(1)

                                // Album
                                Text(song.albumTitle)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .frame(width: 180, alignment: .leading)
                                    .lineLimit(1)

                                // Date Added
                                Text(song.relativeDateAdded ?? "-")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                    .frame(width: 120, alignment: .leading)
                                    .lineLimit(1)

                                // Duration
                                Text(song.formattedDuration)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .frame(width: 50, alignment: .trailing)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(isPlayingThis ? Color.accentColor.opacity(0.12) : (isHovered ? Color.secondary.opacity(0.08) : Color.clear))
                            )
                            .contentShape(Rectangle())
                            .onHover { hovering in
                                hoveredSongID = hovering ? song.id : nil
                            }
                            .onTapGesture {
                                player.play(song: song, inContext: songs)
                            }
                            .contextMenu {
                                Button("Play") {
                                    player.play(song: song, inContext: songs)
                                }
                                Button("Play Next") {
                                    player.playNext(song: song)
                                }
                                Button("Add to Queue") {
                                    player.addToQueue(song: song)
                                }
                                Divider()
                                if let url = song.location {
                                    Button("Show in Finder") {
                                        NSWorkspace.shared.activateFileViewerSelecting([url])
                                    }
                                }
                            }
                        }

                        // Bottom clearance for floating liquid glass panel
                        Color.clear.frame(height: 84)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                }
            }
        }
    }
}
