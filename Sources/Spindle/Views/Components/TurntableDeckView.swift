import SwiftUI
import AppKit

public struct TurntableDeckView: View {
    let album: Album?
    let isPlaying: Bool
    @ObservedObject var player: AudioPlayer
    var onTogglePlay: () -> Void
    var onSelectDetail: () -> Void
    var onEject: (() -> Void)? = nil

    @State private var artworkImage: NSImage?
    @State private var isHoveringJacket: Bool = false
    @State private var isHoveringVinyl: Bool = false

    public init(
        album: Album?,
        isPlaying: Bool,
        player: AudioPlayer,
        onTogglePlay: @escaping () -> Void,
        onSelectDetail: @escaping () -> Void,
        onEject: (() -> Void)? = nil
    ) {
        self.album = album
        self.isPlaying = isPlaying
        self.player = player
        self.onTogglePlay = onTogglePlay
        self.onSelectDetail = onSelectDetail
        self.onEject = onEject
    }

    private var currentSong: Song? {
        player.currentSong ?? album?.representativeSong
    }

    public var body: some View {
        GeometryReader { geo in
            let availableH = geo.size.height
            let availableW = geo.size.width

            // Dynamic responsive scaling for album art and turntable display:
            // Calculate headroom so it gracefully scales up to 920pt on 4K displays
            let minLeftPadding: CGFloat = max(24, min(64, availableW * 0.035))
            let minRightMargin: CGFloat = max(24, min(50, availableW * 0.030))

            // Vertical constraint: ensure deck + details + margins fit comfortably
            let maxSleeveH: CGFloat = max(320, availableH - 135)

            // Horizontal constraint: total deck frame width is (sleeveSize * 1.52 + 120)
            let maxSleeveW: CGFloat = max(320, (availableW - minLeftPadding - minRightMargin - 120) / 1.52)

            // Dynamic sleeve size: up to 920pt on ultra-large 4K / 5K screens
            let sleeveSize: CGFloat = min(920, min(maxSleeveH, maxSleeveW))
            let discSlideOffset: CGFloat = sleeveSize * 0.52
            let tonearmScale: CGFloat = sleeveSize * 0.98

            // Deck width and dynamic left margin to center the turntable across wide screens
            let deckFrameWidth: CGFloat = sleeveSize + discSlideOffset + 120
            let spareWidth: CGFloat = max(0, availableW - (deckFrameWidth + minLeftPadding + minRightMargin))
            let leftPadding: CGFloat = minLeftPadding + spareWidth * 0.40

            // Mathematical alignment matching the Teenage Engineering Bauhaus turntable reference:
            // Center of the turntable platter & vinyl disc:
            let spindleX: CGFloat = discSlideOffset + sleeveSize * 0.50 // = sleeveSize * 1.02
            let spindleY: CGFloat = sleeveSize * 0.50

            // Tonearm pivot coordinates (identical between empty deck & loaded deck):
            let tonearmPivotX: CGFloat = spindleX + sleeveSize * 0.365
            let tonearmPivotY: CGFloat = spindleY - sleeveSize * 0.396
            let tScale = tonearmScale / 380.0

            let deckSpacing = max(18.0, min(28.0, sleeveSize * 0.028))
            let titleSize = max(22.0, min(34.0, sleeveSize * 0.038))
            let artistSize = max(15.0, min(22.0, sleeveSize * 0.024))
            let badgeSize = max(10.5, min(14.0, sleeveSize * 0.016))
            let metaSize = max(11.5, min(15.5, sleeveSize * 0.018))
            let detailSpacing = max(4.0, min(7.0, sleeveSize * 0.007))

            VStack(alignment: .leading, spacing: deckSpacing) {
                Spacer(minLength: 8)

                if let album = album {
                    // MARK: - Loaded Turntable Deck: Large Album + White Vinyl Disc + Tonearm
                    ZStack(alignment: .leading) {
                        // 1. Pearlescent White Vinyl Disc (Sliding out to the right onto the platter)
                        VinylDiscView(
                            artwork: artworkImage,
                            isPlaying: isPlaying,
                            size: sleeveSize,
                            isBlackVinyl: false // White vinyl disc as requested
                        )
                        .offset(x: discSlideOffset, y: 0)
                        .contentShape(Circle())
                        .onHover { h in isHoveringVinyl = h }
                        .onTapGesture { onTogglePlay() }

                        // 2. Large Front Album Sleeve / Jacket
                        albumJacketView(size: sleeveSize)
                            .contentShape(Rectangle())
                            .onHover { h in isHoveringJacket = h }
                            .onTapGesture { onTogglePlay() }

                        // 3. Precision Audiophile Tonearm (Unified placement)
                        TonearmView(
                            isPlaying: isPlaying,
                            size: tonearmScale
                        )
                        .offset(
                            x: tonearmPivotX - 50 * tScale,
                            y: tonearmPivotY - 70 * tScale
                        )
                        .allowsHitTesting(false)
                    }
                    .frame(width: deckFrameWidth, height: sleeveSize, alignment: .leading)
                    .transition(.opacity.combined(with: .scale(scale: 0.94)))

                    // MARK: - Album Details (Clean typography centered directly beneath album sleeve)
                    VStack(spacing: detailSpacing) {
                        HStack(spacing: 6) {
                            if isPlaying {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: badgeSize + 0.5, weight: .bold))
                                    .foregroundColor(.accentColor)
                            }
                            Text("NOW PLAYING")
                                .font(.system(size: badgeSize, weight: .bold))
                                .tracking(1.2)
                                .foregroundColor(.white.opacity(0.70))
                        }

                        Text(album.title)
                            .font(.system(size: titleSize, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(album.artistName)
                            .font(.system(size: artistSize, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                            .lineLimit(1)

                        HStack(spacing: 8) {
                            if album.year > 0 {
                                Text(String(album.year))
                            }
                            Text("•")
                            Text("\(album.trackCount) tracks")
                            Text("•")
                            Text(album.formattedDuration)
                        }
                        .font(.system(size: metaSize))
                        .foregroundColor(.white.opacity(0.60))
                    }
                    .frame(width: sleeveSize)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                } else {
                    // MARK: - Empty Turntable Deck (When a song/LP isn't selected)
                    emptyDiskTrayView(
                        size: sleeveSize,
                        discSlideOffset: discSlideOffset,
                        tonearmScale: tonearmScale,
                        tonearmPivotX: tonearmPivotX,
                        tonearmPivotY: tonearmPivotY
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.94)))
                }

                Spacer(minLength: 16)
            }
            .padding(.leading, leftPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .task(id: album?.id) {
            await loadArtwork()
        }
    }

    // MARK: - Empty Turntable Deck (Bauhaus Minimalist Slotted Sleeve + Matte Charcoal Platter + Orange Spindle + Tonearm)
    @ViewBuilder
    private func emptyDiskTrayView(
        size: CGFloat,
        discSlideOffset: CGFloat,
        tonearmScale: CGFloat,
        tonearmPivotX: CGFloat,
        tonearmPivotY: CGFloat
    ) -> some View {
        let tScale = tonearmScale / 380.0

        VStack(alignment: .leading, spacing: 24) {
            ZStack(alignment: .leading) {
                // 1. Recessed Deck Platter Groove Well (Subtle machined shadow channel)
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.black.opacity(0.55), Color.black.opacity(0.25)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.5
                    )
                    .frame(width: size + 8, height: size + 8)
                    .offset(x: discSlideOffset - 4, y: -4)

                // 2. Circular Matte Charcoal Turntable Platter
                ZStack {
                    // Platter Drop Shadow
                    Circle()
                        .fill(Color.black.opacity(0.50))
                        .frame(width: size, height: size)
                        .blur(radius: 14)
                        .offset(x: 2, y: 6)

                    // Matte Charcoal Platter Body
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.30, green: 0.30, blue: 0.31), // #4C4C4F
                                    Color(red: 0.22, green: 0.22, blue: 0.23), // #38383B
                                    Color(red: 0.16, green: 0.16, blue: 0.17)  // #29292B
                                ],
                                center: .center,
                                startRadius: size * 0.10,
                                endRadius: size * 0.50
                            )
                        )
                        .frame(width: size, height: size)
                        .overlay(
                            // Outer beveled rim highlight
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.18), Color.black.opacity(0.40)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )

                    // Concentric Slipmat Groove Traction Rings
                    ForEach([0.86, 0.72, 0.56, 0.40, 0.28], id: \.self) { fraction in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.06), Color.black.opacity(0.35)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                            .frame(width: size * fraction, height: size * fraction)
                    }

                    // Center Spindle Hub Assembly (Vibrant Orange Ring + Metallic Silver Pin)
                    ZStack {
                        // Vibrant Bauhaus Orange Hub Disc
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.00, green: 0.62, blue: 0.24), // #FB9239
                                        Color(red: 0.94, green: 0.48, blue: 0.14)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: size * 0.095, height: size * 0.095)
                            .overlay(
                                Circle()
                                    .stroke(Color.black.opacity(0.25), lineWidth: 0.8)
                            )
                            .shadow(color: Color.black.opacity(0.35), radius: 2.5, x: 0, y: 1.5)

                        // Center Silver Spindle Pin
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color(white: 0.98), Color(white: 0.75), Color(white: 0.50)],
                                    center: .center,
                                    startRadius: 1,
                                    endRadius: size * 0.014
                                )
                            )
                            .frame(width: size * 0.028, height: size * 0.028)
                            .overlay(Circle().stroke(Color.white.opacity(0.85), lineWidth: 0.6))
                    }
                }
                .frame(width: size, height: size)
                .offset(x: discSlideOffset, y: 0)

                // 3. Slotted Matte Off-White Dock Sleeve (Left half, framing center spindle through slot cutout)
                ZStack(alignment: .bottomLeading) {
                    // Sleeve Body with Precision Slot Cutout
                    SlottedSleeveShape()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.91, green: 0.89, blue: 0.87), // #E8E4DF warm chalk
                                    Color(red: 0.86, green: 0.84, blue: 0.82)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            SlottedSleeveShape()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.65), Color.black.opacity(0.12)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.0
                                )
                        )
                        .shadow(color: Color.black.opacity(0.40), radius: 16, x: 4, y: 6)

                    // • EJECT Label at Bottom-Left Corner
                    let ejectFontSize = max(10.5, min(14.5, size * 0.017))
                    let ejectDotSize = max(5.0, min(7.5, size * 0.009))
                    HStack(spacing: 5.5) {
                        Circle()
                            .fill(Color(red: 0.88, green: 0.22, blue: 0.18))
                            .frame(width: ejectDotSize, height: ejectDotSize)

                        Text("EJECT")
                            .font(.system(size: ejectFontSize, weight: .bold, design: .default))
                            .tracking(1.8)
                            .foregroundColor(Color(red: 0.88, green: 0.22, blue: 0.18))
                    }
                    .padding(.leading, size * 0.055)
                    .padding(.bottom, size * 0.055)
                }
                .frame(width: size, height: size)

                // 4. Audiophile Tonearm (Resting vertically on the right)
                TonearmView(
                    isPlaying: false,
                    size: tonearmScale
                )
                .offset(
                    x: tonearmPivotX - 50 * tScale,
                    y: tonearmPivotY - 70 * tScale
                )
                .allowsHitTesting(false)
            }
            .frame(width: size + discSlideOffset + 120, height: size, alignment: .leading)

            // Welcoming subtitle centered beneath the deck
            let readyIconSize = max(15.0, min(20.0, size * 0.022))
            let readyTitleSize = max(12.0, min(16.0, size * 0.018))
            let readySubSize = max(13.0, min(16.5, size * 0.019))
            VStack(spacing: max(6.0, min(9.0, size * 0.010))) {
                HStack(spacing: 7) {
                    Image(systemName: "record.circle")
                        .font(.system(size: readyIconSize, weight: .semibold))
                        .foregroundColor(.accentColor)
                    Text("TURNTABLE READY")
                        .font(.system(size: readyTitleSize, weight: .bold))
                        .tracking(1.4)
                        .foregroundColor(.white.opacity(0.85))
                }

                Text("Select an LP from the crate on the right to start playing")
                    .font(.system(size: readySubSize))
                    .foregroundColor(.white.opacity(0.60))
            }
            .frame(width: size)
        }
    }

    // MARK: - Album Jacket Sleeve
    @ViewBuilder
    private func albumJacketView(size: CGFloat) -> some View {
        let playPillSize = max(56.0, min(84.0, size * 0.10))
        let playIconSize = max(22.0, min(34.0, size * 0.040))
        let notchCornerRadius = max(8.0, min(16.0, size * 0.018))

        ZStack(alignment: .center) {
            // Artwork Image
            if let img = artworkImage {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color(white: 0.18))
                Image(systemName: "music.note")
                    .font(.system(size: size * 0.22))
                    .foregroundColor(.white.opacity(0.5))
            }

            // Realistic vinyl sleeve sheen & texture
            LinearGradient(
                colors: [
                    Color.white.opacity(0.18),
                    Color.clear,
                    Color.black.opacity(0.30)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Tactile spine crease highlight on left edge
            HStack {
                Rectangle()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 2)
                Spacer()
            }

            // Hover play pill
            if isHoveringJacket {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.65))
                        .frame(width: playPillSize, height: playPillSize)
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: playIconSize, weight: .bold))
                        .foregroundColor(.white)
                        .offset(x: isPlaying ? 0 : 2)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: size, height: size)
        .clipShape(SleeveWithNotchShape(hasNotch: true, cornerRadius: notchCornerRadius, notchDepth: size * 0.12, notchHeight: size * 0.22))
        .overlay(
            SleeveWithNotchShape(hasNotch: true, cornerRadius: notchCornerRadius, notchDepth: size * 0.12, notchHeight: size * 0.22)
                .stroke(Color.white.opacity(0.24), lineWidth: 1.2)
        )
        .shadow(color: Color.black.opacity(0.55), radius: 24, x: -6, y: 12)
    }

    private func loadArtwork() async {
        guard let song = currentSong else {
            self.artworkImage = nil
            return
        }
        if let cached = ArtworkLoader.shared.cachedImage(for: song) {
            self.artworkImage = cached
            return
        }
        if let loaded = await ArtworkLoader.shared.loadArtwork(for: song) {
            self.artworkImage = loaded
        }
    }
}

// MARK: - Slotted Dock Sleeve Shape
// Precision vector shape modeled on the Teenage Engineering minimalist turntable sleeve cutout
public struct SlottedSleeveShape: Shape {
    public var cornerRadius: CGFloat = 16
    public var slotHeightFraction: CGFloat = 0.155
    public var slotDepthFraction: CGFloat = 0.52
    public var slotInnerCornerRadius: CGFloat = 10
    public var slotMouthRadius: CGFloat = 6

    public init(
        cornerRadius: CGFloat = 16,
        slotHeightFraction: CGFloat = 0.155,
        slotDepthFraction: CGFloat = 0.52,
        slotInnerCornerRadius: CGFloat = 10,
        slotMouthRadius: CGFloat = 6
    ) {
        self.cornerRadius = cornerRadius
        self.slotHeightFraction = slotHeightFraction
        self.slotDepthFraction = slotDepthFraction
        self.slotInnerCornerRadius = slotInnerCornerRadius
        self.slotMouthRadius = slotMouthRadius
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = cornerRadius
        let sir = slotInnerCornerRadius
        let smr = slotMouthRadius

        let slotH = rect.height * slotHeightFraction
        let slotW = rect.width * slotDepthFraction
        let slotTop = rect.midY - slotH / 2
        let slotBottom = rect.midY + slotH / 2
        let slotLeft = rect.maxX - slotW

        // 1. Top-left rounded corner
        path.move(to: CGPoint(x: rect.minX + r, y: rect.minY))

        // 2. Top horizontal edge to top-right corner
        path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        path.addArc(
            center: CGPoint(x: rect.maxX - r, y: rect.minY + r),
            radius: r,
            startAngle: .degrees(-90),
            endAngle: .degrees(0),
            clockwise: false
        )

        // 3. Upper right edge down to slot mouth
        path.addLine(to: CGPoint(x: rect.maxX, y: slotTop - smr))
        path.addArc(
            center: CGPoint(x: rect.maxX - smr, y: slotTop - smr),
            radius: smr,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )

        // 4. Slot top horizontal edge inward
        path.addLine(to: CGPoint(x: slotLeft + sir, y: slotTop))
        path.addArc(
            center: CGPoint(x: slotLeft + sir, y: slotTop + sir),
            radius: sir,
            startAngle: .degrees(-90),
            endAngle: .degrees(180),
            clockwise: true
        )

        // 5. Slot inner vertical back edge
        path.addLine(to: CGPoint(x: slotLeft, y: slotBottom - sir))
        path.addArc(
            center: CGPoint(x: slotLeft + sir, y: slotBottom - sir),
            radius: sir,
            startAngle: .degrees(180),
            endAngle: .degrees(90),
            clockwise: true
        )

        // 6. Slot bottom horizontal edge outward to slot mouth
        path.addLine(to: CGPoint(x: rect.maxX - smr, y: slotBottom))
        path.addArc(
            center: CGPoint(x: rect.maxX - smr, y: slotBottom + smr),
            radius: smr,
            startAngle: .degrees(-90),
            endAngle: .degrees(0),
            clockwise: false
        )

        // 7. Lower right edge down to bottom-right corner
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        path.addArc(
            center: CGPoint(x: rect.maxX - r, y: rect.maxY - r),
            radius: r,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )

        // 8. Bottom edge to bottom-left corner
        path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        path.addArc(
            center: CGPoint(x: rect.minX + r, y: rect.maxY - r),
            radius: r,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )

        // 9. Left vertical edge back up to top-left corner
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        path.addArc(
            center: CGPoint(x: rect.minX + r, y: rect.minY + r),
            radius: r,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )

        path.closeSubpath()
        return path
    }
}
