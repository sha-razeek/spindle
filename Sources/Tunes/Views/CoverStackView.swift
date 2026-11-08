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
            ZStack {
                // MARK: - Studio Drawer Backdrop Gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.18, green: 0.26, blue: 0.32),
                        Color(red: 0.13, green: 0.19, blue: 0.24),
                        Color(red: 0.09, green: 0.14, blue: 0.18)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    retractPoppedOutAlbum()
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
                                            let isOtherPopped = (poppedOutAlbumID != nil && !isPopped)
                                            AlbumSlabView(
                                                album: album,
                                                isPoppedOut: isPopped,
                                                isOtherAlbumPoppedOut: isOtherPopped,
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
                            // Gradient Alpha Mask: Eliminates sudden appearance at bottom/top
                            .mask(
                                LinearGradient(
                                    stops: [
                                        .init(color: .clear, location: 0.0),
                                        .init(color: .black, location: 0.06),
                                        .init(color: .black, location: 0.88),
                                        .init(color: .clear, location: 0.98)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
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

                        // Bottom Atmospheric Gradient Fade: Albums dissolve smoothly into darkness
                        VStack {
                            Spacer()
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color(red: 0.09, green: 0.14, blue: 0.18).opacity(0.85),
                                    Color(red: 0.09, green: 0.14, blue: 0.18)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 90)
                            .allowsHitTesting(false)
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
