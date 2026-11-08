import SwiftUI

public struct AlbumDetailView: View {
    let album: Album
    @ObservedObject var player: AudioPlayer
    var onBack: (() -> Void)?

    @State private var hoveredSongID: String?

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Back button if needed
                if let onBack = onBack {
                    Button {
                        onBack()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Albums")
                        }
                        .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                }

                // Album Header
                HStack(alignment: .bottom, spacing: 24) {
                    ArtworkView(song: album.representativeSong, cornerRadius: 10, size: 180)
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("ALBUM")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)

                        Text(album.title)
                            .font(.system(size: 26, weight: .bold))
                            .lineLimit(2)

                        Text(album.artistName)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)

                        HStack(spacing: 6) {
                            if album.year > 0 {
                                Text("\(album.year)")
                                Text("•")
                            }
                            Text("\(album.trackCount) songs")
                            Text("•")
                            Text(album.formattedDuration)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)

                        // Play & Shuffle Buttons
                        HStack(spacing: 12) {
                            Button {
                                if let first = album.songs.first {
                                    player.play(song: first, inContext: album.songs)
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "play.fill")
                                    Text("Play")
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)

                            Button {
                                if !album.songs.isEmpty {
                                    var shuffled = album.songs
                                    shuffled.shuffle()
                                    if let first = shuffled.first {
                                        player.isShuffleEnabled = true
                                        player.play(song: first, inContext: album.songs)
                                    }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "shuffle")
                                    Text("Shuffle")
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.secondary.opacity(0.15))
                                .foregroundColor(.primary)
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 4)
                    }
                }

                Divider()

                // Track list
                LazyVStack(spacing: 2) {
                    ForEach(album.songs) { song in
                        let isPlayingThis = (player.currentSong?.id == song.id)
                        let isHovered = (hoveredSongID == song.id)

                        HStack(spacing: 12) {
                            ZStack {
                                if isPlayingThis && player.isPlaying {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(.accentColor)
                                } else if isHovered {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(.accentColor)
                                } else {
                                    Text("\(song.trackNumber > 0 ? "\(song.trackNumber)" : "-")")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(width: 28, alignment: .center)

                            Text(song.title)
                                .font(.system(size: 13, weight: isPlayingThis ? .semibold : .regular))
                                .foregroundColor(isPlayingThis ? .accentColor : .primary)
                                .lineLimit(1)

                            Spacer()

                            Text(song.formattedDuration)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isPlayingThis ? Color.accentColor.opacity(0.12) : (isHovered ? Color.secondary.opacity(0.08) : Color.clear))
                        )
                        .contentShape(Rectangle())
                        .onHover { h in
                            hoveredSongID = h ? song.id : nil
                        }
                        .onTapGesture {
                            player.play(song: song, inContext: album.songs)
                        }
                        .contextMenu {
                            Button("Play") { player.play(song: song, inContext: album.songs) }
                            Button("Play Next") { player.playNext(song: song) }
                            Button("Add to Queue") { player.addToQueue(song: song) }
                            if let url = song.location {
                                Divider()
                                Button("Show in Finder") {
                                    NSWorkspace.shared.activateFileViewerSelecting([url])
                                }
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
    }
}
