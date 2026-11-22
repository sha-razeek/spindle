import SwiftUI
import AppKit

public struct MiniPlayerView: View {
    @ObservedObject var player: AudioPlayer
    var onExpand: () -> Void

    @ObservedObject private var progress: PlaybackProgress
    @State private var artworkImage: NSImage?
    @State private var isHoveringJacket: Bool = false
    @State private var isDraggingScrubber: Bool = false
    @State private var scrubTime: TimeInterval = 0

    public init(player: AudioPlayer, onExpand: @escaping () -> Void) {
        self.player = player
        self.onExpand = onExpand
        self._progress = ObservedObject(wrappedValue: player.progress)
    }

    private var currentSong: Song? {
        player.currentSong
    }

    private var currentPalette: BackdropPalette {
        if let song = currentSong {
            return ArtworkLoader.shared.backdropPalette(for: song, fallbackID: song.id)
        }
        return ArtworkLoader.shared.defaultBackdropPalette
    }

    public var body: some View {
        ZStack {
            // MARK: - 1. Liquid Glass Translucent Window Background
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)

            // Dynamic ambient lighting pool matching album art
            RadialGradient(
                colors: [
                    currentPalette.primary.opacity(0.35),
                    currentPalette.mid.opacity(0.12),
                    Color.clear
                ],
                center: .init(x: 0.22, y: 0.50),
                startRadius: 20,
                endRadius: 300
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            // Specular border highlight
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.40),
                            Color.white.opacity(0.12),
                            Color.white.opacity(0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )

            // MARK: - 2. Content: Left Album + Spinning Disc, Right Title & Controls
            HStack(spacing: 16) {
                // LEFT: Smaller Album Sleeve + Sliding Vinyl Disc
                miniTurntableDeckView
                    .frame(width: 154, height: 110)

                // RIGHT: Song Title, Details, Scrubber, Transport & Expand Button
                detailsSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .frame(width: 480, height: 160)
        .task(id: player.currentSong?.id) {
            await loadArtwork()
        }
    }

    // MARK: - Left Deck (Smaller Album Sleeve + Sliding Vinyl Disc)
    private var miniTurntableDeckView: some View {
        let sleeveSize: CGFloat = 104
        let discSize: CGFloat = 98
        let discOffset: CGFloat = 44

        return ZStack(alignment: .leading) {
            // White Vinyl Disc sliding out from the sleeve and rotating during playback
            VinylDiscView(
                artwork: artworkImage,
                isPlaying: player.isPlaying,
                size: discSize,
                isBlackVinyl: false
            )
            .offset(x: discOffset, y: 0)
            .contentShape(Circle())
            .onTapGesture {
                player.togglePlayPause()
            }

            // Front Album Sleeve
            ZStack(alignment: .center) {
                if let img = artworkImage {
                    Image(nsImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    LinearGradient(
                        colors: [Color.pink.opacity(0.8), Color.purple.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "music.note")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.85))
                }

                // Sleek hover overlay to quickly play/pause
                if isHoveringJacket {
                    Circle()
                        .fill(Color.black.opacity(0.55))
                        .frame(width: 34, height: 34)
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .offset(x: player.isPlaying ? 0 : 1)
                }
            }
            .frame(width: sleeveSize, height: sleeveSize)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.white.opacity(0.20), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.40), radius: 8, x: 2, y: 4)
            .contentShape(Rectangle())
            .onHover { isHoveringJacket = $0 }
            .onTapGesture {
                player.togglePlayPause()
            }
        }
    }

    // MARK: - Right Details Section
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Top Bar: Badge + Expand Button
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "record.circle")
                        .font(.system(size: 9, weight: .bold))
                    Text("SPINDLE MINI")
                        .font(.system(size: 8.5, weight: .bold))
                        .tracking(0.8)
                }
                .foregroundColor(.white.opacity(0.75))
                .padding(.horizontal, 6)
                .padding(.vertical, 2.5)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.10))
                )

                Spacer()

                // Button that will expand to the larger player
                Button {
                    onExpand()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 9.5, weight: .bold))
                    }
                    .foregroundColor(.white.opacity(0.88))
                    .frame(width: 22, height: 22)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.12))
                            .overlay(Circle().stroke(Color.white.opacity(0.20), lineWidth: 0.8))
                    )
                    .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Expand to Full Player")
            }

            // Title & Artist
            VStack(alignment: .leading, spacing: 1.5) {
                Text(currentSong?.title ?? "Not Playing")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(currentSong?.artistName ?? "Select a track to start listening")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 2)

            // Scrubber Bar
            scrubberView

            // Bottom Transport Controls Row
            HStack(spacing: 12) {
                // Shuffle
                Button {
                    player.isShuffleEnabled.toggle()
                } label: {
                    Image(systemName: "shuffle")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundColor(player.isShuffleEnabled ? Color.accentColor : .secondary)
                }
                .buttonStyle(.plain)
                .help(player.isShuffleEnabled ? "Shuffle On" : "Shuffle Off")

                // Previous
                Button {
                    player.previousTrack()
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
                .help("Previous Track")

                // Play / Pause Button (Accent circle)
                Button {
                    player.togglePlayPause()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 28, height: 28)
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .offset(x: player.isPlaying ? 0 : 1)
                    }
                }
                .buttonStyle(.plain)
                .help(player.isPlaying ? "Pause" : "Play")

                // Next
                Button {
                    player.nextTrack()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
                .help("Next Track")

                // Repeat
                Button {
                    player.cycleRepeatMode()
                } label: {
                    Image(systemName: player.repeatMode == .one ? "repeat.1" : "repeat")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundColor(player.repeatMode != .off ? Color.accentColor : .secondary)
                }
                .buttonStyle(.plain)
                .help("Cycle Repeat Mode")

                Spacer()

                // Mini Volume Slider
                volumeControlView
            }
        }
    }

    // MARK: - Scrubber View
    private var scrubberView: some View {
        GeometryReader { geo in
            let totalW = geo.size.width
            let duration = max(1.0, progress.duration)
            let current = isDraggingScrubber ? scrubTime : progress.currentTime
            let ratio = min(1.0, max(0.0, current / duration))

            VStack(spacing: 2) {
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.15))
                        .frame(height: 3)

                    Capsule()
                        .fill(Color.primary.opacity(0.85))
                        .frame(width: max(0, totalW * CGFloat(ratio)), height: 3)
                }
                .frame(height: 6)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { val in
                            isDraggingScrubber = true
                            let r = max(0.0, min(1.0, Double(val.location.x / totalW)))
                            scrubTime = r * duration
                        }
                        .onEnded { val in
                            let r = max(0.0, min(1.0, Double(val.location.x / totalW)))
                            let target = r * duration
                            player.seek(to: target)
                            isDraggingScrubber = false
                        }
                )

                HStack {
                    Text(formatSeconds(current))
                        .font(.system(size: 8.5))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("-\(formatSeconds(max(0, duration - current)))")
                        .font(.system(size: 8.5))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(height: 18)
    }

    // MARK: - Volume Control
    private var volumeControlView: some View {
        HStack(spacing: 3) {
            Button {
                player.isMuted.toggle()
            } label: {
                Image(systemName: volumeIcon)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)

            Slider(value: Binding(
                get: { Double(player.volume) },
                set: { player.volume = Float($0) }
            ), in: 0...1)
            .frame(width: 50)
            .scaleEffect(0.72)
        }
    }

    private var volumeIcon: String {
        if player.isMuted || player.volume == 0 {
            return "speaker.slash.fill"
        } else if player.volume < 0.33 {
            return "speaker.wave.1.fill"
        } else if player.volume < 0.66 {
            return "speaker.wave.2.fill"
        } else {
            return "speaker.wave.3.fill"
        }
    }

    private func formatSeconds(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }

    private func loadArtwork() async {
        guard let song = currentSong else {
            self.artworkImage = nil
            return
        }
        if let cached = ArtworkLoader.shared.cachedThumbnail(for: song) {
            self.artworkImage = cached
            return
        }
        if let loaded = await ArtworkLoader.shared.loadThumbnail(for: song, maxPixelSize: 380) {
            guard !Task.isCancelled else { return }
            self.artworkImage = loaded
        }
    }
}
