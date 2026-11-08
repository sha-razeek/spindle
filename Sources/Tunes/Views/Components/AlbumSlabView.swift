import SwiftUI
import AppKit

public struct AlbumSlabView: View {
    let album: Album
    let isPoppedOut: Bool
    @ObservedObject var player: AudioPlayer
    var onTogglePopOut: () -> Void
    var onSelectDetail: () -> Void

    @State private var artworkImage: NSImage?
    @State private var isHovered: Bool = false
    @State private var spineBgColor: Color = Color.secondary.opacity(0.25)
    @State private var spineTextColor: Color = .primary

    private var isCurrentlyPlayingThisAlbum: Bool {
        guard let current = player.currentSong else { return false }
        return album.songs.contains(where: { $0.id == current.id })
    }

    public init(
        album: Album,
        isPoppedOut: Bool,
        player: AudioPlayer,
        onTogglePopOut: @escaping () -> Void,
        onSelectDetail: @escaping () -> Void
    ) {
        self.album = album
        self.isPoppedOut = isPoppedOut
        self.player = player
        self.onTogglePopOut = onTogglePopOut
        self.onSelectDetail = onSelectDetail
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            // MARK: - 1. Vinyl Record Disc (Slides out of the sleeve ~1/8th of the way when selected)
            VinylDiscView(
                artwork: artworkImage,
                isPlaying: isCurrentlyPlayingThisAlbum && player.isPlaying,
                size: 210
            )
            // Positioned behind jacket, slides out to the right when popped out
            .position(
                x: isPoppedOut ? 425 : 240,
                y: isPoppedOut ? 140 : 130
            )
            .opacity(isPoppedOut ? 1.0 : (isHovered ? 0.35 : 0.0))
            .animation(.spring(response: 0.42, dampingFraction: 0.72), value: isPoppedOut)

            // MARK: - 2. Front Album Jacket (Drawer Sleeve)
            VStack(spacing: 0) {
                // Top Spine Edge (Visible in drawer)
                HStack(spacing: 8) {
                    if isCurrentlyPlayingThisAlbum && player.isPlaying {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(spineTextColor)
                            .padding(.trailing, 2)
                    }

                    // Bold Album / Song Title
                    Text(album.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(spineTextColor)
                        .lineLimit(1)

                    // Regular Artist Name
                    Text(album.artistName)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(spineTextColor.opacity(0.85))
                        .lineLimit(1)

                    Spacer()

                    // Track count badge
                    Text("\(album.trackCount) tracks")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(spineTextColor.opacity(0.75))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2.5)
                        .background(spineTextColor.opacity(0.12))
                        .cornerRadius(4)
                }
                .padding(.horizontal, 14)
                .frame(width: 480, height: 32)
                .background(spineBgColor)
                .overlay(
                    // Top highlight ridge catching drawer light and bottom shadow ridge
                    VStack {
                        Rectangle()
                            .fill(Color.white.opacity(0.40))
                            .frame(height: 1)
                        Spacer()
                        Rectangle()
                            .fill(Color.black.opacity(0.28))
                            .frame(height: 1)
                    }
                )
                .shadow(
                    color: Color.black.opacity(isPoppedOut ? 0.45 : 0.25),
                    radius: isPoppedOut ? 10 : 4,
                    x: 0,
                    y: isPoppedOut ? 5 : 2
                )
                .zIndex(10)

                // Album Artwork Jacket Surface (Straight, natural perspective)
                ZStack(alignment: .center) {
                    if let image = artworkImage {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(1, contentMode: .fill)
                    } else {
                        LinearGradient(
                            colors: [spineBgColor.opacity(0.9), Color.purple.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        Image(systemName: "music.note")
                            .font(.system(size: 56))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    // Gentle subtle lighting sheen
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isPoppedOut ? 0.20 : 0.10),
                            Color.clear,
                            Color.black.opacity(isPoppedOut ? 0.10 : 0.25)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    // Controls Overlay when Album is Taken Out of the Drawer
                    if isPoppedOut {
                        VStack {
                            Spacer()
                            HStack(spacing: 16) {
                                Button {
                                    player.togglePlayPause()
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(Color.black.opacity(0.70))
                                            .frame(width: 54, height: 54)
                                        Image(systemName: (isCurrentlyPlayingThisAlbum && player.isPlaying) ? "pause.fill" : "play.fill")
                                            .font(.system(size: 22, weight: .bold))
                                            .foregroundColor(.white)
                                            .offset(x: (isCurrentlyPlayingThisAlbum && player.isPlaying) ? 0 : 2)
                                    }
                                }
                                .buttonStyle(.plain)

                                Button {
                                    onSelectDetail()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "list.bullet")
                                        Text("Tracks")
                                    }
                                    .font(.system(size: 13, weight: .semibold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Color.black.opacity(0.70))
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.bottom, 22)
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        }
                    } else if isHovered {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.55))
                                .frame(width: 48, height: 48)
                            Image(systemName: (isCurrentlyPlayingThisAlbum && player.isPlaying) ? "pause.fill" : "play.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .offset(x: (isCurrentlyPlayingThisAlbum && player.isPlaying) ? 0 : 2)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: 480, height: isPoppedOut ? 280 : 220)
                .clipped()
                .overlay(
                    // Clean parallel side sleeve borders
                    HStack {
                        Rectangle().fill(Color.white.opacity(0.20)).frame(width: 1)
                        Spacer()
                        Rectangle().fill(Color.black.opacity(0.30)).frame(width: 1)
                    }
                )
            }
            .frame(width: 480)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .shadow(
                color: Color.black.opacity(isPoppedOut ? 0.60 : (isHovered ? 0.35 : 0.18)),
                radius: isPoppedOut ? 28 : (isHovered ? 10 : 4),
                x: 0,
                y: isPoppedOut ? 16 : (isHovered ? 5 : 2)
            )
        }
        // When clicked, the album slides UP out of the drawer!
        .offset(y: isPoppedOut ? -110 : (isHovered ? -5 : 0))
        .frame(width: 520, height: 62)
        .zIndex(isPoppedOut ? 999 : 0)
        .animation(.spring(response: 0.38, dampingFraction: 0.72), value: isPoppedOut)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            onTogglePopOut()
        }
        .contextMenu {
            Button("Play Album") {
                if let first = album.songs.first {
                    player.play(song: first, inContext: album.songs)
                }
            }
            Button("Shuffle Album") {
                var shuffled = album.songs
                shuffled.shuffle()
                if let first = shuffled.first {
                    player.isShuffleEnabled = true
                    player.play(song: first, inContext: album.songs)
                }
            }
            Divider()
            Button("View Album Details") {
                onSelectDetail()
            }
        }
        .task(id: album.id) {
            await loadArtworkAndSpineColor()
        }
    }

    private func loadArtworkAndSpineColor() async {
        let initialColors = ArtworkLoader.shared.spineColors(for: album.representativeSong, fallbackID: album.id)
        self.spineBgColor = initialColors.bg
        self.spineTextColor = initialColors.text

        guard let song = album.representativeSong else { return }

        if let cached = ArtworkLoader.shared.cachedImage(for: song) {
            self.artworkImage = cached
            let extracted = ArtworkLoader.shared.extractSpineColor(from: cached)
            self.spineBgColor = extracted.bg
            self.spineTextColor = extracted.text
            return
        }

        if let loaded = await ArtworkLoader.shared.loadArtwork(for: song) {
            self.artworkImage = loaded
            let extracted = ArtworkLoader.shared.extractSpineColor(from: loaded)
            self.spineBgColor = extracted.bg
            self.spineTextColor = extracted.text
        }
    }
}
