import SwiftUI
import AppKit

public struct TurntableDeckView: View {
    let album: Album?
    let isPlaying: Bool
    @ObservedObject var player: AudioPlayer
    var onTogglePlay: () -> Void
    var onSelectDetail: () -> Void

    @State private var artworkImage: NSImage?
    @State private var isHoveringJacket: Bool = false
    @State private var isHoveringVinyl: Bool = false

    public init(
        album: Album?,
        isPlaying: Bool,
        player: AudioPlayer,
        onTogglePlay: @escaping () -> Void,
        onSelectDetail: @escaping () -> Void
    ) {
        self.album = album
        self.isPlaying = isPlaying
        self.player = player
        self.onTogglePlay = onTogglePlay
        self.onSelectDetail = onSelectDetail
    }

    private var currentSong: Song? {
        player.currentSong ?? album?.representativeSong
    }

    public var body: some View {
        GeometryReader { geo in
            // Calculate dynamic large album size based on available view dimensions
            let availableH = geo.size.height
            let availableW = geo.size.width

            // Much bigger album scale: ~360pt minimum, up to ~430pt on large screens
            let sleeveSize: CGFloat = min(max(340, availableH - 220), min(430, availableW - 280))
            let discSlideOffset: CGFloat = sleeveSize * 0.52
            let tonearmScale: CGFloat = sleeveSize * 0.90

            VStack(spacing: 24) {
                Spacer(minLength: 12)

                // MARK: - Big Album Sleeve + Spinning Vinyl + Audiophile Tonearm (No container rectangle)
                ZStack(alignment: .leading) {
                    // 1. Classic Deep Black Vinyl Disc (Sliding out to the right)
                    VinylDiscView(
                        artwork: artworkImage,
                        isPlaying: isPlaying,
                        size: sleeveSize,
                        isBlackVinyl: true
                    )
                    .offset(x: discSlideOffset, y: 0)
                    .contentShape(Circle())
                    .onHover { h in isHoveringVinyl = h }
                    .onTapGesture { onTogglePlay() }

                    // 2. Large Front Album Sleeve / Jacket
                    albumJacketView(size: sleeveSize)
                        .contentShape(Rectangle())
                        .onHover { h in isHoveringJacket = h }
                        .onTapGesture { onTogglePlay() }

                    // 3. Precision Audiophile Tonearm (Mounted on the right of the vinyl disc)
                    TonearmView(
                        isPlaying: isPlaying,
                        size: tonearmScale
                    )
                    .offset(x: discSlideOffset + sleeveSize * 0.44, y: -sleeveSize * 0.16)
                    .allowsHitTesting(false)
                }
                .frame(width: sleeveSize + discSlideOffset + 140, height: sleeveSize)

                // MARK: - Album Details & Playback Transport Controls
                if let album = album {
                    VStack(spacing: 12) {
                        // Title & Artist
                        VStack(spacing: 4) {
                            HStack(spacing: 6) {
                                if isPlaying {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.accentColor)
                                }
                                Text("NOW PLAYING")
                                    .font(.system(size: 10.5, weight: .bold))
                                    .tracking(1.2)
                                    .foregroundColor(.white.opacity(0.70))
                            }

                            Text(album.title)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)

                            Text(album.artistName)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                                .lineLimit(1)

                            HStack(spacing: 8) {
                                if album.year > 0 {
                                    Text("\(album.year)")
                                }
                                Text("•")
                                Text("\(album.trackCount) tracks")
                                Text("•")
                                Text(album.formattedDuration)
                            }
                            .font(.system(size: 11.5))
                            .foregroundColor(.white.opacity(0.60))
                        }

                        // Transport Controls
                        HStack(spacing: 18) {
                            // Previous Track
                            Button {
                                player.previousTrack()
                            } label: {
                                Image(systemName: "backward.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.85))
                                    .frame(width: 36, height: 36)
                            }
                            .buttonStyle(.plain)
                            .disabled(!player.hasPrevious)
                            .help("Previous Track")

                            // Play / Pause Button
                            Button {
                                onTogglePlay()
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color.accentColor)
                                        .frame(width: 50, height: 50)
                                        .shadow(color: Color.accentColor.opacity(0.45), radius: 10, x: 0, y: 4)
                                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                        .offset(x: isPlaying ? 0 : 1.5)
                                }
                            }
                            .buttonStyle(.plain)
                            .help(isPlaying ? "Pause" : "Play")

                            // Next Track
                            Button {
                                player.nextTrack()
                            } label: {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.85))
                                    .frame(width: 36, height: 36)
                            }
                            .buttonStyle(.plain)
                            .disabled(!player.hasNext)
                            .help("Next Track")

                            Divider()
                                .frame(height: 22)
                                .background(Color.white.opacity(0.25))

                            // Tracklist Button
                            Button {
                                onSelectDetail()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "list.bullet")
                                    Text("Tracklist")
                                }
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(
                                    Capsule()
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                            .help("View Full Album Tracklist")
                        }
                        .padding(.top, 4)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }

                Spacer(minLength: 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .task(id: album?.id) {
            await loadArtwork()
        }
    }

    // MARK: - Album Jacket Sleeve
    @ViewBuilder
    private func albumJacketView(size: CGFloat) -> some View {
        ZStack(alignment: .center) {
            // Artwork Image
            if let img = artworkImage {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color(white: 0.18))
                Image(systemName: "music.note")
                    .font(.system(size: size * 0.22))
                    .foregroundColor(.white.opacity(0.5))
            }

            // Realistic vinyl sleeve sheen & texture
            LinearGradient(
                colors: [
                    Color.white.opacity(0.18),
                    Color.clear,
                    Color.black.opacity(0.30)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Tactile spine crease highlight on left edge
            HStack {
                Rectangle()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 2)
                Spacer()
            }

            // Hover play pill
            if isHoveringJacket {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.65))
                        .frame(width: 56, height: 56)
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .offset(x: isPlaying ? 0 : 2)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: size, height: size)
        .clipShape(SleeveWithNotchShape(hasNotch: true, cornerRadius: 8, notchDepth: size * 0.12, notchHeight: size * 0.22))
        .overlay(
            SleeveWithNotchShape(hasNotch: true, cornerRadius: 8, notchDepth: size * 0.12, notchHeight: size * 0.22)
                .stroke(Color.white.opacity(0.24), lineWidth: 1.2)
        )
        .shadow(color: Color.black.opacity(0.55), radius: 24, x: -6, y: 12)
    }

    private func loadArtwork() async {
        guard let song = currentSong else {
            self.artworkImage = nil
            return
        }
        if let cached = ArtworkLoader.shared.cachedImage(for: song) {
            self.artworkImage = cached
            return
        }
        if let loaded = await ArtworkLoader.shared.loadArtwork(for: song) {
            self.artworkImage = loaded
        }
    }
}
