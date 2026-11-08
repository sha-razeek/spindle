import SwiftUI

public enum NavigationItem: Hashable {
    case songs
    case albums
    case coverStack
    case artists
    case playlist(String)
}

public struct ContentView: View {
    @StateObject private var library = LibraryManager()
    @StateObject private var player = AudioPlayer.shared

    @State private var selectedItem: NavigationItem? = .songs
    @State private var showExpandedNowPlaying: Bool = false

    public init() {}

    public var body: some View {
        NavigationSplitView {
            // MARK: - Sidebar
            List(selection: $selectedItem) {
                Section("Library") {
                    Label("Songs", systemImage: "music.note")
                        .badge(library.songs.count)
                        .tag(NavigationItem.songs)

                    Label("Albums", systemImage: "square.stack")
                        .badge(library.albums.count)
                        .tag(NavigationItem.albums)

                    Label("3D Covers", systemImage: "square.stack.3d.up.fill")
                        .badge(library.albums.count)
                        .tag(NavigationItem.coverStack)

                    Label("Artists", systemImage: "music.mic")
                        .badge(library.artists.count)
                        .tag(NavigationItem.artists)
                }

                if !library.playlists.isEmpty {
                    Section("Playlists") {
                        ForEach(library.playlists) { playlist in
                            Label(playlist.name, systemImage: "music.note.list")
                                .badge(playlist.songCount)
                                .tag(NavigationItem.playlist(playlist.id))
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 200, ideal: 230, max: 300)
            .safeAreaInset(edge: .bottom) {
                // Bottom Library Status
                VStack(spacing: 6) {
                    Divider()
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(library.isLoading ? Color.orange : Color.green)
                                    .frame(width: 7, height: 7)
                                Text("Apple Music Library")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                            Text("\(library.localItemsCount) local • 0 bytes duplicated")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button {
                            Task {
                                await library.loadLibrary()
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Refresh Library")
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
                }
                .background(.ultraThinMaterial)
            }
        } detail: {
            // MARK: - Main Content Area
            VStack(spacing: 0) {
                if showExpandedNowPlaying {
                    ExpandedNowPlayingView(
                        player: player,
                        library: library,
                        isPresented: $showExpandedNowPlaying
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else if library.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Reading Apple Music Library...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let err = library.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 44))
                            .foregroundColor(.orange)
                        Text("Library Access Notice")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text(err)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: 420)
                        Button("Retry Access") {
                            Task {
                                await library.loadLibrary()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(32)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Content switcher
                    Group {
                        switch selectedItem {
                        case .songs, .none:
                            SongsListView(songs: library.songs, player: player)
                        case .albums:
                            AlbumsGridView(albums: library.albums, player: player)
                        case .coverStack:
                            CoverStackView(albums: library.albums, player: player)
                        case .artists:
                            ArtistsView(artists: library.artists, player: player)
                        case .playlist(let id):
                            if let playlist = library.playlists.first(where: { $0.id == id }) {
                                PlaylistDetailView(playlist: playlist, player: player)
                            } else {
                                Text("Playlist not found")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                // MARK: - Bottom Now Playing Bar
                NowPlayingBar(player: player) {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                        showExpandedNowPlaying.toggle()
                    }
                }
            }
        }
        .searchable(text: $library.searchQuery, prompt: "Search songs, artists, albums...")
        .onChange(of: library.searchQuery) { _, _ in
            library.rebuildCollections()
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}
