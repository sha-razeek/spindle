import SwiftUI
import AppKit

public struct SongsListView: View {
    let songs: [Song]
    @ObservedObject var player: AudioPlayer

    @State private var hoveredSongID: String?
    @State private var sortOrder: SortField = .title
    @State private var sortAscending: Bool = true

    enum SortField {
        case title, artist, album, duration
    }

    private var sortedSongs: [Song] {
        songs.sorted { a, b in
            let result: Bool
            switch sortOrder {
            case .title:
                result = a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
            case .artist:
                result = a.artistName.localizedCaseInsensitiveCompare(b.artistName) == .orderedAscending
            case .album:
                result = a.albumTitle.localizedCaseInsensitiveCompare(b.albumTitle) == .orderedAscending
            case .duration:
                result = a.duration < b.duration
            }
            return sortAscending ? result : !result
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack(spacing: 12) {
                Text("#")
                    .frame(width: 36, alignment: .center)
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    Text("Title")
                    if sortOrder == .title {
                        Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                            .font(.system(size: 9))
                    }
                }
                .font(.caption)
                .foregroundColor(sortOrder == .title ? .accentColor : .secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture { toggleSort(.title) }

                HStack(spacing: 4) {
                    Text("Artist")
                    if sortOrder == .artist {
                        Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                            .font(.system(size: 9))
                    }
                }
                .font(.caption)
                .foregroundColor(sortOrder == .artist ? .accentColor : .secondary)
                .frame(width: 200, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture { toggleSort(.artist) }

                HStack(spacing: 4) {
                    Text("Album")
                    if sortOrder == .album {
                        Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                            .font(.system(size: 9))
                    }
                }
                .font(.caption)
                .foregroundColor(sortOrder == .album ? .accentColor : .secondary)
                .frame(width: 200, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture { toggleSort(.album) }

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                    if sortOrder == .duration {
                        Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                            .font(.system(size: 9))
                    }
                }
                .font(.caption)
                .foregroundColor(sortOrder == .duration ? .accentColor : .secondary)
                .frame(width: 60, alignment: .trailing)
                .contentShape(Rectangle())
                .onTapGesture { toggleSort(.duration) }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.6))

            Divider()

            if sortedSongs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "music.note")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No songs found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(Array(sortedSongs.enumerated()), id: \.element.id) { index, song in
                            let isPlayingThis = (player.currentSong?.id == song.id)
                            let isHovered = (hoveredSongID == song.id)

                            HStack(spacing: 12) {
                                // Track number or play icon
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
                                .frame(width: 36, alignment: .center)

                                // Artwork + Title
                                HStack(spacing: 10) {
                                    ArtworkView(song: song, cornerRadius: 4, size: 32)
                                    Text(song.title)
                                        .font(.system(size: 13, weight: isPlayingThis ? .semibold : .regular))
                                        .foregroundColor(isPlayingThis ? .accentColor : .primary)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                // Artist
                                Text(song.artistName)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .frame(width: 200, alignment: .leading)
                                    .lineLimit(1)

                                // Album
                                Text(song.albumTitle)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .frame(width: 200, alignment: .leading)
                                    .lineLimit(1)

                                // Duration
                                Text(song.formattedDuration)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .frame(width: 60, alignment: .trailing)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(isPlayingThis ? Color.accentColor.opacity(0.12) : (isHovered ? Color.secondary.opacity(0.08) : Color.clear))
                            )
                            .contentShape(Rectangle())
                            .onHover { hovering in
                                hoveredSongID = hovering ? song.id : nil
                            }
                            .onTapGesture {
                                player.play(song: song, inContext: sortedSongs)
                            }
                            .contextMenu {
                                Button("Play") {
                                    player.play(song: song, inContext: sortedSongs)
                                }
                                Button("Play Next") {
                                    player.playNext(song: song)
                                }
                                Button("Add to Queue") {
                                    player.addToQueue(song: song)
                                }
                                Divider()
                                if let url = song.location {
                                    Button("Show in Finder") {
                                        NSWorkspace.shared.activateFileViewerSelecting([url])
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                }
            }
        }
    }

    private func toggleSort(_ field: SortField) {
        if sortOrder == field {
            sortAscending.toggle()
        } else {
            sortOrder = field
            sortAscending = true
        }
    }
}
