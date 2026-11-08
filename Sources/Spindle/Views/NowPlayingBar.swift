import SwiftUI
import AppKit

public struct NowPlayingBar: View {
    @ObservedObject var player: AudioPlayer
    var onExpand: (() -> Void)? = nil

    @State private var isDraggingScrubber: Bool = false
    @State private var scrubTime: TimeInterval = 0
    @State private var showQueuePopover: Bool = false
    @State private var isHoveringThumbnail: Bool = false

    public init(player: AudioPlayer, onExpand: (() -> Void)? = nil) {
        self.player = player
        self.onExpand = onExpand
    }

    public var body: some View {
        HStack(spacing: 16) {
            // MARK: - Left: Track Info & Artwork
            HStack(spacing: 12) {
                if let song = player.currentSong {
                    ZStack {
                        ArtworkView(song: song, cornerRadius: 6, size: 48)

                        if isHoveringThumbnail {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.black.opacity(0.35))
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 48, height: 48)
                    .contentShape(Rectangle())
                    .onHover { isHoveringThumbnail = $0 }
                    .onTapGesture {
                        onExpand?()
                    }
                    .help("Click to expand Now Playing view")

                    VStack(alignment: .leading, spacing: 3) {
                        Text(song.title)
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(1)

                        Text("\(song.artistName) — \(song.albumTitle)")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: 240, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onExpand?()
                    }
                    .help("Click to expand Now Playing view")

                    if let url = song.location {
                        Button {
                            NSWorkspace.shared.activateFileViewerSelecting([url])
                        } label: {
                            Image(systemName: "folder")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Show in Finder (local file)")
                    }
                } else {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.secondary.opacity(0.15))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: "music.note")
                                .foregroundColor(.secondary)
                        )

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Not Playing")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text("Select a song to start listening")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    .frame(maxWidth: 240, alignment: .leading)
                }
            }
            .frame(width: 320, alignment: .leading)

            Spacer()

            // MARK: - Center: Transport Controls & Scrubber
            VStack(spacing: 6) {
                // Controls Row
                HStack(spacing: 18) {
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

                    // Previous
                    Button {
                        player.previousTrack()
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 15))
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
                                .fill(Color.accentColor)
                                .frame(width: 34, height: 34)
                            Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .offset(x: player.isPlaying ? 0 : 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.space, modifiers: [])
                    .help(player.isPlaying ? "Pause" : "Play")

                    // Next
                    Button {
                        player.nextTrack()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 15))
                    }
                    .buttonStyle(.plain)
                    .disabled(!player.hasNext)
                    .help("Next Track")

                    // Repeat
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

                // Scrubber Row
                HStack(spacing: 8) {
                    Text(isDraggingScrubber ? formatSeconds(scrubTime) : player.formattedCurrentTime)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .frame(width: 36, alignment: .trailing)

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
                    .frame(maxWidth: 380)

                    Text(player.formattedRemainingTime)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .frame(width: 42, alignment: .leading)
                }
            }

            Spacer()

            // MARK: - Right: Volume & Queue
            HStack(spacing: 12) {
                // Volume
                Button {
                    player.isMuted.toggle()
                } label: {
                    Image(systemName: volumeIcon)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .frame(width: 18)
                }
                .buttonStyle(.plain)

                Slider(value: $player.volume, in: 0...1)
                    .frame(width: 80)
                    .accentColor(.accentColor)

                // Queue button
                Button {
                    showQueuePopover.toggle()
                } label: {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(showQueuePopover ? .accentColor : .secondary)
                        .padding(6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(showQueuePopover ? Color.accentColor.opacity(0.15) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .help("Up Next Queue")
                .popover(isPresented: $showQueuePopover, arrowEdge: .top) {
                    QueuePopoverView(player: player)
                }
            }
            .frame(width: 220, alignment: .trailing)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color(NSColor.separatorColor)),
                    alignment: .top
                )
        )
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
