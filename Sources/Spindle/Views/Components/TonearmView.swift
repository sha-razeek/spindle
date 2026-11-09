import SwiftUI

// MARK: - Audiophile Minimalist Tonearm View
// Modeled precisely on the Bauhaus / Teenage Engineering reference image
public struct TonearmView: View {
    public let isPlaying: Bool
    public let size: CGFloat // reference scale, default ~380

    public init(isPlaying: Bool, size: CGFloat = 380) {
        self.isPlaying = isPlaying
        self.size = size
    }

    private var scale: CGFloat {
        size / 380.0
    }

    // Geometry anchors:
    // Total height: 380 * scale.
    // Pivot is located at 68pt from top (y: 68 * scale)
    private var pivotY: CGFloat { 68.0 * scale }
    private var anchorFraction: CGFloat { 68.0 / 380.0 } // ~0.1789

    public var body: some View {
        TimelineView(.animation(paused: !isPlaying)) { timeline in
            let date = timeline.date.timeIntervalSinceReferenceDate
            let needleJitter = isPlaying ? (sin(date * 14.0) * 0.15) : 0.0

            // Resting angle: -14.0° (lifted and resting safely away from the vinyl disc)
            // Playing angle: +12.5° (needle tracking on vinyl music grooves)
            let angle: Double = isPlaying ? (12.5 + needleJitter) : -14.0

            ZStack(alignment: .top) {
                // Drop shadow cast by tonearm on the record / platter
                tonearmShape
                    .foregroundColor(.black.opacity(isPlaying ? 0.35 : 0.18))
                    .blur(radius: isPlaying ? 5 * scale : 9 * scale)
                    .offset(x: isPlaying ? 5 * scale : 9 * scale, y: isPlaying ? 6 * scale : 12 * scale)
                    .rotationEffect(.degrees(angle), anchor: UnitPoint(x: 0.5, y: anchorFraction))
                    .animation(.spring(response: 0.72, dampingFraction: 0.80), value: isPlaying)

                // The Tonearm Assembly
                tonearmAssembly
                    .rotationEffect(.degrees(angle), anchor: UnitPoint(x: 0.5, y: anchorFraction))
                    .animation(.spring(response: 0.72, dampingFraction: 0.80), value: isPlaying)
            }
            .frame(width: 80 * scale, height: 380 * scale)
        }
    }

    // MARK: - Tonearm Assembly (From Top Counterweight to Bottom Headshell)
    private var tonearmAssembly: some View {
        VStack(spacing: 0) {
            // 1. Counterweight with Orange End Button (Top, extending behind pivot)
            counterweightSection
                .frame(height: 52 * scale)

            // 2. Gimbal Pivot Block & Integral Base Lobe (At pivot point y = 68 * scale)
            gimbalAndBaseSection
                .frame(height: 36 * scale)

            // 3. Satin Silver Aluminum Arm Wand Tube
            armWandSection

            // 4. Connecting Collar
            collarSection

            // 5. Headshell & Cartridge (Bottom, tracking record grooves)
            headshellSection
        }
        .frame(width: 80 * scale)
    }

    // MARK: - 1. Counterweight Section
    private var counterweightSection: some View {
        VStack(spacing: 0) {
            // Vibrant Orange End Plug / Button (Signature Bauhaus accent)
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

            // Cylindrical Satin Aluminum Counterweight Barrel
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
                .frame(width: 32 * scale, height: 22 * scale)
                .overlay(
                    RoundedRectangle(cornerRadius: 2.5 * scale)
                        .stroke(Color.white.opacity(0.40), lineWidth: 0.6 * scale)
                )

            // Connecting Spindle Shaft to Gimbal
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.90), Color(white: 0.70)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 7 * scale, height: 16 * scale)
        }
    }

    // MARK: - 2. Gimbal Pivot Housing & Base Lobe
    private var gimbalAndBaseSection: some View {
        ZStack(alignment: .leading) {
            // Lower Base Plate Lobe (extending to the right side of the pivot)
            HStack(spacing: 0) {
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 5 * scale, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.90, green: 0.89, blue: 0.87),
                                    Color(red: 0.86, green: 0.85, blue: 0.83)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28 * scale, height: 28 * scale)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5 * scale, style: .continuous)
                                .stroke(Color.white.opacity(0.50), lineWidth: 0.75 * scale)
                        )

                    // Dial & button on the base plate (matching reference image)
                    HStack(spacing: 3.5 * scale) {
                        // Small black circular button/pin
                        Circle()
                            .fill(Color(white: 0.20))
                            .frame(width: 5 * scale, height: 5 * scale)
                            .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)

                        // Knurled silver dial with indicator tick line
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color(white: 0.92), Color(white: 0.74), Color(white: 0.65)],
                                        center: .center,
                                        startRadius: 1,
                                        endRadius: 6 * scale
                                    )
                                )
                                .frame(width: 13 * scale, height: 13 * scale)
                                .overlay(Circle().stroke(Color.black.opacity(0.25), lineWidth: 0.6 * scale))

                            // Indicator tick
                            Rectangle()
                                .fill(Color.black.opacity(0.70))
                                .frame(width: 1 * scale, height: 4 * scale)
                                .offset(y: -2 * scale)
                        }
                    }
                }
                .offset(x: 10 * scale, y: 2 * scale)
            }
            .frame(width: 80 * scale)

            // Main Gimbal Pivot Housing Block (Centered on the arm axis)
            ZStack {
                RoundedRectangle(cornerRadius: 4 * scale, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.92, green: 0.91, blue: 0.89),
                                Color(red: 0.88, green: 0.87, blue: 0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 34 * scale, height: 32 * scale)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4 * scale, style: .continuous)
                            .stroke(Color.white.opacity(0.60), lineWidth: 0.75 * scale)
                    )

                // Top & Bottom horizontal pivot screws
                VStack {
                    Circle()
                        .fill(LinearGradient(colors: [Color(white: 0.85), Color(white: 0.55)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 4.5 * scale, height: 4.5 * scale)
                        .overlay(Circle().stroke(Color.black.opacity(0.3), lineWidth: 0.5 * scale))
                    Spacer()
                    Circle()
                        .fill(LinearGradient(colors: [Color(white: 0.85), Color(white: 0.55)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 4.5 * scale, height: 4.5 * scale)
                        .overlay(Circle().stroke(Color.black.opacity(0.3), lineWidth: 0.5 * scale))
                }
                .padding(.vertical, 2 * scale)
            }
            .frame(width: 80 * scale, alignment: .center)
        }
    }

    // MARK: - 3. Satin Silver Aluminum Arm Wand Tube
    private var armWandSection: some View {
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
            .frame(width: 8 * scale, height: 200 * scale)
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
    }

    // MARK: - 4. Connecting Collar
    private var collarSection: some View {
        RoundedRectangle(cornerRadius: 1 * scale)
            .fill(
                LinearGradient(
                    colors: [Color(white: 0.88), Color(white: 0.68), Color(white: 0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 10 * scale, height: 5 * scale)
            .overlay(
                RoundedRectangle(cornerRadius: 1 * scale)
                    .stroke(Color.white.opacity(0.40), lineWidth: 0.5 * scale)
            )
    }

    // MARK: - 5. Minimalist Headshell & Cartridge
    private var headshellSection: some View {
        ZStack(alignment: .topTrailing) {
            // Main Headshell Block (Matte off-white)
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
                    .frame(width: 25 * scale, height: 44 * scale)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3.5 * scale, style: .continuous)
                            .stroke(Color.white.opacity(0.55), lineWidth: 0.75 * scale)
                    )

                // Yellow Accent Block at the top-left corner (from reference image)
                RoundedRectangle(cornerRadius: 1 * scale)
                    .fill(Color(red: 0.95, green: 0.84, blue: 0.35))
                    .frame(width: 7.5 * scale, height: 8.5 * scale)
                    .offset(x: 2 * scale, y: 2.5 * scale)

                // Two Orange Screw Points on the side of headshell
                VStack(spacing: 8 * scale) {
                    Circle()
                        .fill(Color(red: 0.94, green: 0.58, blue: 0.27))
                        .frame(width: 4 * scale, height: 4 * scale)
                    Circle()
                        .fill(Color(red: 0.94, green: 0.58, blue: 0.27))
                        .frame(width: 4 * scale, height: 4 * scale)
                }
                .offset(x: 17 * scale, y: 12 * scale)
            }

            // Finger cue lift tab extending to the right
            Path { path in
                path.move(to: CGPoint(x: 25 * scale, y: 22 * scale))
                path.addLine(to: CGPoint(x: 35 * scale, y: 24 * scale))
                path.addLine(to: CGPoint(x: 35 * scale, y: 27 * scale))
                path.addLine(to: CGPoint(x: 25 * scale, y: 26 * scale))
            }
            .fill(Color(red: 0.89, green: 0.88, blue: 0.86))

            // Vibrant Orange Cartridge Body protruding at the bottom
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
                .frame(width: 15 * scale, height: 12 * scale)
                .overlay(
                    // Stylus cantilever pin & diamond tip
                    VStack {
                        Spacer()
                        Circle()
                            .fill(Color(white: 0.90))
                            .frame(width: 2.5 * scale, height: 2.5 * scale)
                            .shadow(color: Color.black.opacity(0.4), radius: 1, x: 0, y: 1)
                            .offset(y: 1.5 * scale)
                    }
                )
                .offset(x: -5 * scale, y: 44 * scale)
        }
        .frame(width: 40 * scale, height: 58 * scale, alignment: .topLeading)
        .offset(x: 18 * scale)
    }

    // Shadow silhouette
    private var tonearmShape: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2.5 * scale)
                .frame(width: 32 * scale, height: 32 * scale)
            RoundedRectangle(cornerRadius: 4 * scale)
                .frame(width: 34 * scale, height: 32 * scale)
            Rectangle()
                .frame(width: 8 * scale, height: 200 * scale)
            RoundedRectangle(cornerRadius: 3.5 * scale)
                .frame(width: 25 * scale, height: 48 * scale)
        }
        .frame(width: 80 * scale)
    }
}
