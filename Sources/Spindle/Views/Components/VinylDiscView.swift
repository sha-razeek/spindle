import SwiftUI
import AppKit

public struct VinylDiscView: View {
    let artwork: NSImage?
    let isPlaying: Bool
    let size: CGFloat

    public init(artwork: NSImage?, isPlaying: Bool, size: CGFloat = 450) {
        self.artwork = artwork
        self.isPlaying = isPlaying
        self.size = size
    }

    public var body: some View {
        TimelineView(.animation(paused: !isPlaying)) { timeline in
            let date = timeline.date.timeIntervalSinceReferenceDate
            // Rotate at ~33 1/3 RPM (~100 degrees per second)
            let angle = (date * 100).truncatingRemainder(dividingBy: 360)

            ZStack {
                // 1. Soft Ambient Drop Shadow cast by the disc
                Circle()
                    .fill(Color.clear)
                    .frame(width: size, height: size)
                    .shadow(color: Color.black.opacity(0.32), radius: 16, x: 8, y: 0)

                // 2. Translucent Pearlescent White Vinyl Base
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(white: 0.98),
                                Color(white: 0.94),
                                Color(white: 0.89)
                            ],
                            center: .center,
                            startRadius: size * 0.15,
                            endRadius: size * 0.50
                        )
                    )
                    .frame(width: size, height: size)

                // 3. Subtle Outer Pressed Edge Ring (Milky clear vinyl rim)
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.95),
                                Color(white: 0.80).opacity(0.6),
                                Color.white.opacity(0.90)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: size - 2, height: size - 2)

                // 4. Concentric Sound Grooves (Fine micro-etched lines in white vinyl)
                ForEach(stride(from: size * 0.20, to: size * 0.47, by: size * 0.016).map { CGFloat($0) }, id: \.self) { r in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.06),
                                    Color.white.opacity(0.55),
                                    Color.black.opacity(0.04),
                                    Color.white.opacity(0.40)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.85
                        )
                        .frame(width: r * 2, height: r * 2)
                }

                // Lead-in outer silent groove
                Circle()
                    .stroke(Color.black.opacity(0.08), lineWidth: 1.2)
                    .frame(width: size * 0.95, height: size * 0.95)

                // Lead-out run-out inner groove ring
                Circle()
                    .stroke(Color.black.opacity(0.07), lineWidth: 1.0)
                    .frame(width: size * 0.38, height: size * 0.38)

                // 5. Dual-Cone Specular Butterfly Sheen (Lustrous white vinyl reflection)
                AngularGradient(
                    colors: [
                        Color.clear,
                        Color.white.opacity(0.65),
                        Color.clear,
                        Color.white.opacity(0.65),
                        Color.clear
                    ],
                    center: .center
                )
                .frame(width: size, height: size)
                .clipShape(Circle())

                // Secondary soft cross-sheen
                AngularGradient(
                    colors: [
                        Color.black.opacity(0.035),
                        Color.clear,
                        Color.black.opacity(0.035),
                        Color.clear
                    ],
                    center: .center,
                    angle: .degrees(90)
                )
                .frame(width: size, height: size)
                .clipShape(Circle())

                // 6. Center Paper Label (Circular album label)
                ZStack {
                    if let img = artwork {
                        Image(nsImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color(red: 0.95, green: 0.45, blue: 0.25)
                    }
                }
                .frame(width: size * 0.32, height: size * 0.32)
                .clipShape(Circle())
                .overlay(
                    // Paper label outer border
                    Circle()
                        .stroke(Color.black.opacity(0.18), lineWidth: 1.5)
                )
                .overlay(
                    // Label inner groove ring
                    Circle()
                        .stroke(Color.white.opacity(0.35), lineWidth: 1)
                        .frame(width: size * 0.24, height: size * 0.24)
                )

                // 7. Center Spindle Hole
                Circle()
                    .fill(Color(white: 0.10))
                    .frame(width: size * 0.055, height: size * 0.055)
                    .overlay(
                        Circle()
                            .stroke(Color(white: 0.85), lineWidth: 1.5)
                    )
            }
            .rotationEffect(.degrees(angle))
        }
    }
}
