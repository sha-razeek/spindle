import SwiftUI

public struct CoverStackView: View {
    let albums: [Album]
    @ObservedObject var player: AudioPlayer

    @State private var selectedAlbum: Album?

    public init(albums: [Album], player: AudioPlayer) {
        self.albums = albums
        self.player = player
    }

    public var body: some View {
        if let album = selectedAlbum {
            AlbumDetailView(album: album, player: player) {
                selectedAlbum = nil
            }
        } else {
            ZStack {
                // MARK: - Studio Backdrop Gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.22, green: 0.32, blue: 0.38),
                        Color(red: 0.16, green: 0.24, blue: 0.30),
                        Color(red: 0.12, green: 0.18, blue: 0.24)
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
                            // Top breathing room
                            Color.clear.frame(height: 120)

                            // 3D Cascading Stack with standard 0 spacing and fixed row heights
                            LazyVStack(spacing: 0) {
                                ForEach(albums) { album in
                                    AlbumSlabView(album: album, player: player) {
                                        selectedAlbum = album
                                    }
                                }
                            }

                            // Bottom breathing room
                            Color.clear.frame(height: 180)
                        }
                        .frame(maxWidth: .infinity)
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
}
