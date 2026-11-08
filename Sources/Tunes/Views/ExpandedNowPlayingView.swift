import SwiftUI
import AppKit

public struct ExpandedNowPlayingView: View {
    @ObservedObject var player: AudioPlayer
    @ObservedObject var library: LibraryManager
    @Binding var isPresented: Bool

    @State private var animateGradients: Bool = false
    @State private var isDraggingScrubber: Bool = false
    @State private var scrubTime: TimeInterval = 0

    private var currentSong: Song? {
        player.currentSong
    }

    private var currentAlbum: Album? {
        guard let song = currentSong else { return nil }
        return library.albums.first(where: {
            $0.title.localizedCaseInsensitiveCompare(song.albumTitle) == .orderedSame &&
            $0.artistName.localizedCaseInsensitiveCompare(song.artistName) == .orderedSame
        }) ?? library.albums.first(where: { $0.songs.contains(where: { $0.id == song.id }) })
    }

    private var paletteColors: (c1: Color, c2: Color, c3: Color) {
        guard let song = currentSong else {
            return (Color.indigo, Color.purple, Color.blue)
        }
        let colors = ArtworkLoader.shared.spineColors(for: song, fallbackID: song.id)
        let primary = colors.bg
        // Generate complementary hues
        let c2 = Color(
            hue: (abs(Double(song.persistentID % 100)) / 100.0),
            saturation: 0.70,
            brightness: 0.65
        )
        let c3 = Color(
            hue: ((abs(Double(song.persistentID % 100)) / 100.0) + 0.35).truncatingRemainder(dividingBy: 1.0),
            saturation: 0.65,
            brightness: 0.55
        )
        return (primary, c2, c3)
    }

    public init(player: AudioPlayer, library: LibraryManager, isPresented: Binding<Bool>) {
        self.player = player
        self.library = library
        self._isPresented = isPresented
    }

    public var body: some View {
        ZStack {
            // MARK: - Dynamic Living Motion Gradient Background
            ZStack {
                Color(white: 0.07).ignoresSafeArea()

                let colors = paletteColors

                // Drifting Ambient Fluid Blobs
                Circle()
                    .fill(colors.c1.opacity(0.55))
                    .frame(width: 580, height: 580)
                    .offset(x: animateGradients ? -160 : 180, y: animateGradients ? -150 : 120)
                    .blur(radius: 110)

                Circle()
                    .fill(colors.c2.opacity(0.50))
                    .frame(width: 520, height: 520)
                    .offset(x: animateGradients ? 180 : -120, y: animateGradients ? 120 : -140)
                    .blur(radius: 120)

                Circle()
                    .fill(colors.c3.opacity(0.45))
                    .frame(width: 480, height: 480)
                    .offset(x: animateGradients ? 90 : -160, y: animateGradients ? -90 : 160)
                    .blur(radius: 115)

                // Soft dark vignette so foreground text remains crystal clear
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.45),
                        Color.clear,
                        Color.black.opacity(0.65)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true)) {
                    animateGradients.toggle()
                }
            }

            // MARK: - Content
            VStack(spacing: 0) {
                // Top Header Bar
                HStack {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                            isPresented = false
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.down.circle.fill")
                                .font(.system(size: 20))
                            Text("Back to Library")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .help("Collapse to Library")

                    Spacer()

                    HStack(spacing: 6) {
                        Image(systemName: "waveform")
                            .font(.system(size: 12))
                        Text("NOW PLAYING")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.5)
                    }
                    .foregroundColor(.white.opacity(0.65))

                    Spacer()

                    // Balance spacing
                    Color.clear.frame(width: 120, height: 20)
                }
                .padding(.horizontal, 28)
                .padding(.top, 20)
                .padding(.bottom, 12)

                // Main Expanded Body
                if let song = currentSong {
                    ScrollView(.vertical, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 44) {
                            // MARK: - Left: Large Artwork & Controls
                            VStack(spacing: 24) {
                                // Large Album Art inside Rounded Rectangle Mask
                                ArtworkView(song: song, cornerRadius: 22, size: 380)
                                    .shadow(color: Color.black.opacity(0.65), radius: 36, x: 0, y: 20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                                            .stroke(Color.white.opacity(0.18), lineWidth: 1.5)
                                    )

                                // Track Information
                                VStack(spacing: 6) {
                                    Text(song.title)
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)

                                    Text(song.artistName)
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.9))
                                        .lineLimit(1)

                                    Text(song.albumTitle)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white.opacity(0.65))
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: 420)

                                // Scrubber Slider
                                VStack(spacing: 8) {
                                    Slider(
                                        value: Binding(
                                            get: { isDraggingScrubber ? scrubTime : player.currentTime },
                                            set: { scrubTime = $0 }
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
                                    .accentColor(.white)

                                    HStack {
                                        Text(isDraggingScrubber ? formatSeconds(scrubTime) : player.formattedCurrentTime)
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(.white.opacity(0.65))
                                        Spacer()
                                        Text(player.formattedRemainingTime)
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(.white.opacity(0.65))
                                    }
                                }
                                .frame(width: 400)

                                // Transport Playback Controls
                                HStack(spacing: 28) {
                                    Button {
                                        player.isShuffleEnabled.toggle()
                                    } label: {
                                        Image(systemName: "shuffle")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(player.isShuffleEnabled ? .white : .white.opacity(0.45))
                                    }
                                    .buttonStyle(.plain)

                                    Button {
                                        player.previousTrack()
                                    } label: {
                                        Image(systemName: "backward.fill")
                                            .font(.system(size: 22))
                                            .foregroundColor(.white)
                                    }
                                    .buttonStyle(.plain)

                                    Button {
                                        player.togglePlayPause()
                                    } label: {
                                        ZStack {
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 58, height: 58)
                                                .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                                            Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                                .font(.system(size: 24, weight: .bold))
                                                .foregroundColor(.black)
                                                .offset(x: player.isPlaying ? 0 : 2)
                                        }
                                    }
                                    .buttonStyle(.plain)

                                    Button {
                                        player.nextTrack()
                                    } label: {
                                        Image(systemName: "forward.fill")
                                            .font(.system(size: 22))
                                            .foregroundColor(.white)
                                    }
                                    .buttonStyle(.plain)

                                    Button {
                                        player.cycleRepeatMode()
                                    } label: {
                                        Image(systemName: player.repeatMode.iconName)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(player.repeatMode != .off ? .white : .white.opacity(0.45))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .frame(maxWidth: 480)

                            // MARK: - Right: Album Details & Tracklist
                            VStack(alignment: .leading, spacing: 20) {
                                // Metadata Card
                                VStack(alignment: .leading, spacing: 14) {
                                    Text("ALBUM DETAILS")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .tracking(1.2)
                                        .foregroundColor(.white.opacity(0.6))

                                    VStack(alignment: .leading, spacing: 10) {
                                        if let alb = currentAlbum {
                                            metadataRow(label: "Album", value: alb.title)
                                            metadataRow(label: "Artist", value: alb.artistName)
                                            metadataRow(label: "Tracks", value: "\(alb.trackCount) songs • \(alb.formattedDuration)")
                                            if alb.year > 0 {
                                                metadataRow(label: "Year", value: "\(alb.year)")
                                            }
                                        }
                                        metadataRow(label: "Genre", value: song.genre)
                                        if song.playCount > 0 {
                                            metadataRow(label: "Plays", value: "\(song.playCount) times")
                                        }
                                        if let loc = song.location {
                                            metadataRow(label: "Format", value: loc.pathExtension.uppercased())
                                        }
                                    }

                                    Divider().background(Color.white.opacity(0.15))

                                    if let url = song.location {
                                        Button {
                                            NSWorkspace.shared.activateFileViewerSelecting([url])
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: "folder")
                                                Text("Show Original File in Finder")
                                            }
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.white.opacity(0.85))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(18)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                        )
                                )

                                // Album Tracks List
                                if let album = currentAlbum {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("ALBUM TRACKLIST")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .tracking(1.2)
                                            .foregroundColor(.white.opacity(0.6))

                                        VStack(spacing: 2) {
                                            ForEach(album.songs) { albumSong in
                                                let isThisPlaying = (albumSong.id == currentSong?.id)
                                                HStack(spacing: 10) {
                                                    ZStack {
                                                        if isThisPlaying && player.isPlaying {
                                                            Image(systemName: "speaker.wave.2.fill")
                                                                .font(.system(size: 10))
                                                                .foregroundColor(.white)
                                                        } else {
                                                            Text("\(albumSong.trackNumber > 0 ? "\(albumSong.trackNumber)" : "-")")
                                                                .font(.system(size: 11, design: .monospaced))
                                                                .foregroundColor(.white.opacity(0.5))
                                                        }
                                                    }
                                                    .frame(width: 22)

                                                    Text(albumSong.title)
                                                        .font(.system(size: 12, weight: isThisPlaying ? .semibold : .regular))
                                                        .foregroundColor(isThisPlaying ? .white : .white.opacity(0.85))
                                                        .lineLimit(1)

                                                    Spacer()

                                                    Text(albumSong.formattedDuration)
                                                        .font(.system(size: 11, design: .monospaced))
                                                        .foregroundColor(.white.opacity(0.5))
                                                }
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 5)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .fill(isThisPlaying ? Color.white.opacity(0.20) : Color.clear)
                                                )
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    player.play(song: albumSong, inContext: album.songs)
                                                }
                                            }
                                        }
                                    }
                                    .padding(18)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                            )
                                    )
                                }
                            }
                            .frame(maxWidth: 380)
                        }
                        .padding(.horizontal, 32)
                        .padding(.top, 16)
                        .padding(.bottom, 36)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "music.note")
                            .font(.system(size: 54))
                            .foregroundColor(.white.opacity(0.4))
                        Text("Nothing Playing")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }

    private func metadataRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 60, alignment: .leading)
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(1)
            Spacer()
        }
    }

    private func formatSeconds(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }
}
