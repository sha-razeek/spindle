import SwiftUI
import AppKit

public struct AlbumSlabView: View {
    let album: Album
    let isPoppedOut: Bool
    let isOtherAlbumPoppedOut: Bool
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
        isOtherAlbumPoppedOut: Bool = false,
        player: AudioPlayer,
        onTogglePopOut: @escaping () -> Void,
        onSelectDetail: @escaping () -> Void
    ) {
        self.album = album
        self.isPoppedOut = isPoppedOut
        self.isOtherAlbumPoppedOut = isOtherAlbumPoppedOut
        self.player = player
        self.onTogglePopOut = onTogglePopOut
        self.onSelectDetail = onSelectDetail
    }

    public var body: some View {
        let isDiscPoppedOut = isPoppedOut && isCurrentlyPlayingThisAlbum

        ZStack(alignment: .top) {
            // MARK: - 1. Spinning White Vinyl Record (slides out to the right only on play)
            VinylDiscView(
                artwork: artworkImage,
                isPlaying: isCurrentlyPlayingThisAlbum && player.isPlaying,
                size: 470
            )
            .position(
                x: isDiscPoppedOut ? 540 : 390,
                y: isDiscPoppedOut ? 266 : 160
            )
            .opacity(isDiscPoppedOut ? 1.0 : 0.0)
            .animation(.spring(response: 0.40, dampingFraction: 0.75), value: isDiscPoppedOut)

            // MARK: - 2. Front Album Jacket
            VStack(spacing: 0) {
                // Top Spine Edge (Clean, distinct, always visible)
                HStack(spacing: 8) {
                    if isCurrentlyPlayingThisAlbum && player.isPlaying {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(spineTextColor)
                            .padding(.trailing, 2)
                    }

                    // Bold Album Title
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
                .frame(width: 520, height: 32)
                .background(spineBgColor)
                .overlay(
                    // 3D tactile bevel edges
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.white.opacity(0.55))
                            .frame(height: 1.5)
                        Spacer()
                        Rectangle()
                            .fill(Color.black.opacity(0.40))
                            .frame(height: 1.5)
                    }
                )
                .shadow(
                    color: Color.black.opacity(isPoppedOut ? 0.45 : 0.25),
                    radius: isPoppedOut ? 10 : 4,
                    x: 0,
                    y: isPoppedOut ? 4 : 2
                )
                .zIndex(10)

                // Album Artwork Jacket
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

                    // Gentle lighting sheen
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isPoppedOut ? 0.20 : 0.08),
                            Color.clear,
                            Color.black.opacity(isPoppedOut ? 0.10 : 0.40)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    // Overlay Controls when Popped Out
                    if isPoppedOut {
                        VStack {
                            Spacer()
                            HStack(spacing: 16) {
                                Button {
                                    player.togglePlayPause()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: (isCurrentlyPlayingThisAlbum && player.isPlaying) ? "pause.fill" : "play.fill")
                                            .font(.system(size: 15, weight: .bold))
                                        Text((isCurrentlyPlayingThisAlbum && player.isPlaying) ? "Pause" : "Play")
                                            .font(.system(size: 13, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 9)
                                    .background(
                                        Capsule()
                                            .fill(Color.black.opacity(0.75))
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)

                                Button {
                                    onSelectDetail()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "list.bullet")
                                        Text("View Tracks")
                                    }
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 9)
                                    .background(
                                        Capsule()
                                            .fill(Color.black.opacity(0.75))
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.bottom, 18)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
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
                .frame(width: 520, height: isPoppedOut ? 500 : 260)
                .clipped()
                .overlay(
                    // Clean sleeve side borders
                    HStack {
                        Rectangle().fill(Color.white.opacity(0.20)).frame(width: 1)
                        Spacer()
                        Rectangle().fill(Color.black.opacity(0.30)).frame(width: 1)
                    }
                )
            }
            .frame(width: 520)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .rotation3DEffect(
                .degrees(isPoppedOut ? 0 : -28),
                axis: (x: 1, y: 0, z: 0),
                anchor: .top,
                perspective: 0.35
            )
            .shadow(
                color: Color.black.opacity(isPoppedOut ? 0.65 : (isOtherAlbumPoppedOut ? 0.15 : (isHovered ? 0.38 : 0.22))),
                radius: isPoppedOut ? 32 : (isOtherAlbumPoppedOut ? 3 : (isHovered ? 12 : 5)),
                x: 0,
                y: isPoppedOut ? 18 : (isHovered ? 6 : 3)
            )
        }
        // Center the combined Jacket + White LP Disc unit horizontally
        .offset(x: isDiscPoppedOut ? -62 : 0)
        .animation(.spring(response: 0.40, dampingFraction: 0.75), value: isDiscPoppedOut)
        // Elegant separation margin above & below the selected album to part the stack
        .padding(.vertical, isPoppedOut ? 22 : 0)
        // Expand the row slot when popped out so the whole cover, white vinyl disc, and controls are visible!
        .frame(width: 780, height: isPoppedOut ? 614 : 96, alignment: .top)
        .offset(y: (isHovered && !isPoppedOut) ? -4 : 0)
        // Non-selected albums gently recede and dim to highlight the centered selection
        .opacity(isOtherAlbumPoppedOut ? 0.65 : 1.0)
        .scaleEffect(isOtherAlbumPoppedOut ? 0.96 : 1.0)
        .zIndex(isPoppedOut ? 999 : 0)
        .animation(.spring(response: 0.42, dampingFraction: 0.80), value: isPoppedOut)
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: isOtherAlbumPoppedOut)
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
