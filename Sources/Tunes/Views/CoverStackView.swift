import SwiftUI

private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

public struct CoverStackView: View {
    let albums: [Album]
    @ObservedObject var player: AudioPlayer

    @State private var selectedAlbumForDetail: Album?
    @State private var poppedOutAlbumID: String? = nil
    @State private var lastScrollY: CGFloat = 0
    @State private var isProgrammaticScroll: Bool = false
    @State private var programmaticScrollTask: Task<Void, Never>? = nil

    private var currentBackdrop: BackdropPalette {
        if let song = player.currentSong {
            return ArtworkLoader.shared.backdropPalette(for: song, fallbackID: song.id)
        }
        return ArtworkLoader.shared.defaultBackdropPalette
    }

    private var currentlyPlayingAlbum: Album? {
        guard let song = player.currentSong else { return nil }
        if let match = albums.first(where: { $0.songs.contains(where: { $0.id == song.id }) }) {
            return match
        }
        let songArtist = song.albumArtistName.isEmpty ? song.artistName : song.albumArtistName
        return albums.first(where: {
            $0.title.localizedCaseInsensitiveCompare(song.albumTitle) == .orderedSame &&
            ($0.artistName.localizedCaseInsensitiveCompare(songArtist) == .orderedSame ||
             $0.artistName.localizedCaseInsensitiveCompare(song.artistName) == .orderedSame)
        })
    }

    public init(albums: [Album], player: AudioPlayer) {
        self.albums = albums
        self.player = player
    }

    public var body: some View {
        if let album = selectedAlbumForDetail {
            AlbumDetailView(album: album, player: player) {
                selectedAlbumForDetail = nil
            }
        } else {
            let backdrop = currentBackdrop

            ZStack {
                // MARK: - Dynamic Playing Album Backdrop
                ZStack {
                    backdrop.bottom.ignoresSafeArea()

                    LinearGradient(
                        colors: [
                            backdrop.top,
                            backdrop.mid,
                            backdrop.bottom
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()

                    // Atmospheric glowing radial spotlight radiating from upper-center
                    RadialGradient(
                        colors: [
                            backdrop.primary.opacity(0.40),
                            backdrop.mid.opacity(0.18),
                            Color.clear
                        ],
                        center: .init(x: 0.5, y: 0.30),
                        startRadius: 70,
                        endRadius: 750
                    )
                    .ignoresSafeArea()

                    // Ambient glowing color aura for rich visual depth
                    Circle()
                        .fill(backdrop.primary.opacity(0.30))
                        .frame(width: 650, height: 650)
                        .offset(x: 100, y: -70)
                        .blur(radius: 120)
                        .allowsHitTesting(false)
                }
                .animation(.easeInOut(duration: 0.80), value: player.currentSong?.id)
                .contentShape(Rectangle())
                .onTapGesture {
                    retractPoppedOutAlbum()
                }
                .task(id: player.currentSong?.id) {
                    if let song = player.currentSong {
                        _ = await ArtworkLoader.shared.loadArtwork(for: song)
                    }
                }

                if albums.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "square.stack.3d.up")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.6))
                        Text("No albums found")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                } else {
                    ZStack {
                        ScrollViewReader { proxy in
                            ScrollView(.vertical, showsIndicators: false) {
                                VStack(spacing: 0) {
                                    // Scroll tracker anchor at the top - only track when an album is popped out
                                    if poppedOutAlbumID != nil {
                                        GeometryReader { geo in
                                            Color.clear
                                                .preference(
                                                    key: ScrollOffsetKey.self,
                                                    value: geo.frame(in: .named("CoverScrollSpace")).minY
                                                )
                                        }
                                        .frame(height: 0)
                                    }

                                    // Dynamic Top breathing room to ensure any album (even the first) can be centered
                                    Color.clear.frame(height: poppedOutAlbumID != nil ? 380 : 100)

                                    // Drawer Albums Stack
                                    LazyVStack(spacing: 0) {
                                        ForEach(albums) { album in
                                            albumSlabRow(for: album, proxy: proxy)
                                        }
                                    }

                                    // Dynamic Bottom breathing room to ensure any album (even the last) can be centered
                                    Color.clear.frame(height: poppedOutAlbumID != nil ? 440 : 180)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .coordinateSpace(name: "CoverScrollSpace")
                            // Track scroll offset changes -> Retract when user scrolls manually
                            .onPreferenceChange(ScrollOffsetKey.self) { currentY in
                                guard poppedOutAlbumID != nil else { return }
                                if isProgrammaticScroll {
                                    lastScrollY = currentY
                                    return
                                }
                                if abs(currentY - lastScrollY) > 3.0 {
                                    retractPoppedOutAlbum()
                                    lastScrollY = currentY
                                }
                            }
                            .onAppear {
                                scrollToPlayingAlbum(proxy: proxy, force: true)
                            }
                            .onChange(of: albums.count) { _, newCount in
                                if newCount > 0 && poppedOutAlbumID == nil {
                                    scrollToPlayingAlbum(proxy: proxy, force: false)
                                }
                            }
                            .onChange(of: player.currentSong?.id) { _, newSongID in
                                guard newSongID != nil else { return }
                                if let playingAlbum = currentlyPlayingAlbum, playingAlbum.id != poppedOutAlbumID {
                                    scrollToPlayingAlbum(proxy: proxy, force: false)
                                }
                            }
                        }
                    }
                }

                // MARK: - Floating Header
                VStack {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "square.stack.3d.up.fill")
                                .font(.system(size: 13))
                            Text("VINYL DRAWER")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1)
                            Text("• \(albums.count) albums")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                        )
                        .foregroundColor(.white)

                        Spacer()
                    }
                    .padding(.leading, 24)
                    .padding(.top, 16)

                    Spacer()
                }
            }
        }
    }

    @ViewBuilder
    private func albumSlabRow(for album: Album, proxy: ScrollViewProxy) -> some View {
        let isPopped = (poppedOutAlbumID == album.id)
        let isCurrent = (currentlyPlayingAlbum?.id == album.id)
        AlbumSlabView(
            album: album,
            isPoppedOut: isPopped,
            isCurrentlyPlayingThisAlbum: isCurrent,
            isPlaying: player.isPlaying,
            player: player,
            onTogglePopOut: {
                handleAlbumClick(album: album, proxy: proxy)
            },
            onSelectDetail: {
                selectedAlbumForDetail = album
            }
        )
        .equatable()
        .id(album.id)
        .zIndex(isPopped ? 999 : 0)
    }

    private func centerAlbum(_ album: Album, proxy: ScrollViewProxy, animated: Bool = true) {
        isProgrammaticScroll = true
        programmaticScrollTask?.cancel()

        withAnimation(animated ? .spring(response: 0.42, dampingFraction: 0.80) : nil) {
            poppedOutAlbumID = album.id
            proxy.scrollTo(album.id, anchor: .center)
        }

        programmaticScrollTask = Task { @MainActor in
            // Stage 1: Quick frame to prime lazy elements around target
            try? await Task.sleep(nanoseconds: 60_000_000)
            withAnimation(animated ? .spring(response: 0.42, dampingFraction: 0.80) : nil) {
                proxy.scrollTo(album.id, anchor: .center)
            }

            // Stage 2: Secondary refinement once slab expansion (614pt) and breathing room settle
            try? await Task.sleep(nanoseconds: 120_000_000)
            withAnimation(animated ? .spring(response: 0.42, dampingFraction: 0.80) : nil) {
                proxy.scrollTo(album.id, anchor: .center)
            }

            // Stage 3: Hold the programmatic scroll guard until inertia and spring animation settle
            try? await Task.sleep(nanoseconds: 480_000_000)
            isProgrammaticScroll = false
        }
    }

    private func scrollToPlayingAlbum(proxy: ScrollViewProxy, force: Bool = false) {
        guard let album = currentlyPlayingAlbum else { return }
        if force || poppedOutAlbumID != album.id {
            centerAlbum(album, proxy: proxy)
        }
    }

    private func handleAlbumClick(album: Album, proxy: ScrollViewProxy) {
        let isAlreadyPlayingThisAlbum = player.currentSong != nil && album.songs.contains(where: { $0.id == player.currentSong?.id })

        if poppedOutAlbumID == album.id {
            // Already popped out: toggle playback
            player.togglePlayPause()
        } else {
            centerAlbum(album, proxy: proxy)

            if isAlreadyPlayingThisAlbum {
                // Already playing: continue playing without starting over!
                if !player.isPlaying {
                    player.togglePlayPause()
                }
            } else {
                // Not playing: start album from the first track
                if let first = album.songs.first {
                    player.play(song: first, inContext: album.songs)
                }
            }
        }
    }

    private func retractPoppedOutAlbum() {
        guard poppedOutAlbumID != nil else { return }
        programmaticScrollTask?.cancel()
        isProgrammaticScroll = false
        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
            poppedOutAlbumID = nil
        }
    }
}
