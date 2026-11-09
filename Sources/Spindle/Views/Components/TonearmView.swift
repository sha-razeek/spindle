import SwiftUI

public struct TonearmView: View {
    public let isPlaying: Bool
    public let size: CGFloat // reference scale, default ~340

    public init(isPlaying: Bool, size: CGFloat = 340) {
        self.isPlaying = isPlaying
        self.size = size
    }

    private var scale: CGFloat {
        size / 340.0
    }

    public var body: some View {
        TimelineView(.animation(paused: !isPlaying)) { timeline in
            let date = timeline.date.timeIntervalSinceReferenceDate
            let needleJitter = isPlaying ? (sin(date * 14.0) * 0.16) : 0.0

            // Resting angle: -18° (lifted and parked over armrest post)
            // Playing angle: +6.5° (needle tracking on vinyl grooves)
            let angle: Double = isPlaying ? (6.5 + needleJitter) : -18.0

            ZStack(alignment: .topTrailing) {
                // Stationary Armrest Post & Cueing Mechanism Base
                armrestBase
                    .offset(x: -68 * scale, y: 72 * scale)

                // Pivoting Audiophile Tonearm (matches user's reference image)
                tonearmBody
                    .rotationEffect(.degrees(angle), anchor: UnitPoint(x: 0.81, y: 0.44))
                    .animation(.spring(response: 0.70, dampingFraction: 0.78), value: isPlaying)
            }
            .frame(width: 320 * scale, height: 160 * scale)
        }
    }

    // MARK: - Stationary Armrest & Cueing Base
    private var armrestBase: some View {
        ZStack {
            // Anti-skate dial base
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.92), Color(white: 0.78), Color(white: 0.65)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 24 * scale, height: 24 * scale)
                .overlay(
                    // Anti-skate dial markings
                    Circle()
                        .stroke(Color.black.opacity(0.35), lineWidth: 1 * scale)
                        .overlay(
                            VStack(spacing: 2 * scale) {
                                ForEach(0..<3) { _ in
                                    Rectangle()
                                        .fill(Color.black.opacity(0.6))
                                        .frame(width: 1 * scale, height: 3 * scale)
                                }
                            }
                        )
                )
                .shadow(color: Color.black.opacity(0.25), radius: 2 * scale, x: 0, y: 1.5 * scale)
                .offset(x: 10 * scale, y: 32 * scale)

            // Curved cueing lift lever with black rubber handle
            Path { path in
                path.move(to: CGPoint(x: 0, y: 18 * scale))
                path.addQuadCurve(
                    to: CGPoint(x: -14 * scale, y: -4 * scale),
                    control: CGPoint(x: -8 * scale, y: 6 * scale)
                )
            }
            .stroke(Color(white: 0.45), style: StrokeStyle(lineWidth: 2.2 * scale, lineCap: .round))

            // Cueing lever rubber tip
            Capsule()
                .fill(Color(white: 0.15))
                .frame(width: 5 * scale, height: 10 * scale)
                .rotationEffect(.degrees(-35))
                .offset(x: -16 * scale, y: -6 * scale)

            // Armrest post with U-clip
            VStack(spacing: 0) {
                // U-cradle clip
                HStack(spacing: 6 * scale) {
                    RoundedRectangle(cornerRadius: 1 * scale)
                        .fill(Color(white: 0.18))
                        .frame(width: 2.5 * scale, height: 8 * scale)
                    Spacer()
                    RoundedRectangle(cornerRadius: 1 * scale)
                        .fill(Color(white: 0.18))
                        .frame(width: 2.5 * scale, height: 8 * scale)
                }
                .frame(width: 14 * scale)

                // Stem post
                RoundedRectangle(cornerRadius: 1.5 * scale)
                    .fill(Color(white: 0.65))
                    .frame(width: 5 * scale, height: 16 * scale)
            }
            .offset(y: 4 * scale)
        }
    }

    // MARK: - Pivoting Tonearm Assembly
    private var tonearmBody: some View {
        ZStack {
            // Drop shadow cast by tonearm
            tonearmSilhouette
                .foregroundColor(.black.opacity(isPlaying ? 0.40 : 0.22))
                .blur(radius: isPlaying ? 5 * scale : 9 * scale)
                .offset(x: isPlaying ? 5 * scale : 10 * scale, y: isPlaying ? 7 * scale : 14 * scale)

            HStack(spacing: 0) {
                // 1. Headshell & Cartridge (Far Left)
                headshellAssembly
                    .offset(x: 2 * scale)

                // 2. Collar
                RoundedRectangle(cornerRadius: 1.5 * scale)
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.88), Color(white: 0.65), Color(white: 0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 7 * scale, height: 11 * scale)
                    .overlay(
                        RoundedRectangle(cornerRadius: 1.5 * scale)
                            .stroke(Color.white.opacity(0.35), lineWidth: 0.5 * scale)
                    )

                // 3. Satin Silver Aluminum Arm Wand
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(white: 0.98),
                                Color(white: 0.84),
                                Color(white: 0.68),
                                Color(white: 0.92)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 145 * scale, height: 8.5 * scale)
                    .overlay(
                        // Specular cylindrical highlight line
                        VStack {
                            Rectangle()
                                .fill(Color.white.opacity(0.65))
                                .frame(height: 1.5 * scale)
                            Spacer()
                        }
                    )

                // 4. Gimbal Pivot & Counterweight Assembly (Far Right)
                gimbalAndCounterweight
            }
        }
    }

    // MARK: - Headshell & Cartridge Detail (Matches exact reference photo)
    private var headshellAssembly: some View {
        ZStack(alignment: .leading) {
            // Bright Orange Audio-Technica / Ortofon style Cartridge underneath
            HStack(spacing: 0) {
                // Stylus body tip
                RoundedRectangle(cornerRadius: 2 * scale)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.98, green: 0.55, blue: 0.15),
                                Color(red: 0.92, green: 0.42, blue: 0.10)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 14 * scale, height: 14 * scale)
                    .overlay(
                        // Stylus cantilever pin
                        Circle()
                            .fill(Color(white: 0.85))
                            .frame(width: 2.5 * scale, height: 2.5 * scale)
                            .offset(x: -3 * scale, y: 3 * scale)
                    )

                // Rear cartridge block with red/green/blue wire terminals
                Rectangle()
                    .fill(Color(white: 0.15))
                    .frame(width: 16 * scale, height: 12 * scale)
                    .overlay(
                        HStack(spacing: 1 * scale) {
                            Circle().fill(Color.red).frame(width: 2 * scale)
                            Circle().fill(Color.green).frame(width: 2 * scale)
                            Circle().fill(Color.yellow).frame(width: 2 * scale)
                        }
                        .offset(x: 4 * scale, y: 2 * scale)
                    )
            }
            .offset(x: 0, y: 3 * scale)

            // Off-White Matte Headshell Housing (Top shell)
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 3 * scale, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.94), Color(white: 0.86), Color(white: 0.78)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44 * scale, height: 19 * scale)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3 * scale, style: .continuous)
                            .stroke(Color.white.opacity(0.4), lineWidth: 0.75 * scale)
                    )

                // Top Cutout Slot revealing mounting screws
                ZStack {
                    RoundedRectangle(cornerRadius: 2 * scale)
                        .fill(Color(white: 0.25))
                        .frame(width: 24 * scale, height: 11 * scale)

                    // Two mounting screws with red/yellow washers (as in photo)
                    HStack(spacing: 5 * scale) {
                        // Left screw with orange washer
                        Circle()
                            .fill(Color(red: 0.95, green: 0.45, blue: 0.15))
                            .frame(width: 6 * scale, height: 6 * scale)
                            .overlay(
                                Circle()
                                    .fill(Color(white: 0.85))
                                    .frame(width: 3.5 * scale, height: 3.5 * scale)
                                    .overlay(Rectangle().fill(Color.black.opacity(0.6)).frame(width: 2 * scale, height: 0.8 * scale))
                            )

                        // Right screw with red washer
                        Circle()
                            .fill(Color(red: 0.88, green: 0.22, blue: 0.20))
                            .frame(width: 6 * scale, height: 6 * scale)
                            .overlay(
                                Circle()
                                    .fill(Color(white: 0.85))
                                    .frame(width: 3.5 * scale, height: 3.5 * scale)
                                    .overlay(Rectangle().fill(Color.black.opacity(0.6)).frame(width: 2 * scale, height: 0.8 * scale))
                            )
                    }
                }
                .offset(x: -8 * scale, y: 4 * scale)

                // Downward / Forward angled finger cue lift tab
                Path { path in
                    path.move(to: CGPoint(x: 24 * scale, y: 19 * scale))
                    path.addLine(to: CGPoint(x: 22 * scale, y: 28 * scale))
                    path.addLine(to: CGPoint(x: 25 * scale, y: 28 * scale))
                    path.addLine(to: CGPoint(x: 27 * scale, y: 19 * scale))
                }
                .fill(Color(white: 0.88))
            }
            .offset(x: 4 * scale, y: -2 * scale)
        }
        .frame(width: 52 * scale)
    }

    // MARK: - Gimbal & Counterweight Assembly (Far Right)
    private var gimbalAndCounterweight: some View {
        HStack(spacing: 0) {
            // Gimbal Bearing Yoke (Organic off-white cast housing)
            ZStack {
                // Base yoke ring
                RoundedRectangle(cornerRadius: 6 * scale, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.92), Color(white: 0.80), Color(white: 0.68)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36 * scale, height: 32 * scale)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6 * scale, style: .continuous)
                            .stroke(Color.white.opacity(0.4), lineWidth: 1 * scale)
                    )

                // Horizontal pivot bearing pin screw
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.85), Color(white: 0.45)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 10 * scale, height: 10 * scale)
                    .overlay(
                        Circle().stroke(Color.black.opacity(0.4), lineWidth: 0.75 * scale)
                    )
            }

            // Knurled Aluminum Counterweight Cylinder
            ZStack(alignment: .trailing) {
                HStack(spacing: 0) {
                    // Knurled Ring Section
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color(white: 0.90), Color(white: 0.72), Color(white: 0.60)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 10 * scale, height: 26 * scale)
                        .overlay(
                            // Fine knurl texture stripes
                            HStack(spacing: 1.5 * scale) {
                                ForEach(0..<5) { _ in
                                    Rectangle()
                                        .fill(Color.black.opacity(0.25))
                                        .frame(width: 0.75 * scale, height: 26 * scale)
                                }
                            }
                        )

                    // Main Counterweight Barrel
                    RoundedRectangle(cornerRadius: 2 * scale)
                        .fill(
                            LinearGradient(
                                colors: [Color(white: 0.96), Color(white: 0.82), Color(white: 0.65)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 16 * scale, height: 28 * scale)
                }

                // Vibrant Orange End Cap Button (Signature detail from reference image)
                RoundedRectangle(cornerRadius: 2 * scale)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.98, green: 0.52, blue: 0.12),
                                Color(red: 0.88, green: 0.38, blue: 0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 6.5 * scale, height: 16 * scale)
                    .offset(x: 6 * scale)
            }
        }
    }

    // MARK: - Silhouette for realistic soft drop shadow
    private var tonearmSilhouette: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3 * scale)
                .frame(width: 48 * scale, height: 18 * scale)
            Rectangle()
                .frame(width: 152 * scale, height: 8 * scale)
            RoundedRectangle(cornerRadius: 6 * scale)
                .frame(width: 36 * scale, height: 32 * scale)
            RoundedRectangle(cornerRadius: 2 * scale)
                .frame(width: 26 * scale, height: 28 * scale)
        }
    }
}
