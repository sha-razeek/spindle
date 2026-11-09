import SwiftUI
import AppKit

public struct NowPlayingBar: View {
    @ObservedObject var player: AudioPlayer
    var onExpand: (() -> Void)? = nil

    @State private var isDraggingScrubber: Bool = false
    @State private var scrubTime: TimeInterval = 0
    @State private var showQueuePopover: Bool = false
    @State private var isHoveringThumbnail: Bool = false
    @State private var isHoveringScrubber: Bool = false

    // Volume control expansion state (matching Apple Music Image 1 vs Image 2)
    @State private var isHoveringVolume: Bool = false
    @State private var isDraggingVolume: Bool = false
    @State private var isVolumePinned: Bool = false

    public init(player: AudioPlayer, onExpand: (() -> Void)? = nil) {
        self.player = player
        self.onExpand = onExpand
    }

    private var isVolumeExpanded: Bool {
        isHoveringVolume || isDraggingVolume || isVolumePinned
    }

    public var body: some View {
        HStack(spacing: 12) {
            // MARK: - Left: Transport Controls (Shuffle, Prev, Play/Pause, Next, Repeat)
            HStack(spacing: 11) {
                // Shuffle
                Button {
                    player.isShuffleEnabled.toggle()
                } label: {
                    Image(systemName: "shuffle")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(player.isShuffleEnabled ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)
                .help(player.isShuffleEnabled ? "Shuffle On" : "Shuffle Off")

                // Previous Track
                Button {
                    player.previousTrack()
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 12.5))
                        .foregroundColor(.primary.opacity(0.85))
                }
                .buttonStyle(.plain)
                .disabled(!player.hasPrevious)
                .help("Previous Track")

                // Play / Pause
                Button {
                    player.togglePlayPause()
                } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 14.5, weight: .bold))
                        .foregroundColor(.primary)
                        .frame(width: 22, height: 22)
                        .offset(x: player.isPlaying ? 0 : 1)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.space, modifiers: [])
                .help(player.isPlaying ? "Pause" : "Play")

                // Next Track
                Button {
                    player.nextTrack()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 12.5))
                        .foregroundColor(.primary.opacity(0.85))
                }
                .buttonStyle(.plain)
                .disabled(!player.hasNext)
                .help("Next Track")

                // Repeat Mode
                Button {
                    player.cycleRepeatMode()
                } label: {
                    Image(systemName: player.repeatMode.iconName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(player.repeatMode != .off ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)
                .help(player.repeatMode.rawValue)
            }
            .frame(width: 115, alignment: .leading)

            Spacer(minLength: 4)

            // MARK: - Center: Artwork, Track Info & Continuous Scrubber (Apple Music layout)
            HStack(spacing: 9) {
                if let song = player.currentSong {
                    // Artwork Thumbnail with hover expand hint
                    ZStack {
                        ArtworkView(song: song, cornerRadius: 5, size: 34)
                            .shadow(color: Color.black.opacity(0.18), radius: 3, x: 0, y: 1.5)

                        if isHoveringThumbnail {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.black.opacity(0.35))
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 9.5, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 34, height: 34)
                    .contentShape(Rectangle())
                    .onHover { isHoveringThumbnail = $0 }
                    .onTapGesture {
                        onExpand?()
                    }
                    .help("Click to expand Now Playing view")

                    VStack(alignment: .leading, spacing: 2) {
                        // Title
                        Text(song.title)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .contentShape(Rectangle())
                            .onTapGesture { onExpand?() }

                        // Artist
                        Text(song.artistName)
                            .font(.system(size: 10.5, weight: .regular))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .contentShape(Rectangle())
                            .onTapGesture { onExpand?() }

                        // Sleek Progress Scrubber running underneath (matching Image 1 & 2)
                        GeometryReader { geo in
                            let totalWidth = geo.size.width
                            let progress = scrubberProgress

                            ZStack(alignment: .leading) {
                                // Background track
                                Capsule()
                                    .fill(Color.primary.opacity(0.18))
                                    .frame(height: isHoveringScrubber || isDraggingScrubber ? 3.5 : 2.5)

                                // Filled track
                                Capsule()
                                    .fill(Color.primary.opacity(0.85))
                                    .frame(width: max(0, totalWidth * CGFloat(progress)), height: isHoveringScrubber || isDraggingScrubber ? 3.5 : 2.5)
                            }
                            .frame(maxHeight: .infinity, alignment: .center)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        isDraggingScrubber = true
                                        let ratio = max(0.0, min(1.0, Double(value.location.x / totalWidth)))
                                        scrubTime = ratio * max(1.0, player.duration)
                                    }
                                    .onEnded { value in
                                        let ratio = max(0.0, min(1.0, Double(value.location.x / totalWidth)))
                                        let target = ratio * max(1.0, player.duration)
                                        player.seek(to: target)
                                        isDraggingScrubber = false
                                    }
                            )
                        }
                        .frame(height: 7)
                        .onHover { isHoveringScrubber = $0 }
                        .help(isDraggingScrubber ? formatSeconds(scrubTime) : "\(player.formattedCurrentTime) / \(formatSeconds(player.duration))")
                    }
                    .frame(maxWidth: 240, alignment: .leading)
                } else {
                    // Empty / Not Playing state
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(Color.secondary.opacity(0.12))
                            .frame(width: 34, height: 34)
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary.opacity(0.7))
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Not Playing")
                                .font(.system(size: 11.5, weight: .semibold))
                                .foregroundColor(.secondary)
                            Text("Select a track to start listening")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)

            Spacer(minLength: 4)

            // MARK: - Right: Options, Lyrics, Queue & Volume Control Capsule (Image 1 & 2)
            HStack(spacing: 8) {
                // More Options (...) button
                Menu {
                    if let song = player.currentSong {
                        Text(song.title).font(.headline)
                        Text(song.artistName).font(.subheadline)
                        Divider()
                        if let url = song.location {
                            Button("Show Original in Finder") {
                                NSWorkspace.shared.activateFileViewerSelecting([url])
                            }
                        }
                        Button("Copy Song Name") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString("\(song.artistName) - \(song.title)", forType: .string)
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary.opacity(0.85))
                        .frame(width: 22, height: 22)
                        .contentShape(Circle())
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .frame(width: 22, height: 22)
                .help("More Options")

                if isVolumeExpanded {
                    // MARK: - Apple Music Volume Capsule (Image 1)
                    HStack(spacing: 8) {
                        // Thick rounded volume slider bar
                        GeometryReader { geo in
                            let width = geo.size.width
                            let vol = player.isMuted ? 0.0 : Double(player.volume)

                            ZStack(alignment: .leading) {
                                // Unfilled subtle grey track
                                Capsule()
                                    .fill(Color.primary.opacity(0.20))
                                    .frame(height: 6)

                                // Filled solid black/primary track
                                Capsule()
                                    .fill(Color.primary)
                                    .frame(width: max(0, width * CGFloat(vol)), height: 6)
                            }
                            .frame(maxHeight: .infinity, alignment: .center)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { val in
                                        isDraggingVolume = true
                                        if player.isMuted { player.isMuted = false }
                                        let newVol = Float(max(0.0, min(1.0, val.location.x / width)))
                                        player.volume = newVol
                                    }
                                    .onEnded { _ in
                                        isDraggingVolume = false
                                    }
                            )
                        }
                        .frame(width: 64, height: 16)

                        // Speaker Icon Button
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                player.isMuted.toggle()
                            }
                        } label: {
                            Image(systemName: volumeIcon)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.primary)
                                .frame(width: 18, height: 18)
                        }
                        .buttonStyle(.plain)
                        .help(player.isMuted ? "Unmute" : "Mute")
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.primary.opacity(0.08))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .onHover { hovering in
                        isHoveringVolume = hovering
                    }
                } else {
                    // MARK: - Idle Icons: Queue & Speaker Icon (Image 2)
                    HStack(spacing: 8) {
                        // Up Next Queue button
                        Button {
                            showQueuePopover.toggle()
                        } label: {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 12.5, weight: .medium))
                                .foregroundColor(showQueuePopover ? .accentColor : .secondary)
                                .frame(width: 20, height: 20)
                        }
                        .buttonStyle(.plain)
                        .help("Up Next Queue")
                        .popover(isPresented: $showQueuePopover, arrowEdge: .top) {
                            QueuePopoverView(player: player)
                        }

                        // Speaker button (hovering expands the volume pill)
                        Button {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                                isVolumePinned.toggle()
                            }
                        } label: {
                            Image(systemName: volumeIcon)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.primary)
                                .frame(width: 22, height: 22)
                        }
                        .buttonStyle(.plain)
                        .help("Volume (Click to toggle slider, Hover to expand)")
                        .onHover { hovering in
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                                isHoveringVolume = hovering
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .frame(width: isVolumeExpanded ? 140 : 85, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .frame(maxWidth: 620)
        .frame(height: 48)
        // MARK: - Apple Liquid Glass Panel Styling (Frosted glass capsule, specular sheen, drop shadow)
        .background(
            ZStack {
                // 1. Frosted ultra thin material blurring content behind
                Capsule()
                    .fill(.ultraThinMaterial)

                // 2. Liquid glass specular light gradient
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.28),
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.16)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // 3. Crisp specular glass perimeter highlight stroke
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.60),
                                Color.white.opacity(0.18),
                                Color.white.opacity(0.38)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.0
                    )
            }
        )
        // Ambient glass elevation shadow
        .shadow(color: Color.black.opacity(0.20), radius: 18, x: 0, y: 6)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 1.5)
    }

    private var scrubberProgress: Double {
        let duration = max(1.0, player.duration)
        let current = isDraggingScrubber ? scrubTime : player.currentTime
        return min(1.0, max(0.0, current / duration))
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
}
