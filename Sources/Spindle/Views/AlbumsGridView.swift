import SwiftUI

public enum AlbumDisplayMode: String, CaseIterable, Identifiable {
    case grid = "Grid"
    case stack = "3D Stack"

    public var id: String { rawValue }
}

public struct AlbumsGridView: View {
    let albums: [Album]
    @ObservedObject var player: AudioPlayer

    @State private var displayMode: AlbumDisplayMode = .grid
    @State private var selectedAlbum: Album?
    @State private var hoveredAlbumID: String?

    let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 20)
    ]

    public init(albums: [Album], player: AudioPlayer) {
        self.albums = albums
        self.player = player
    }

    public var body: some View {
        if let album = selectedAlbum {
            AlbumDetailView(album: album, player: player) {
                selectedAlbum = nil
            }
        } else if displayMode == .stack {
            CoverStackView(albums: albums, player: player)
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        displayModePicker
                    }
                }
        } else {
            VStack(spacing: 0) {
                if albums.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "square.stack")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No albums found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 24) {
                            ForEach(albums) { album in
                                let isHovered = hoveredAlbumID == album.id

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
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    displayModePicker
                }
            }
        }
    }

    private var displayModePicker: some View {
        Picker("View Mode", selection: $displayMode) {
            Image(systemName: "square.grid.2x2").tag(AlbumDisplayMode.grid)
            Image(systemName: "square.stack.3d.up.fill").tag(AlbumDisplayMode.stack)
        }
        .pickerStyle(.segmented)
        .frame(width: 80)
        .help("Switch between Grid and 3D Cover Stack")
    }
}
