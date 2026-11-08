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
        ZStack(alignment: .top) {
            // MARK: - 3D Slab Visual Assembly
            VStack(spacing: 0) {
                // MARK: - 1. Front Spine Area (at the TOP of each album!)
                HStack(spacing: 8) {
                    if isCurrentlyPlayingThisAlbum && player.isPlaying {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(spineTextColor)
                            .padding(.trailing, 2)
                    }

                    // Bold Title
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
                    // Top highlight ridge (light catching edge) and bottom shadow ridge
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
                .overlay(
                    // Side 3D thickness hints
                    HStack {
                        Rectangle().fill(Color.white.opacity(0.20)).frame(width: 1)
                        Spacer()
                        Rectangle().fill(Color.black.opacity(0.35)).frame(width: 1)
                    }
                )
                .shadow(
                    color: Color.black.opacity(isPoppedOut ? 0.6 : 0.35),
                    radius: isPoppedOut ? 12 : 5,
                    x: 0,
                    y: isPoppedOut ? 6 : 3
                )
                .zIndex(10)

                // MARK: - 2. Tilted Album Cover Surface (Extends downward from the spine)
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
                            .font(.system(size: isPoppedOut ? 72 : 56))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    // Studio Lighting Overlay (specular sheen near spine, subtle falloff below)
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isPoppedOut ? 0.28 : (isHovered ? 0.22 : 0.12)),
                            Color.clear,
                            Color.black.opacity(isPoppedOut ? 0.15 : 0.35)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    // Controls Overlay when Popped Out or Hovered
                    if isPoppedOut {
                        VStack {
                            Spacer()
                            HStack(spacing: 16) {
                                Button {
                                    player.togglePlayPause()
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(Color.black.opacity(0.65))
                                            .frame(width: 58, height: 58)
                                        Image(systemName: (isCurrentlyPlayingThisAlbum && player.isPlaying) ? "pause.fill" : "play.fill")
                                            .font(.system(size: 24, weight: .bold))
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
                                    .background(Color.black.opacity(0.65))
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.bottom, 24)
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        }
                    } else if isHovered {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.55))
                                .frame(width: 50, height: 50)
                            Image(systemName: (isCurrentlyPlayingThisAlbum && player.isPlaying) ? "pause.fill" : "play.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .offset(x: (isCurrentlyPlayingThisAlbum && player.isPlaying) ? 0 : 2)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: 480, height: isPoppedOut ? 320 : 240)
                .clipped()
                .overlay(
                    // Side 3D edge lines
                    HStack {
                        Rectangle().fill(Color.white.opacity(0.25)).frame(width: 1.5)
                        Spacer()
                        Rectangle().fill(Color.black.opacity(0.35)).frame(width: 1.5)
                    }
                )
                // 3D Perspective Rotation anchored at the spine connection (.top)
                .rotation3DEffect(
                    .degrees(isPoppedOut ? 18 : (isHovered ? 45 : 52)),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: .top,
                    perspective: 0.45
                )
                .allowsHitTesting(isPoppedOut)
            }
            .offset(y: isPoppedOut ? -35 : (isHovered ? -4 : 0))
            .scaleEffect(isPoppedOut ? 1.08 : 1.0)
            .shadow(
                color: Color.black.opacity(isPoppedOut ? 0.65 : (isHovered ? 0.35 : 0.18)),
                radius: isPoppedOut ? 32 : (isHovered ? 12 : 5),
                x: 0,
                y: isPoppedOut ? 22 : (isHovered ? 6 : 2)
            )
        }
        .frame(width: 520, height: 95)
        .zIndex(isPoppedOut ? 999 : 0)
        .animation(.spring(response: 0.35, dampingFraction: 0.72), value: isPoppedOut)
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
        // Initial color from cache or palette
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
