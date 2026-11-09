import SwiftUI
import AppKit

public struct RackAlbumSlabView: View, Equatable {
    let album: Album
    let isSelected: Bool
    let isPlaying: Bool
    var onSelect: () -> Void

    @State private var artworkImage: NSImage?
    @State private var isHovered: Bool = false
    @State private var spineBgColor: Color = Color(red: 0.22, green: 0.26, blue: 0.30)
    @State private var spineTextColor: Color = .white

    public static func == (lhs: RackAlbumSlabView, rhs: RackAlbumSlabView) -> Bool {
        lhs.album.id == rhs.album.id &&
        lhs.isSelected == rhs.isSelected &&
        lhs.isPlaying == rhs.isPlaying
    }

    public init(
        album: Album,
        isSelected: Bool,
        isPlaying: Bool,
        onSelect: @escaping () -> Void
    ) {
        self.album = album
        self.isSelected = isSelected
        self.isPlaying = isPlaying
        self.onSelect = onSelect
    }

    public var body: some View {
        HStack(spacing: 10) {
            // 1. Artwork Thumbnail
            ZStack {
                if let img = artworkImage {
                    Image(nsImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(spineBgColor)
                    Image(systemName: "music.note")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .frame(width: 44, height: 44)
            .cornerRadius(5)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.75)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 3, x: 1, y: 1.5)

            // 2. Title & Artist
            VStack(alignment: .leading, spacing: 2.5) {
                HStack(spacing: 4) {
                    if isSelected && isPlaying {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(spineTextColor)
                    }

                    Text(album.title)
                        .font(.system(size: 12.5, weight: isSelected ? .bold : .semibold))
                        .foregroundColor(spineTextColor)
                        .lineLimit(1)
                }

                Text(album.artistName)
                    .font(.system(size: 11))
                    .foregroundColor(spineTextColor.opacity(0.85))
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            // 3. Right Badge (Track count or ON DECK)
            if isSelected {
                Text(isPlaying ? "PLAYING" : "ON DECK")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.6)
                    .foregroundColor(spineTextColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(spineTextColor.opacity(0.22))
                    .cornerRadius(4)
            } else {
                Text("\(album.trackCount)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(spineTextColor.opacity(0.70))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(spineTextColor.opacity(0.10))
                    .cornerRadius(3.5)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(spineBgColor)
        )
        .overlay(
            // Highlighted border if selected or hovered
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(
                    isSelected ? Color.white.opacity(0.85) : (isHovered ? Color.white.opacity(0.40) : Color.white.opacity(0.12)),
                    lineWidth: isSelected ? 1.75 : 1
                )
        )
        .shadow(
            color: Color.black.opacity(isSelected ? 0.45 : (isHovered ? 0.35 : 0.20)),
            radius: isSelected ? 8 : (isHovered ? 5 : 2.5),
            x: 0,
            y: isSelected ? 4 : (isHovered ? 2.5 : 1)
        )
        .offset(y: (isHovered && !isSelected) ? -2 : 0)
        .contentShape(Rectangle())
        .onHover { h in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = h
            }
        }
        .onTapGesture {
            onSelect()
        }
        .task(id: album.id) {
            await loadArtworkAndSpine()
        }
    }

    private func loadArtworkAndSpine() async {
        let song = album.representativeSong
        let initialColors = ArtworkLoader.shared.spineColors(for: song, fallbackID: album.id)
        self.spineBgColor = initialColors.bg
        self.spineTextColor = initialColors.text

        guard let targetSong = song else { return }

        if let cached = ArtworkLoader.shared.cachedImage(for: targetSong) {
            self.artworkImage = cached
            return
        }

        // Brief debounce to keep fast scrolling silky smooth
        try? await Task.sleep(nanoseconds: 80_000_000)
        guard !Task.isCancelled else { return }

        if let loaded = await ArtworkLoader.shared.loadArtwork(for: targetSong) {
            guard !Task.isCancelled else { return }
            self.artworkImage = loaded
            let colors = ArtworkLoader.shared.spineColors(for: targetSong, fallbackID: album.id)
            self.spineBgColor = colors.bg
            self.spineTextColor = colors.text
        }
    }
}
