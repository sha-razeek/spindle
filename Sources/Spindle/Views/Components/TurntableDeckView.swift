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
    @State private var isHoveringDeck: Bool = false

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

    private var backdrop: BackdropPalette {
        if let song = currentSong {
            return ArtworkLoader.shared.backdropPalette(for: song, fallbackID: album?.id ?? "turntable")
        }
        return ArtworkLoader.shared.defaultBackdropPalette
    }

    public var body: some View {
        VStack(spacing: 20) {
            // MARK: - 1. Turntable Plinth / Deck (Matching reference image)
            ZStack {
                // Turntable Plinth Surface (Rounded rectangle with warm tone / dynamic palette)
                plinthBackground

                // Plinth Top Elements: Sleeve + Vinyl + Tonearm
                HStack(spacing: 0) {
                    Spacer(minLength: 24)

                    ZStack(alignment: .leading) {
                        // 1. Vinyl Record (Sliding out to the right of the sleeve)
                        VinylDiscView(
                            artwork: artworkImage,
                            isPlaying: isPlaying,
                            size: 260,
                            isBlackVinyl: true
                        )
                        .offset(x: 125, y: 0)
                        .contentShape(Circle())
                        .onHover { h in isHoveringVinyl = h }
                        .onTapGesture { onTogglePlay() }

                        // 2. Front Album Sleeve / Jacket
                        albumJacketView
                            .contentShape(Rectangle())
                            .onHover { h in isHoveringJacket = h }
                            .onTapGesture { onTogglePlay() }

                        // 3. Tonearm (Pivots over the record from the right)
                        TonearmView(
                            isPlaying: isPlaying,
                            size: 275
                        )
                        .offset(x: 295, y: -22)
                        .allowsHitTesting(false) // Let clicks through to record/deck
                    }
                    .frame(width: 440, height: 280)

                    Spacer(minLength: 24)
                }
            }
            .frame(maxWidth: 580, minHeight: 330, maxHeight: 360)
            .padding(.horizontal, 16)

            // MARK: - 2. Album Metadata & Interactive Controls
            if let album = album {
                VStack(spacing: 12) {
                    // Album Title & Artist
                    VStack(spacing: 4) {
                        HStack(spacing: 6) {
                            if isPlaying {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.accentColor)
                            }
                            Text("NOW ON DECK")
                                .font(.system(size: 10.5, weight: .bold))
                                .tracking(1)
                                .foregroundColor(.white.opacity(0.7))
                        }

                        Text(album.title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(album.artistName)
                            .font(.system(size: 14, weight: .medium))
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
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.65))
                    }

                    // Transport Buttons
                    HStack(spacing: 16) {
                        // Previous Track
                        Button {
                            player.previousTrack()
                        } label: {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.85))
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(.plain)
                        .disabled(!player.hasPrevious)

                        // Play / Pause Circle
                        Button {
                            onTogglePlay()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 46, height: 46)
                                    .shadow(color: Color.accentColor.opacity(0.4), radius: 8, x: 0, y: 3)
                                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .offset(x: isPlaying ? 0 : 1.5)
                            }
                        }
                        .buttonStyle(.plain)

                        // Next Track
                        Button {
                            player.nextTrack()
                        } label: {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.85))
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(.plain)
                        .disabled(!player.hasNext)

                        Divider()
                            .frame(height: 20)
                            .background(Color.white.opacity(0.2))

                        // View Tracklist / Album Details Button
                        Button {
                            onSelectDetail()
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "list.bullet")
                                Text("Tracklist")
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.15))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else {
                VStack(spacing: 8) {
                    Text("Select an album from the drawer")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .task(id: album?.id) {
            await loadArtwork()
        }
    }

    // MARK: - Plinth Background Surface
    private var plinthBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        backdrop.primary.opacity(0.92),
                        backdrop.mid.opacity(0.85),
                        backdrop.bottom.opacity(0.92)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                // 3D tactile deck rim bevel
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.35),
                                Color.white.opacity(0.10),
                                Color.black.opacity(0.35)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: Color.black.opacity(0.45), radius: 24, x: 0, y: 12)
            .animation(.easeInOut(duration: 0.6), value: album?.id)
    }

    // MARK: - Album Jacket Sleeve
    private var albumJacketView: some View {
        ZStack(alignment: .center) {
            // Artwork Image
            if let img = artworkImage {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color(white: 0.2))
                Image(systemName: "music.note")
                    .font(.system(size: 48))
                    .foregroundColor(.white.opacity(0.5))
            }

            // Lighting sheen across sleeve
            LinearGradient(
                colors: [
                    Color.white.opacity(0.16),
                    Color.clear,
                    Color.black.opacity(0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Hover play pill
            if isHoveringJacket {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.65))
                        .frame(width: 50, height: 50)
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .offset(x: isPlaying ? 0 : 2)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 250, height: 250)
        .clipShape(SleeveWithNotchShape(hasNotch: true, cornerRadius: 6, notchDepth: 30, notchHeight: 56))
        .overlay(
            SleeveWithNotchShape(hasNotch: true, cornerRadius: 6, notchDepth: 30, notchHeight: 56)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.55), radius: 16, x: -4, y: 8)
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
