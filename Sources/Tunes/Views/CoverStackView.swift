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
                        // Subtle Drawer Rail Guides on sides
                        HStack {
                            Spacer()
                            Rectangle()
                                .fill(Color.white.opacity(0.06))
                                .frame(width: 2)
                            Spacer().frame(width: 536)
                            Rectangle()
                                .fill(Color.white.opacity(0.06))
                                .frame(width: 2)
                            Spacer()
                        }
                        .allowsHitTesting(false)

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

                                // Drawer Albums Stack
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
                                Color.clear.frame(height: 180)
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
                        // Track scroll offset changes -> Retract when user scrolls
                        .onPreferenceChange(ScrollOffsetKey.self) { currentY in
                            if abs(currentY - lastScrollY) > 2.0 {
                                retractPoppedOutAlbum()
                                lastScrollY = currentY
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

    private func handleAlbumClick(album: Album) {
        if poppedOutAlbumID == album.id {
            // Already popped out: toggle playback
            player.togglePlayPause()
        } else {
            // Expand this album and smoothly move all albums below it down!
            withAnimation(.spring(response: 0.38, dampingFraction: 0.75)) {
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
