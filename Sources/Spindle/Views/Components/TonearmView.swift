import SwiftUI
import AppKit

// MARK: - Photorealistic Tonearm Image Loader
public final class TonearmImageLoader {
    public static let shared = TonearmImageLoader()
    public private(set) var image: NSImage?

    private init() {
        // 1. App Bundle Contents/Resources
        if let url = Bundle.main.url(forResource: "tonearm", withExtension: "png"),
           let img = NSImage(contentsOf: url) {
            self.image = img
            return
        }
        // 2. Relative Resources directory (development / command line run)
        let devUrl = URL(fileURLWithPath: "Resources/tonearm.png")
        if let img = NSImage(contentsOf: devUrl) {
            self.image = img
            return
        }
        // 3. Current bundle directory traversal
        let bundleRel = Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/tonearm.png")
        if let img = NSImage(contentsOf: bundleRel) {
            self.image = img
            return
        }
    }
}

// MARK: - Audiophile Tonearm View
public struct TonearmView: View {
    public let isPlaying: Bool
    public let size: CGFloat // reference height, default ~340

    public init(isPlaying: Bool, size: CGFloat = 340) {
        self.isPlaying = isPlaying
        self.size = size
    }

    // Geometry of the tonearm image (178w x 759h):
    // Anchor at pivot bearing: x = 67 / 178 ≈ 0.3764, y = 167 / 759 ≈ 0.2200
    private let anchorX: CGFloat = 0.3764
    private let anchorY: CGFloat = 0.2200
    private let aspectRatio: CGFloat = 178.0 / 759.0

    private var armWidth: CGFloat {
        size * aspectRatio
    }

    public var body: some View {
        TimelineView(.animation(paused: !isPlaying)) { timeline in
            let date = timeline.date.timeIntervalSinceReferenceDate
            let needleJitter = isPlaying ? (sin(date * 14.0) * 0.16) : 0.0

            // Resting angle: -14.0° (lifted and resting safely away from the vinyl disc)
            // Playing angle: +12.5° (needle tracking on vinyl music grooves)
            let angle: Double = isPlaying ? (12.5 + needleJitter) : -14.0

            ZStack(alignment: .topLeading) {
                // MARK: - Photorealistic Tonearm with Realistic Drop Shadow
                if let tonearmImg = TonearmImageLoader.shared.image {
                    // Soft depth shadow cast on the turntable platter/record
                    Image(nsImage: tonearmImg)
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(.black.opacity(isPlaying ? 0.42 : 0.24))
                        .blur(radius: isPlaying ? 5 : 9)
                        .offset(x: isPlaying ? 6 : 10, y: isPlaying ? 6 : 12)
                        .frame(width: armWidth, height: size)
                        .rotationEffect(
                            .degrees(angle),
                            anchor: UnitPoint(x: anchorX, y: anchorY)
                        )
                        .animation(.spring(response: 0.72, dampingFraction: 0.80), value: isPlaying)

                    // The Photorealistic Tonearm Image (Matching reference photo exactly)
                    Image(nsImage: tonearmImg)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: armWidth, height: size)
                        .rotationEffect(
                            .degrees(angle),
                            anchor: UnitPoint(x: anchorX, y: anchorY)
                        )
                        .animation(.spring(response: 0.72, dampingFraction: 0.80), value: isPlaying)
                } else {
                    // Fallback vector representation
                    fallbackVectorTonearm(angle: angle)
                }
            }
            .frame(width: armWidth, height: size)
        }
    }

    // MARK: - Fallback Vector Tonearm (Clean design without yellow-circled elements)
    @ViewBuilder
    private func fallbackVectorTonearm(angle: Double) -> some View {
        let scale = size / 350.0
        let pivotX = 65.0 * scale
        let pivotY = 62.0 * scale

        VStack(spacing: 0) {
            // Orange counterweight cap
            RoundedRectangle(cornerRadius: 2 * scale)
                .fill(Color(red: 0.98, green: 0.52, blue: 0.12))
                .frame(width: 14 * scale, height: 7 * scale)

            // Counterweight cylinder
            RoundedRectangle(cornerRadius: 2 * scale)
                .fill(LinearGradient(colors: [Color(white: 0.96), Color(white: 0.75)], startPoint: .leading, endPoint: .trailing))
                .frame(width: 26 * scale, height: 18 * scale)

            // Gimbal bearing housing
            RoundedRectangle(cornerRadius: 5 * scale)
                .fill(LinearGradient(colors: [Color(white: 0.92), Color(white: 0.78)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 32 * scale, height: 26 * scale)

            // Arm tube
            Rectangle()
                .fill(LinearGradient(colors: [Color(white: 0.98), Color(white: 0.82), Color(white: 0.68)], startPoint: .leading, endPoint: .trailing))
                .frame(width: 8 * scale, height: 185 * scale)

            // Headshell with orange cartridge
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 3 * scale)
                    .fill(Color(white: 0.90))
                    .frame(width: 22 * scale, height: 40 * scale)

                RoundedRectangle(cornerRadius: 2 * scale)
                    .fill(Color(red: 0.98, green: 0.48, blue: 0.10))
                    .frame(width: 16 * scale, height: 24 * scale)
                    .offset(x: -6 * scale, y: 6 * scale)
            }
        }
        .frame(width: 60 * scale)
        .rotationEffect(
            .degrees(angle),
            anchor: UnitPoint(x: pivotX / (60 * scale), y: pivotY / size)
        )
        .animation(.spring(response: 0.72, dampingFraction: 0.80), value: isPlaying)
    }
}
