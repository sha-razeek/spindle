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
        HStack(spacing: 20) {
            // MARK: - Left: Transport Controls (Matches Apple Music layout in reference image 3)
            HStack(spacing: 16) {
                // Shuffle
                Button {
                    player.isShuffleEnabled.toggle()
                } label: {
                    Image(systemName: "shuffle")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(player.isShuffleEnabled ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)
                .help(player.isShuffleEnabled ? "Shuffle On" : "Shuffle Off")

                // Previous Track
                Button {
                    player.previousTrack()
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.primary.opacity(0.85))
                }
                .buttonStyle(.plain)
                .disabled(!player.hasPrevious)
                .help("Previous Track")

                // Play / Pause
                Button {
                    player.togglePlayPause()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.primary.opacity(0.12))
                            .frame(width: 36, height: 36)
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                            .offset(x: player.isPlaying ? 0 : 1.2)
                    }
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.space, modifiers: [])
                .help(player.isPlaying ? "Pause" : "Play")

                // Next Track
                Button {
                    player.nextTrack()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 15))
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
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(player.repeatMode != .off ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)
                .help(player.repeatMode.rawValue)
            }
            .frame(width: 175, alignment: .leading)

            Spacer(minLength: 8)

            // MARK: - Center: Track Info Thumbnail & Live Scrubber
            HStack(spacing: 12) {
                if let song = player.currentSong {
                    // Artwork Thumbnail
                    ZStack {
                        ArtworkView(song: song, cornerRadius: 5, size: 38)
                            .shadow(color: Color.black.opacity(0.20), radius: 4, x: 0, y: 2)

                        if isHoveringThumbnail {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.black.opacity(0.40))
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 38, height: 38)
                    .contentShape(Rectangle())
                    .onHover { isHoveringThumbnail = $0 }
                    .onTapGesture {
                        onExpand?()
                    }
                    .help("Click to expand Now Playing view")

                    VStack(alignment: .leading, spacing: 3) {
                        // Title & Artist
                        HStack(spacing: 6) {
                            Text(song.title)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            Text("•")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary.opacity(0.6))

                            Text(song.artistName)
                                .font(.system(size: 11.5))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onExpand?()
                        }

                        // Sleek Scrubber Bar
                        HStack(spacing: 8) {
                            Text(isDraggingScrubber ? formatSeconds(scrubTime) : player.formattedCurrentTime)
                                .font(.system(size: 9.5, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(width: 32, alignment: .trailing)

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
                            .frame(maxWidth: 320)
                            .onHover { h in isHoveringScrubber = h }

                            Text(player.formattedRemainingTime)
                                .font(.system(size: 9.5, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(width: 36, alignment: .leading)
                        }
                    }
                } else {
                    // Empty / Not Playing state
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(Color.secondary.opacity(0.12))
                            .frame(width: 38, height: 38)
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary.opacity(0.7))
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Not Playing")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                            Text("Select an album or track to start listening")
                                .font(.system(size: 10.5))
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)

            Spacer(minLength: 8)

            // MARK: - Right: Lyrics, Queue, AirPlay & Volume (Matches reference image 3)
            HStack(spacing: 14) {
                // Lyrics button
                Button {
                    showLyrics.toggle()
                    onExpand?()
                } label: {
                    Image(systemName: "quote.bubble")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(showLyrics ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)
                .help("Lyrics")

                // Up Next Queue button
                Button {
                    showQueuePopover.toggle()
                } label: {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundColor(showQueuePopover ? .accentColor : .secondary)
                        .padding(5)
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

                // AirPlay route selector button
                Button {
                    showAirPlayPicker()
                } label: {
                    Image(systemName: "airplayaudio")
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("AirPlay & Audio Devices")

                // Volume icon + slider
                HStack(spacing: 6) {
                    Button {
                        player.isMuted.toggle()
                    } label: {
                        Image(systemName: volumeIcon)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .frame(width: 16)
                    }
                    .buttonStyle(.plain)
                    .help(player.isMuted ? "Unmute" : "Mute")

                    Slider(value: $player.volume, in: 0...1)
                        .frame(width: 74)
                        .accentColor(.accentColor)
                }
            }
            .frame(width: 215, alignment: .trailing)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .frame(height: 62)
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
        .shadow(color: Color.black.opacity(0.28), radius: 22, x: 0, y: 8)
        .shadow(color: Color.black.opacity(0.10), radius: 5, x: 0, y: 2)
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

    private func showAirPlayPicker() {
        // Open macOS Sound Output selector in System Settings
        if let url = URL(string: "x-apple.systempreferences:com.apple.Sound-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }
}
