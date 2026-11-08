import SwiftUI
import AppKit

public struct ArtworkView: View {
    let song: Song?
    var cornerRadius: CGFloat = 8
    var size: CGFloat = 48

    @State private var image: NSImage?
    @State private var isLoading = false

    public init(song: Song?, cornerRadius: CGFloat = 8, size: CGFloat = 48) {
        self.song = song
        self.cornerRadius = cornerRadius
        self.size = size
    }

    public var body: some View {
        ZStack {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                // Stylish gradient placeholder
                LinearGradient(
                    colors: [Color.pink.opacity(0.8), Color.purple.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: "music.note")
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .task(id: song?.id) {
            await loadArtwork()
        }
    }

    private func loadArtwork() async {
        guard let song = song else {
            image = nil
            return
        }

        if let cached = ArtworkLoader.shared.cachedImage(for: song) {
            self.image = cached
            return
        }

        let loaded = await ArtworkLoader.shared.loadArtwork(for: song)
        self.image = loaded
    }
}
