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
    @ObservedObject private var artworkLoader = ArtworkLoader.shared

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
                                    // Scroll tracker anchor at the top
                                    GeometryReader { geo in
                                        Color.clear
                                            .preference(
                                                key: ScrollOffsetKey.self,
                                                value: geo.frame(in: .named("CoverScrollSpace")).minY
                                            )
                                    }
                                    .frame(height: 0)

                                    // Dynamic Top breathing room to ensure any album (even the first) can be centered
                                    Color.clear.frame(height: poppedOutAlbumID != nil ? 380 : 100)

                                    // Drawer Albums Stack
                                    LazyVStack(spacing: 0) {
                                        ForEach(albums) { album in
                                            let isPopped = (poppedOutAlbumID == album.id)
                                            AlbumSlabView(
                                                album: album,
                                                isPoppedOut: isPopped,
                                                player: player,
                                                onTogglePopOut: {
                                                    handleAlbumClick(album: album, proxy: proxy)
                                                },
                                                onSelectDetail: {
                                                    selectedAlbumForDetail = album
                                                }
                                            )
                                            .id(album.id)
                                            .zIndex(isPopped ? 999 : 0)
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
                                if isProgrammaticScroll {
                                    lastScrollY = currentY
                                    return
                                }
                                if abs(currentY - lastScrollY) > 3.0 {
                                    retractPoppedOutAlbum()
                                    lastScrollY = currentY
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

    private func handleAlbumClick(album: Album, proxy: ScrollViewProxy) {
        let isAlreadyPlayingThisAlbum = player.currentSong != nil && album.songs.contains(where: { $0.id == player.currentSong?.id })

        if poppedOutAlbumID == album.id {
            // Already popped out: toggle playback
            player.togglePlayPause()
        } else {
            // Flag programmatic scroll to prevent auto-retraction during centering
            isProgrammaticScroll = true
            programmaticScrollTask?.cancel()

            // Highlight, expand and center this album smoothly
            withAnimation(.spring(response: 0.42, dampingFraction: 0.80)) {
                poppedOutAlbumID = album.id
                proxy.scrollTo(album.id, anchor: .center)
            }

            programmaticScrollTask = Task { @MainActor in
                // Secondary alignment tick once dynamic row height updates in layout tree
                try? await Task.sleep(nanoseconds: 60_000_000)
                withAnimation(.spring(response: 0.42, dampingFraction: 0.80)) {
                    proxy.scrollTo(album.id, anchor: .center)
                }
                // Retain guard until spring settling completes
                try? await Task.sleep(nanoseconds: 480_000_000)
                isProgrammaticScroll = false
            }

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
