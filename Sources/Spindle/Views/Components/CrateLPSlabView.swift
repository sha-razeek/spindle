import SwiftUI
import AppKit

public struct CrateLPSlabView: View, Equatable {
    let album: Album
    let isSelected: Bool
    let isPlaying: Bool
    var onSelect: () -> Void

    @State private var artworkImage: NSImage?
    @State private var isHovered: Bool = false
    @State private var spineBgColor: Color = Color(red: 0.22, green: 0.26, blue: 0.30)
    @State private var spineTextColor: Color = .white

    public static func == (lhs: CrateLPSlabView, rhs: CrateLPSlabView) -> Bool {
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
        ZStack(alignment: .top) {
            // MARK: - 3D Album LP Jacket & Spine Stack
            VStack(spacing: 0) {
                // Top Spine Edge (Distinct, tactile physical LP spine)
                HStack(spacing: 6) {
                    if isSelected && isPlaying {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(spineTextColor)
                            .padding(.trailing, 2)
                    }

                    // Album Title
                    Text(album.title)
                        .font(.system(size: 12.5, weight: isSelected ? .bold : .semibold))
                        .foregroundColor(spineTextColor)
                        .lineLimit(1)

                    // Artist Name
                    Text(album.artistName)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(spineTextColor.opacity(0.85))
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    // Track count badge
                    if isSelected {
                        Text(isPlaying ? "PLAYING" : "ON DECK")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(0.6)
                            .foregroundColor(spineTextColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2.5)
                            .background(spineTextColor.opacity(0.22))
                            .cornerRadius(3.5)
                    } else {
                        Text("\(album.trackCount) tracks")
                            .font(.system(size: 9.5, weight: .medium))
                            .foregroundColor(spineTextColor.opacity(0.75))
                            .padding(.horizontal, 5.5)
                            .padding(.vertical, 2)
                            .background(spineTextColor.opacity(0.12))
                            .cornerRadius(3.5)
                    }
                }
                .padding(.horizontal, 10)
                .frame(width: 310, height: 28)
                .background(spineBgColor)
                .overlay(
                    // 3D tactile bevel edge lines
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.white.opacity(0.55))
                            .frame(height: 1.2)
                        Spacer()
                        Rectangle()
                            .fill(Color.black.opacity(0.40))
                            .frame(height: 1.2)
                    }
                )
                .overlay(
                    // Active selection ring
                    RoundedRectangle(cornerRadius: 1)
                        .stroke(isSelected ? Color.white.opacity(0.85) : Color.clear, lineWidth: 1.5)
                )
                .shadow(
                    color: Color.black.opacity(isSelected ? 0.40 : 0.20),
                    radius: isSelected ? 6 : 3,
                    x: 0,
                    y: isSelected ? 3 : 1.5
                )
                .zIndex(10)

                // Front Album Artwork Jacket (Angled backwards in 3D perspective)
                jacketView
            }
            .frame(width: 310)
            .rotation3DEffect(
                .degrees(-26),
                axis: (x: 1, y: 0, z: 0),
                anchor: .top,
                perspective: 0.38
            )
            .shadow(
                color: Color.black.opacity(isSelected ? 0.50 : (isHovered ? 0.35 : 0.22)),
                radius: isSelected ? 12 : (isHovered ? 8 : 4),
                x: 0,
                y: isSelected ? 8 : (isHovered ? 5 : 2.5)
            )
        }
        // Overlapping row height: 76pt row height creates stacked physical LP appearance
        .frame(width: 310, height: 76, alignment: .top)
        .offset(y: (isHovered && !isSelected) ? -3 : 0)
        .animation(.spring(response: 0.35, dampingFraction: 0.80), value: isSelected)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .contentShape(Rectangle())
        .onHover { h in
            isHovered = h
        }
        .onTapGesture {
            onSelect()
        }
        .task(id: album.id) {
            await loadArtworkAndSpine()
        }
    }

    // MARK: - Angled Jacket View
    @ViewBuilder
    private var jacketView: some View {
        ZStack(alignment: .center) {
            if let image = artworkImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
            } else {
                LinearGradient(
                    colors: [spineBgColor, Color.purple.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: "music.note")
                    .font(.system(size: 36))
                    .foregroundColor(.white.opacity(0.8))
            }

            // Gentle lighting sheen
            LinearGradient(
                colors: [
                    Color.white.opacity(0.12),
                    Color.clear,
                    Color.black.opacity(0.38)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Hover play pill
            if isHovered && !isSelected {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.60))
                        .frame(width: 36, height: 36)
                    Image(systemName: "play.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .offset(x: 1)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 310, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 3.5, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1.0)
        )
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
