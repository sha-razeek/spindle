import SwiftUI

public struct TonearmView: View {
    public let isPlaying: Bool
    public let size: CGFloat // reference scale, default ~300

    public init(isPlaying: Bool, size: CGFloat = 300) {
        self.isPlaying = isPlaying
        self.size = size
    }

    // Scale factor relative to base design size (300pt height)
    private var scale: CGFloat {
        size / 300.0
    }

    public var body: some View {
        TimelineView(.animation(paused: !isPlaying)) { timeline in
            let date = timeline.date.timeIntervalSinceReferenceDate
            // Micro-vibration to simulate needle groove tracking while playing
            let needleJitter = isPlaying ? (sin(date * 14.0) * 0.18) : 0.0

            // Rest angle: -14 degrees (resting on the armrest clip)
            // Playing angle: +8.5 degrees (needle resting on outer-mid vinyl grooves)
            let targetAngle: Double = isPlaying ? (8.5 + needleJitter) : -14.0

            ZStack(alignment: .topTrailing) {
                // MARK: - 1. Recessed Deck Plinth Base (Matching reference image)
                deckBaseRecess

                // MARK: - 2. Stationary Armrest Post & Cueing Lift
                armRestPost
                    .offset(x: -16 * scale, y: 155 * scale)

                // MARK: - 3. Rotating Tonearm Assembly (Pivots around gimbal base)
                tonearmAssembly
                    .rotationEffect(.degrees(targetAngle), anchor: UnitPoint(x: 0.76, y: 0.165))
                    .animation(.spring(response: 0.65, dampingFraction: 0.78), value: isPlaying)
            }
            .frame(width: 140 * scale, height: 320 * scale)
        }
    }

    // MARK: - Deck Base Recess
    private var deckBaseRecess: some View {
        ZStack {
            // Oblong rounded recess in the turntable plinth
            RoundedRectangle(cornerRadius: 32 * scale, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.12),
                            Color.black.opacity(0.04),
                            Color.white.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 32 * scale, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.20),
                                    Color.white.opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5 * scale
                        )
                )
                .frame(width: 66 * scale, height: 110 * scale)
                .offset(x: -8 * scale, y: 8 * scale)

            // Inner Pivot Base Ring
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(white: 0.35),
                            Color(white: 0.18),
                            Color(white: 0.10)
                        ],
                        center: .center,
                        startRadius: 4 * scale,
                        endRadius: 28 * scale
                    )
                )
                .frame(width: 52 * scale, height: 52 * scale)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.4), Color.black.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5 * scale
                        )
                )
                .shadow(color: Color.black.opacity(0.4), radius: 4 * scale, x: 0, y: 2 * scale)
                .offset(x: -15 * scale, y: 26 * scale)
        }
    }

    // MARK: - Armrest Post
    private var armRestPost: some View {
        ZStack {
            // Post column
            RoundedRectangle(cornerRadius: 2 * scale)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.6), Color(white: 0.25)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 5 * scale, height: 18 * scale)

            // U-shaped arm cradle clip
            HStack(spacing: 4 * scale) {
                RoundedRectangle(cornerRadius: 1 * scale)
                    .fill(Color(white: 0.2))
                    .frame(width: 2.5 * scale, height: 8 * scale)
                Spacer()
                RoundedRectangle(cornerRadius: 1 * scale)
                    .fill(Color(white: 0.2))
                    .frame(width: 2.5 * scale, height: 8 * scale)
            }
            .frame(width: 14 * scale)
            .offset(y: -9 * scale)
        }
        .shadow(color: Color.black.opacity(0.25), radius: 2 * scale, x: 1 * scale, y: 1 * scale)
    }

    // MARK: - Pivoting Tonearm Assembly
    private var tonearmAssembly: some View {
        ZStack {
            // Drop Shadow cast by the tonearm onto the deck
            tonearmSilhouette
                .foregroundColor(.black.opacity(isPlaying ? 0.35 : 0.22))
                .blur(radius: isPlaying ? 3.5 * scale : 6.0 * scale)
                .offset(x: isPlaying ? 4 * scale : 8 * scale, y: isPlaying ? 4 * scale : 9 * scale)

            // Actual metallic tonearm body
            ZStack {
                // 1. Rear Counterweight (cylindrical weight behind the pivot)
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 4 * scale)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(white: 0.35),
                                    Color(white: 0.15),
                                    Color(white: 0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 20 * scale, height: 32 * scale)
                        .overlay(
                            // Calibration tracking weight scale lines
                            HStack(spacing: 2 * scale) {
                                ForEach(0..<4) { _ in
                                    Rectangle()
                                        .fill(Color.white.opacity(0.35))
                                        .frame(width: 0.8 * scale, height: 12 * scale)
                                }
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 4 * scale)
                                .stroke(Color.white.opacity(0.2), lineWidth: 0.75 * scale)
                        )
                    Spacer()
                }
                .offset(x: 23 * scale, y: 12 * scale)

                // 2. Center Gimbal Pivot Bell / Bearing Ring
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(white: 0.85),
                                Color(white: 0.45),
                                Color(white: 0.25)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28 * scale, height: 28 * scale)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.6), lineWidth: 1 * scale)
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 3 * scale, x: 1 * scale, y: 2 * scale)
                    .offset(x: 23 * scale, y: 39 * scale)

                // 3. Brushed Aluminum Tonearm Wand
                // Straight silver cylindrical tube extending down and left
                Path { path in
                    let startX = 106.0 * scale
                    let startY = 53.0 * scale
                    let endX = 38.0 * scale
                    let endY = 245.0 * scale
                    path.move(to: CGPoint(x: startX, y: startY))
                    path.addLine(to: CGPoint(x: endX, y: endY))
                }
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(white: 0.98),
                            Color(white: 0.78),
                            Color(white: 0.60),
                            Color(white: 0.92)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 5.5 * scale, lineCap: .round)
                )

                // 4. Offset Angled Connector Collar
                Path { path in
                    let p1 = CGPoint(x: 38.0 * scale, y: 245.0 * scale)
                    let p2 = CGPoint(x: 28.0 * scale, y: 268.0 * scale)
                    path.move(to: p1)
                    path.addLine(to: p2)
                }
                .stroke(
                    Color(white: 0.18),
                    style: StrokeStyle(lineWidth: 6.5 * scale, lineCap: .square)
                )

                // 5. Matte Black Headshell & Cartridge (Angled to ride tangent to groove)
                headshellView
                    .offset(x: -36 * scale, y: 262 * scale)
            }
        }
    }

    // MARK: - Headshell & Cartridge Detail
    private var headshellView: some View {
        ZStack(alignment: .topTrailing) {
            // Main rectangular headshell block
            RoundedRectangle(cornerRadius: 3.5 * scale, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(white: 0.22),
                            Color(white: 0.12),
                            Color(white: 0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 22 * scale, height: 34 * scale)
                .rotationEffect(.degrees(24))
                .overlay(
                    RoundedRectangle(cornerRadius: 3.5 * scale, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 0.75 * scale)
                        .rotationEffect(.degrees(24))
                )

            // Stylus cartridge tip housing
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.85), Color.red.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 8 * scale, height: 5 * scale)
                .rotationEffect(.degrees(24))
                .offset(x: -8 * scale, y: 27 * scale)

            // Finger lift cueing tab on the right edge
            Path { path in
                path.move(to: CGPoint(x: 18 * scale, y: 6 * scale))
                path.addQuadCurve(
                    to: CGPoint(x: 28 * scale, y: 0),
                    control: CGPoint(x: 25 * scale, y: 1 * scale)
                )
            }
            .stroke(Color(white: 0.4), style: StrokeStyle(lineWidth: 1.5 * scale, lineCap: .round))
        }
    }

    // MARK: - Silhouette for soft realistic drop shadow
    private var tonearmSilhouette: some View {
        ZStack {
            Circle()
                .frame(width: 28 * scale, height: 28 * scale)
                .offset(x: 23 * scale, y: 39 * scale)

            Path { path in
                let startX = 106.0 * scale
                let startY = 53.0 * scale
                let endX = 28.0 * scale
                let endY = 268.0 * scale
                path.move(to: CGPoint(x: startX, y: startY))
                path.addLine(to: CGPoint(x: endX, y: endY))
            }
            .stroke(Color.black, style: StrokeStyle(lineWidth: 7 * scale, lineCap: .round))

            RoundedRectangle(cornerRadius: 3.5 * scale)
                .frame(width: 22 * scale, height: 34 * scale)
                .rotationEffect(.degrees(24))
                .offset(x: -36 * scale, y: 262 * scale)
        }
    }
}
