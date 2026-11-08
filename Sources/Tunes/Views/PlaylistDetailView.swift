import SwiftUI

public struct PlaylistDetailView: View {
    let playlist: Playlist
    @ObservedObject var player: AudioPlayer

    @State private var hoveredSongID: String?

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Playlist Header
                HStack(alignment: .bottom, spacing: 24) {
                    ArtworkView(song: playlist.songs.first, cornerRadius: 10, size: 160)
                        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("PLAYLIST")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)

                        Text(playlist.name)
                            .font(.system(size: 26, weight: .bold))
                            .lineLimit(2)

                        HStack(spacing: 6) {
                            Text("\(playlist.songCount) songs")
                            Text("•")
                            Text(playlist.formattedDuration)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)

                        // Play & Shuffle Buttons
                        HStack(spacing: 12) {
                            Button {
                                if let first = playlist.songs.first {
                                    player.play(song: first, inContext: playlist.songs)
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
                                if !playlist.songs.isEmpty {
                                    var shuffled = playlist.songs
                                    shuffled.shuffle()
                                    if let first = shuffled.first {
                                        player.isShuffleEnabled = true
                                        player.play(song: first, inContext: playlist.songs)
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

                // Playlist Songs
                LazyVStack(spacing: 2) {
                    ForEach(Array(playlist.songs.enumerated()), id: \.element.id) { index, song in
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
                                    Text("\(index + 1)")
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(width: 32, alignment: .center)

                            ArtworkView(song: song, cornerRadius: 4, size: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(song.title)
                                    .font(.system(size: 13, weight: isPlayingThis ? .semibold : .regular))
                                    .foregroundColor(isPlayingThis ? .accentColor : .primary)
                                    .lineLimit(1)
                                Text(song.artistName)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Text(song.albumTitle)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .frame(width: 180, alignment: .leading)
                                .lineLimit(1)

                            Text(song.formattedDuration)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(width: 50, alignment: .trailing)
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
                            player.play(song: song, inContext: playlist.songs)
                        }
                        .contextMenu {
                            Button("Play") { player.play(song: song, inContext: playlist.songs) }
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
