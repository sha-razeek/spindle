import SwiftUI

public struct QueuePopoverView: View {
    @ObservedObject var player: AudioPlayer

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Up Next")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text("\(player.queue.count) songs")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 12)

            Divider()

            if player.queue.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("The queue is empty")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(Array(player.queue.enumerated()), id: \.element.id) { index, song in
                            let isCurrent = (index == player.queueIndex)
                            HStack(spacing: 10) {
                                ArtworkView(song: song, cornerRadius: 4, size: 36)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(song.title)
                                        .font(.system(size: 13, weight: isCurrent ? .bold : .regular))
                                        .foregroundColor(isCurrent ? .accentColor : .primary)
                                        .lineLimit(1)
                                    Text(song.artistName)
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }

                                Spacer()

                                if isCurrent {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .font(.caption)
                                        .foregroundColor(.accentColor)
                                }

                                Text(song.formattedDuration)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(isCurrent ? Color.accentColor.opacity(0.12) : Color.clear)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                player.play(song: song, inContext: player.queue)
                            }
                        }
                    }
                    .padding(.horizontal, 6)
                }
            }
        }
        .frame(width: 320, height: 420)
    }
}
