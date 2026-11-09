import SwiftUI
import AppKit

public struct TurntableDeckView: View {
    let album: Album?
    let isPlaying: Bool
    @ObservedObject var player: AudioPlayer
    var onTogglePlay: () -> Void
    var onSelectDetail: () -> Void
    var onEject: (() -> Void)? = nil

    @State private var artworkImage: NSImage?
    @State private var isHoveringJacket: Bool = false
    @State private var isHoveringVinyl: Bool = false

    public init(
        album: Album?,
        isPlaying: Bool,
        player: AudioPlayer,
        onTogglePlay: @escaping () -> Void,
        onSelectDetail: @escaping () -> Void,
        onEject: (() -> Void)? = nil
    ) {
        self.album = album
        self.isPlaying = isPlaying
        self.player = player
        self.onTogglePlay = onTogglePlay
        self.onSelectDetail = onSelectDetail
        self.onEject = onEject
    }

    private var currentSong: Song? {
        player.currentSong ?? album?.representativeSong
    }

    public var body: some View {
        GeometryReader { geo in
            let availableH = geo.size.height
            let availableW = geo.size.width

            // Much bigger scale: ~350pt to ~430pt depending on available room
            let sleeveSize: CGFloat = min(max(340, availableH - 220), min(430, availableW - 280))
            let discSlideOffset: CGFloat = sleeveSize * 0.52
            let tonearmScale: CGFloat = sleeveSize * 0.90

            VStack(spacing: 24) {
                Spacer(minLength: 12)

                if let album = album {
                    // MARK: - Loaded Turntable Deck: Large Album + White Vinyl Disc + Tonearm (No container rectangle)
                    ZStack(alignment: .leading) {
                        // 1. Pearlescent White Vinyl Disc (Sliding out to the right)
                        VinylDiscView(
                            artwork: artworkImage,
                            isPlaying: isPlaying,
                            size: sleeveSize,
                            isBlackVinyl: false // White vinyl disc as requested
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

                        // 3. Precision Audiophile Tonearm (Placed away from disc, moves to disc when playing)
                        let tHeight = sleeveSize * 0.90
                        let tWidth = tHeight * (178.0 / 759.0)
                        TonearmView(
                            isPlaying: isPlaying,
                            size: tHeight
                        )
                        .offset(
                            x: discSlideOffset + sleeveSize * 0.86 - tWidth * 0.3764,
                            y: sleeveSize * 0.08 - tHeight * 0.2200
                        )
                        .allowsHitTesting(false)
                    }
                    .frame(width: sleeveSize + discSlideOffset + 120, height: sleeveSize)
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))

                    // MARK: - Album Details & Playback Transport Controls
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
                        HStack(spacing: 16) {
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

                            // Eject / Clear Platter Button
                            if let onEject = onEject {
                                Button {
                                    onEject()
                                } label: {
                                    Image(systemName: "eject.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.75))
                                        .padding(7)
                                        .background(Circle().fill(.ultraThinMaterial))
                                }
                                .buttonStyle(.plain)
                                .help("Eject Album / Return to Empty Tray")
                            }
                        }
                        .padding(.top, 4)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                } else {
                    // MARK: - Empty Disk Tray (When a song isn't selected)
                    emptyDiskTrayView(size: sleeveSize, tonearmScale: tonearmScale)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }

                Spacer(minLength: 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .task(id: album?.id) {
            await loadArtwork()
        }
    }

    // MARK: - Empty Disk Tray (Turntable Platter with Tonearm resting away)
    @ViewBuilder
    private func emptyDiskTrayView(size: CGFloat, tonearmScale: CGFloat) -> some View {
        VStack(spacing: 28) {
            ZStack(alignment: .leading) {
                // Circular Turntable Platter (Empty Mat)
                ZStack {
                    // Platter Drop Shadow
                    Circle()
                        .fill(Color.clear)
                        .frame(width: size, height: size)
                        .shadow(color: Color.black.opacity(0.50), radius: 26, x: 4, y: 12)

                    // Brushed Aluminum Platter Bevel Rim with Stroboscope Timing Rings
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(white: 0.22),
                                    Color(white: 0.14),
                                    Color(white: 0.08)
                                ],
                                center: .center,
                                startRadius: size * 0.20,
                                endRadius: size * 0.50
                            )
                        )
                        .frame(width: size, height: size)
                        .overlay(
                            // Outer aluminum rim
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color(white: 0.85), Color(white: 0.45), Color(white: 0.80)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 3
                                )
                        )

                    // Rubber Slipmat Traction Rings
                    ForEach([0.90, 0.78, 0.65, 0.52, 0.38, 0.24], id: \.self) { fraction in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.08), Color.black.opacity(0.60)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                            .frame(width: size * fraction, height: size * fraction)
                    }

                    // Center Spindle Pin
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color(white: 0.98), Color(white: 0.65), Color(white: 0.35)],
                                    center: .center,
                                    startRadius: 1,
                                    endRadius: 7
                                )
                            )
                            .frame(width: 14, height: 14)
                            .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 1))
                            .shadow(color: Color.black.opacity(0.4), radius: 3, x: 0, y: 2)
                    }
                }
                .frame(width: size, height: size)

                // Tonearm resting away on its armrest post outside the platter
                let tHeight = size * 0.90
                let tWidth = tHeight * (178.0 / 759.0)
                TonearmView(
                    isPlaying: false,
                    size: tHeight
                )
                .offset(
                    x: size * 0.86 - tWidth * 0.3764,
                    y: size * 0.08 - tHeight * 0.2200
                )
                .allowsHitTesting(false)
            }
            .frame(width: size + 100, height: size)

            // Welcoming subtitle
            VStack(spacing: 6) {
                HStack(spacing: 7) {
                    Image(systemName: "record.circle")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.accentColor)
                    Text("TURNTABLE READY")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1.4)
                        .foregroundColor(.white.opacity(0.85))
                }

                Text("Select an LP from the crate on the right to start playing")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.60))
            }
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
