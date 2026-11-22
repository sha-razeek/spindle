import SwiftUI
import AppKit

public struct MiniPlayerView: View {
    @ObservedObject var player: AudioPlayer
    var onExpand: () -> Void

    @ObservedObject private var progress: PlaybackProgress
    @State private var artworkImage: NSImage?
    @State private var isHoveringJacket: Bool = false
    @State private var isHoveringDisc: Bool = false
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
            // MARK: - 0. Native Window Drag Area (Clicking empty space moves the window)
            WindowDragArea()

            // MARK: - 1. Liquid Glass Translucent Window Background
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
                .allowsHitTesting(false)

            // Dynamic ambient lighting pool matching album art
            RadialGradient(
                colors: [
                    currentPalette.primary.opacity(0.36),
                    currentPalette.mid.opacity(0.14),
                    Color.clear
                ],
                center: .init(x: 0.22, y: 0.50),
                startRadius: 20,
                endRadius: 380
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .allowsHitTesting(false)

            // Specular border highlight
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.42),
                            Color.white.opacity(0.14),
                            Color.white.opacity(0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .allowsHitTesting(false)

            // MARK: - 2. Content: Left Album + Spinning Disc, Right Title & Controls
            // Generous 36pt separation between the vinyl disk and text, plus wide edge padding
            HStack(spacing: 36) {
                // LEFT: Album Sleeve + Sliding Vinyl Disc
                miniTurntableDeckView
                    .frame(width: 186, height: 140)

                // RIGHT: Song Title, Details, Progress & Streamlined Transport Controls
                detailsSection
            }
            .padding(.leading, 26)
            .padding(.trailing, 28)
            .padding(.vertical, 22)
        }
        .frame(width: 620, height: 215)
        .task(id: player.currentSong?.id) {
            await loadArtwork()
        }
    }

    // MARK: - Left Deck (Album Sleeve + Sliding Vinyl Disc)
    private var miniTurntableDeckView: some View {
        let sleeveSize: CGFloat = 138
        let discSize: CGFloat = 132
        let discOffset: CGFloat = 48

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
            .onHover { isHoveringDisc = $0 }
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
                        .font(.system(size: 38))
                        .foregroundColor(.white.opacity(0.85))
                }

                // Sleek hover overlay to quickly play/pause
                if isHoveringJacket || isHoveringDisc {
                    Circle()
                        .fill(Color.black.opacity(0.55))
                        .frame(width: 44, height: 44)
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .offset(x: player.isPlaying ? 0 : 1.5)
                }
            }
            .frame(width: sleeveSize, height: sleeveSize)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.42), radius: 12, x: 2, y: 6)
            .contentShape(Rectangle())
            .onHover { isHoveringJacket = $0 }
            .onTapGesture {
                player.togglePlayPause()
            }
        }
    }

    // MARK: - Right Details Section
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top Bar: Clean Transparent Header with Expand Button
            HStack {
                Text("SPINDLE")
                    .font(.system(size: 9.5, weight: .bold))
                    .tracking(1.4)
                    .foregroundColor(.secondary.opacity(0.70))
                    .allowsHitTesting(false) // Clicking header moves window

                Spacer()

                // Transparent expand button
                Button {
                    onExpand()
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(5)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Expand to Full Player")
            }

            Spacer(minLength: 6)

            // Title & Artist (generous spacing, allowsHitTesting false so clicking text also drags window)
            VStack(alignment: .leading, spacing: 4) {
                Text(currentSong?.title ?? "Not Playing")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(currentSong?.artistName ?? "Select a track to start listening")
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .allowsHitTesting(false)

            Spacer(minLength: 12)

            // Scrubber Bar
            scrubberView

            Spacer(minLength: 12)

            // Streamlined Controls Row: Only Previous, Next, and Volume Control
            HStack(spacing: 20) {
                // Previous Track
                Button {
                    player.previousTrack()
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary.opacity(0.9))
                }
                .buttonStyle(.plain)
                .help("Previous Track")

                // Next Track
                Button {
                    player.nextTrack()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary.opacity(0.9))
                }
                .buttonStyle(.plain)
                .help("Next Track")

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

            VStack(spacing: 3) {
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.14))
                        .frame(height: 3.5)

                    Capsule()
                        .fill(Color.primary.opacity(0.85))
                        .frame(width: max(0, totalW * CGFloat(ratio)), height: 3.5)
                }
                .frame(height: 8)
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
                        .font(.system(size: 9.5))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("-\(formatSeconds(max(0, duration - current)))")
                        .font(.system(size: 9.5))
                        .foregroundColor(.secondary)
                }
                .allowsHitTesting(false)
            }
        }
        .frame(height: 20)
    }

    // MARK: - Volume Control
    private var volumeControlView: some View {
        HStack(spacing: 6) {
            Button {
                player.isMuted.toggle()
            } label: {
                Image(systemName: volumeIcon)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)

            Slider(value: Binding(
                get: { Double(player.volume) },
                set: { player.volume = Float($0) }
            ), in: 0...1)
            .frame(width: 72)
            .scaleEffect(0.84)
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

// MARK: - Native AppKit Window Drag Area
public struct WindowDragArea: NSViewRepresentable {
    public init() {}

    public func makeNSView(context: Context) -> DraggableBackgroundNSView {
        let view = DraggableBackgroundNSView()
        return view
    }

    public func updateNSView(_ nsView: DraggableBackgroundNSView, context: Context) {}
}

public final class DraggableBackgroundNSView: NSView {
    public override var mouseDownCanMoveWindow: Bool {
        return true
    }

    public override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}
