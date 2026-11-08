import SwiftUI
import AppKit

public struct AlbumSlabView: View {
    let album: Album
    @ObservedObject var player: AudioPlayer
    var onSelectDetail: () -> Void

    @State private var artworkImage: NSImage?
    @State private var isHovered: Bool = false

    private var isCurrentlyPlayingThisAlbum: Bool {
        guard let current = player.currentSong else { return false }
        return album.songs.contains(where: { $0.id == current.id })
    }

    private var palette: (bg: Color, text: Color) {
        defaultPalette(for: album)
    }

    public init(album: Album, player: AudioPlayer, onSelectDetail: @escaping () -> Void) {
        self.album = album
        self.player = player
        self.onSelectDetail = onSelectDetail
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            // MARK: - 3D Visual Layer (Extends upward into the slot above)
            VStack(spacing: 0) {
                // Tilted Artwork Surface
                ZStack(alignment: .center) {
                    if let image = artworkImage {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(1, contentMode: .fill)
                    } else {
                        LinearGradient(
                            colors: [palette.bg.opacity(0.8), Color.purple.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        Image(systemName: "music.note")
                            .font(.system(size: 56))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    // Studio Lighting Overlay (specular sheen on top, subtle shadow below)
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isHovered ? 0.22 : 0.12),
                            Color.clear,
                            Color.black.opacity(0.35)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    // Hover Play/Pause Indicator
                    if isHovered {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.55))
                                .frame(width: 54, height: 54)
                            Image(systemName: (isCurrentlyPlayingThisAlbum && player.isPlaying) ? "pause.fill" : "play.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                                .offset(x: (isCurrentlyPlayingThisAlbum && player.isPlaying) ? 0 : 2)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: 460, height: 260)
                .clipped()
                .overlay(
                    // Subtle side bevel edge lines
                    HStack {
                        Rectangle().fill(Color.white.opacity(0.18)).frame(width: 1)
                        Spacer()
                        Rectangle().fill(Color.black.opacity(0.25)).frame(width: 1)
                    }
                )
                // 3D Perspective Rotation (purely visual)
                .rotation3DEffect(
                    .degrees(isHovered ? -50 : -55),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: .bottom,
                    perspective: 0.45
                )
                .allowsHitTesting(false)

                // Front Spine / Shelf Edge
                HStack(spacing: 10) {
                    if isCurrentlyPlayingThisAlbum && player.isPlaying {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(palette.text)
                    }

                    Text(album.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(palette.text)
                        .lineLimit(1)

                    Text(album.artistName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(palette.text.opacity(0.85))
                        .lineLimit(1)

                    Spacer()

                    // Track count / Details button
                    Button {
                        onSelectDetail()
                    } label: {
                        HStack(spacing: 3) {
                            Text("\(album.trackCount) tracks")
                                .font(.system(size: 10, weight: .semibold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 8, weight: .bold))
                        }
                        .foregroundColor(palette.text.opacity(0.75))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(palette.text.opacity(0.12))
                        .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                    .help("View tracklist")
                }
                .padding(.horizontal, 14)
                .frame(width: 460, height: 34)
                .background(palette.bg)
                .overlay(
                    // Top bevel highlight and bottom shadow ridge
                    VStack {
                        Rectangle()
                            .fill(Color.white.opacity(0.35))
                            .frame(height: 1)
                        Spacer()
                        Rectangle()
                            .fill(Color.black.opacity(0.25))
                            .frame(height: 1)
                    }
                )
                .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 4)
            }
            .offset(y: isHovered ? -5 : 0)
        }
        // Fixed positive height slot so LazyVStack scrolling and layout is 100% stable
        .frame(width: 480, height: 85)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            // Single click starts playback immediately
            if let first = album.songs.first {
                player.play(song: first, inContext: album.songs)
            }
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
            await loadArtwork()
        }
    }

    private func loadArtwork() async {
        guard let song = album.representativeSong else { return }

        if let cached = ArtworkLoader.shared.cachedImage(for: song) {
            self.artworkImage = cached
            return
        }

        if let loaded = await ArtworkLoader.shared.loadArtwork(for: song) {
            self.artworkImage = loaded
        }
    }

    private func defaultPalette(for album: Album) -> (bg: Color, text: Color) {
        // Vibrant and pastel palette matching the user's reference photo
        let palettes: [(Color, Color)] = [
            (Color(red: 0.90, green: 0.65, blue: 0.75), .black.opacity(0.85)), // Soft Pink (Projector Monster Blues)
            (Color(red: 0.82, green: 0.85, blue: 0.87), .black.opacity(0.85)), // Clean Grey (Head Down Season)
            (Color(red: 0.30, green: 0.58, blue: 0.42), .white.opacity(0.95)), // Forest/Jade Green (Signal Ghost)
            (Color(red: 0.96, green: 0.72, blue: 0.30), .black.opacity(0.85)), // Warm Amber (See You Again)
            (Color(red: 0.95, green: 0.93, blue: 0.88), .black.opacity(0.85)), // Still Blooming White/Cream
            (Color(red: 0.93, green: 0.88, blue: 0.80), .black.opacity(0.85)), // Peel Slowly Sand
            (Color(red: 0.78, green: 0.46, blue: 0.35), .white.opacity(0.95)), // Channel After Midnight Terracotta
            (Color(red: 0.62, green: 0.80, blue: 0.90), .black.opacity(0.85)), // Skyward Proof Sky Blue
            (Color(red: 0.72, green: 0.64, blue: 0.78), .white.opacity(0.95)), // Lavender
            (Color(red: 0.88, green: 0.54, blue: 0.46), .black.opacity(0.85)), // Coral
            (Color(red: 0.55, green: 0.70, blue: 0.64), .white.opacity(0.95)), // Mint / Sage
            (Color(red: 0.85, green: 0.75, blue: 0.55), .black.opacity(0.85))  // Warm Ochre
        ]

        let hash = abs(album.id.hashValue)
        return palettes[hash % palettes.count]
    }
}
