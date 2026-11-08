import SwiftUI
import AppKit

// MARK: - Die-Cut Sleeve Shape with Right Thumb Notch
public struct SleeveWithNotchShape: Shape {
    public var hasNotch: Bool
    public var cornerRadius: CGFloat = 4
    public var notchDepth: CGFloat = 38
    public var notchHeight: CGFloat = 66
    public var fillet: CGFloat = 8

    public var animatableData: Double {
        get { hasNotch ? 1.0 : 0.0 }
        set { hasNotch = newValue > 0.5 }
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let r = cornerRadius

        // Start top-left
        path.move(to: CGPoint(x: r, y: 0))
        // Top edge
        path.addLine(to: CGPoint(x: w - r, y: 0))
        // Top-right corner
        path.addArc(tangent1End: CGPoint(x: w, y: 0), tangent2End: CGPoint(x: w, y: r), radius: r)

        if hasNotch {
            let midY = h / 2
            let topY = midY - notchHeight / 2
            let botY = midY + notchHeight / 2
            let innerR = (notchHeight - 2 * fillet) / 2

            // Down right edge to notch top fillet
            path.addLine(to: CGPoint(x: w, y: topY - fillet))
            // Smooth outer fillet curving inward to the left
            path.addQuadCurve(
                to: CGPoint(x: w - fillet, y: topY),
                control: CGPoint(x: w, y: topY)
            )
            // Straight inward line
            path.addLine(to: CGPoint(x: w - notchDepth + innerR, y: topY))
            // Semicircular inner notch
            path.addArc(
                center: CGPoint(x: w - notchDepth + innerR, y: midY),
                radius: innerR,
                startAngle: .degrees(-90),
                endAngle: .degrees(90),
                clockwise: true
            )
            // Straight outward line
            path.addLine(to: CGPoint(x: w - fillet, y: botY))
            // Smooth outer fillet curving back out to right edge
            path.addQuadCurve(
                to: CGPoint(x: w, y: botY + fillet),
                control: CGPoint(x: w, y: botY)
            )
        }

        // Down right edge to bottom-right corner
        path.addLine(to: CGPoint(x: w, y: h - r))
        // Bottom-right corner
        path.addArc(tangent1End: CGPoint(x: w, y: h), tangent2End: CGPoint(x: w - r, y: h), radius: r)
        // Bottom edge
        path.addLine(to: CGPoint(x: r, y: h))
        // Bottom-left corner
        path.addArc(tangent1End: CGPoint(x: 0, y: h), tangent2End: CGPoint(x: 0, y: h - r), radius: r)
        // Left edge
        path.addLine(to: CGPoint(x: 0, y: r))
        // Top-left corner
        path.addArc(tangent1End: CGPoint(x: 0, y: 0), tangent2End: CGPoint(x: r, y: 0), radius: r)
        path.closeSubpath()
        return path
    }
}

public struct AlbumSlabView: View {
    let album: Album
    let isPoppedOut: Bool
    let isOtherAlbumPoppedOut: Bool
    @ObservedObject var player: AudioPlayer
    var onTogglePopOut: () -> Void
    var onSelectDetail: () -> Void

    @State private var artworkImage: NSImage?
    @State private var isHovered: Bool = false
    @State private var spineBgColor: Color = Color(red: 0.22, green: 0.26, blue: 0.30)
    @State private var spineTextColor: Color = .white

    private var isCurrentlyPlayingThisAlbum: Bool {
        guard let current = player.currentSong else { return false }
        return album.songs.contains(where: { $0.id == current.id })
    }

    public init(
        album: Album,
        isPoppedOut: Bool,
        isOtherAlbumPoppedOut: Bool = false,
        player: AudioPlayer,
        onTogglePopOut: @escaping () -> Void,
        onSelectDetail: @escaping () -> Void
    ) {
        self.album = album
        self.isPoppedOut = isPoppedOut
        self.isOtherAlbumPoppedOut = isOtherAlbumPoppedOut
        self.player = player
        self.onTogglePopOut = onTogglePopOut
        self.onSelectDetail = onSelectDetail
    }

    public var body: some View {
        let isDiscPoppedOut = isPoppedOut && isCurrentlyPlayingThisAlbum

        ZStack(alignment: .top) {
            // MARK: - 0. Inner Dark Cardboard Sleeve Backing (visible through right notch)
            if isPoppedOut {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color(red: 0.12, green: 0.14, blue: 0.16))
                    .frame(width: 520, height: 500)
                    .offset(y: 32)
            }

            // MARK: - 1. Spinning White Vinyl Record (slides out to the right only on play)
            VinylDiscView(
                artwork: artworkImage,
                isPlaying: isCurrentlyPlayingThisAlbum && player.isPlaying,
                size: 470
            )
            .offset(
                x: isDiscPoppedOut ? 210 : 0,
                y: isPoppedOut ? 47 : 0
            )
            .opacity(isPoppedOut ? 1.0 : 0.0)
            .animation(.spring(response: 0.42, dampingFraction: 0.75), value: isDiscPoppedOut)

            // MARK: - 2. Front Album Jacket
            VStack(spacing: 0) {
                // Top Spine Edge (Clean, distinct, always visible)
                HStack(spacing: 8) {
                    if isCurrentlyPlayingThisAlbum && player.isPlaying {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(spineTextColor)
                            .padding(.trailing, 2)
                    }

                    // Bold Album Title
                    Text(album.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(spineTextColor)
                        .lineLimit(1)

                    // Regular Artist Name
                    Text(album.artistName)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(spineTextColor.opacity(0.85))
                        .lineLimit(1)

                    Spacer()

                    // Track count badge
                    Text("\(album.trackCount) tracks")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(spineTextColor.opacity(0.75))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2.5)
                        .background(spineTextColor.opacity(0.12))
                        .cornerRadius(4)
                }
                .padding(.horizontal, 14)
                .frame(width: 520, height: 32)
                .background(spineBgColor)
                .overlay(
                    // 3D tactile bevel edges
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.white.opacity(0.55))
                            .frame(height: 1.5)
                        Spacer()
                        Rectangle()
                            .fill(Color.black.opacity(0.40))
                            .frame(height: 1.5)
                    }
                )
                .shadow(
                    color: Color.black.opacity(isPoppedOut ? 0.45 : 0.25),
                    radius: isPoppedOut ? 10 : 4,
                    x: 0,
                    y: isPoppedOut ? 4 : 2
                )
                .zIndex(10)

                // Album Artwork Jacket with Right Notch Cutout
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
                            .font(.system(size: 56))
                            .foregroundColor(.white.opacity(0.9))
                    }

                    // Gentle lighting sheen
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isPoppedOut ? 0.20 : 0.08),
                            Color.clear,
                            Color.black.opacity(isPoppedOut ? 0.10 : 0.40)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    // Overlay Controls when Popped Out
                    if isPoppedOut {
                        VStack {
                            Spacer()
                            HStack(spacing: 16) {
                                Button {
                                    player.togglePlayPause()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: (isCurrentlyPlayingThisAlbum && player.isPlaying) ? "pause.fill" : "play.fill")
                                            .font(.system(size: 15, weight: .bold))
                                        Text((isCurrentlyPlayingThisAlbum && player.isPlaying) ? "Pause" : "Play")
                                            .font(.system(size: 13, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 9)
                                    .background(
                                        Capsule()
                                            .fill(Color.black.opacity(0.75))
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)

                                Button {
                                    onSelectDetail()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "list.bullet")
                                        Text("View Tracks")
                                    }
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 9)
                                    .background(
                                        Capsule()
                                            .fill(Color.black.opacity(0.75))
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.bottom, 18)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }
                    } else if isHovered {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.55))
                                .frame(width: 48, height: 48)
                            Image(systemName: (isCurrentlyPlayingThisAlbum && player.isPlaying) ? "pause.fill" : "play.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .offset(x: (isCurrentlyPlayingThisAlbum && player.isPlaying) ? 0 : 2)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: 520, height: isPoppedOut ? 500 : 260)
                .clipShape(SleeveWithNotchShape(hasNotch: isPoppedOut))
                .overlay(
                    SleeveWithNotchShape(hasNotch: isPoppedOut)
                        .stroke(Color.white.opacity(0.22), lineWidth: 1.0)
                )
            }
            .frame(width: 520)
            .rotation3DEffect(
                .degrees(isPoppedOut ? 0 : -28),
                axis: (x: 1, y: 0, z: 0),
                anchor: .top,
                perspective: 0.35
            )
            .shadow(
                color: Color.black.opacity(isPoppedOut ? 0.65 : (isHovered ? 0.38 : 0.22)),
                radius: isPoppedOut ? 32 : (isHovered ? 12 : 5),
                x: 0,
                y: isPoppedOut ? 18 : (isHovered ? 6 : 3)
            )
        }
        // Elegant separation margin above & below the selected album to part the stack
        .padding(.vertical, isPoppedOut ? 22 : 0)
        // Expand the row slot when popped out so the whole cover, white vinyl disc, and controls are visible!
        .frame(width: 780, height: isPoppedOut ? 614 : 96, alignment: .top)
        .offset(y: (isHovered && !isPoppedOut) ? -4 : 0)
        .opacity(1.0)
        .zIndex(isPoppedOut ? 999 : 0)
        .animation(.spring(response: 0.42, dampingFraction: 0.80), value: isPoppedOut)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            onTogglePopOut()
        }
        .contextMenu {
            Button("Play Album") {
                if let first = album.songs.first {
                    player.play(song: first, inContext: album.songs)
                }
            }
            Button("Shuffle Album") {
                var shuffled = album.songs
                shuffled.shuffle()
                if let first = shuffled.first {
                    player.isShuffleEnabled = true
                    player.play(song: first, inContext: album.songs)
                }
            }
            Divider()
            Button("View Album Details") {
                onSelectDetail()
            }
        }
        .task(id: album.id) {
            await loadArtworkAndSpineColor()
        }
    }

    private func loadArtworkAndSpineColor() async {
        let initialColors = ArtworkLoader.shared.spineColors(for: album.representativeSong, fallbackID: album.id)
        self.spineBgColor = initialColors.bg
        self.spineTextColor = initialColors.text

        guard let song = album.representativeSong else { return }

        if let cached = ArtworkLoader.shared.cachedImage(for: song) {
            self.artworkImage = cached
            let extracted = ArtworkLoader.shared.extractSpineColor(from: cached)
            self.spineBgColor = extracted.bg
            self.spineTextColor = extracted.text
            return
        }

        if let loaded = await ArtworkLoader.shared.loadArtwork(for: song) {
            self.artworkImage = loaded
            let extracted = ArtworkLoader.shared.extractSpineColor(from: loaded)
            self.spineBgColor = extracted.bg
            self.spineTextColor = extracted.text
        }
    }
}
