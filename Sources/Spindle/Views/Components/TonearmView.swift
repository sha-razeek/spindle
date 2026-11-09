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

    // Pivot center relative to the 130 x 350 frame
    private var pivotX: CGFloat { 65.0 * scale }
    private var pivotY: CGFloat { 62.0 * scale }

    public var body: some View {
        TimelineView(.animation(paused: !isPlaying)) { timeline in
            let date = timeline.date.timeIntervalSinceReferenceDate
            let needleJitter = isPlaying ? (sin(date * 14.0) * 0.16) : 0.0

            // Resting angle: -15.0° (lifted and safely parked in armrest cradle away from disc)
            // Playing angle: +13.5° (needle tracking on vinyl music grooves)
            let angle: Double = isPlaying ? (13.5 + needleJitter) : -15.0

            ZStack(alignment: .topLeading) {
                // MARK: - 1. Stationary Turntable Base & Armrest Cradle
                stationaryBase

                // MARK: - 2. Pivoting Precision Tonearm Assembly
                pivotingArm
                    .rotationEffect(
                        .degrees(angle),
                        anchor: UnitPoint(x: 65.0 / 130.0, y: 62.0 / 350.0)
                    )
                    .animation(.spring(response: 0.72, dampingFraction: 0.80), value: isPlaying)
            }
            .frame(width: 130 * scale, height: 350 * scale)
        }
    }

    // MARK: - Stationary Base (Mounting flange, anti-skate dial, cueing lever, armrest post)
    private var stationaryBase: some View {
        ZStack(alignment: .topLeading) {
            // Organic rounded base plate (pale cast aluminum)
            RoundedRectangle(cornerRadius: 18 * scale, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(white: 0.92),
                            Color(white: 0.82),
                            Color(white: 0.72)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 54 * scale, height: 72 * scale)
                .overlay(
                    RoundedRectangle(cornerRadius: 18 * scale, style: .continuous)
                        .stroke(Color.white.opacity(0.60), lineWidth: 1.0 * scale)
                )
                .shadow(color: Color.black.opacity(0.28), radius: 6 * scale, x: 2 * scale, y: 3 * scale)
                .offset(x: pivotX - 27 * scale, y: pivotY - 26 * scale)

            // Anti-skate dial on the lower right lobe (matches reference photo)
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(white: 0.95), Color(white: 0.78), Color(white: 0.65)],
                            center: .center,
                            startRadius: 1,
                            endRadius: 11 * scale
                        )
                    )
                    .frame(width: 20 * scale, height: 20 * scale)
                    .overlay(Circle().stroke(Color.black.opacity(0.35), lineWidth: 0.8 * scale))

                // Calibration markings & indicator dot
                VStack(spacing: 1.5 * scale) {
                    Circle()
                        .fill(Color.black.opacity(0.75))
                        .frame(width: 2 * scale, height: 2 * scale)
                    Rectangle()
                        .fill(Color.black.opacity(0.65))
                        .frame(width: 0.8 * scale, height: 4 * scale)
                }
            }
            .shadow(color: Color.black.opacity(0.20), radius: 2 * scale, x: 0, y: 1 * scale)
            .offset(x: pivotX + 13 * scale, y: pivotY + 16 * scale)

            // Curved cueing lift guide bar under the wand
            Path { path in
                path.move(to: CGPoint(x: pivotX - 16 * scale, y: pivotY + 44 * scale))
                path.addQuadCurve(
                    to: CGPoint(x: pivotX + 22 * scale, y: pivotY + 40 * scale),
                    control: CGPoint(x: pivotX + 4 * scale, y: pivotY + 48 * scale)
                )
            }
            .stroke(
                LinearGradient(
                    colors: [Color(white: 0.80), Color(white: 0.50)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 2.5 * scale, lineCap: .round)
            )

            // Cueing lift lever with black rubber handle
            Path { path in
                path.move(to: CGPoint(x: pivotX - 6 * scale, y: pivotY + 28 * scale))
                path.addQuadCurve(
                    to: CGPoint(x: pivotX - 24 * scale, y: pivotY + 42 * scale),
                    control: CGPoint(x: pivotX - 16 * scale, y: pivotY + 32 * scale)
                )
            }
            .stroke(Color(white: 0.40), style: StrokeStyle(lineWidth: 2.0 * scale, lineCap: .round))

            // Cueing lever rubber handle tip
            Capsule()
                .fill(Color(white: 0.15))
                .frame(width: 5 * scale, height: 11 * scale)
                .rotationEffect(.degrees(32))
                .offset(x: pivotX - 28 * scale, y: pivotY + 38 * scale)

            // Armrest post & U-cradle clip
            // Perfectly positioned under the tonearm at resting angle (-15.0°)
            // Distance = 82pt from pivot: (x: pivotX + 82*sin(15°), y: pivotY + 82*cos(15°)) = (pivotX + 21.2, pivotY + 79.2)
            armrestPostView
                .offset(x: pivotX + 21.2 * scale - 7 * scale, y: pivotY + 79.2 * scale - 6 * scale)
        }
    }

    // Armrest Post with U-clip
    private var armrestPostView: some View {
        VStack(spacing: 0) {
            // U-cradle clip
            HStack(spacing: 7 * scale) {
                RoundedRectangle(cornerRadius: 1 * scale)
                    .fill(Color(white: 0.16))
                    .frame(width: 2.5 * scale, height: 8 * scale)
                Spacer()
                RoundedRectangle(cornerRadius: 1 * scale)
                    .fill(Color(white: 0.16))
                    .frame(width: 2.5 * scale, height: 8 * scale)
            }
            .frame(width: 14 * scale)

            // Cradle crossbar
            RoundedRectangle(cornerRadius: 1 * scale)
                .fill(Color(white: 0.16))
                .frame(width: 14 * scale, height: 2.5 * scale)

            // Vertical stem post
            RoundedRectangle(cornerRadius: 1.5 * scale)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.75), Color(white: 0.45)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 4.5 * scale, height: 14 * scale)
        }
    }

    // MARK: - Pivoting Tonearm Body (Wand, Headshell, Cartridge, Gimbal, Counterweight)
    private var pivotingArm: some View {
        ZStack(alignment: .top) {
            // Soft drop shadow cast by tonearm
            tonearmShadow
                .foregroundColor(.black.opacity(isPlaying ? 0.38 : 0.20))
                .blur(radius: isPlaying ? 5 * scale : 9 * scale)
                .offset(x: isPlaying ? 5 * scale : 8 * scale, y: isPlaying ? 6 * scale : 12 * scale)

            VStack(spacing: 0) {
                // 1. Counterweight Assembly (Top, extending behind pivot)
                counterweightView

                // 2. Gimbal Bearing Yoke (At Pivot Y = 62 * scale)
                gimbalBearingView
                    .frame(height: 28 * scale)

                // 3. Satin Silver Aluminum Arm Wand Tube
                armWandView

                // 4. Connecting Collar
                collarView

                // 5. Headshell & Cartridge Assembly (Bottom, lands on vinyl)
                headshellAssemblyView
            }
            .frame(width: 60 * scale)
            .offset(x: pivotX - 30 * scale, y: pivotY - 50 * scale)
        }
    }

    // MARK: - Counterweight Assembly (Behind Pivot)
    private var counterweightView: some View {
        VStack(spacing: 0) {
            // Vibrant Orange End Cap Button (Signature detail from reference image 2)
            RoundedRectangle(cornerRadius: 2 * scale)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.98, green: 0.52, blue: 0.12),
                            Color(red: 0.88, green: 0.38, blue: 0.08)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 13 * scale, height: 6.5 * scale)

            // Main Counterweight Barrel
            RoundedRectangle(cornerRadius: 2 * scale)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.96), Color(white: 0.82), Color(white: 0.65)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 25 * scale, height: 16 * scale)
                .overlay(
                    RoundedRectangle(cornerRadius: 2 * scale)
                        .stroke(Color.white.opacity(0.40), lineWidth: 0.5 * scale)
                )

            // Knurled Ring Section with fine texture stripes
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.90), Color(white: 0.72), Color(white: 0.60)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 24 * scale, height: 9 * scale)
                .overlay(
                    HStack(spacing: 1.8 * scale) {
                        ForEach(0..<8) { _ in
                            Rectangle()
                                .fill(Color.black.opacity(0.28))
                                .frame(width: 0.8 * scale, height: 9 * scale)
                        }
                    }
                )

            // Connecting rear stub to gimbal
            Rectangle()
                .fill(Color(white: 0.78))
                .frame(width: 9 * scale, height: 7 * scale)
        }
    }

    // MARK: - Gimbal Bearing Yoke (At Pivot Point)
    private var gimbalBearingView: some View {
        ZStack {
            // Pale off-white / silver cast gimbal housing
            RoundedRectangle(cornerRadius: 6 * scale, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.93), Color(white: 0.82), Color(white: 0.70)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32 * scale, height: 26 * scale)
                .overlay(
                    RoundedRectangle(cornerRadius: 6 * scale, style: .continuous)
                        .stroke(Color.white.opacity(0.50), lineWidth: 0.8 * scale)
                )

            // Horizontal bearing pivot screw cap
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.85), Color(white: 0.45)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 9 * scale, height: 9 * scale)
                .overlay(
                    Circle().stroke(Color.black.opacity(0.4), lineWidth: 0.75 * scale)
                        .overlay(
                            Rectangle()
                                .fill(Color.black.opacity(0.65))
                                .frame(width: 5 * scale, height: 1.0 * scale)
                        )
                )
        }
    }

    // MARK: - Straight Satin Aluminum Wand Tube
    private var armWandView: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color(white: 0.98),
                        Color(white: 0.85),
                        Color(white: 0.68),
                        Color(white: 0.90)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: 8.5 * scale, height: 180 * scale)
            .overlay(
                // Specular cylindrical highlight line
                HStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.65))
                        .frame(width: 1.8 * scale)
                        .padding(.leading, 1.2 * scale)
                    Spacer()
                }
            )
    }

    // Collar
    private var collarView: some View {
        RoundedRectangle(cornerRadius: 1.5 * scale)
            .fill(
                LinearGradient(
                    colors: [Color(white: 0.88), Color(white: 0.65), Color(white: 0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 10 * scale, height: 7 * scale)
            .overlay(
                RoundedRectangle(cornerRadius: 1.5 * scale)
                    .stroke(Color.white.opacity(0.35), lineWidth: 0.5 * scale)
            )
    }

    // MARK: - Headshell & Cartridge Detail (Matches exact reference photo 2)
    private var headshellAssemblyView: some View {
        ZStack(alignment: .topTrailing) {
            // Bright Orange Audio-Technica / Ortofon style Cartridge underneath
            VStack(spacing: 0) {
                // Cartridge body
                RoundedRectangle(cornerRadius: 2.5 * scale)
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
                    .frame(width: 16 * scale, height: 26 * scale)
                    .overlay(
                        // Stylus cantilever pin & tip
                        VStack {
                            Spacer()
                            Circle()
                                .fill(Color(white: 0.90))
                                .frame(width: 2.8 * scale, height: 2.8 * scale)
                                .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1)
                                .offset(y: 2 * scale)
                        }
                    )

                // Wire terminal pins
                HStack(spacing: 1.5 * scale) {
                    Circle().fill(Color.red).frame(width: 2 * scale)
                    Circle().fill(Color.green).frame(width: 2 * scale)
                    Circle().fill(Color.blue).frame(width: 2 * scale)
                }
                .offset(y: 2 * scale)
            }
            .offset(x: -8 * scale, y: 8 * scale)

            // Molded Matte Off-White Headshell Housing
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 3 * scale, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.94), Color(white: 0.86), Color(white: 0.78)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 22 * scale, height: 42 * scale)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3 * scale, style: .continuous)
                            .stroke(Color.white.opacity(0.4), lineWidth: 0.75 * scale)
                    )

                // Top Cutout Slot revealing mounting screws
                ZStack {
                    RoundedRectangle(cornerRadius: 2 * scale)
                        .fill(Color(white: 0.22))
                        .frame(width: 13 * scale, height: 24 * scale)

                    // Two mounting screws with orange/red washers (as in photo 2)
                    VStack(spacing: 5 * scale) {
                        // Top screw with orange washer
                        Circle()
                            .fill(Color(red: 0.95, green: 0.45, blue: 0.15))
                            .frame(width: 6 * scale, height: 6 * scale)
                            .overlay(
                                Circle()
                                    .fill(Color(white: 0.85))
                                    .frame(width: 3.5 * scale, height: 3.5 * scale)
                                    .overlay(Rectangle().fill(Color.black.opacity(0.6)).frame(width: 2 * scale, height: 0.8 * scale))
                            )

                        // Bottom screw with red washer
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
                .offset(y: 6 * scale)

                // Outward finger cue lift tab extending to the right
                Path { path in
                    path.move(to: CGPoint(x: 22 * scale, y: 16 * scale))
                    path.addLine(to: CGPoint(x: 32 * scale, y: 18 * scale))
                    path.addLine(to: CGPoint(x: 32 * scale, y: 21 * scale))
                    path.addLine(to: CGPoint(x: 22 * scale, y: 20 * scale))
                }
                .fill(Color(white: 0.88))
            }
            .offset(x: -5 * scale)
        }
        .frame(width: 40 * scale, height: 48 * scale)
    }

    // Shadow silhouette
    private var tonearmShadow: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2 * scale)
                .frame(width: 25 * scale, height: 36 * scale)
            RoundedRectangle(cornerRadius: 6 * scale)
                .frame(width: 32 * scale, height: 26 * scale)
            Rectangle()
                .frame(width: 8.5 * scale, height: 180 * scale)
            RoundedRectangle(cornerRadius: 3 * scale)
                .frame(width: 22 * scale, height: 42 * scale)
        }
        .frame(width: 60 * scale)
        .offset(x: pivotX - 30 * scale, y: pivotY - 50 * scale)
    }
}
