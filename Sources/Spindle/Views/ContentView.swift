import SwiftUI

public enum NavigationItem: Hashable {
    case search
    case home
    case recentlyAdded
    case artists
    case albums
    case songs
    case coverStack
}

public enum LibraryViewMode: String, CaseIterable, Identifiable {
    case songs = "Songs"
    case grid = "Grid"
    case stack = "3D Stack"

    public var id: String { rawValue }
}

public struct ContentView: View {
    @StateObject private var library = LibraryManager()
    @StateObject private var player = AudioPlayer.shared

    @State private var selectedItem: NavigationItem? = .recentlyAdded
    @State private var showExpandedNowPlaying: Bool = false

    private let appleMusicBlue = Color(red: 0.004, green: 0.471, blue: 0.941)

    public init() {}

    public var body: some View {
        NavigationSplitView {
            // MARK: - Sidebar
            ScrollView {
                VStack(alignment: .leading, spacing: 3) {
                    sidebarItem(
                        title: "Search",
                        icon: "magnifyingglass",
                        item: .search,
                        count: nil
                    )

                    sidebarItem(
                        title: "Home",
                        icon: "house",
                        item: .home,
                        count: nil
                    )

                    Text("Library")
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 14)
                        .padding(.top, 14)
                        .padding(.bottom, 4)

                    sidebarItem(
                        title: "Recently Added",
                        icon: "clock",
                        item: .recentlyAdded,
                        count: nil
                    )

                    sidebarItem(
                        title: "Artists",
                        icon: "music.mic",
                        item: .artists,
                        count: nil
                    )

                    sidebarItem(
                        title: "Albums",
                        icon: "square.stack",
                        item: .albums,
                        count: library.albums.count
                    )

                    sidebarItem(
                        title: "Songs",
                        icon: "music.note",
                        item: .songs,
                        count: library.songs.count
                    )

                    sidebarItem(
                        title: "3D Covers",
                        icon: "square.stack.3d.up.fill",
                        item: .coverStack,
                        count: nil
                    )
                }
                .padding(.horizontal, 8)
                .padding(.top, 46)
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 235, max: 300)
            .simultaneousGesture(
                TapGesture().onEnded {
                    if showExpandedNowPlaying {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showExpandedNowPlaying = false
                        }
                    }
                }
            )
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
                    // MARK: - Main Content Area with Floating Liquid Glass Bar
                    ZStack(alignment: .bottom) {
                        // Content switcher
                        Group {
                            switch selectedItem {
                            case .search:
                                SearchView(library: library, player: player)
                            case .home:
                                RecentlyAddedView(
                                    albums: library.recentlyAddedAlbums,
                                    songs: library.recentlyAddedSongs,
                                    player: player
                                )
                            case .recentlyAdded:
                                RecentlyAddedView(
                                    albums: library.recentlyAddedAlbums,
                                    songs: library.recentlyAddedSongs,
                                    player: player
                                )
                            case .songs, .none:
                                SongsListView(songs: library.songs, player: player)
                            case .albums:
                                AlbumsGridView(albums: library.albums, player: player)
                            case .coverStack:
                                CoverStackView(albums: library.albums, player: player)
                            case .artists:
                                ArtistsView(artists: library.artists, player: player)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                        // MARK: - Apple Liquid Glass Floating Now Playing Panel
                        NowPlayingBar(player: player) {
                            withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                                showExpandedNowPlaying.toggle()
                            }
                        }
                        .padding(.horizontal, 28)
                        .padding(.bottom, 16)
                    }
                }
            }
            .toolbar {
                if selectedItem == .songs || selectedItem == .albums || selectedItem == .coverStack {
                    ToolbarItem(placement: .automatic) {
                        Picker("View Mode", selection: Binding(
                            get: {
                                switch selectedItem {
                                case .songs: return LibraryViewMode.songs
                                case .albums: return LibraryViewMode.grid
                                case .coverStack: return LibraryViewMode.stack
                                default: return LibraryViewMode.songs
                                }
                            },
                            set: { newMode in
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    switch newMode {
                                    case .songs: selectedItem = .songs
                                    case .grid: selectedItem = .albums
                                    case .stack: selectedItem = .coverStack
                                    }
                                }
                            }
                        )) {
                            Image(systemName: "list.bullet").tag(LibraryViewMode.songs)
                            Image(systemName: "square.grid.2x2").tag(LibraryViewMode.grid)
                            Image(systemName: "square.stack.3d.up.fill").tag(LibraryViewMode.stack)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 110)
                        .help("Switch between Song List, Album Grid, and 3D Covers")
                    }
                }
            }
        }
        .searchable(text: $library.searchQuery, prompt: "Search songs, artists, albums...")
        .onChange(of: library.searchQuery) { _, _ in
            library.rebuildCollections()
        }
        .onChange(of: selectedItem) { _, _ in
            if showExpandedNowPlaying {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showExpandedNowPlaying = false
                }
            }
        }
        .toolbar(removing: .sidebarToggle)
        .navigationTitle("")
        .toolbarBackground(.ultraThinMaterial, for: .windowToolbar)
        .toolbarBackground(.visible, for: .windowToolbar)
        .background(WindowTranslucencyConfigurator())
        .frame(minWidth: 900, minHeight: 600)
    }

    @ViewBuilder
    private func sidebarItem(title: String, icon: String, item: NavigationItem, count: Int?) -> some View {
        SidebarItemRow(
            title: title,
            icon: icon,
            iconColor: appleMusicBlue,
            isSelected: selectedItem == item,
            count: count
        ) {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedItem = item
            }
        }
    }
}

// MARK: - Apple Music Styled Sidebar Row
struct SidebarItemRow: View {
    let title: String
    let icon: String
    let iconColor: Color
    let isSelected: Bool
    let count: Int?
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24, alignment: .center)

                Text(title)
                    .font(.system(size: 14.5, weight: isSelected ? .bold : .medium))
                    .foregroundColor(.primary)

                Spacer()

                if let count = count {
                    Text(count.formatted())
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 7.5)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.primary.opacity(0.10) : (isHovered ? Color.primary.opacity(0.04) : Color.clear))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Window Translucency Configurator
// Ensures the macOS top title bar and toolbar are translucent frosted glass like Apple Music
struct WindowTranslucencyConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.toolbar?.showsBaselineSeparator = false
            window.styleMask.insert(.fullSizeContentView)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let window = nsView.window else { return }
            window.titleVisibility = .hidden
            if !window.titlebarAppearsTransparent {
                window.titlebarAppearsTransparent = true
            }
            if !window.styleMask.contains(.fullSizeContentView) {
                window.styleMask.insert(.fullSizeContentView)
            }
            window.toolbar?.showsBaselineSeparator = false
        }
    }
}
