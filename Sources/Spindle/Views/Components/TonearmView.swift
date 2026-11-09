import SwiftUI

// MARK: - Audiophile Minimalist Bauhaus Tonearm View
// Modeled precisely on the Teenage Engineering / Bauhaus reference image
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
    // Total frame: width = 100 * scale, height = 380 * scale.
    // Centerline is at x = 50 * scale.
    // Pivot axis is at y = 70 * scale (inside the circular pivot bearing).
    private var centerX: CGFloat { 50.0 * scale }
    private var pivotY: CGFloat { 70.0 * scale }
    private var anchorFraction: CGFloat { 70.0 / 380.0 } // ~0.1842

    public var body: some View {
        TimelineView(.animation(paused: !isPlaying)) { timeline in
            let date = timeline.date.timeIntervalSinceReferenceDate
            let needleJitter = isPlaying ? (sin(date * 14.0) * 0.15) : 0.0

            // Resting angle: -2.0° (straight vertical/slightly away from record)
            // Playing angle: +16.5° (needle tracking on vinyl music grooves)
            let angle: Double = isPlaying ? (16.5 + needleJitter) : -2.0

            ZStack(alignment: .topLeading) {
                // 1. Stationary Pedestal Base (Fixed on the deck, does not rotate)
                stationaryPedestalBase

                // 2. Dynamic Drop Shadow (Casts on platter/record and rotates with wand)
                tonearmSilhouette
                    .foregroundColor(.black.opacity(isPlaying ? 0.38 : 0.22))
                    .blur(radius: isPlaying ? 5 * scale : 8 * scale)
                    .offset(x: isPlaying ? 5 * scale : 8 * scale, y: isPlaying ? 7 * scale : 12 * scale)
                    .rotationEffect(.degrees(angle), anchor: UnitPoint(x: 0.5, y: anchorFraction))
                    .animation(.spring(response: 0.75, dampingFraction: 0.82), value: isPlaying)

                // 3. Rotating Arm Assembly (Counterweight, central hub, wand, and angled headshell)
                rotatingArmAssembly
                    .rotationEffect(.degrees(angle), anchor: UnitPoint(x: 0.5, y: anchorFraction))
                    .animation(.spring(response: 0.75, dampingFraction: 0.82), value: isPlaying)
            }
            .frame(width: 100 * scale, height: 380 * scale)
        }
    }

    // MARK: - Stationary Pedestal Base (Off-white circular puck mounted on turntable deck)
    private var stationaryPedestalBase: some View {
        ZStack {
            // Recessed base ring shadow
            Circle()
                .fill(Color.black.opacity(0.18))
                .frame(width: 78 * scale, height: 78 * scale)
                .offset(x: 1.5 * scale, y: 3 * scale)

            // Circular Pedestal Puck
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.94, green: 0.93, blue: 0.91),
                            Color(red: 0.88, green: 0.87, blue: 0.85),
                            Color(red: 0.81, green: 0.80, blue: 0.78)
                        ],
                        center: .topLeading,
                        startRadius: 4 * scale,
                        endRadius: 40 * scale
                    )
                )
                .frame(width: 76 * scale, height: 76 * scale)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.85), Color.black.opacity(0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.0 * scale
                        )
                )

            // Inner elevated bearing collar ring
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.96, green: 0.95, blue: 0.93),
                            Color(red: 0.86, green: 0.85, blue: 0.83)
                        ],
                        center: .center,
                        startRadius: 2 * scale,
                        endRadius: 25 * scale
                    )
                )
                .frame(width: 50 * scale, height: 50 * scale)
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.08), lineWidth: 0.8 * scale)
                )
        }
        .offset(x: centerX - 38 * scale, y: pivotY - 38 * scale)
    }

    // MARK: - Rotating Arm Assembly
    private var rotatingArmAssembly: some View {
        ZStack(alignment: .topLeading) {
            // A. Top Metallic Spindle Shaft Pin (Sticking out of top of counterweight)
            RoundedRectangle(cornerRadius: 1.5 * scale)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.96), Color(white: 0.78), Color(white: 0.65)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 4 * scale, height: 10 * scale)
                .offset(x: centerX - 2 * scale, y: 10 * scale)

            // B. Vibrant Bauhaus Orange Counterweight Cylinder
            ZStack {
                // Cylindrical main body
                RoundedRectangle(cornerRadius: 3.5 * scale)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.00, green: 0.64, blue: 0.28), // bright orange
                                Color(red: 0.96, green: 0.52, blue: 0.18),
                                Color(red: 0.85, green: 0.40, blue: 0.12)  // deep orange shadow
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 28 * scale, height: 26 * scale)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3.5 * scale)
                            .stroke(Color.white.opacity(0.35), lineWidth: 0.75 * scale)
                    )

                // Top bevel highlight
                VStack {
                    RoundedRectangle(cornerRadius: 1 * scale)
                        .fill(Color.white.opacity(0.40))
                        .frame(width: 24 * scale, height: 1.2 * scale)
                        .padding(.top, 1.5 * scale)
                    Spacer()
                }
            }
            .frame(width: 28 * scale, height: 26 * scale)
            .offset(x: centerX - 14 * scale, y: 19 * scale)

            // C. Rear Spindle Shaft (Between counterweight and central pivot hub)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.95), Color(white: 0.75), Color(white: 0.88)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 6.5 * scale, height: 26 * scale)
                .offset(x: centerX - 3.25 * scale, y: 44 * scale)

            // D. Front Aluminum Wand Tube (Running from pivot hub down to headshell collar)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(white: 0.98),
                            Color(white: 0.88),
                            Color(white: 0.74),
                            Color(white: 0.92)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 6.5 * scale, height: 236 * scale)
                .overlay(
                    // Specular metallic highlight line
                    HStack {
                        Rectangle()
                            .fill(Color.white.opacity(0.75))
                            .frame(width: 1.5 * scale)
                            .padding(.leading, 1.0 * scale)
                        Spacer()
                    }
                )
                .offset(x: centerX - 3.25 * scale, y: 70 * scale)

            // E. Central Elevated Pivot Bearing Cap (Sits on pivot axis over the wand)
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.95, green: 0.94, blue: 0.92),
                                Color(red: 0.86, green: 0.85, blue: 0.83),
                                Color(red: 0.78, green: 0.77, blue: 0.75)
                            ],
                            center: .topLeading,
                            startRadius: 2 * scale,
                            endRadius: 18 * scale
                        )
                    )
                    .frame(width: 34 * scale, height: 34 * scale)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.60), lineWidth: 0.75 * scale)
                    )
                    .shadow(color: Color.black.opacity(0.18), radius: 2 * scale, x: 0, y: 1.5 * scale)

                // Center recessed bearing screw
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.82), Color(white: 0.60)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 8 * scale, height: 8 * scale)
                    .overlay(Circle().stroke(Color.black.opacity(0.25), lineWidth: 0.5 * scale))
            }
            .frame(width: 34 * scale, height: 34 * scale)
            .offset(x: centerX - 17 * scale, y: pivotY - 17 * scale)

            // F. Connecting Collar Ring (At base of wand tube)
            RoundedRectangle(cornerRadius: 1 * scale)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.92), Color(white: 0.70), Color(white: 0.86)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 8.5 * scale, height: 4.5 * scale)
                .offset(x: centerX - 4.25 * scale, y: 304 * scale)

            // G. Angled Headshell Assembly (Inward offset angle ~24° towards record)
            angledHeadshellView
                .offset(x: centerX - 22 * scale, y: 308 * scale)
        }
        .frame(width: 100 * scale, height: 380 * scale, alignment: .topLeading)
    }

    // MARK: - Angled Headshell with Stylus and Orange Finger Cue Lift
    private var angledHeadshellView: some View {
        // Angled inward by +24° (towards platter center on the left)
        ZStack(alignment: .top) {
            // Headshell Body Block
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 3 * scale, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.92, green: 0.91, blue: 0.89),
                                Color(red: 0.86, green: 0.85, blue: 0.83)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 20 * scale, height: 44 * scale)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3 * scale, style: .continuous)
                            .stroke(Color.white.opacity(0.60), lineWidth: 0.75 * scale)
                    )

                // Twin Cartridge Screw Slots
                HStack(spacing: 5 * scale) {
                    ForEach(0..<2) { _ in
                        ZStack {
                            Capsule()
                                .fill(Color(white: 0.22))
                                .frame(width: 2.2 * scale, height: 8.5 * scale)

                            Circle()
                                .fill(LinearGradient(colors: [Color(white: 0.90), Color(white: 0.65)], startPoint: .top, endPoint: .bottom))
                                .frame(width: 2.2 * scale, height: 2.2 * scale)
                        }
                    }
                }
                .padding(.top, 10 * scale)

                // Stylus diamond tip peek at the bottom-left corner
                VStack {
                    Spacer()
                    HStack {
                        Circle()
                            .fill(Color(white: 0.95))
                            .frame(width: 2 * scale, height: 2 * scale)
                            .padding(.leading, 3 * scale)
                        Spacer()
                    }
                    .padding(.bottom, 2 * scale)
                }
            }
            .frame(width: 20 * scale, height: 44 * scale)

            // Orange Finger Cue Lift Pin (Extending outward to the right)
            RoundedRectangle(cornerRadius: 1.6 * scale)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.98, green: 0.58, blue: 0.22),
                            Color(red: 0.92, green: 0.48, blue: 0.16)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 17 * scale, height: 3.2 * scale)
                .overlay(
                    RoundedRectangle(cornerRadius: 1.6 * scale)
                        .stroke(Color.white.opacity(0.35), lineWidth: 0.5 * scale)
                )
                .offset(x: 16 * scale, y: 22 * scale)
        }
        .frame(width: 44 * scale, height: 48 * scale, alignment: .top)
        .rotationEffect(.degrees(24.0), anchor: .top)
    }

    // MARK: - Shadow Silhouette
    private var tonearmSilhouette: some View {
        ZStack(alignment: .topLeading) {
            // Counterweight shadow
            RoundedRectangle(cornerRadius: 3.5 * scale)
                .frame(width: 28 * scale, height: 26 * scale)
                .offset(x: centerX - 14 * scale, y: 19 * scale)

            // Pivot hub cap shadow
            Circle()
                .frame(width: 34 * scale, height: 34 * scale)
                .offset(x: centerX - 17 * scale, y: pivotY - 17 * scale)

            // Wand tube shadow
            Rectangle()
                .frame(width: 6.5 * scale, height: 236 * scale)
                .offset(x: centerX - 3.25 * scale, y: 70 * scale)

            // Angled headshell shadow
            RoundedRectangle(cornerRadius: 3 * scale)
                .frame(width: 20 * scale, height: 44 * scale)
                .rotationEffect(.degrees(24.0), anchor: .top)
                .offset(x: centerX - 10 * scale, y: 308 * scale)
        }
        .frame(width: 100 * scale, height: 380 * scale, alignment: .topLeading)
    }
}
