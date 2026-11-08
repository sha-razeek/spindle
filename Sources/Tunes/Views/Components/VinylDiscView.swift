import SwiftUI
import AppKit

public struct VinylDiscView: View {
    let artwork: NSImage?
    let isPlaying: Bool
    let size: CGFloat

    public init(artwork: NSImage?, isPlaying: Bool, size: CGFloat = 220) {
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
                // Vinyl black base with soft drop shadow
                Circle()
                    .fill(Color(white: 0.08))
                    .frame(width: size, height: size)
                    .shadow(color: Color.black.opacity(0.4), radius: 6, x: 3, y: 0)

                // Realistic concentric sound groove rings
                ForEach(stride(from: size * 0.22, to: size * 0.46, by: size * 0.038).map { CGFloat($0) }, id: \.self) { r in
                    Circle()
                        .stroke(Color.white.opacity(0.045), lineWidth: 1)
                        .frame(width: r * 2, height: r * 2)
                }

                // Vinyl Dual-Cone Specular Sheen (authentic turntable light reflection)
                AngularGradient(
                    colors: [
                        Color.clear,
                        Color.white.opacity(0.12),
                        Color.clear,
                        Color.white.opacity(0.12),
                        Color.clear
                    ],
                    center: .center
                )
                .frame(width: size, height: size)
                .clipShape(Circle())

                // Center Paper Label
                ZStack {
                    if let img = artwork {
                        Image(nsImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color(white: 0.2)
                    }
                }
                .frame(width: size * 0.36, height: size * 0.36)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.35), lineWidth: 1.5)
                )

                // Center Spindle Hole
                Circle()
                    .fill(Color.black)
                    .frame(width: size * 0.075, height: size * 0.075)
                    .overlay(
                        Circle()
                            .stroke(Color(white: 0.7), lineWidth: 1.5)
                    )
            }
            .rotationEffect(.degrees(angle))
        }
    }
}
