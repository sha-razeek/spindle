import SwiftUI

public enum NavigationItem: Hashable {
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
    @State private var recentlyAddedDisplayMode: RecentlyAddedDisplayMode = .grid
    @State private var showExpandedNowPlaying: Bool = false

    private let appleMusicBlue = Color(red: 0.004, green: 0.471, blue: 0.941)

    public init() {}

    public var body: some View {
        NavigationSplitView {
            // MARK: - Sidebar
            List(selection: $selectedItem) {
                Section("Library") {
                    sidebarRow(
                        title: "Recently Added",
                        icon: "clock",
                        item: .recentlyAdded,
                        count: nil
                    )

                    sidebarRow(
                        title: "Artists",
                        icon: "music.mic",
                        item: .artists,
                        count: nil
                    )

                    sidebarRow(
                        title: "Albums",
                        icon: "square.stack",
                        item: .albums,
                        count: library.albums.count
                    )

                    sidebarRow(
                        title: "Songs",
                        icon: "music.note",
                        item: .songs,
                        count: library.songs.count
                    )

                    sidebarRow(
                        title: "3D Covers",
                        icon: "square.stack.3d.up.fill",
                        item: .coverStack,
                        count: nil
                    )
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
                    // MARK: - Main Content Area with Floating Liquid Glass Bar
                    ZStack(alignment: .bottom) {
                        // Content switcher
                        Group {
                            switch selectedItem {
                            case .recentlyAdded, .none:
                                RecentlyAddedView(
                                    albums: library.recentlyAddedAlbums,
                                    songs: library.recentlyAddedSongs,
                                    player: player,
                                    displayMode: $recentlyAddedDisplayMode
                                )
                            case .artists:
                                ArtistsView(artists: library.artists, player: player)
                            case .albums:
                                AlbumsGridView(albums: library.albums, player: player)
                            case .songs:
                                SongsListView(songs: library.songs, player: player)
                            case .coverStack:
                                CoverStackView(albums: library.albums, player: player)
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
                ToolbarItemGroup(placement: .automatic) {
                    if selectedItem == .songs || selectedItem == .albums || selectedItem == .coverStack {
                        ToolbarViewModeSwitcher(selectedItem: $selectedItem)
                    } else if selectedItem == .recentlyAdded || selectedItem == nil {
                        ToolbarRecentlyAddedSwitcher(displayMode: $recentlyAddedDisplayMode)
                    }

                    ToolbarSearchField(
                        query: $library.searchQuery,
                        prompt: (selectedItem == .recentlyAdded || selectedItem == nil) ? "Find in Recently Added" : "Find in Library"
                    )
                }
            }
        }
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
        .navigationTitle("Spindle")
        .toolbarBackground(.ultraThinMaterial, for: .windowToolbar)
        .toolbarBackground(.visible, for: .windowToolbar)
        .background(WindowTranslucencyConfigurator())
        .frame(minWidth: 900, minHeight: 600)
    }

    @ViewBuilder
    private func sidebarRow(title: String, icon: String, item: NavigationItem, count: Int?) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16.5, weight: .medium))
                .foregroundColor(appleMusicBlue)
                .frame(width: 24, alignment: .center)

            Text(title)
                .font(.system(size: 14, weight: selectedItem == item ? .semibold : .regular))
                .foregroundColor(.primary)

            Spacer()

            if let count = count {
                Text(count.formatted())
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .tag(item)
    }
}

// MARK: - Window Translucency Configurator
// Ensures the macOS top title bar and toolbar are translucent frosted glass like Apple Music
struct WindowTranslucencyConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.titlebarAppearsTransparent = true
            window.toolbar?.showsBaselineSeparator = false
            window.styleMask.insert(.fullSizeContentView)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let window = nsView.window else { return }
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

// MARK: - Apple Music Styled View Mode Switcher (Capsule buttons with very rounded corners)
struct ToolbarViewModeSwitcher: View {
    @Binding var selectedItem: NavigationItem?

    var currentMode: LibraryViewMode {
        switch selectedItem {
        case .songs: return .songs
        case .albums: return .grid
        case .coverStack: return .stack
        default: return .songs
        }
    }

    var body: some View {
        HStack(spacing: 2) {
            switcherButton(icon: "list.bullet", mode: .songs, help: "Song List") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedItem = .songs
                }
            }

            switcherButton(icon: "square.grid.2x2", mode: .grid, help: "Album Grid") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedItem = .albums
                }
            }

            switcherButton(icon: "square.stack.3d.up.fill", mode: .stack, help: "3D Covers") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedItem = .coverStack
                }
            }
        }
        .padding(2.5)
        .background(
            Capsule()
                .fill(Color.primary.opacity(0.06))
        )
        .overlay(
            Capsule()
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.8)
        )
        .frame(height: 28)
    }

    @ViewBuilder
    private func switcherButton(icon: String, mode: LibraryViewMode, help: String, action: @escaping () -> Void) -> some View {
        let isSelected = currentMode == mode
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .primary : .secondary)
                .frame(width: 28, height: 23)
                .background(
                    Group {
                        if isSelected {
                            Capsule()
                                .fill(Color(NSColor.controlBackgroundColor))
                                .shadow(color: Color.black.opacity(0.12), radius: 2, x: 0, y: 1)
                        } else {
                            Color.clear
                        }
                    }
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .help(help)
    }
}

// MARK: - Apple Music Styled Recently Added View Mode Switcher
struct ToolbarRecentlyAddedSwitcher: View {
    @Binding var displayMode: RecentlyAddedDisplayMode

    var body: some View {
        HStack(spacing: 2) {
            switcherButton(icon: "list.bullet", mode: .songs, help: "Song List") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    displayMode = .songs
                }
            }

            switcherButton(icon: "square.grid.2x2", mode: .grid, help: "Album Grid") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    displayMode = .grid
                }
            }

            switcherButton(icon: "square.stack.3d.up.fill", mode: .stack, help: "3D Covers") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    displayMode = .stack
                }
            }
        }
        .padding(2.5)
        .background(
            Capsule()
                .fill(Color.primary.opacity(0.06))
        )
        .overlay(
            Capsule()
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.8)
        )
        .frame(height: 28)
    }

    @ViewBuilder
    private func switcherButton(icon: String, mode: RecentlyAddedDisplayMode, help: String, action: @escaping () -> Void) -> some View {
        let isSelected = displayMode == mode
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .primary : .secondary)
                .frame(width: 28, height: 23)
                .background(
                    Group {
                        if isSelected {
                            Capsule()
                                .fill(Color(NSColor.controlBackgroundColor))
                                .shadow(color: Color.black.opacity(0.12), radius: 2, x: 0, y: 1)
                        } else {
                            Color.clear
                        }
                    }
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .help(help)
    }
}

// MARK: - Apple Music Styled Search Field (Capsule with very rounded corners)
struct ToolbarSearchField: View {
    @Binding var query: String
    var prompt: String = "Find in Library"
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)

            TextField(prompt, text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 12.5))
                .focused($isFocused)

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11.5))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .frame(width: 200, height: 28)
        .background(
            Capsule()
                .fill(Color.primary.opacity(0.06))
        )
        .overlay(
            Capsule()
                .stroke(
                    isFocused ? Color(red: 0.004, green: 0.471, blue: 0.941).opacity(0.85) : Color.primary.opacity(0.10),
                    lineWidth: isFocused ? 1.5 : 0.8
                )
        )
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}
