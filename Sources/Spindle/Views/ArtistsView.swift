import SwiftUI

public struct ArtistsView: View {
    let artists: [Artist]
    @ObservedObject var player: AudioPlayer

    @State private var selectedArtistID: String?

    private var currentArtist: Artist? {
        if let id = selectedArtistID {
            return artists.first { $0.id == id }
        }
        return artists.first
    }

    public var body: some View {
        if artists.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "music.mic")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)
                Text("No artists found")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            HSplitView {
                // Artists list
                List(artists, selection: $selectedArtistID) { artist in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(artist.name)
                                .font(.system(size: 13, weight: .medium))
                            Text("\(artist.songCount) songs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedArtistID = artist.id
                    }
                    .tag(artist.id)
                }
                .frame(minWidth: 180, idealWidth: 220, maxWidth: 280)

                // Artist detail / Discography
                if let artist = currentArtist {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            // Header
                            HStack(spacing: 16) {
                                ArtworkView(song: artist.representativeSong, cornerRadius: 50, size: 100)
                                    .clipShape(Circle())
                                    .shadow(radius: 4)

                                VStack(alignment: .leading, spacing: 6) {
                                    Text(artist.name)
                                        .font(.system(size: 24, weight: .bold))
                                    Text("\(artist.albumCount) albums • \(artist.songCount) songs")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)

                                    Button {
                                        if let first = artist.songs.first {
                                            player.play(song: first, inContext: artist.songs)
                                        }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "play.fill")
                                            Text("Play All")
                                        }
                                        .font(.system(size: 12, weight: .semibold))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 6)
                                        .background(Color.accentColor)
                                        .foregroundColor(.white)
                                        .cornerRadius(6)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.bottom, 8)

                            Divider()

                            // Albums by this artist
                            ForEach(artist.albums) { album in
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 12) {
                                        ArtworkView(song: album.representativeSong, cornerRadius: 6, size: 60)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(album.title)
                                                .font(.system(size: 15, weight: .semibold))
                                            Text("\(album.year > 0 ? "\(album.year) • " : "")\(album.trackCount) songs • \(album.formattedDuration)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Button {
                                            if let first = album.songs.first {
                                                player.play(song: first, inContext: album.songs)
                                            }
                                        } label: {
                                            Image(systemName: "play.circle.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(.accentColor)
                                        }
                                        .buttonStyle(.plain)
                                    }

                                    // Album songs
                                    VStack(spacing: 2) {
                                        ForEach(album.songs) { song in
                                            let isPlayingThis = (player.currentSong?.id == song.id)
                                            HStack(spacing: 10) {
                                                Text("\(song.trackNumber > 0 ? "\(song.trackNumber)" : "-")")
                                                    .font(.system(size: 11))
                                                    .foregroundColor(.secondary)
                                                    .frame(width: 24, alignment: .trailing)

                                                Text(song.title)
                                                    .font(.system(size: 12, weight: isPlayingThis ? .semibold : .regular))
                                                    .foregroundColor(isPlayingThis ? .accentColor : .primary)
                                                    .lineLimit(1)

                                                Spacer()

                                                Text(song.formattedDuration)
                                                    .font(.system(size: 11))
                                                    .foregroundColor(.secondary)
                                            }
                                            .padding(.vertical, 4)
                                            .padding(.horizontal, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(isPlayingThis ? Color.accentColor.opacity(0.12) : Color.clear)
                                            )
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                player.play(song: song, inContext: album.songs)
                                            }
                                        }
                                    }
                                }
                                .padding(.bottom, 16)
                            }

                            // Bottom clearance for floating liquid glass panel
                            Color.clear.frame(height: 84)
                        }
                        .padding(20)
                    }
                } else {
                    Text("Select an artist")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }
}
