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
                // MARK: - Studio Backdrop Gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.20, green: 0.30, blue: 0.36),
                        Color(red: 0.15, green: 0.22, blue: 0.28),
                        Color(red: 0.10, green: 0.16, blue: 0.22)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

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

                            // Top breathing room
                            Color.clear.frame(height: 100)

                            // 3D Cascading Stack
                            LazyVStack(spacing: 0) {
                                ForEach(albums) { album in
                                    let isPopped = (poppedOutAlbumID == album.id)
                                    AlbumSlabView(
                                        album: album,
                                        isPoppedOut: isPopped,
                                        player: player,
                                        onTogglePopOut: {
                                            handleAlbumClick(album: album)
                                        },
                                        onSelectDetail: {
                                            selectedAlbumForDetail = album
                                        }
                                    )
                                    .zIndex(isPopped ? 999 : 0)
                                }
                            }

                            // Bottom breathing room
                            Color.clear.frame(height: 200)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .coordinateSpace(name: "CoverScrollSpace")
                    // Track scroll offset changes -> Retract when user scrolls
                    .onPreferenceChange(ScrollOffsetKey.self) { currentY in
                        if abs(currentY - lastScrollY) > 2.0 {
                            retractPoppedOutAlbum()
                            lastScrollY = currentY
                        }
                    }
                }

                // MARK: - Floating Header
                VStack {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "square.stack.3d.up.fill")
                                .font(.system(size: 13))
                            Text("3D COVER VIEW")
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

    private func handleAlbumClick(album: Album) {
        if poppedOutAlbumID == album.id {
            // Already popped out: toggle playback
            player.togglePlayPause()
        } else {
            // Pop out and start playing
            withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) {
                poppedOutAlbumID = album.id
            }
            if let first = album.songs.first {
                player.play(song: first, inContext: album.songs)
            }
        }
    }

    private func retractPoppedOutAlbum() {
        guard poppedOutAlbumID != nil else { return }
        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
            poppedOutAlbumID = nil
        }
    }
}
