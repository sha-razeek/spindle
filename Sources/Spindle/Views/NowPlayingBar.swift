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
    @State private var showLyrics: Bool = false

    public init(player: AudioPlayer, onExpand: (() -> Void)? = nil) {
        self.player = player
        self.onExpand = onExpand
    }

    public var body: some View {
        HStack(spacing: 12) {
            // MARK: - Left: Transport Controls (Compact Apple Music layout)
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
            .frame(width: 118, alignment: .leading)

            Spacer(minLength: 4)

            // MARK: - Center: Track Info Thumbnail & Live Scrubber
            HStack(spacing: 8) {
                if let song = player.currentSong {
                    // Artwork Thumbnail
                    ZStack {
                        ArtworkView(song: song, cornerRadius: 4, size: 32)
                            .shadow(color: Color.black.opacity(0.18), radius: 3, x: 0, y: 1.5)

                        if isHoveringThumbnail {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.black.opacity(0.40))
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 9.5, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
                    .onHover { isHoveringThumbnail = $0 }
                    .onTapGesture {
                        onExpand?()
                    }
                    .help("Click to expand Now Playing view")

                    VStack(alignment: .leading, spacing: 2) {
                        // Title & Artist
                        HStack(spacing: 5) {
                            Text(song.title)
                                .font(.system(size: 11.5, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            Text("•")
                                .font(.system(size: 8))
                                .foregroundColor(.secondary.opacity(0.6))

                            Text(song.artistName)
                                .font(.system(size: 10.5))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onExpand?()
                        }

                        // Sleek Compact Scrubber Bar
                        HStack(spacing: 6) {
                            Text(isDraggingScrubber ? formatSeconds(scrubTime) : player.formattedCurrentTime)
                                .font(.system(size: 8.5, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(width: 28, alignment: .trailing)

                            // Scrubber Slider
                            Slider(
                                value: Binding(
                                    get: { isDraggingScrubber ? scrubTime : player.currentTime },
                                    set: { newValue in
                                        scrubTime = newValue
                                    }
                                ),
                                in: 0...max(1.0, player.duration),
                                onEditingChanged: { editing in
                                    isDraggingScrubber = editing
                                    if !editing {
                                        player.seek(to: scrubTime)
                                    } else {
                                        scrubTime = player.currentTime
                                    }
                                }
                            )
                            .accentColor(.accentColor)
                            .frame(maxWidth: 160)
                            .onHover { h in isHoveringScrubber = h }

                            Text(player.formattedRemainingTime)
                                .font(.system(size: 8.5, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(width: 30, alignment: .leading)
                        }
                    }
                } else {
                    // Empty / Not Playing state
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color.secondary.opacity(0.12))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary.opacity(0.7))
                            )

                        VStack(alignment: .leading, spacing: 1) {
                            Text("Not Playing")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                            Text("Select a track to start listening")
                                .font(.system(size: 9.5))
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)

            Spacer(minLength: 4)

            // MARK: - Right: Lyrics, Queue & Volume (AirPlay button removed per user request)
            HStack(spacing: 12) {
                // Lyrics button
                Button {
                    showLyrics.toggle()
                    onExpand?()
                } label: {
                    Image(systemName: "quote.bubble")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(showLyrics ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)
                .help("Lyrics")

                // Up Next Queue button
                Button {
                    showQueuePopover.toggle()
                } label: {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(showQueuePopover ? .accentColor : .secondary)
                        .padding(4)
                        .background(
                            Circle()
                                .fill(showQueuePopover ? Color.accentColor.opacity(0.18) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .help("Up Next Queue")
                .popover(isPresented: $showQueuePopover, arrowEdge: .top) {
                    QueuePopoverView(player: player)
                }

                // Volume icon + slider
                HStack(spacing: 5) {
                    Button {
                        player.isMuted.toggle()
                    } label: {
                        Image(systemName: volumeIcon)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .frame(width: 14)
                    }
                    .buttonStyle(.plain)
                    .help(player.isMuted ? "Unmute" : "Mute")

                    Slider(value: $player.volume, in: 0...1)
                        .frame(width: 64)
                        .accentColor(.accentColor)
                }
            }
            .frame(width: 135, alignment: .trailing)
        }
        .padding(.horizontal, 14)
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
                                Color.white.opacity(0.24),
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.15)
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
                                Color.white.opacity(0.55),
                                Color.white.opacity(0.18),
                                Color.white.opacity(0.35)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.0
                    )
            }
        )
        // Ambient glass elevation shadow
        .shadow(color: Color.black.opacity(0.25), radius: 18, x: 0, y: 6)
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 1.5)
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
