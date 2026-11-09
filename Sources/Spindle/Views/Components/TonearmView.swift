import SwiftUI

// MARK: - Audiophile Minimalist Tonearm View
// Modeled precisely on the Bauhaus / Teenage Engineering reference image
public struct TonearmView: View {
    public let isPlaying: Bool
    public let size: CGFloat // reference height, default ~380

    public init(isPlaying: Bool, size: CGFloat = 380) {
        self.isPlaying = isPlaying
        self.size = size
    }

    private var scale: CGFloat {
        size / 380.0
    }

    // Geometry anchors:
    // Total frame: width = 90 * scale, height = 380 * scale.
    // Centerline is at x = 45 * scale.
    // Pivot axis is at y = 67 * scale (inside the pivot block).
    private var centerX: CGFloat { 45.0 * scale }
    private var pivotY: CGFloat { 67.0 * scale }
    private var anchorFraction: CGFloat { 67.0 / 380.0 } // ~0.1763

    public var body: some View {
        TimelineView(.animation(paused: !isPlaying)) { timeline in
            let date = timeline.date.timeIntervalSinceReferenceDate
            let needleJitter = isPlaying ? (sin(date * 14.0) * 0.15) : 0.0

            // Resting angle: -14.0° (lifted and resting safely away from the vinyl disc)
            // Playing angle: +11.5° (needle tracking on vinyl music grooves)
            let angle: Double = isPlaying ? (11.5 + needleJitter) : -14.0

            ZStack(alignment: .topLeading) {
                // Drop shadow cast by tonearm on the record / platter
                tonearmSilhouette
                    .foregroundColor(.black.opacity(isPlaying ? 0.35 : 0.18))
                    .blur(radius: isPlaying ? 5 * scale : 9 * scale)
                    .offset(x: isPlaying ? 5 * scale : 9 * scale, y: isPlaying ? 7 * scale : 13 * scale)
                    .rotationEffect(.degrees(angle), anchor: UnitPoint(x: 0.5, y: anchorFraction))
                    .animation(.spring(response: 0.72, dampingFraction: 0.80), value: isPlaying)

                // The Complete Unified Tonearm Assembly
                tonearmBody
                    .rotationEffect(.degrees(angle), anchor: UnitPoint(x: 0.5, y: anchorFraction))
                    .animation(.spring(response: 0.72, dampingFraction: 0.80), value: isPlaying)
            }
            .frame(width: 90 * scale, height: 380 * scale)
        }
    }

    // MARK: - Unified Tonearm Body (All elements aligned on centerX)
    private var tonearmBody: some View {
        ZStack(alignment: .topLeading) {
            // 1. Spindle Shaft & Arm Wand Tube (Runs continuously from orange button through counterweight, pivot, down into headshell)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(white: 0.98),
                            Color(white: 0.86),
                            Color(white: 0.72),
                            Color(white: 0.92)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 8 * scale, height: 322 * scale)
                .overlay(
                    // Specular highlight line along the cylindrical tube
                    HStack {
                        Rectangle()
                            .fill(Color.white.opacity(0.70))
                            .frame(width: 1.8 * scale)
                            .padding(.leading, 1.2 * scale)
                        Spacer()
                    }
                )
                .offset(x: centerX - 4 * scale, y: 4 * scale)

            // 2. Base Plate Platform & Side Lobe (Underlaps the pivot block and extends rightward with dial and button)
            ZStack(alignment: .trailing) {
                RoundedRectangle(cornerRadius: 5 * scale, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.90, green: 0.89, blue: 0.87),
                                Color(red: 0.85, green: 0.84, blue: 0.82)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36 * scale, height: 30 * scale)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5 * scale, style: .continuous)
                            .stroke(Color.white.opacity(0.50), lineWidth: 0.75 * scale)
                    )

                HStack(spacing: 4 * scale) {
                    // Small black circular button/pin
                    Circle()
                        .fill(Color(white: 0.20))
                        .frame(width: 4.5 * scale, height: 4.5 * scale)
                        .shadow(color: Color.black.opacity(0.25), radius: 0.5, x: 0, y: 0.5)

                    // Knurled silver dial with indicator tick line
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color(white: 0.94), Color(white: 0.76), Color(white: 0.65)],
                                    center: .center,
                                    startRadius: 1,
                                    endRadius: 6.5 * scale
                                )
                            )
                            .frame(width: 13 * scale, height: 13 * scale)
                            .overlay(Circle().stroke(Color.black.opacity(0.30), lineWidth: 0.6 * scale))

                        // Indicator tick
                        Rectangle()
                            .fill(Color.black.opacity(0.75))
                            .frame(width: 1 * scale, height: 4.5 * scale)
                            .offset(y: -2.5 * scale)
                    }
                }
                .padding(.trailing, 4 * scale)
            }
            .frame(width: 36 * scale, height: 30 * scale)
            .offset(x: centerX + 6 * scale, y: 52 * scale)

            // 3. Gimbal Pivot Block (Enclosing the tube at the pivot axis, centered on centerX)
            ZStack {
                RoundedRectangle(cornerRadius: 4.5 * scale, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.93, green: 0.92, blue: 0.90),
                                Color(red: 0.88, green: 0.87, blue: 0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36 * scale, height: 38 * scale)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4.5 * scale, style: .continuous)
                            .stroke(Color.white.opacity(0.60), lineWidth: 0.75 * scale)
                    )

                // Top & Bottom horizontal pivot screw caps
                VStack {
                    Circle()
                        .fill(LinearGradient(colors: [Color(white: 0.88), Color(white: 0.58)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 4.5 * scale, height: 4.5 * scale)
                        .overlay(Circle().stroke(Color.black.opacity(0.3), lineWidth: 0.5 * scale))
                    Spacer()
                    Circle()
                        .fill(LinearGradient(colors: [Color(white: 0.88), Color(white: 0.58)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 4.5 * scale, height: 4.5 * scale)
                        .overlay(Circle().stroke(Color.black.opacity(0.3), lineWidth: 0.5 * scale))
                }
                .padding(.vertical, 3 * scale)
            }
            .frame(width: 36 * scale, height: 38 * scale)
            .offset(x: centerX - 18 * scale, y: 48 * scale)

            // 4. Counterweight Barrel (Mounted on rear spindle shaft, centered on centerX)
            ZStack {
                RoundedRectangle(cornerRadius: 2.5 * scale)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(white: 0.94),
                                Color(white: 0.80),
                                Color(white: 0.70),
                                Color(white: 0.88)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 34 * scale, height: 24 * scale)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2.5 * scale)
                            .stroke(Color.white.opacity(0.40), lineWidth: 0.6 * scale)
                    )

                // Precision knurling ribs on forward half
                HStack(spacing: 2.5 * scale) {
                    ForEach(0..<6) { _ in
                        Rectangle()
                            .fill(Color.black.opacity(0.08))
                            .frame(width: 0.8 * scale, height: 18 * scale)
                    }
                }
                .offset(y: 2 * scale)
            }
            .frame(width: 34 * scale, height: 24 * scale)
            .offset(x: centerX - 17 * scale, y: 7 * scale)

            // 5. Orange End Button (Signature Bauhaus accent at the very top, centered on centerX)
            RoundedRectangle(cornerRadius: 2 * scale)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.96, green: 0.62, blue: 0.30),
                            Color(red: 0.90, green: 0.54, blue: 0.24)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 14 * scale, height: 7 * scale)
                .offset(x: centerX - 7 * scale, y: 0)

            // 6. Connecting Collar (At the junction where tube enters headshell, centered on centerX)
            RoundedRectangle(cornerRadius: 1 * scale)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.88), Color(white: 0.68), Color(white: 0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 11 * scale, height: 6 * scale)
                .offset(x: centerX - 5.5 * scale, y: 314 * scale)

            // 7. Headshell Block (Directly attached to the wand along centerX!)
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 3.5 * scale, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.92, green: 0.91, blue: 0.89),
                                Color(red: 0.87, green: 0.86, blue: 0.84)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 26 * scale, height: 46 * scale)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3.5 * scale, style: .continuous)
                            .stroke(Color.white.opacity(0.55), lineWidth: 0.75 * scale)
                    )

                // Yellow Accent Block at the top-left corner
                RoundedRectangle(cornerRadius: 1 * scale)
                    .fill(Color(red: 0.95, green: 0.84, blue: 0.35))
                    .frame(width: 7.5 * scale, height: 8.5 * scale)
                    .offset(x: 2.5 * scale, y: 2.5 * scale)

                // Cartridge mounting screw slots with orange accents
                VStack(spacing: 8 * scale) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 1.5 * scale)
                            .fill(Color(red: 0.94, green: 0.58, blue: 0.27))
                            .frame(width: 5 * scale, height: 6 * scale)
                        Circle()
                            .fill(LinearGradient(colors: [Color(white: 0.95), Color(white: 0.70)], startPoint: .top, endPoint: .bottom))
                            .frame(width: 3.5 * scale, height: 3.5 * scale)
                        Rectangle()
                            .fill(Color.black.opacity(0.6))
                            .frame(width: 0.6 * scale, height: 2.5 * scale)
                    }

                    ZStack {
                        RoundedRectangle(cornerRadius: 1.5 * scale)
                            .fill(Color(red: 0.94, green: 0.58, blue: 0.27))
                            .frame(width: 5 * scale, height: 6 * scale)
                        Circle()
                            .fill(LinearGradient(colors: [Color(white: 0.95), Color(white: 0.70)], startPoint: .top, endPoint: .bottom))
                            .frame(width: 3.5 * scale, height: 3.5 * scale)
                        Rectangle()
                            .fill(Color.black.opacity(0.6))
                            .frame(width: 0.6 * scale, height: 2.5 * scale)
                    }
                }
                .offset(x: 17 * scale, y: 14 * scale)
            }
            .offset(x: centerX - 13 * scale, y: 318 * scale)

            // 8. Finger Cue Lift Tab (Attached and extending to the right of the headshell)
            RoundedRectangle(cornerRadius: 1.5 * scale)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.90, green: 0.89, blue: 0.87), Color(red: 0.84, green: 0.83, blue: 0.81)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 14 * scale, height: 3.5 * scale)
                .offset(x: centerX + 12 * scale, y: 341 * scale)

            // 9. Vibrant Orange Cartridge Body (Protruding out the bottom of the headshell along centerX)
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 2 * scale)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.96, green: 0.60, blue: 0.28),
                                Color(red: 0.90, green: 0.52, blue: 0.22)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 15 * scale, height: 14 * scale)

                // Stylus Cantilever & Diamond Tip
                Circle()
                    .fill(Color(white: 0.90))
                    .frame(width: 2.5 * scale, height: 2.5 * scale)
                    .shadow(color: Color.black.opacity(0.4), radius: 1, x: 0, y: 1)
                    .offset(y: 2 * scale)
            }
            .offset(x: centerX - 7.5 * scale, y: 364 * scale)
        }
        .frame(width: 90 * scale, height: 380 * scale, alignment: .topLeading)
    }

    // Shadow silhouette
    private var tonearmSilhouette: some View {
        ZStack(alignment: .topLeading) {
            // Counterweight & orange plug shadow
            RoundedRectangle(cornerRadius: 2.5 * scale)
                .frame(width: 34 * scale, height: 32 * scale)
                .offset(x: centerX - 17 * scale, y: 2 * scale)

            // Base plate platform lobe shadow
            RoundedRectangle(cornerRadius: 5 * scale)
                .frame(width: 36 * scale, height: 30 * scale)
                .offset(x: centerX + 6 * scale, y: 52 * scale)

            // Gimbal pivot block shadow
            RoundedRectangle(cornerRadius: 4.5 * scale)
                .frame(width: 36 * scale, height: 38 * scale)
                .offset(x: centerX - 18 * scale, y: 48 * scale)

            // Aluminum tube wand shadow
            Rectangle()
                .frame(width: 8 * scale, height: 234 * scale)
                .offset(x: centerX - 4 * scale, y: 86 * scale)

            // Headshell, finger lift and cartridge shadow
            RoundedRectangle(cornerRadius: 3.5 * scale)
                .frame(width: 26 * scale, height: 60 * scale)
                .offset(x: centerX - 13 * scale, y: 318 * scale)
        }
        .frame(width: 90 * scale, height: 380 * scale, alignment: .topLeading)
    }
}
